--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

local _worldCooldown = {}
local WORLD_COOLDOWN_MS = GetConvarInt('cqadmin_world_cooldown_ms', 2000)
AddEventHandler('playerDropped', function()
    local src = source
    _worldCooldown[src] = nil
end)

local function _sanitizeModelName(name)
    if type(name) ~= 'string' then return '' end
    name = name:match('^%s*(.-)%s*$') or ''
    -- allow only alnum, underscore, dot, and dash; limit length
    name = name:gsub('[^%w%._%-]', '')
    if #name > 64 then name = name:sub(1, 64) end
    return name
end

RegisterNetEvent('cq-admin:sv:spawnObject', function(model)
    local src = source
    local group = GROUPS.spawnObject
    if not hasGroup(src, group) then return deny(src, 'spawnObject', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid object model', false)
    end
    issueGrant(src, 'spawnObject', 'cq-admin:cl:spawnObject', model)
end)

RegisterNetEvent('cq-admin:sv:spawnObjectAt', function(model, x, y, z, heading)
    local src = source
    local group = GROUPS.spawnObjectAt or GROUPS.spawnObject
    if not hasGroup(src, group) then return deny(src, 'spawnObjectAt', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid object model', false)
    end
    x = tonumber(x); y = tonumber(y); z = tonumber(z); heading = tonumber(heading) or 0.0
    if not x or not y or not z then
        return notify(src, 'error', 'Invalid placement coordinates', false)
    end
    issueGrant(src, 'spawnObjectAt', 'cq-admin:cl:spawnObjectAt', model, x, y, z, heading)
end)

RegisterNetEvent('cq-admin:sv:deleteNearby', function(entType, radius)
    local src = source
    local group = GROUPS.delNearby
    if not hasGroup(src, group) then return deny(src, 'deleteNearby', group) end
    local now = GetGameTimer()
    local last = _worldCooldown[src] or 0
    if (now - last) < WORLD_COOLDOWN_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled deleteNearby from src %d'):format(src))
        end
        return
    end
    _worldCooldown[src] = now
    local t = tostring(entType or 'objects')
    if t ~= 'objects' and t ~= 'vehicles' and t ~= 'peds' and t ~= 'all' then
        t = 'objects'
    end
    local r = tonumber(radius) or 30.0
    if r < 1.0 then r = 1.0 end
    if r > 200.0 then r = 200.0 end
    issueGrant(src, 'deleteNearby', 'cq-admin:cl:deleteNearby', t, r)
end)
