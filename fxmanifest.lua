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
version '2.0.1'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/imgui.js',
    'html/imgui.wasm',
    'html/fonts/ProggyClean.ttf'
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
    'server/_ctx.lua',
    'server/default/*.lua'
}

node_version '22'
