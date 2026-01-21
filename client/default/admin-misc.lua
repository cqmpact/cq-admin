--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

-- luacheck: max_line_length 200
-- luacheck: globals CQAdmin
local ValidateGrant = (CQAdmin and CQAdmin._internal and CQAdmin._internal.validateGrant) or function() return false end
RegisterAdminCategory('misc', {
    build = function()
        return {
            id = "misc_settings",
            label = "Misc Settings",
            sub = "Visual and utility settings",
            enabled = true,
            groups = {
                {
                    id = "display_options",
                    type = "group",
                    label = "Display options",
                    children = {
                        { label = "Show speedometer (KM/H)", type = "toggle", key = "speedo_kmh_t", callback = "cq-admin:cb:speedoKMH", default = false },
                        { label = "Show speedometer (MPH)", type = "toggle", key = "speedo_mph_t", callback = "cq-admin:cb:speedoMPH", default = false },
                        { label = "Show coordinates", type = "toggle", key = "show_coords_t", callback = "cq-admin:cb:showCoords", default = false },
                        { label = "Hide HUD", type = "toggle", key = "hide_hud_t", callback = "cq-admin:cb:hideHUD", default = false },
                        { label = "Hide radar/minimap", type = "toggle", key = "hide_radar_t", callback = "cq-admin:cb:hideRadar", default = false },
                        { label = "Show location", type = "toggle", key = "show_location_t", callback = "cq-admin:cb:showLocation", default = false },
                        { label = "Show time", type = "toggle", key = "show_time_t", callback = "cq-admin:cb:showTime", default = false },
                    }
                },
                {
                    id = "vision_modes",
                    type = "group",
                    label = "Vision modes",
                    children = {
                        { label = "Night vision", type = "toggle", key = "night_vision_t", callback = "cq-admin:cb:nightVision", default = false },
                        { label = "Thermal vision", type = "toggle", key = "thermal_vision_t", callback = "cq-admin:cb:thermalVision", default = false },
                    }
                },
                {
                    id = "camera_options",
                    type = "group",
                    label = "Camera options",
                    children = {
                        { label = "Lock camera horizontal", type = "toggle", key = "lock_cam_x_t", callback = "cq-admin:cb:lockCamX", default = false },
                        { label = "Lock camera vertical", type = "toggle", key = "lock_cam_y_t", callback = "cq-admin:cb:lockCamY", default = false },
                    }
                },
                {
                    id = "utility_actions",
                    type = "group",
                    label = "Utility actions",
                    children = {
                        { label = "Clear area (100m)", type = "button", buttonLabel = "Clear", callback = "cq-admin:cb:clearArea" },
                    }
                }
            }
        }
    end
})

local U = CQ and CQ.Util or {}
local drawText = (U and U.drawText) or function(x, y, text, opts)
    opts = opts or {}
    local scale = opts.scale or 0.5
    local sx = type(scale) == 'table' and (scale[1] or 0.5) or scale
    local sy = type(scale) == 'table' and (scale[2] or sx) or scale
    SetTextFont(opts.font or 4)
    SetTextProportional(0)
    SetTextScale(sx, sy)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(tostring(text or ''))
    DrawText(x or 0.0, y or 0.0)
end
local kmh = (U and U.kmh) or function(mps) return (tonumber(mps) or 0) * 3.6 end
local mph = (U and U.mph) or function(mps) return (tonumber(mps) or 0) * 2.236936 end
local makeLocationText = (U and U.makeLocationText) or function(coords, heading)
    local zone = GetNameOfZone(coords.x, coords.y, coords.z)
    local zoneName = GetLabelText(zone)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    local h = (tonumber(heading) or 0.0) % 360.0
    local dir = (h >= 315 or h < 45) and "North" or (h >= 45 and h < 135) and "East" or (h >= 135 and h < 225) and "South" or "West"
    local text = zoneName
    if street1 ~= "" then
        text = text .. " | " .. street1
        if street2 ~= "" then
            text = text .. " / " .. street2
        end
    end
    text = text .. " | " .. dir
    return text
end
local formatClock = (U and U.formatClock) or function(hour, minute)
    return string.format("%02d:%02d", math.floor(tonumber(hour) or 0), math.floor(tonumber(minute) or 0))
end

local _speedoKMH = false
local _speedoMPH = false
local _showCoords = false
local _hideHUD = false
local _hideRadar = false
local _showLocation = false
local _showTime = false
local _nightVision = false
local _thermalVision = false
local _lockCamX = false
local _lockCamY = false

