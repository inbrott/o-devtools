fx_version 'bodacious'
game 'gta5'

author 'Oscar'
description 'wafawfawfawf'
version '1.0.0'

shared_scripts {
	'@qb-core/shared/locale.lua',
}

client_script "client/main.lua"

server_script {
	"server/main.lua",
	"server/permissions.lua"
}

ui_page 'html/index.html'

files {
	'html/index.html',
    'html/app.js'
    
}
