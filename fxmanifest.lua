fx_version 'cerulean'
games { 'gta5' }
author 'MOXHA'
lua54 'yes'
shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'index.js',
    'server/*.lua',
}
