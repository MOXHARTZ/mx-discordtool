--- @param identifier string 
---@return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, inventory: table}
function GetUserData(identifier)
    local result = MySQL.prepare.await('SELECT firstname, lastname, accounts, job, inventory, `group` FROM users WHERE identifier = ?', {
        identifier
    })

    if not result then return {} end
    result.accounts = json.decode(result.accounts)
    result.inventory = json.decode(result.inventory)
    local charinfo = {
        firstname = result.firstname,
        lastname = result.lastname
    }

    -- TODO: Implement this
    local banned = false
    local whitelisted = false

    return {
        charinfo = charinfo,
        identifier = identifier,
        accounts = result.accounts,
        job = result.job,
        banned = banned,
        group = result.group,
        whitelisted = whitelisted,
        inventory = result.inventory
    }
end

--- @param data table
---@return {banned: boolean, whitelisted: boolean, job: string, charinfo: table, accounts: table, group: string, identifier: string, status: 'offline', inventory: table}
function GetUserById(data)
    local resolve = GetUserData(data.data.identifier)
    resolve.status = 'offline'
    ---@diagnostic disable-next-line: return-type-mismatch
    return resolve
end

CreateThread(function()
    local user = GetUserData('0:246a9bdb081228f5ff60af41b6b471bf1d382dd3')
    -- Warn('GetUserData', Dump(user))
end)


function GetUser()
    return {}
end
