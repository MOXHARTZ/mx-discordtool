ESX = exports['es_extended']:getSharedObject()

local function getPlayerAccounts(player)
    local accounts = player.getAccounts()
    local result = {}
    if not accounts then return result end
    for _, account in ipairs(accounts) do
        result[account.name] = account.money
    end
    return result
end

---@param inventory table
---@return table
local function formatInventory(inventory)
    local result = {}
    if not inventory then return result end
    for _, item in ipairs(inventory) do
        table.insert(result, item)
    end
    return result
end

---@param identifier string
---@return boolean
function Framework:CheckUserIsExistInSql(identifier)
    local result = MySQL.prepare.await('SELECT identifier FROM users WHERE identifier = ?', {
        identifier
    })
    return result ~= nil
end

---@param source number
---@param message string
function Framework:ShowNotification(source, message)
    TriggerClientEvent('esx:showNotification', source, message)
end

---@param source string
---@return string
function Framework:Revive(source)
    local resourceState = GetResourceState('esx_ambulancejob')
    if resourceState ~= 'started' then 
        Warn('To use revive function, you need to start esx_ambulancejob resource.')
        return 'To use revive function, you need to start esx_ambulancejob resource.'
    end
    local player = ESX.GetPlayerFromId(source)
    if not player then return 'Player not found' end
    player.triggerEvent('esx_ambulancejob:revive')
    player.showNotification('You have been revived by an admin.')
    return 'success'
end

function Framework:SetJob(identifier, job)
    local result = MySQL.update.await('UPDATE users SET job = ? WHERE identifier = ?', {
        job,
        identifier
    })
    return result
end

function Framework:SetGroup(identifier, group)
    local result = MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', {
        group,
        identifier
    })
    return result
end

---@param identifier string
---@return table
function Framework:GetPlayerByIdentifier(identifier)
    return ESX.GetPlayerFromIdentifier(identifier)
end

--- @param identifier string
---@return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, inventory: table, status: 'online' | 'offline'}
function Framework:GetUserData(identifier)
    local str = 'SELECT firstname, lastname, accounts, job, inventory, `group`, sex, dateofbirth, phone_number, height FROM users WHERE identifier = ?'
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        str = 'SELECT firstname, lastname, sex, dateofbirth, phone_number, height FROM users WHERE identifier = ?'
    end
     
    local result = MySQL.prepare.await(str, {
        identifier
    })

    if not result then return {} end

    if player then
        local source = player.source
        local ped = GetPlayerPed(source)
        local inventory = formatInventory(player.getInventory())
        result.accounts = getPlayerAccounts(player)
        result.job = player.getJob().name
        result.inventory = inventory
        result.group = player.getGroup()
        result.armor = tostring(GetPedArmour(ped))
        result.health = GetEntityHealth(ped)
        result.ping = GetPlayerPing(source)
        result.discord = GetPlayerDiscordId(source)
    else
        result.accounts = json.decode(result.accounts)
        result.inventory = json.decode(result.inventory)
        result.inventory = formatInventory(result.inventory)
    end

    local charinfo = {
        firstname = result.firstname,
        lastname = result.lastname,
        birthdate = result.dateofbirth,
        gender = FormatGender(result.sex),
        phone = result.phone_number,
        height = result.height
    }

    local banned = CheckPlayerIsBanned(identifier)
    local whitelisted = CheckPlayerIsWhitelisted({
        license = identifier
    })

    return {
        charinfo = charinfo,
        identifier = identifier,
        accounts = result.accounts,
        job = result.job,
        banned = banned,
        group = result.group,
        whitelisted = whitelisted,
        inventory = result.inventory,
        status = player and 'online' or 'offline',
        isActive = player ~= nil,
        health = result.health,
        ping = result.ping,
        discord = result.discord,
        armor = result.armor
    }
end

--- @param source string
---@return string
function Framework:GetIdentifier(source)
    local player = ESX.GetPlayerFromId(source)
    return player?.identifier
end