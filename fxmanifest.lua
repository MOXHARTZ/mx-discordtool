fx_version 'cerulean'
games { 'gta5' }
author 'MOXHA'
lua54 'yes'
shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'bridge/client.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/*.lua'
}
