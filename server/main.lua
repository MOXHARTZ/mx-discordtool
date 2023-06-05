--- @class Response
--- @field owner string The owner of the data (The discord id)
--- @field guild string The guild of the data (The discord guild id)
--- @field type TypeEnum The type of the data
--- @field data table It's coming from discord

local LISTENER_URL = 'http://localhost:3000/listener/getWaitingListeners/'
local SEND_URL = 'http://localhost:3000/listener/'
local GUILD = config.guild

local function getEnumName(value)
    for k, v in pairs(TypeEnum) do
        if v == value then return k end
    end
    return nil
end

local function enumToFunction(enum, owner, ...)
    if not enum then return error('enum is nil') end
    local enumName = getEnumName(enum)
    if not enumName then return error(('Failed to get enum name: %s'):format(enum)) end
    local funcName = _G[enumName]
    if not funcName then return error(('Failed to load enum: %s'):format(enumName)) end
    local data = funcName(...)
    return data
end

---@param data table
local function getRequestData(owner, guild, type, data)
    return enumToFunction(type, owner, data)
end

exports('GetRequestData', getRequestData)

-- ---@param data Response
-- local function progressAll(data)
--     if not next(data) or #data == 0 then return end
--     for _, v in ipairs(data) do
--         enumToFunction(v.type, v.owner, v)
--     end
-- end

-- local function listener()
--     Wait(1000)
--     local url = LISTENER_URL .. GUILD
--     ---@param data Response
--     PerformHttpRequest(url, function(statusCode, data, headers)
--         if not data then return Warn('Failed to get data from the discord api') end
--         if statusCode ~= 200 then return Warn('Failed to get data from the discord api') end
--         if data == 'null' then return end
--         if not data then return Warn('Failed to decode data from the discord api') end
--         data = type(data) == 'string' and json.decode(data) or data
--         progressAll(data)
--     end, 'GET', json.encode({}), { ['Content-Type'] = 'application/json' })
-- end

-- CreateThread(function()
--     while true do
--         Wait(1000)
--         listener()
--     end
-- end)

---@param owner string The owner of coming the discord api
---@param data table The data to send to the discord api
function SendData(owner, data)
    local url = SEND_URL .. GUILD .. '/' .. owner
    PerformHttpRequest(url, function(statusCode, text, headers)
        print(statusCode)
        print(text)
        print(headers)
    end, 'PUT', json.encode(data), { ['Content-Type'] = 'application/json' })
end

---@param player string The player server id to get the identifier from
---@param identifierType string | table The type of the identifier to get (discord, steam, license, xbl, live, fivem)
---@return string | table | nil The identifier(s)
function GetPlayerIdentifierFromType(player, identifierType)
    local data = {}
    local typeOf = type(identifierType)
    if typeOf == 'string' then identifierType = { identifierType } end
    for _, v in ipairs(identifierType) do
        local identifiers = GetPlayerIdentifiers(player)
        for _, identifier in ipairs(identifiers) do
            if identifier:find(v) then
                data[v] = identifier
                if typeOf == 'string' and v == identifierType then return identifier end
                break
            end
        end
    end
    return next(data) and data or nil
end

---@param player string The player server id to get the discord id from
---@return string | nil The discord id
function GetPlayerDiscordId(player)
    local discordId = nil
    local identifier = GetPlayerIdentifierFromType(player, 'discord')
    if identifier and type(identifier) == 'string' then
        discordId = identifier:gsub('discord:', '')
    end
    return discordId
end

---@param discordId string The discord id to get the player from
---@return string | nil The player server id
function GetPlayerFromDiscordId(discordId)
    discordId = discordId:gsub('discord:', '')
    local players = GetPlayers()
    for _, player in ipairs(players) do
        local playerDiscordId = GetPlayerDiscordId(player)
        if playerDiscordId == discordId then
            return player
        end
    end
    return nil
end

-- https://stackoverflow.com/a/27028488/19627917
---@param o table The table to dump
---@return string The dumped table
function Dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. Dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

