fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'Texas Legend Gaming'
description 'Speakeasy System for VORP Framework with Moonshine Brewing Minigame'
version '1.1.9'

dependencies {
    'vorp_core',
    'vorp_inventory',
    'oxmysql',
    'vorp_menu',
}

client_scripts {
    'client.lua',
    'moonshinemaster.lua'
}

server_scripts {
    'server.lua'
}

ui_page 'html/ui.html'

files {
    'html/ui.html'
}