ESX = exports['es_extended']:getSharedObject()

function GetPlayerAccounts(player)
    local accounts = player.getAccounts()
    local result = {}
    for _, account in ipairs(accounts) do
        table.insert(result, {
            name = account.name,
            money = account.money
        })
    end
    return result
end

--- @param identifier string
---@return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, inventory: table, status: 'online' | 'offline'}
function GetUserData(identifier)
    identifier = SetIdentifierToBase(identifier)
    local str = [[
        SELECT firstname, lastname, accounts, job, inventory, `group` FROM users WHERE identifier = ?
    ]]
    local player = ESX.GetPlayerFromIdentifier(identifier)
    if player then
        str = [[
            SELECT firstname, lastname FROM users WHERE identifier = ?
        ]]
    end
     
    local result = MySQL.prepare.await(str, {
        identifier
    })

    if not result then return {} end

    if player then
        result.accounts = GetPlayerAccounts(player)
        result.job = player.getJob().name
        result.inventory = player.getInventory()
        result.group = player.getGroup()
    else
        result.accounts = json.decode(result.accounts)
        result.inventory = json.decode(result.inventory)
    end

    local charinfo = {
        firstname = result.firstname,
        lastname = result.lastname
    }

    local banned = CheckPlayerIsBanned(identifier)
    local whitelisted = CheckPlayerIsWhitelisted(identifier)

    return {
        charinfo = charinfo,
        identifier = identifier,
        accounts = result.accounts,
        job = result.job,
        banned = banned,
        group = result.group,
        whitelisted = whitelisted,
        inventory = result.inventory,
        status = player and 'online' or 'offline'
    }
end

--- @param data table
function GetUserById(data)
    local resolve = GetUserData(data.identifier)
    return resolve
end

function GetUser()
    return {}
end

--- @param source string
---@return string
function GetFrameworkIdentifier(source)
    local player = ESX.GetPlayerFromId(source)
    return player?.identifier
end

RegisterCommand('checkToken', function(source, args)
    local tokens = GetPlayerTokens(source)
    for _, token in ipairs(tokens) do
        print('all:', token)
    end
    local token = GetPlayerToken(source, 1)

    print(token)
end, false)
