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

RegisterNetEvent('cq-admin:sv:spawnVehicle', function(model)
    local src = source
    local group = GROUPS.spawnVehicle
    if not hasGroup(src, group) then return deny(src, 'spawnVehicle', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid vehicle model', false)
    end
    issueGrant(src, 'spawnVehicle', 'cq-admin:cl:spawnVehicle', model)
end)

RegisterNetEvent('cq-admin:sv:spawnVehicleGizmo', function(model)
    local src = source
    local group = GROUPS.spawnVehicle
    if not hasGroup(src, group) then return deny(src, 'spawnVehicleGizmo', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid vehicle model', false)
    end
    issueGrant(src, 'spawnVehicleGizmo', 'cq-admin:cl:spawnVehicleGizmo', model)
end)

RegisterNetEvent('cq-admin:sv:spawnVehicleAt', function(model, x, y, z, heading)
    local src = source
    local group = GROUPS.spawnVehicle
    if not hasGroup(src, group) then return deny(src, 'spawnVehicleAt', group) end
    model = _sanitizeModelName(model)
    if model == '' then
        return notify(src, 'error', 'Invalid vehicle model', false)
    end
    x = tonumber(x); y = tonumber(y); z = tonumber(z); heading = tonumber(heading) or 0.0
    if not x or not y or not z then
        return notify(src, 'error', 'Invalid placement coordinates', false)
    end
    issueGrant(src, 'spawnVehicleAt', 'cq-admin:cl:spawnVehicleAt', model, x, y, z, heading)
end)

RegisterNetEvent('cq-admin:sv:toggleGodMode', function(enabled)
    local src = source
    local group = GROUPS.godMode
    if not hasGroup(src, group) then return deny(src, 'toggleGodMode', group) end
    issueGrant(src, 'toggleGodMode', 'cq-admin:cl:toggleGodMode', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:fixVehicle', function()
    local src = source
    local group = GROUPS.fixVehicle
    if not hasGroup(src, group) then return deny(src, 'fixVehicle', group) end
    issueGrant(src, 'fixVehicle', 'cq-admin:cl:fixVehicle')
end)

RegisterNetEvent('cq-admin:sv:cleanVehicle', function()
    local src = source
    local group = GROUPS.cleanVehicle
    if not hasGroup(src, group) then return deny(src, 'cleanVehicle', group) end
    issueGrant(src, 'cleanVehicle', 'cq-admin:cl:cleanVehicle')
end)

RegisterNetEvent('cq-admin:sv:deleteVehicle', function()
    local src = source
    local group = GROUPS.deleteVeh
    if not hasGroup(src, group) then return deny(src, 'deleteVehicle', group) end
    issueGrant(src, 'deleteVehicle', 'cq-admin:cl:deleteVehicle')
end)

RegisterNetEvent('cq-admin:sv:flipVehicle', function()
    local src = source
    local group = GROUPS.flipVeh
    if not hasGroup(src, group) then return deny(src, 'flipVehicle', group) end
    issueGrant(src, 'flipVehicle', 'cq-admin:cl:flipVehicle')
end)

RegisterNetEvent('cq-admin:sv:warpIntoNearest', function()
    local src = source
    local group = GROUPS.warpVeh
    if not hasGroup(src, group) then return deny(src, 'warpIntoNearest', group) end
    issueGrant(src, 'warpIntoNearest', 'cq-admin:cl:warpIntoNearest')
end)

RegisterNetEvent('cq-admin:sv:toggleEngine', function()
    local src = source
    local group = GROUPS.toggleEngine
    if not hasGroup(src, group) then return deny(src, 'toggleEngine', group) end
    issueGrant(src, 'toggleEngine', 'cq-admin:cl:toggleEngine')
end)

RegisterNetEvent('cq-admin:sv:vehicleInvisible', function(enabled)
    local src = source
    local group = GROUPS.vehicleInvisible
    if not hasGroup(src, group) then return deny(src, 'vehicleInvisible', group) end
    issueGrant(src, 'vehicleInvisible', 'cq-admin:cl:vehicleInvisible', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:maxPerformance', function()
    local src = source
    local group = GROUPS.maxPerformance
    if not hasGroup(src, group) then return deny(src, 'maxPerformance', group) end
    issueGrant(src, 'maxPerformance', 'cq-admin:cl:maxPerformance')
end)

local function _sanitizePlate(p)
    if type(p) ~= 'string' then return 'ADMIN' end
    p = p:upper()
    p = p:gsub('%s+', '')
    p = p:gsub('[^A-Z0-9%-]', '')
    if #p == 0 then p = 'ADMIN' end
    if #p > 8 then p = p:sub(1, 8) end
    return p
end

local function _parseRGBString(s, defR, defG, defB)
    defR, defG, defB = defR or 255, defG or 0, defB or 0
    if type(s) == 'table' and s.r and s.g and s.b then
        local r = math.max(0, math.min(255, tonumber(s.r) or defR))
        local g = math.max(0, math.min(255, tonumber(s.g) or defG))
        local b = math.max(0, math.min(255, tonumber(s.b) or defB))
        return ('%d,%d,%d'):format(r, g, b)
    elseif type(s) == 'string' then
        local parts = {}
        for part in s:gmatch('[^,]+') do parts[#parts+1] = tonumber(part) end
        local r = math.max(0, math.min(255, parts[1] or defR))
        local g = math.max(0, math.min(255, parts[2] or defG))
        local b = math.max(0, math.min(255, parts[3] or defB))
        return ('%d,%d,%d'):format(r, g, b)
    end
    return ('%d,%d,%d'):format(defR, defG, defB)
end

RegisterNetEvent('cq-admin:sv:setLicensePlate', function(plate)
    local src = source
    local group = GROUPS.setLicensePlate
    if not hasGroup(src, group) then return deny(src, 'setLicensePlate', group) end
    local safe = _sanitizePlate(plate)
    issueGrant(src, 'setLicensePlate', 'cq-admin:cl:setLicensePlate', safe)
end)

RegisterNetEvent('cq-admin:sv:openAllDoors', function()
    local src = source
    local group = GROUPS.openAllDoors
    if not hasGroup(src, group) then return deny(src, 'openAllDoors', group) end
    issueGrant(src, 'openAllDoors', 'cq-admin:cl:openAllDoors')
end)

RegisterNetEvent('cq-admin:sv:closeAllDoors', function()
    local src = source
    local group = GROUPS.closeAllDoors
    if not hasGroup(src, group) then return deny(src, 'closeAllDoors', group) end
    issueGrant(src, 'closeAllDoors', 'cq-admin:cl:closeAllDoors')
end)

RegisterNetEvent('cq-admin:sv:popAllWindows', function()
    local src = source
    local group = GROUPS.popAllWindows
    if not hasGroup(src, group) then return deny(src, 'popAllWindows', group) end
    issueGrant(src, 'popAllWindows', 'cq-admin:cl:popAllWindows')
end)

RegisterNetEvent('cq-admin:sv:setNeonColor', function(color)
    local src = source
    local group = GROUPS.setNeonColor
    if not hasGroup(src, group) then return deny(src, 'setNeonColor', group) end
    local norm = _parseRGBString(color, 255, 0, 0)
    issueGrant(src, 'setNeonColor', 'cq-admin:cl:setNeonColor', norm)
end)

RegisterNetEvent('cq-admin:sv:enableNeon', function(enabled)
    local src = source
    local group = GROUPS.enableNeon
    if not hasGroup(src, group) then return deny(src, 'enableNeon', group) end
    issueGrant(src, 'enableNeon', 'cq-admin:cl:enableNeon', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:setPrimaryColor', function(color)
    local src = source
    local group = GROUPS.setPrimaryColor
    if not hasGroup(src, group) then return deny(src, 'setPrimaryColor', group) end
    local norm = _parseRGBString(color, 255, 0, 0)
    issueGrant(src, 'setPrimaryColor', 'cq-admin:cl:setPrimaryColor', norm)
end)

RegisterNetEvent('cq-admin:sv:setSecondaryColor', function(color)
    local src = source
    local group = GROUPS.setSecondaryColor
    if not hasGroup(src, group) then return deny(src, 'setSecondaryColor', group) end
    local norm = _parseRGBString(color, 0, 0, 255)
    issueGrant(src, 'setSecondaryColor', 'cq-admin:cl:setSecondaryColor', norm)
end)

