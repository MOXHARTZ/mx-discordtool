--- @class Response
--- @field owner string The owner of the data (The discord id)
--- @field guild string The guild of the data (The discord guild id)
--- @field type TypeEnum The type of the data
--- @field data table It's coming from discord

local convar = GetConvar("mysql_connection_string", "")

local function parseUri(connectionString)
    local uri = {}
    local str = connectionString:sub(9)
    local split = str:split('?')
    local uriStr = split[1]
    local paramsStr = split[2]
    local uriSplit = uriStr:split('@')
    local auth = uriSplit[1]
    local host = uriSplit[2]
    local authSplit = auth:split(':')
    local user = authSplit[1]
    local password = authSplit[2]
    local hostSplit = host:split('/')
    local hostSplit2 = hostSplit[1]:split(':')
    local hostName = hostSplit2[1]
    local port = hostSplit2[2]
    local database = hostSplit[2]
    uri.user = user
    uri.password = password
    uri.hostName = hostName
    uri.port = port
    uri.database = database
    if paramsStr then
        local paramsSplit = paramsStr:split('&')
        for _, param in ipairs(paramsSplit) do
            local paramSplit = param:split('=')
            local key = paramSplit[1]
            local value = paramSplit[2]
            uri[key] = value
        end
    end
    return uri
end

DATABASE_NAME = convar:match("database=(.-);")

if not DATABASE_NAME and convar:match("mysql://") then
    local uri = parseUri(convar)
    DATABASE_NAME = uri.database
end

if not DATABASE_NAME then
    error('Failed to get database name from mysql_connection_string convar. Please check your mysql_connection_string convar. You can reference here: https://overextended.dev/oxmysql/issues')
end

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

---@param player string The player server id to get the identifier from
---@param identifierType string | table The type of the identifier to get (discord, steam, license, xbl, live, fivem)
---@return string | table | nil The identifier(s)
function GetPlayerIdentifierFromType(player, identifierType)
    local data
    local typeOf = type(identifierType)
    if typeOf == 'string' then identifierType = { identifierType } end
    if typeOf == 'table' then data = {} end
    for _, v in ipairs(identifierType) do
        local identifiers = GetPlayerIdentifiers(player)
        for _, identifier in ipairs(identifiers) do
            if identifier:find(v) then
                if typeOf == 'table' then
                    data[v] = identifier
                end
                if typeOf == 'string' and v == identifierType[1] then 
                    data = identifier
                end
                break
            end
        end
    end
    if type(data) == 'table' and not next(data) then return nil end
    return data
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

---@param unknownId string The unknown id to get the player server id from (must be discord or identifier or source)
---@return string | nil The player server id
function GetPlayerFromUnknownId(unknownId)
    unknownId = unknownId:gsub('discord:', '')
    local players = GetPlayers()
    for _, player in ipairs(players) do
        if player == unknownId then return player end
        local identifier = Framework:GetIdentifier(player)
        if identifier == unknownId then return player end
        local playerDiscordId = GetPlayerDiscordId(player)
        if playerDiscordId == unknownId then return player end
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
    local split = identifier:split(':')
    if #split > 1 then
        identifier = split[2]
    end
    return identifier
end

--- @param data {identifier: string}
--- @return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, inventory: table, status: 'online' | 'offline'}
function GetUserById(data)
    local resolve = Framework:GetUserData(data.identifier)
    return resolve
end

---@param data {discord: string, character: number} 
---@return table
function GetUserByDiscord(data)
    local source = GetPlayerFromUnknownId(data.discord)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        } 
    end
    local identifier = Framework:GetIdentifier(source)
    local resolve = Framework:GetUserData(identifier)
    return resolve
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
local function banSql(identifier, fivem, license, xbl, live, discord, tokens, duration, reason)
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
    return banList ~= nil
end

---@param identifiers table {license: string, steam: string}
---@return boolean If the player is whitelisted
function CheckPlayerIsWhitelisted(identifiers)
    if identifiers.license then
        identifiers.license = SetIdentifierToBase(identifiers.license)
    end
    local whitelist = MySQL.prepare.await('SELECT identifier FROM mx_whitelist WHERE identifier = ? OR identifier = ?', {
        identifiers.license,
        identifiers.steam or '-1'
    })
    return whitelist ~= nil 
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
        'fivem',
        'steam'
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
    if not banList or #banList == 0 then goto skipBanCheck end

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

    ::skipBanCheck::

    Wait(100)

    if not config.whitelist then return deferrals.done() end

    deferrals.update('We are checking if you are whitelisted, please wait.')

    Wait(1000)
    
    -- Hmm i don't know how to i get rockstar license from the api, so i'm using the steam id for the whitelist.
    local whitelisted = CheckPlayerIsWhitelisted({
        license = identifiers?.license,
        steam = identifiers?.steam
    })

    if not whitelisted then
        deferrals.done(config.notAllowedWhitelistText)
        return
    end

    Wait(0)

    deferrals.done()
end

AddEventHandler('playerConnecting', onPlayerConnecting)

