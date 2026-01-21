--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

local _timeWxCooldown = {}
local TIMEWX_COOLDOWN_MS = GetConvarInt('cqadmin_timewx_cooldown_ms', 1000)
AddEventHandler('playerDropped', function()
    local src = source
    _timeWxCooldown[src] = nil
end)

RegisterNetEvent('cq-admin:sv:freezeTime', function(enabled)
    local src = source
    local group = GROUPS.freezeTime
    if not hasGroup(src, group) then return deny(src, 'freezeTime', group) end
    local now = GetGameTimer()
    local last = _timeWxCooldown[src] or 0
    if (now - last) < TIMEWX_COOLDOWN_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled freezeTime from src %d'):format(src))
        end
        return
    end
    _timeWxCooldown[src] = now
    issueGrant(src, 'freezeTime', 'cq-admin:cl:freezeTime', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:setTime', function(time)
    local src = source
    local group = GROUPS.setTime
    if not hasGroup(src, group) then return deny(src, 'setTime', group) end
    local now = GetGameTimer()
    local last = _timeWxCooldown[src] or 0
    if (now - last) < TIMEWX_COOLDOWN_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled setTime from src %d'):format(src))
        end
        return
    end
    _timeWxCooldown[src] = now
    local function _normalizeTime(s)
        if type(s) ~= 'string' then return nil end
        s = s:match('^%s*(.-)%s*$') or ''
        local hh, mm = s:match('^(%d+)%s*:%s*(%d+)$')
        if not hh or not mm then return nil end
        local h = tonumber(hh) or 0
        local m = tonumber(mm) or 0
        if h < 0 or h > 23 or m < 0 or m > 59 then
            h = math.max(0, math.min(h, 23))
            m = math.max(0, math.min(m, 59))
        end
        return ("%02d:%02d"):format(h, m)
    end

    local t = _normalizeTime(time)
    if not t then
        return notify(src, 'error', 'Invalid time format (use HH:MM)', false)
    end
    TriggerClientEvent('cq-admin:cl:broadcastSetTime', -1, t, src)
end)

RegisterNetEvent('cq-admin:sv:setWeather', function(weather)
    local src = source
    local group = GROUPS.setWeather
    if not hasGroup(src, group) then return deny(src, 'setWeather', group) end
    local now = GetGameTimer()
    local last = _timeWxCooldown[src] or 0
    if (now - last) < TIMEWX_COOLDOWN_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled setWeather from src %d'):format(src))
        end
        return
    end
    _timeWxCooldown[src] = now
    local allowed = {
        EXTRASUNNY = true, CLEAR = true, CLOUDS = true, FOGGY = true,
        OVERCAST = true, RAIN = true, THUNDER = true, SNOW = true,
        BLIZZARD = true, SNOWLIGHT = true, XMAS = true, HALLOWEEN = true,
    }
    local w = 'CLEAR'
    if type(weather) == 'string' then
        w = (weather:match('^%s*(.-)%s*$') or ''):upper()
    end
    if not allowed[w] then
        return notify(src, 'error', 'Invalid weather type', false)
    end
    TriggerClientEvent('cq-admin:cl:broadcastSetWeather', -1, w, src)
end)