---@param source string The player server id to get the tokens from
---@return table | nil The tokens
function GetTokensFromPlayer(source)
    local data = {}
    local tokens = GetNumPlayerTokens(source)
    if not tokens or tokens < 0 then return nil end
    for i = 0, tokens - 1 do
        local token = GetPlayerToken(source, i)
        table.insert(data, token)
    end
    return data
end

---@param identifier string The identifier to set to base (important for using the multicharacter)
---@return string The identifier without the multicharacter code (ex: 1:123456789 -> 123456789)
function SetIdentifierToBase(identifier)
    identifier = identifier:gsub(':%d+', '')
    identifier = identifier:gsub(':', '')
    return identifier
end

---@param identifier string The identifier to get the tokens from
---@param fivem string The fivem identifier
---@param license string The license identifier
---@param xbl string The xbl identifier
---@param live string The live identifier
---@param discord string The discord identifier
---@param tokens table The tokens
---@param duration number The duration of the ban
---@param reason string The reason of the ban
function Ban(identifier, fivem, license, xbl, live, discord, tokens, duration, reason)
    identifier = identifier or ''
    fivem = fivem or ''
    license = license or ''
    xbl = xbl or ''
    live = live or ''
    discord = discord or ''
    tokens = tokens or {}
    duration = duration or os.time() + config.defaultBanDuration
    reason = reason or ''
    MySQL.insert.await('INSERT INTO mx_banlist (identifier, fivem, license, xbl, live, discord, tokens, duration, reason) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        identifier,
        fivem,
        license,
        xbl,
        live,
        discord,
        json.encode(tokens),
        duration,
        reason
    })
end

--- @param type string The type of the identifier to get (discord, license, xbl, live, fivem, identifier)
--- @param identifier string The identifier to get the player from
function Unban(type, identifier)
    identifier = SetIdentifierToBase(identifier)
    local str = ([[
        DELETE FROM mx_banlist WHERE %s = ?
    ]]):format(type)
    MySQL.execute.await(str, {
        identifier
    })
end

---@param identifier string The identifier to set to base (important for using the multicharacter)
function SetWhitelist(identifier)
    identifier = SetIdentifierToBase(identifier)
    MySQL.insert.await('INSERT INTO mx_whitelist (identifier) VALUES (?) ON DUPLICATE KEY UPDATE identifier = ?', {
        identifier,
        identifier
    })
end

---@param identifier string The identifier to set to base (important for using the multicharacter)
function RemoveWhitelist(identifier)
    identifier = SetIdentifierToBase(identifier)
    MySQL.execute.await('DELETE FROM mx_whitelist WHERE identifier = ?', {
        identifier
    })
end

---@param tokens1 table The first tokens
---@param tokens2 table The second tokens
---@return boolean If the tokens are the same
local function checkTokens(tokens1, tokens2)
    for _, token1 in ipairs(tokens1) do
        for _, token2 in ipairs(tokens2) do
            if token1 == token2 then return true end
        end
    end
    return false
end

---@param time number The time to format
---@return string The formatted time
local function formatDuration(time)
    local duration = time - os.time()
    local years = math.floor(duration / (60 * 60 * 24 * 365))
    duration = duration - (years * 60 * 60 * 24 * 365)
    local months = math.floor(duration / (60 * 60 * 24 * 30))
    duration = duration - (months * 60 * 60 * 24 * 30)
    local days = math.floor(duration / (60 * 60 * 24))
    duration = duration - (days * 60 * 60 * 24)
    local hours = math.floor(duration / (60 * 60))
    duration = duration - (hours * 60 * 60)
    local minutes = math.floor(duration / 60)
    duration = duration - (minutes * 60)
    local seconds = math.floor(duration)
    local data = {}
    if years > 0 then table.insert(data, years .. ' year' .. (years > 1 and 's' or '')) end
    if months > 0 then table.insert(data, months .. ' month' .. (months > 1 and 's' or '')) end
    if days > 0 then table.insert(data, days .. ' day' .. (days > 1 and 's' or '')) end
    if hours > 0 then table.insert(data, hours .. ' hour' .. (hours > 1 and 's' or '')) end
    if minutes > 0 then table.insert(data, minutes .. ' minute' .. (minutes > 1 and 's' or '')) end
    if seconds > 0 then table.insert(data, seconds .. ' second' .. (seconds > 1 and 's' or '')) end
    return table.concat(data, ', ')
