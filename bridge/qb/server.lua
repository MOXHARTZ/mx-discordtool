---@diagnostic disable: duplicate-set-field
local QBCore = exports['qb-core']:GetCoreObject()

---@param citizenid string
---@return boolean
function Framework:CheckUserIsExistInSql(citizenid)
    local result = MySQL.prepare.await('SELECT citizenid FROM players WHERE citizenid = ?', {
        citizenid
    })
    return result ~= nil
end

---@param source number
---@param message string
function Framework:ShowNotification(source, message)
    TriggerClientEvent('QBCore:Notify', source, message)
end

---@param source string
---@return string
function Framework:Revive(source)
    local resourceState = GetResourceState('qb-ambulancejob')
    if resourceState ~= 'started' then
        Warn('To use revive function, you need to start qb-ambulancejob resource.')
        return 'To use revive function, you need to start qb-ambulancejob resource.'
    end
    local src = tonumber(source)
    if not src then return 'Invalid source' end
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return 'Player not found' end
    TriggerClientEvent('hospital:client:Revive', src)
    self:ShowNotification(src, _T('revive.notification'))
    return 'success'
end

---@param citizenid string
---@param job string
---@param grade number
---@return string
function Framework:SetJob(citizenid, job, grade)
    local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if player then
        player.Functions.SetJob(job, grade)
        self:ShowNotification(player.PlayerData.source, _T('set_job.notification', job, grade))
        return 'success'
    end
    return 'SetJob is not supported for offline players for now.'
end

---@param citizenid string
---@param amount number
---@param moneyType string 'cash' | 'money' | 'black_money'
---@param action string 'add_money' | 'remove_money' | 'set_money'
---@return string
function Framework:SetMoney(citizenid, amount, moneyType, action)
    if moneyType ~= 'bank' and moneyType ~= 'cash' and moneyType ~= 'black_money' then
        return 'Invalid money type'
    end
    if moneyType == 'black_money' then
        Debug('Black money is not supported for qb. We will use crypto instead.')
        moneyType = 'crypto'
    end
    if action ~= 'add_money' and action ~= 'remove_money' and action ~= 'set_money' then
        return 'Invalid action'
    end
    local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if player then
        if action == 'add_money' then
            player.Functions.AddMoney(moneyType, amount)
            self:ShowNotification(player.PlayerData.source, _T('set_money.add.notification', moneyType, amount))
        elseif action == 'remove_money' then
            player.Functions.RemoveMoney(moneyType, amount)
            self:ShowNotification(player.PlayerData.source, _T('set_money.remove.notification', moneyType, amount))
        elseif action == 'set_money' then
            player.Functions.SetMoney(moneyType, amount)
            self:ShowNotification(player.PlayerData.source, _T('set_money.set.notification', moneyType, amount))
        end
        return 'success'
    end
    if not self:CheckUserIsExistInSql(citizenid) then return _T('command.not_found_user_in_database') end
    local accounts = MySQL.prepare.await('SELECT money FROM players WHERE citizenid = ?', {
        citizenid
    })
    if not accounts then return _T('command.not_found_user_in_database') end
    if type(accounts) == 'string' then 
        accounts = json.decode(accounts)
    end
    if action == 'set_money' then
        accounts[moneyType] = amount
    else
        amount = action == 'add_money' and amount or -amount
        accounts[moneyType]+= amount
    end
    MySQL.update.await('UPDATE players SET money = ? WHERE citizenid = ?', {
        json.encode(accounts),
        citizenid
    })
    return 'success'
end

---@param citizenid string
---@param group string
---@return string
function Framework:SetGroup(citizenid, group)
    local player = self:GetPlayerByIdentifier(citizenid)
    if player then
        if group == 'user' then
            QBCore.Functions.RemovePermission(player.PlayerData.source)
        else
            QBCore.Functions.AddPermission(player.PlayerData.source, group)
        end
        self:ShowNotification(player.PlayerData.source, _T('set_group.notification', group))
        return 'success'
    end
    return _T('qb.set_group.error')
end

