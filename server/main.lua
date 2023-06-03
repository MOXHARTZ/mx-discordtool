--- @class Response
--- @field id string The id of the data
--- @field status StatusEnum The status of the data
--- @field owner string The owner of the data (The discord id)
--- @field guild string The guild of the data (The discord guild id)
--- @field type TypeEnum The type of the data
--- @field callback table This go to the discord
--- @field data table It's coming from discord
--- @field error string The error message

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
    SendData(owner, data)
end

---@param data Response
local function progressAll(data)
    if not next(data) or #data == 0 then return end
    for _, v in ipairs(data) do
        enumToFunction(v.type, v.owner, v)
    end
end

local function listener()
    Wait(1000)
    local url = LISTENER_URL .. GUILD
    ---@param data Response
    PerformHttpRequest(url, function(statusCode, data, headers)
        if not data then return Warn('Failed to get data from the discord api') end
        if statusCode ~= 200 then return Warn('Failed to get data from the discord api') end
        if data == 'null' then return end
        if not data then return Warn('Failed to decode data from the discord api') end
        data = type(data) == 'string' and json.decode(data) or data
        progressAll(data)
    end, 'GET', json.encode({}), { ['Content-Type'] = 'application/json' })
end

CreateThread(function()
    while true do
        Wait(1000)
        listener()
    end
end)

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

---@param player string The player server id to get the discord id from
---@return string | nil The discord id
function GetPlayerDiscordId(player)
    local discordId = nil
    local identifiers = GetPlayerIdentifiers(player)
    for _, identifier in ipairs(identifiers) do
        if string.find(identifier, 'discord:') then
            discordId = string.gsub(identifier, 'discord:', '')
            break
        end
    end
    return discordId
end

---@param discordId string The discord id to get the player from
---@return string | nil The player server id
function GetPlayerFromDiscordId(discordId)
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