end

local banReasonProvider = [[
    You are banned from this server. 
    Reason: %s 
    Expires: %s
]]

---@param identifier string The identifier to check
---@return boolean If the player is banned
function CheckPlayerIsBanned(identifier)
    identifier = SetIdentifierToBase(identifier)
    local banList = MySQL.prepare.await('SELECT id FROM mx_banlist WHERE identifier = ?', {
        identifier
    })
    return banList and true or false
end

function CheckPlayerIsWhitelisted(identifier)
    identifier = SetIdentifierToBase(identifier)
    local whitelist = MySQL.prepare.await('SELECT id FROM mx_whitelist WHERE identifier = ?', {
        identifier
    })
    return whitelist and true or false
end

local function onPlayerConnecting(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()
    Wait(0)
    deferrals.update('We are checking some things, please wait.')
    Wait(1000)
    local identifiers = GetPlayerIdentifierFromType(source, {
        'discord',
        'license',
        'xbl',
        'live',
        'fivem'
    })
    if not identifiers then 
        deferrals.done('We can\'t get your identifiers, please try again later. If the problem persists, contact the server owner.')
        return
    end

    
    deferrals.update('We are checking if you are banned, please wait.')
    Wait(1000)

    local tokens = GetTokensFromPlayer(source)
    if not tokens then 
        deferrals.done('We can\'t get your tokens, please try again later. If the problem persists, contact the server owner.')
        return
    end
    local banList = MySQL.query.await('SELECT * FROM mx_banlist')
    if not banList or #banList == 0 then
        deferrals.done()
        return
    end

    Wait(0)

    for _, ban in ipairs(banList) do
        local banned = false
        if ban?.fivem == identifiers?.fivem then banned = true end
        if ban?.license == identifiers?.license then banned = true end
        if ban?.xbl == identifiers?.xbl then banned = true end
        if ban?.live == identifiers?.live then banned = true end
        if ban?.discord == identifiers?.discord then banned = true end
        if checkTokens(tokens, json.decode(ban.tokens)) then banned = true end
        if banned then
            if ban.duration < os.time() then
                MySQL.execute.await('DELETE FROM mx_banlist WHERE id = ?', {
                    ban.id
                })
                deferrals.done()
                return
            end
            local duration = formatDuration(ban.duration)
            local reason = banReasonProvider:format(ban.reason, duration)
            deferrals.done(reason)
            return
        end
    end

    Wait(100)

    if not config.whitelist then return deferrals.done() end

    deferrals.update('We are checking if you are whitelisted, please wait.')

    Wait(1000)
    
    local whitelisted = CheckPlayerIsWhitelisted(identifiers?.license)
    
    if not whitelisted then
        deferrals.done(config.notAllowedWhitelistText)
        return
    end

    Wait(0)

    deferrals.done()
end

AddEventHandler('playerConnecting', onPlayerConnecting)

function BanPlayer(source, reason, duration)
    local frameworkIdentifier = GetFrameworkIdentifier(source)
    if not frameworkIdentifier then return Warn('Failed to get framework identifier from source :' .. source) end
    local identifiers = GetPlayerIdentifierFromType(source, {
        'discord',
        'license',
        'xbl',
        'live',
        'fivem'
    })
    if not identifiers then return Warn('Failed to get identifier from source :' .. source) end
    local tokens = GetTokensFromPlayer(source)
    if not tokens then return Warn('Failed to get tokens from source :' .. source) end
    Ban(frameworkIdentifier, identifiers?.fivem, identifiers?.license, identifiers?.xbl, identifiers?.live, identifiers.discord, tokens, duration, reason)
    -- DropPlayer(source, reason)
end

RegisterCommand('testBan', function(source, args)
    BanPlayer(source, 'test', os.time() + 60 * 60 * 24 * 7)
end, false)
