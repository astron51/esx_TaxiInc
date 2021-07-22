-- Resource Metadata
fx_version 'cerulean'
games {'gta5' }

author 'Meowdy'
description 'AI Taxi'
version '1.1.5'

dependencies{
    'es_extended'
}

shared_script '@es_extended/imports.lua'

client_scripts {
    '@es_extended/locale.lua',
    'locale/*.lua',
    'shared/config.lua',
    'client/client.lua'
}
server_script {
    '@es_extended/locale.lua',
    'locale/*.lua',
    'shared/config.lua',
    'server/server.lua'
}