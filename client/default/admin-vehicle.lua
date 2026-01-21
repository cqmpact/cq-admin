--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

-- luacheck: max_line_length 400
-- luacheck: globals CQAdmin
local ValidateGrant = (CQAdmin and CQAdmin._internal and CQAdmin._internal.validateGrant) or function() return false end
local VEH_REFRESH_MS = 1500
local _veh_last_hash = ''
local _veh_state = {
    inVehicle = false,
    engineOn = false,
    invincible = false,
    invisible = false,
    neonEnabled = false,
    neonColor = { r = 255, g = 0, b = 0 },
    primaryColor = { r = 255, g = 0, b = 0 },
    secondaryColor = { r = 0, g = 0, b = 255 },
}

local function _getVehicleState()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        return {
            inVehicle = false,
            engineOn = false,
            invincible = false,
            invisible = false,
            neonEnabled = false,
            neonColor = { r = 255, g = 0, b = 0 },
            primaryColor = { r = 255, g = 0, b = 0 },
            secondaryColor = { r = 0, g = 0, b = 255 },
        }
    end

    local nr, ng, nb = GetVehicleNeonLightsColour(veh)
    local pr, pg, pb = GetVehicleCustomPrimaryColour(veh)
    local sr, sg, sb = GetVehicleCustomSecondaryColour(veh)
    local neon_on = false
    for i = 0, 3 do
        if IsVehicleNeonLightEnabled(veh, i) then
            neon_on = true
            break
        end
    end

    return {
        inVehicle = true,
        engineOn = GetIsVehicleEngineRunning(veh),
        invincible = GetEntityCanBeDamaged(veh) == false,
        invisible = not IsEntityVisible(veh),
        neonEnabled = neon_on,
        neonColor = { r = nr or 255, g = ng or 0, b = nb or 0 },
        primaryColor = { r = pr or 255, g = pg or 0, b = pb or 0 },
        secondaryColor = { r = sr or 0, g = sg or 0, b = sb or 255 },
    }
end

local function _veh_state_hash(s)
    return table.concat({
        s.inVehicle and 1 or 0,
        s.engineOn and 1 or 0,
        s.invincible and 1 or 0,
        s.invisible and 1 or 0,
        s.neonEnabled and 1 or 0,
        s.neonColor.r, s.neonColor.g, s.neonColor.b,
        s.primaryColor.r, s.primaryColor.g, s.primaryColor.b,
        s.secondaryColor.r, s.secondaryColor.g, s.secondaryColor.b,
    }, ':')
end

local function _refreshVehicleState(force)
    local s = _getVehicleState()
    local h = _veh_state_hash(s)
    if h ~= _veh_last_hash then
        _veh_last_hash = h
        _veh_state = s
        if type(CQAdmin_RequestMenuRefresh) == 'function' then
            CQAdmin_RequestMenuRefresh()
        end
        return
    end
    if force and type(CQAdmin_RequestMenuRefresh) == 'function' then
        _veh_state = s
        CQAdmin_RequestMenuRefresh()
    end
end

CreateThread(function()
    while true do
        Wait(VEH_REFRESH_MS)
        local open = type(CQAdmin_IsMenuOpen) == 'function' and CQAdmin_IsMenuOpen()
        _refreshVehicleState(open)
    end
end)