RegisterNUICallback('cq-admin:cb:speedoKMH', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:speedoKMH', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:speedoKMH', function(reqId, enabled)
    if not ValidateGrant(reqId, 'speedoKMH') then return end
    _speedoKMH = enabled and true or false
    if notify then notify('info', ('Speedometer KM/H: %s'):format(_speedoKMH and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:speedoMPH', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:speedoMPH', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:speedoMPH', function(reqId, enabled)
    if not ValidateGrant(reqId, 'speedoMPH') then return end
    _speedoMPH = enabled and true or false
    if notify then notify('info', ('Speedometer MPH: %s'):format(_speedoMPH and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:showCoords', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:showCoords', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:showCoords', function(reqId, enabled)
    if not ValidateGrant(reqId, 'showCoords') then return end
    _showCoords = enabled and true or false
    if notify then notify('info', ('Show Coordinates: %s'):format(_showCoords and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:hideHUD', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:hideHUD', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:hideHUD', function(reqId, enabled)
    if not ValidateGrant(reqId, 'hideHUD') then return end
    _hideHUD = enabled and true or false
    DisplayHud(not _hideHUD)
    if notify then notify('info', ('Hide HUD: %s'):format(_hideHUD and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:hideRadar', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:hideRadar', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:hideRadar', function(reqId, enabled)
    if not ValidateGrant(reqId, 'hideRadar') then return end
    _hideRadar = enabled and true or false
    DisplayRadar(not _hideRadar)
    if notify then notify('info', ('Hide Radar: %s'):format(_hideRadar and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:showLocation', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:showLocation', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:showLocation', function(reqId, enabled)
    if not ValidateGrant(reqId, 'showLocation') then return end
    _showLocation = enabled and true or false
    if notify then notify('info', ('Show Location: %s'):format(_showLocation and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:showTime', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:showTime', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:showTime', function(reqId, enabled)
    if not ValidateGrant(reqId, 'showTime') then return end
    _showTime = enabled and true or false
    if notify then notify('info', ('Show Time: %s'):format(_showTime and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:nightVision', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:nightVision', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:nightVision', function(reqId, enabled)
    if not ValidateGrant(reqId, 'nightVision') then return end
    _nightVision = enabled and true or false
    SetNightvision(_nightVision)
    if notify then notify('info', ('Night Vision: %s'):format(_nightVision and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:thermalVision', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:thermalVision', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:thermalVision', function(reqId, enabled)
    if not ValidateGrant(reqId, 'thermalVision') then return end
    _thermalVision = enabled and true or false
    SetSeethrough(_thermalVision)
    if notify then notify('info', ('Thermal Vision: %s'):format(_thermalVision and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:lockCamX', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:lockCamX', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:lockCamX', function(reqId, enabled)
    if not ValidateGrant(reqId, 'lockCamX') then return end
    _lockCamX = enabled and true or false
    if notify then notify('info', ('Lock Camera Horizontal: %s'):format(_lockCamX and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:lockCamY', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:lockCamY', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:lockCamY', function(reqId, enabled)
    if not ValidateGrant(reqId, 'lockCamY') then return end
    _lockCamY = enabled and true or false
    if notify then notify('info', ('Lock Camera Vertical: %s'):format(_lockCamY and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:clearArea', function(_, cb)
    TriggerServerEvent('cq-admin:sv:clearArea')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:clearArea', function(reqId)
    if not ValidateGrant(reqId, 'clearArea') then return end
    local ped = (U and U.ped and U.ped()) or PlayerPedId()
    local coords = GetEntityCoords(ped)
    local radius = 100.0

    ClearAreaOfVehicles(coords.x, coords.y, coords.z, radius, false, false, false, false, false)
    ClearAreaOfPeds(coords.x, coords.y, coords.z, radius, false)
    ClearAreaOfObjects(coords.x, coords.y, coords.z, radius, 0)

    if notify then notify('success', 'Area cleared (100m radius)') end
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if _speedoKMH then
            local speed = kmh(GetEntitySpeed(ped))
            drawText(0.85, 0.92, ("%.1f KM/H"):format(speed), { scale = 0.5 })
        end

        if _speedoMPH then
            local speed = mph(GetEntitySpeed(ped))
            drawText(0.85, 0.92, ("%.1f MPH"):format(speed), { scale = 0.5 })
        end

        if _showCoords then
            drawText(0.40, 0.02, ("X: %.2f Y: %.2f Z: %.2f"):format(coords.x, coords.y, coords.z), { scale = 0.4 })
        end

        if _showLocation then
            local text = makeLocationText(coords, GetEntityHeading(ped))
            drawText(0.40, 0.95, text, { scale = 0.35 })
        end

        if _showTime then
            drawText(0.92, 0.02, formatClock(GetClockHours(), GetClockMinutes()), { scale = 0.45 })
        end

        if _lockCamX then
            SetGameplayCamRelativeHeading(0.0)
        end
        if _lockCamY then
            SetGameplayCamRelativePitch(0.0, 1.0)
        end
    end
end)


