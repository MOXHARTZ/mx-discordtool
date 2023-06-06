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

---@param identifier string
---@param job string
---@param grade number
---@return string
function Framework:SetJob(identifier, job, grade)
    if not ESX.DoesJobExist(job, grade) then 
        return 'Job or grade does not exist'
    end
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        player.setJob(job)
        player.showNotification('Your job has been changed to ' .. job)
        return 'success'
    end
    if not self:CheckUserIsExistInSql(identifier) then return 'User not found in the sql.' end
    MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
        job,
        grade,
        identifier
    })
    return 'success'
end

---@param identifier string
---@param amount number
---@param moneyType string 'cash' | 'money' | 'black_money'
---@param action string 'add_money' | 'remove_money' | 'set_money'
---@return string
function Framework:SetMoney(identifier, amount, moneyType, action)
    if moneyType ~= 'bank' and moneyType ~= 'cash' and moneyType ~= 'black_money' then
        return 'Invalid money type'
    end
    if moneyType == 'cash' then moneyType = 'money' end
    if action ~= 'add_money' and action ~= 'remove_money' and action ~= 'set_money' then
        return 'Invalid action'
    end
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        if action == 'add_money' then
            player.addAccountMoney(moneyType, amount)
            player.showNotification('You have been given ' .. amount .. ' ' .. moneyType)
        elseif action == 'remove_money' then
            player.removeAccountMoney(moneyType, amount)
            player.showNotification('You have been removed ' .. amount .. ' ' .. moneyType)
        elseif action == 'set_money' then
            player.setAccountMoney(moneyType, amount)
            player.showNotification('Your ' .. moneyType .. ' has been set to ' .. amount)
        end
        return 'success'
    end
    if not self:CheckUserIsExistInSql(identifier) then return 'User not found in the sql.' end
    local accounts = MySQL.prepare.await('SELECT accounts FROM users WHERE identifier = ?', {
        identifier
    })
    if not accounts then return 'User not found in the sql.' end
    if type(accounts) == 'string' then 
        accounts = json.decode(accounts)
    end
    if action == 'set_money' then
        accounts[moneyType] = amount
    else
        amount = action == 'add_money' and amount or -amount
        accounts[moneyType]+= amount
    end
    MySQL.update.await('UPDATE users SET accounts = ? WHERE identifier = ?', {
        json.encode(accounts),
        identifier
    })
    return 'success'
end

---@param identifier string
---@param group string
---@return string
function Framework:SetGroup(identifier, group)
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        player.setGroup(group)
        player.showNotification('Your group has been changed to ' .. group)
        return 'success'
    end
    if not self:CheckUserIsExistInSql(identifier) then return 'User not found in the sql.' end
    MySQL.update.await('UPDATE users SET `group` = ? WHERE identifier = ?', {
        group,
        identifier
    })
    return 'success'
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

-- ---@param inventory table
-- ---@param name string
-- ---@param count number
-- local function addItem(inventory, name, count)
--     for _, item in ipairs(inventory) do
--         if item.name == name then
--             item.count+= count
--             return inventory
--         end
--     end
--     table.insert(inventory, {
--         name = name,
--         count = count
--     })
-- end

---@param source string
---@param item string
---@param count number
---@return string
function Framework:GiveItem(source, item, count)
    local player = ESX.GetPlayerFromId(source)
    if player then
        player.addInventoryItem(item, count)
        player.showNotification('You have been given ' .. count .. ' ' .. item)
        return 'success'
    end
    return 'ESX player is not found'
end

---@param source string
---@param item string
---@param count number
---@return string
function Framework:RemoveItem(source, item, count)
    local player = ESX.GetPlayerFromId(source)
    if player then
        player.removeInventoryItem(item, count)
        player.showNotification('You have been removed ' .. count .. ' ' .. item)
        return 'success'
    end
    return 'ESX player is not found'
end