RegisterAdminCategory('vehicles', {
    build = function()
        local s = _getVehicleState()
        _veh_state = s
        local disableVeh = not s.inVehicle
        return {
            id = "vehicles",
            label = "Vehicles",
            sub = "Spawn and manage vehicles",
            enabled = true,
            groups = {
                {
                    id = "veh_actions",
                    type = "group",
                    label = "Vehicle actions",
                    children = {
                        { label = "Spawn vehicle", type = "inputButton", placeholder = "adder", buttonLabel = "Spawn", callback = "cq-admin:cb:spawnVehicle", payloadKey = "model", inlineToggle = { label = "Spawn in vehicle?", key = "veh_spawn_in", callback = "cq-admin:cb:setSpawnInVehicle", default = false } },
                        { label = "Vehicle God Mode", type = "toggle", key = "veh_god", callback = "cq-admin:cb:toggleGodMode", default = false },
                        { label = "Fix vehicle", type = "button", buttonLabel = "Fix", callback = "cq-admin:cb:fixVehicle" },
                        { label = "Clean vehicle", type = "button", buttonLabel = "Clean", callback = "cq-admin:cb:cleanVehicle" },
                        { label = "Delete current vehicle", type = "button", buttonLabel = "Delete", callback = "cq-admin:cb:deleteVehicle" },
                        { label = "Flip upright", type = "button", buttonLabel = "Flip", callback = "cq-admin:cb:flipVehicle" },
                        { label = "Warp into nearest driver seat", type = "button", buttonLabel = "Warp", callback = "cq-admin:cb:warpIntoNearest" },
                    }
                },
                {
                    id = "veh_features",
                    type = "group",
                    label = "Vehicle features",
                    disabled = disableVeh,
                    disabledReason = "Sit in a vehicle to use these features.",
                    children = {
                        { label = "Toggle engine", type = "button", buttonLabel = "Toggle", callback = "cq-admin:cb:toggleEngine", disabled = disableVeh },
                        { label = "Toggle vehicle visibility", type = "toggle", key = "veh_invis", callback = "cq-admin:cb:vehicleInvisible", default = false, disabled = disableVeh },
                        { label = "Max vehicle performance", type = "button", buttonLabel = "Max", callback = "cq-admin:cb:maxPerformance", disabled = disableVeh },
                        { label = "Set license plate", type = "inputButton", placeholder = "ADMIN", buttonLabel = "Set", callback = "cq-admin:cb:setLicensePlate", payloadKey = "plate", disabled = disableVeh },
                        { label = "Open all doors", type = "button", buttonLabel = "Open", callback = "cq-admin:cb:openAllDoors", disabled = disableVeh },
                        { label = "Close all doors", type = "button", buttonLabel = "Close", callback = "cq-admin:cb:closeAllDoors", disabled = disableVeh },
                        { label = "Pop all windows", type = "button", buttonLabel = "Pop", callback = "cq-admin:cb:popAllWindows", disabled = disableVeh },
                    }
                },
                {
                    id = "veh_mods",
                    type = "group",
                    label = "Vehicle modifications",
                    disabled = disableVeh,
                    disabledReason = "Sit in a vehicle to use these modifications.",
                    children = {
                        { label = "Set neon color", type = "colorPicker", key = "neon_color", callback = "cq-admin:cb:setNeonColor", default = { r = 255, g = 0, b = 0 }, disabled = disableVeh },
                        { label = "Enable neon lights", type = "toggle", key = "neon_t", callback = "cq-admin:cb:enableNeon", default = false, disabled = disableVeh },
                        { label = "Set primary color", type = "colorPicker", key = "primary_color", callback = "cq-admin:cb:setPrimaryColor", default = { r = 255, g = 0, b = 0 }, disabled = disableVeh },
                        { label = "Set secondary color", type = "colorPicker", key = "secondary_color", callback = "cq-admin:cb:setSecondaryColor", default = { r = 0, g = 0, b = 255 }, disabled = disableVeh },
                    }
                }
            }
        }
    end,
    values = function()
        local s = _getVehicleState()
        _veh_state = s
        return {
            veh_god = s.invincible,
            veh_invis = s.invisible,
            neon_t = s.neonEnabled,
            neon_color = s.neonColor,
            primary_color = s.primaryColor,
            secondary_color = s.secondaryColor,
        }
    end
})


local vehSpawnIn = false

RegisterNUICallback('cq-admin:cb:setSpawnInVehicle', function(data, cb)
    local enabled = false
    if type(data) == 'table' then
        enabled = (data.enabled == true) or (data.value == true) or (data.state == true)
    end
    vehSpawnIn = enabled
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:spawnVehicle', function(data, cb)
    local model = data and data.model or nil
    if vehSpawnIn then
        TriggerServerEvent('cq-admin:sv:spawnVehicle', model)
    else
        TriggerServerEvent('cq-admin:sv:spawnVehicleGizmo', model)
    end
    cb({ ok = true })
end)


