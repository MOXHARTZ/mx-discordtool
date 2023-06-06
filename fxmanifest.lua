fx_version 'cerulean'
game 'gta5'
author 'MOXHA'
lua54 'yes'

name 'MX Discord Tool'
description 'A Tool for the MX BOT'
version '1.0.0'
repository 'https://github.com/MOXHARTZ/mx-discordtool'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/modules/translate.lua',
    'bridge/server.lua',
    'index.js',
    'server/*.lua',
}

dependencies {
    '/server:5895',
    '/onesync',
    'oxmysql',
    'ox_lib'
}
