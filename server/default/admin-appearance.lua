--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

local function _sanitizeModelName(name)
    if type(name) ~= 'string' then return '' end
    name = name:match('^%s*(.-)%s*$') or ''
    name = name:gsub('[^%w%._%-]', '')
    if #name > 64 then name = name:sub(1, 64) end
    return name
end

RegisterNetEvent('cq-admin:sv:spawnPedByName', function(model)
    local src = source
    local group = GROUPS.spawnPedByName
    if not hasGroup(src, group) then return deny(src, 'spawnPedByName', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid ped model', false)
    end
    issueGrant(src, 'spawnPedByName', 'cq-admin:cl:spawnPedByName', model)
end)

RegisterNetEvent('cq-admin:sv:resetPed', function()
    local src = source
    local group = GROUPS.resetPed
    if not hasGroup(src, group) then return deny(src, 'resetPed', group) end
    issueGrant(src, 'resetPed', 'cq-admin:cl:resetPed')
end)

RegisterNetEvent('cq-admin:sv:setPedPreset', function(model)
    local src = source
    local group = GROUPS.setPedPreset
    if not hasGroup(src, group) then return deny(src, 'setPedPreset', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid ped model', false)
    end
    issueGrant(src, 'setPedPreset', 'cq-admin:cl:setPedPreset', model)
end)