local vehGodMode = false

RegisterNetEvent('cq-admin:cl:spawnVehicle', function(reqId, model)
    if not ValidateGrant(reqId, 'spawnVehicle') then return end
    local ped = PlayerPedId()
    if not model or model == '' then
        return (notify and notify('error', 'Invalid vehicle model'))
    end
    local hash = GetHashKey(model)
    RequestModel(hash)
    local waited = 0
    while not HasModelLoaded(hash) and waited < 5000 do
        Wait(10)
        waited = waited + 10
    end
    if not HasModelLoaded(hash) then
        return (notify and notify('error', ('Model failed to load: %s'):format(model)))
    end
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        TaskWarpPedIntoVehicle(ped, veh, -1)
        SetModelAsNoLongerNeeded(hash)
        if notify then notify('success', ('Spawned vehicle: %s'):format(model)) end
    else
        if notify then notify('error', 'Failed to create vehicle') end
    end
end)

RegisterNetEvent('cq-admin:cl:toggleGodMode', function(reqId, enabled)
    if not ValidateGrant(reqId, 'toggleGodMode') then return end
    vehGodMode = enabled and true or false
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetEntityInvincible(veh, vehGodMode)
        SetVehicleTyresCanBurst(veh, not vehGodMode)
        SetVehicleCanBreak(veh, not vehGodMode)
    end
    if notify then notify('info', ('Vehicle God Mode: %s'):format(vehGodMode and 'ON' or 'OFF')) end
end)

RegisterNetEvent('cq-admin:cl:fixVehicle', function(reqId)
    if not ValidateGrant(reqId, 'fixVehicle') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    SetVehicleFixed(veh)
    SetVehicleDirtLevel(veh, 0.0)
    SetVehicleEngineHealth(veh, 1000.0)
    if notify then notify('success', 'Vehicle fixed') end
end)

RegisterNetEvent('cq-admin:cl:cleanVehicle', function(reqId)
    if not ValidateGrant(reqId, 'cleanVehicle') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    SetVehicleDirtLevel(veh, 0.0)
    WashDecalsFromVehicle(veh, 1.0)
    if notify then notify('success', 'Vehicle cleaned') end
end)

RegisterNetEvent('cq-admin:cl:deleteVehicle', function(reqId)
    if not ValidateGrant(reqId, 'deleteVehicle') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteEntity(veh)
    if notify then notify('success', 'Vehicle deleted') end
end)

RegisterNetEvent('cq-admin:cl:flipVehicle', function(reqId)
    if not ValidateGrant(reqId, 'flipVehicle') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    SetVehicleOnGroundProperly(veh)
    SetVehicleFixed(veh)
    if notify then notify('success', 'Vehicle uprighted') end
end)

RegisterNetEvent('cq-admin:cl:warpIntoNearest', function(reqId)
    if not ValidateGrant(reqId, 'warpIntoNearest') then return end
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local handle, veh = FindFirstVehicle()
    local success
    local closest, dist = 0, 999999.0
    repeat
        if DoesEntityExist(veh) then
            local vCoords = GetEntityCoords(veh)
            local d = #(pCoords - vCoords)
            if d < dist then
                closest = veh
                dist = d
            end
        end
        success, veh = FindNextVehicle(handle)
    until not success
    EndFindVehicle(handle)
    if closest ~= 0 and dist < 50.0 then
        TaskWarpPedIntoVehicle(ped, closest, -1)
        if notify then notify('success', 'Warped into nearest vehicle') end
    else
        if notify then notify('error', 'No nearby vehicle found') end
    end
end)

