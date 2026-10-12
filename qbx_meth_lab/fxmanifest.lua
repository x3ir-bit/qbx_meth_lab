fx_version 'cerulean'
game 'gta5'

author 'x3ir'
description 'QBCore Meth Lab - Merged & Fixed'
version '2.0.0'

shared_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@ox_lib/init.lua',
    'config.lua'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}

server_scripts {
    'server/main.lua',
    'server/workers.lua',
    'server/dealers.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/dealer.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/images/*.png'
}

lua54 'yes'   