---@param citizenid string
---@return table
function Framework:GetPlayerByIdentifier(citizenid)
    return QBCore.Functions.GetPlayerByCitizenId(citizenid)
end

---@param permissions string[]
---@return string
local function concatPermissions(permissions)
    local str = ''
    for i = 1, #permissions do
        str = str .. permissions[i]
        if i ~= #permissions then
            str = str .. ','
        end
    end
    return str
end

--- @param citizenid string
---@return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, inventory: table, status: 'online' | 'offline', source?: number}
function Framework:GetUserData(citizenid)
    if not citizenid then 
        return {
            errorCode = 301
        } 
    end
    local str = 'SELECT charinfo, money, job, inventory, license FROM players WHERE citizenid = ?'
    local player = self:GetPlayerByIdentifier(citizenid)
    local result
     
    if not player then
        result = MySQL.prepare.await(str, {
            citizenid
        })    
    end
    
    if not result and not player then return {} end
    if not result then result = {} end

    if player then
        local playerData = player.PlayerData
        local source = playerData.source
        local ped = GetPlayerPed(source)
        local inventory = FormatInventory(playerData.items)
        result.license = playerData.license
        result.charinfo = playerData.charinfo
        result.accounts = playerData.money
        result.job = playerData.job.label
        result.inventory = inventory
        local permissions = QBCore.Functions.GetPermission(source)
        result.group = concatPermissions(permissions)
        result.source = source
        result.health = GetEntityHealth(ped)
        result.ping = GetPlayerPing(source)
        result.discord = GetPlayerDiscordId(source)
    else
        result.job = json.decode(result.job)
        result.job = result.job.label
        result.accounts = json.decode(result.money)
        result.charinfo = json.decode(result.charinfo)
        result.inventory = json.decode(result.inventory)
        result.inventory = FormatInventory(result.inventory)
    end

    result.accounts['black_money'] = result.accounts['crypto'] .. ' (crypto)'

    local charinfo = result.charinfo
    charinfo.gender = FormatGender(result.charinfo.gender)
    charinfo.height = 'Unknown'

    local banned = CheckPlayerIsBanned(result.license)
    local whitelisted = CheckPlayerIsWhitelisted({
        license = result.license
    })

    return {
        charinfo = charinfo,
        identifier = citizenid,
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
        source = result.source
    }
end

--- @param source number | string
---@return string
function Framework:GetIdentifier(source)
    local src = tonumber(source)
    if not src then return 'Invalid source' end
    local player = QBCore.Functions.GetPlayer(src)
    return player?.PlayerData?.citizenid
end

--- @param citizenid string
---@return string | false
function Framework:SetIdentifier(citizenid)
    local license = MySQL.prepare.await('SELECT license FROM players WHERE citizenid = ?', {
        citizenid
    })
    if not license or type(license) ~= 'string' then return false end
    return license
end

---@param source string
---@param item string
---@param count number
---@return string
function Framework:GiveItem(source, item, count)
    local src = tonumber(source)
    if not src then return 'Invalid source' end
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        player.Functions.AddItem(item, count)
        self:ShowNotification(src, _T('give_item.notification', count, item))
        return 'success'
    end
    return _T('qb.player_not_found')
end

---@param source string
---@param item string
---@param count number
---@return string
function Framework:RemoveItem(source, item, count)
    local src = tonumber(source)
    if not src then return 'Invalid source' end
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        player.Functions.RemoveItem(item, count)
        self:ShowNotification(src, _T('remove_item.notification', count, item))
        return 'success'
    end
    return _T('qb.player_not_found')
end

---@param firstName string
---@param lastName string
---@return string | table {errorCode: number}
function Framework:GetIdentifierByFirstnameAndLastname(firstName, lastName)
    local citizenid = MySQL.prepare.await('SELECT citizenid FROM players WHERE charinfo LIKE ? OR charinfo LIKE ?', {
        '%' .. firstName .. '%',
        '%' .. lastName .. '%'
    })
    if not citizenid then 
        return {
            errorCode = 301
        }
    end
    return citizenid
end