RegisterNUICallback('cq-admin:cb:toggleGodMode', function(data, cb)
    local enabled = false
    if type(data) == 'table' then
        if data.value ~= nil then enabled = data.value and true or false end
        if data.enabled ~= nil then enabled = data.enabled and true or false end
    end
    TriggerServerEvent('cq-admin:sv:toggleGodMode', enabled)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:fixVehicle', function(_, cb)
    TriggerServerEvent('cq-admin:sv:fixVehicle')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:cleanVehicle', function(_, cb)
    TriggerServerEvent('cq-admin:sv:cleanVehicle')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:deleteVehicle', function(_, cb)
    TriggerServerEvent('cq-admin:sv:deleteVehicle')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:flipVehicle', function(_, cb)
    TriggerServerEvent('cq-admin:sv:flipVehicle')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:warpIntoNearest', function(_, cb)
    TriggerServerEvent('cq-admin:sv:warpIntoNearest')
    cb({ ok = true })
end)

-- New vehicle feature callbacks
RegisterNUICallback('cq-admin:cb:toggleEngine', function(_, cb)
    TriggerServerEvent('cq-admin:sv:toggleEngine')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:toggleEngine', function(reqId)
    if not ValidateGrant(reqId, 'toggleEngine') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    local running = GetIsVehicleEngineRunning(veh)
    SetVehicleEngineOn(veh, not running, false, true)
    if notify then notify('success', ('Engine: %s'):format(running and 'OFF' or 'ON')) end
end)

local _vehicleInvisible = false

