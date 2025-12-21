--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

RegisterNetEvent('cq-admin:sv:speedoKMH', function(enabled)
    local src = source
    local group = GROUPS.speedoKMH
    if not hasGroup(src, group) then return deny(src, 'speedoKMH', group) end
    issueGrant(src, 'speedoKMH', 'cq-admin:cl:speedoKMH', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:speedoMPH', function(enabled)
    local src = source
    local group = GROUPS.speedoMPH
    if not hasGroup(src, group) then return deny(src, 'speedoMPH', group) end
    issueGrant(src, 'speedoMPH', 'cq-admin:cl:speedoMPH', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:showCoords', function(enabled)
    local src = source
    local group = GROUPS.showCoords
    if not hasGroup(src, group) then return deny(src, 'showCoords', group) end
    issueGrant(src, 'showCoords', 'cq-admin:cl:showCoords', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:hideHUD', function(enabled)
    local src = source
    local group = GROUPS.hideHUD
    if not hasGroup(src, group) then return deny(src, 'hideHUD', group) end
    issueGrant(src, 'hideHUD', 'cq-admin:cl:hideHUD', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:hideRadar', function(enabled)
    local src = source
    local group = GROUPS.hideRadar
    if not hasGroup(src, group) then return deny(src, 'hideRadar', group) end
    issueGrant(src, 'hideRadar', 'cq-admin:cl:hideRadar', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:showLocation', function(enabled)
    local src = source
    local group = GROUPS.showLocation
    if not hasGroup(src, group) then return deny(src, 'showLocation', group) end
    issueGrant(src, 'showLocation', 'cq-admin:cl:showLocation', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:showTime', function(enabled)
    local src = source
    local group = GROUPS.showTime
    if not hasGroup(src, group) then return deny(src, 'showTime', group) end
    issueGrant(src, 'showTime', 'cq-admin:cl:showTime', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:nightVision', function(enabled)
    local src = source
    local group = GROUPS.nightVision
    if not hasGroup(src, group) then return deny(src, 'nightVision', group) end
    issueGrant(src, 'nightVision', 'cq-admin:cl:nightVision', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:thermalVision', function(enabled)
    local src = source
    local group = GROUPS.thermalVision
    if not hasGroup(src, group) then return deny(src, 'thermalVision', group) end
    issueGrant(src, 'thermalVision', 'cq-admin:cl:thermalVision', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:lockCamX', function(enabled)
    local src = source
    local group = GROUPS.lockCamX
    if not hasGroup(src, group) then return deny(src, 'lockCamX', group) end
    issueGrant(src, 'lockCamX', 'cq-admin:cl:lockCamX', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:lockCamY', function(enabled)
    local src = source
    local group = GROUPS.lockCamY
    if not hasGroup(src, group) then return deny(src, 'lockCamY', group) end
    issueGrant(src, 'lockCamY', 'cq-admin:cl:lockCamY', enabled and true or false)
end)

local _miscCooldown = {}
local MISC_COOLDOWN_MS = GetConvarInt('cqadmin_misc_cooldown_ms', 2000)
AddEventHandler('playerDropped', function()
    local src = source
    _miscCooldown[src] = nil
end)

RegisterNetEvent('cq-admin:sv:clearArea', function()
    local src = source
    local group = GROUPS.clearArea
    if not hasGroup(src, group) then return deny(src, 'clearArea', group) end
    local now = GetGameTimer()
    local last = _miscCooldown[src] or 0
    if (now - last) < MISC_COOLDOWN_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled clearArea from src %d'):format(src))
        end
        return
    end
    _miscCooldown[src] = now
    issueGrant(src, 'clearArea', 'cq-admin:cl:clearArea')
end)