---@param source string The player server id to get the framework identifier from
---@param reason string The reason of the ban
---@param duration number The duration of the ban
local function ban(source, reason, duration)
    local frameworkIdentifier = Framework:GetIdentifier(source)
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
    banSql(frameworkIdentifier, identifiers?.fivem, identifiers?.license, identifiers?.xbl, identifiers?.live, identifiers.discord, tokens, duration, reason)
    DropPlayer(source, reason)
end

exports('Ban', ban)

---@param data {identifier: string, reason: string, duration: string | number} The data to ban the user
---@return string | table The error code or success
function BanUser(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        }
    end
    local duration = tonumber(data.duration)
    if not duration then return 'Duration is not a number!' end
    duration = os.time() + duration * 60 * 60
    ban(source, data.reason, duration)
    return 'success'
end

local genders = {
    ['m'] = 'Male',
    ['f'] = 'Female',
    [0] = 'Male',
    [1] = 'Female'
}

function FormatGender(gender)
    gender = genders[gender]
    return gender or 'Unknown Gender' 
end

---@param data {identifier: string} The data to get the user from
---@return string returns the screenshot url
function Screenshot(data)
    local resourceState = GetResourceState('screenshot-basic')
    if resourceState ~= 'started' then 
        Warn('Screenshot property is working with screenshot-basic resource. If you want to use it, please install the screenshot-basic. https://github.com/citizenfx/screenshot-basic')
        return 'Screenshot property is working with screenshot-basic resource. If you want to use it, please install the screenshot-basic.'
    end
    local discord = data.identifier
    local source = GetPlayerFromUnknownId(discord)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        } 
    end
    local screenshot = lib.callback.await('mx-discordtool:takeScreenshot', source)
    return screenshot
end

---@param data {identifier:string, reason: string}
---@return string | table The error code or success
function KickUser(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        }
    end
    DropPlayer(source, data.reason)
    return 'success'
end

local wipeFetch = ([[
    SELECT TABLE_NAME, COLUMN_NAME, CHARACTER_MAXIMUM_LENGTH
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = '%s' AND DATA_TYPE = 'varchar' AND COLUMN_NAME IN('identifier','owner','citizenid')
]]):format(DATABASE_NAME)

---@param identifier string The identifier to wipe
---@return string | table The error code or success
local function sqlWipe(identifier)
    local userIsExist = Framework:CheckUserIsExistInSql(identifier)
    if not userIsExist then 
        return {
            errorCode = 301 -- User is not in the database
        }
    end

    local result = MySQL.query.await(wipeFetch)
    for k,element in pairs(result) do
        local wipeExecute = ([[
            DELETE FROM %s WHERE %s = ?
        ]]):format(element.TABLE_NAME, element.COLUMN_NAME)
        MySQL.Sync.execute(wipeExecute:format(element.TABLE_NAME, element.COLUMN_NAME), {
            identifier
        })
    end
    return 'success'
end

---@param data {identifier: string }
---@return string | table The error code or success
function Wipe(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    local identifier
    if source then 
        local identifier = Framework:GetIdentifier(source)
        if not identifier then return 'Failed to get identifier from source :' .. source end
        DropPlayer(source, 'You have been wiped from the server.')
    else    
        identifier = data.identifier
        local player = Framework:GetPlayerByIdentifier(identifier)
        if player then
            DropPlayer(player.source, 'You have been wiped from the server.')
        end
    end
    
    return sqlWipe(identifier)
end

---@param data {identifier: string }
---@return string | table The error code or success
function Revive(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        }
    end
    return Framework:Revive(source)
end

---@param data {identifier: string }
---@return string | table The error code or success
function Kill(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        }
    end
    local src = tonumber(source)
    if not src then return 'Source is not a number!' end
    TriggerClientEvent('mx-discordtool:die', src)
    Framework:ShowNotification(src, 'You have been killed by an admin.')
    return 'success'
end

---@param data {identifier: string, coords: {x: number, y: number, z: number} }
---@return string | table The error code or success
function SetCoords(data)
    local source = GetPlayerFromUnknownId(data.identifier)
    if not source then 
        return {
            errorCode = 301 -- User is not in the server
        }
    end
    local src = tonumber(source)
    if not src then return 'Source is not a number!' end
    local ped = GetPlayerPed(src)
    local coords = data.coords
    local x = tonumber(coords.x)
    local y = tonumber(coords.y)
    local z = tonumber(coords.z)
    if not x or not y or not z then return 'Invalid coords' end
    SetEntityCoords(ped, x, y, z, true, false, false, false)
    Framework:ShowNotification(src, 'Your coordinates have been set by an admin.')
    return 'success'
end

---@param data {identifier: string }
---@return string | table The error code or success
function ToggleWhitelist(data)
    local whitelisted = CheckPlayerIsWhitelisted({
        license = data.identifier
    })
    if whitelisted then
        RemoveWhitelist(data.identifier)
    else
        SetWhitelist(data.identifier)
    end
    return 'Changed whitelist status. New status: ' .. (whitelisted and '❌' or '✅') 
end