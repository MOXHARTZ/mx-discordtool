config = {
    framework          = 'esx',
    guild              = '720326694271189124',         -- DISCORD SERVER GUILD
    debug              = true,                         -- Shows debug messages in console
    warning            = true,                         -- Shows warning messages in console
    defaultBanDuration = 60 * 60 * 24 * 7,             -- 7 days
    whitelist          = true,                         -- Enable whitelist
    discordInviteLink  = 'https://discord.gg/7ZyX3ZQ', -- Discord invite link
    webhook            = '',                           -- Discord webhook for the screenshots
    language           = 'en-US',                      -- (en-US) https://github.com/MOXHARTZ/fivem-manager-bot-translations
}

exports('GetConfig', function()
    return config
end)
