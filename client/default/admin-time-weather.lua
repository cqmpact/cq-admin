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

RegisterAdminCategory('time_weather', {
    build = function()
        return {
            id = "time_weather_mgmt",
            label = "Time & Weather",
            sub = "Control time and weather",
            enabled = true,
            groups = {
                {
                    id = "time_controls",
                    type = "group",
                    label = "Time controls",
                    children = {
                        { label = "Freeze time", type = "toggle", key = "freeze_time_t", callback = "cq-admin:cb:freezeTime", default = false },
                        { label = "Set time (HH:MM)", type = "inputButton", placeholder = "12:00", buttonLabel = "Set", callback = "cq-admin:cb:setTime", payloadKey = "time" },
                        { label = "Early Morning (06:00)", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setTimePreset", meta = { time = "06:00" } },
                        { label = "Noon (12:00)", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setTimePreset", meta = { time = "12:00" } },
                        { label = "Evening (18:00)", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setTimePreset", meta = { time = "18:00" } },
                        { label = "Midnight (00:00)", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setTimePreset", meta = { time = "00:00" } },
                    }
                },
                {
                    id = "weather_controls",
                    type = "group",
                    label = "Weather controls",
                    children = {
                        { label = "Extra Sunny", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "EXTRASUNNY" } },
                        { label = "Clear", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "CLEAR" } },
                        { label = "Cloudy", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "CLOUDS" } },
                        { label = "Foggy", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "FOGGY" } },
                        { label = "Overcast", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "OVERCAST" } },
                        { label = "Rain", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "RAIN" } },
                        { label = "Thunder", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "THUNDER" } },
                        { label = "Snow", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "SNOW" } },
                        { label = "Blizzard", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "BLIZZARD" } },
                        { label = "Light Snow", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "SNOWLIGHT" } },
                        { label = "Christmas", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "XMAS" } },
                        { label = "Halloween", type = "button", buttonLabel = "Set", callback = "cq-admin:cb:setWeather", meta = { weather = "HALLOWEEN" } },
                    }
                }
            }
        }
    end
})

local _freezeTime = false
local _myServerId = nil
local function _getMyServerId()
    if _myServerId == nil then
        _myServerId = GetPlayerServerId(PlayerId())
    end
    return _myServerId
end


RegisterNUICallback('cq-admin:cb:freezeTime', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:freezeTime', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:freezeTime', function(reqId, enabled)
    if not ValidateGrant(reqId, 'freezeTime') then return end
    _freezeTime = enabled and true or false
    if notify then notify('info', ('Freeze Time: %s'):format(_freezeTime and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _freezeTime then
            local hour, minute = GetClockHours(), GetClockMinutes()
            NetworkOverrideClockTime(hour, minute, 0)
        end
    end
end)

RegisterNUICallback('cq-admin:cb:setTime', function(data, cb)
    local time = data and (data.time or data.value) or '12:00'
    TriggerServerEvent('cq-admin:sv:setTime', time)
    cb({ ok = true })
end)

local function _applyTime(time, showNotify)
    local hour, minute = 12, 0
    if type(time) == 'string' then
        local parts = {}
        for part in time:gmatch('[^:]+') do
            table.insert(parts, tonumber(part))
        end
        if #parts >= 2 then
            hour = math.max(0, math.min(parts[1] or 12, 23))
            minute = math.max(0, math.min(parts[2] or 0, 59))
        end
    end
    NetworkOverrideClockTime(hour, minute, 0)
    local shouldNotify = (showNotify == nil) and true or showNotify
    if notify and shouldNotify then notify('success', ('Time set to %02d:%02d'):format(hour, minute)) end
end

local function _applyWeather(weather, showNotify)
    SetWeatherTypeNowPersist(weather or 'CLEAR')
    SetWeatherTypeNow(weather or 'CLEAR')
    SetWeatherTypePersist(weather or 'CLEAR')
    local shouldNotify = (showNotify == nil) and true or showNotify
    if notify and shouldNotify then notify('success', ('Weather set to: %s'):format(weather or 'CLEAR')) end
end

RegisterNetEvent('cq-admin:cl:setTime', function(reqId, time, showNotify)
    if not ValidateGrant(reqId, 'setTime') then return end
    _applyTime(time, showNotify)
end)

RegisterNUICallback('cq-admin:cb:setTimePreset', function(data, cb)
    local time = '12:00'
    if data then
        time = data.time or data.value or (data.meta and data.meta.time) or time
    end
    TriggerServerEvent('cq-admin:sv:setTime', time)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:setWeather', function(data, cb)
    local weather = 'CLEAR'
    if data then
        weather = data.weather or data.value or (data.meta and data.meta.weather) or weather
    end
    TriggerServerEvent('cq-admin:sv:setWeather', weather)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setWeather', function(reqId, weather, showNotify)
    if not ValidateGrant(reqId, 'setWeather') then return end
    _applyWeather(weather, showNotify)
end)

RegisterNetEvent('cq-admin:cl:broadcastSetTime', function(time, initiatorSrc)
    _applyTime(time, initiatorSrc == _getMyServerId())
end)

RegisterNetEvent('cq-admin:cl:broadcastSetWeather', function(weather, initiatorSrc)
    _applyWeather(weather, initiatorSrc == _getMyServerId())
end)


