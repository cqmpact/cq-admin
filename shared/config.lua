--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

CQAdmin_Config = CQAdmin_Config or {}

CQAdmin_Config.enabledModules = CQAdmin_Config.enabledModules or {
    player = true,
    weapons = true,
    vehicles = true,
    appearance = true,
    time_weather = true,
    misc = true,
    world = true,
    debug = true,
}

if CQAdmin_Config.quietNotifications == nil then
    CQAdmin_Config.quietNotifications = true
end
