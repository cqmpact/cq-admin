--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

fx_version 'cerulean'

game 'gta5'

author 'cqmpact <https://github.com/cqmpact>'
description 'Dear ImgUi inspired admin menu'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_scripts {
    'shared/config.lua'
}

client_scripts {
    'client/utils.lua',
    'client/main.lua',
    'client/default/*.lua',
    'client/gizmo.js'
}
server_scripts {
    'server/main.lua',
    'server/default/*.lua'
}

node_version '22'