RegisterNUICallback('cq-admin:cb:vehicleInvisible', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:vehicleInvisible', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:vehicleInvisible', function(reqId, enabled)
    if not ValidateGrant(reqId, 'vehicleInvisible') then return end
    _vehicleInvisible = enabled and true or false
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        SetEntityVisible(veh, not _vehicleInvisible, false)
    end
    if notify then notify('info', ('Vehicle Invisible: %s'):format(_vehicleInvisible and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:maxPerformance', function(_, cb)
    TriggerServerEvent('cq-admin:sv:maxPerformance')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:maxPerformance', function(reqId)
    if not ValidateGrant(reqId, 'maxPerformance') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end

    SetVehicleModKit(veh, 0)
    SetVehicleMod(veh, 11, GetNumVehicleMods(veh, 11) - 1, false)
    SetVehicleMod(veh, 12, GetNumVehicleMods(veh, 12) - 1, false)
    SetVehicleMod(veh, 13, GetNumVehicleMods(veh, 13) - 1, false)
    SetVehicleMod(veh, 15, GetNumVehicleMods(veh, 15) - 1, false)
    SetVehicleMod(veh, 16, GetNumVehicleMods(veh, 16) - 1, false)
    ToggleVehicleMod(veh, 18, true)

    if notify then notify('success', 'Vehicle maxed') end
end)

RegisterNUICallback('cq-admin:cb:setLicensePlate', function(data, cb)
    local plate = data and (data.plate or data.value) or 'ADMIN'
    TriggerServerEvent('cq-admin:sv:setLicensePlate', plate)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setLicensePlate', function(reqId, plate)
    if not ValidateGrant(reqId, 'setLicensePlate') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    SetVehicleNumberPlateText(veh, plate or 'ADMIN')
    if notify then notify('success', ('License plate set to: %s'):format(plate or 'ADMIN')) end
end)

RegisterNUICallback('cq-admin:cb:openAllDoors', function(_, cb)
    TriggerServerEvent('cq-admin:sv:openAllDoors')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:openAllDoors', function(reqId)
    if not ValidateGrant(reqId, 'openAllDoors') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    for i = 0, 7 do
        SetVehicleDoorOpen(veh, i, false, false)
    end
    if notify then notify('success', 'All doors opened') end
end)

RegisterNUICallback('cq-admin:cb:closeAllDoors', function(_, cb)
    TriggerServerEvent('cq-admin:sv:closeAllDoors')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:closeAllDoors', function(reqId)
    if not ValidateGrant(reqId, 'closeAllDoors') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    for i = 0, 7 do
        SetVehicleDoorShut(veh, i, false)
    end
    if notify then notify('success', 'All doors closed') end
end)

RegisterNUICallback('cq-admin:cb:popAllWindows', function(_, cb)
    TriggerServerEvent('cq-admin:sv:popAllWindows')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:popAllWindows', function(reqId)
    if not ValidateGrant(reqId, 'popAllWindows') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end
    for i = 0, 7 do
        SmashVehicleWindow(veh, i)
    end
    if notify then notify('success', 'All windows popped') end
end)

RegisterNUICallback('cq-admin:cb:setNeonColor', function(data, cb)
    local color = data and (data.neon_color or data.color or data.value) or '255,0,0'
    if type(color) == 'table' and color.r and color.g and color.b then
        color = string.format('%d,%d,%d', color.r, color.g, color.b)
    end
    TriggerServerEvent('cq-admin:sv:setNeonColor', color)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setNeonColor', function(reqId, color)
    if not ValidateGrant(reqId, 'setNeonColor') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end

    local r, g, b = 255, 0, 0
    if type(color) == 'table' then
        r, g, b = color.r or 255, color.g or 0, color.b or 0
    elseif type(color) == 'string' then
        local parts = {}
        for part in color:gmatch('[^,]+') do
            table.insert(parts, tonumber(part))
        end
        if #parts >= 3 then
            r, g, b = parts[1] or 255, parts[2] or 0, parts[3] or 0
        end
    end

    SetVehicleNeonLightsColour(veh, r, g, b)
    if notify then notify('success', ('Neon color set to RGB(%d,%d,%d)'):format(r, g, b)) end
end)

RegisterNUICallback('cq-admin:cb:enableNeon', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:enableNeon', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:enableNeon', function(reqId, enabled)
    if not ValidateGrant(reqId, 'enableNeon') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end

    for i = 0, 3 do
        SetVehicleNeonLightEnabled(veh, i, enabled and true or false)
    end

    if notify then notify('info', ('Neon lights: %s'):format(enabled and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:setPrimaryColor', function(data, cb)
    local color = data and (data.primary_color or data.color or data.value) or '255,0,0'
    if type(color) == 'table' and color.r and color.g and color.b then
        color = string.format('%d,%d,%d', color.r, color.g, color.b)
    end
    TriggerServerEvent('cq-admin:sv:setPrimaryColor', color)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setPrimaryColor', function(reqId, color)
    if not ValidateGrant(reqId, 'setPrimaryColor') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end

    local r, g, b = 255, 0, 0
    if type(color) == 'table' then
        r, g, b = color.r or 255, color.g or 0, color.b or 0
    elseif type(color) == 'string' then
        local parts = {}
        for part in color:gmatch('[^,]+') do
            table.insert(parts, tonumber(part))
        end
        if #parts >= 3 then
            r, g, b = parts[1] or 255, parts[2] or 0, parts[3] or 0
        end
    end

    SetVehicleCustomPrimaryColour(veh, r, g, b)
    if notify then notify('success', ('Primary color set to RGB(%d,%d,%d)'):format(r, g, b)) end
end)

RegisterNUICallback('cq-admin:cb:setSecondaryColor', function(data, cb)
    local color = data and (data.secondary_color or data.color or data.value) or '0,0,255'
    if type(color) == 'table' and color.r and color.g and color.b then
        color = string.format('%d,%d,%d', color.r, color.g, color.b)
    end
    TriggerServerEvent('cq-admin:sv:setSecondaryColor', color)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setSecondaryColor', function(reqId, color)
    if not ValidateGrant(reqId, 'setSecondaryColor') then return end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return (notify and notify('error', 'Not in a vehicle')) end

    local r, g, b = 0, 0, 255
    if type(color) == 'table' then
        r, g, b = color.r or 0, color.g or 0, color.b or 255
    elseif type(color) == 'string' then
        local parts = {}
        for part in color:gmatch('[^,]+') do
            table.insert(parts, tonumber(part))
        end
        if #parts >= 3 then
            r, g, b = parts[1] or 0, parts[2] or 0, parts[3] or 255
        end
    end

    SetVehicleCustomSecondaryColour(veh, r, g, b)
    if notify then notify('success', ('Secondary color set to RGB(%d,%d,%d)'):format(r, g, b)) end
end)


