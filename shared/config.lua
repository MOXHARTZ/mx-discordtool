config = {
    framework               = 'esx',
    guild                   = '720326694271189124', -- DISCORD SERVER GUILD
    debug                   = true,                 -- Shows debug messages in console
    warning                 = true,                 -- Shows warning messages in console
    defaultBanDuration      = 60 * 60 * 24 * 7,     -- 7 days
    whitelist               = true,                 -- Enable whitelist
    notAllowedWhitelistText = [[
        You are not whitelisted on this server.
    ]]
}

exports('GetConfig', function()
    return config
end)
