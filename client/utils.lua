--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

CQ = CQ or {}

CQ.Controls = CQ.Controls or {
    MOVE_LR = 30,
    MOVE_UD = 31,
    ATTACK = 24,
    ATTACK2 = 257,
    AIM = 25,
    SELECT_WEAPON = 37,
    SELECT_NEXT_WEAPON = 16,
    SELECT_PREV_WEAPON = 17,
    NEXT_WEAPON = 261,
    PREV_WEAPON = 262,
    COVER = 44,
    PICKUP = 38,
    RELOAD = 45,
    MOVE_UP_ONLY = 32,
    MOVE_DOWN_ONLY = 33,
    MOVE_LEFT_ONLY = 34,
    MOVE_RIGHT_ONLY = 35,
    MELEE_ATTACK_LIGHT = 140,
    MELEE_ATTACK_HEAVY = 141,
    MELEE_ATTACK_ALTERNATE = 142,
    MELEE_BLOCK = 143,
    MELEE_ATTACK1 = 263,
    SPRINT = 21,
    DUCK = 36,
    CHARACTER_WHEEL = 19,
    SCROLL_UP = 241,
    SCROLL_DOWN = 242,
}

CQ.NoclipDisableControls = CQ.NoclipDisableControls or {
    30, 31,
    24, 257,
    140, 141, 142, 143, 263,
    25,
    37, 16, 17,
    261, 262,
    44, 38, 45,
    32, 33, 34, 35,
}

CQ.Util = CQ.Util or {}

function CQ.Util.ped()
    return PlayerPedId()
end

function CQ.Util.clamp(value, minVal, maxVal)
    local n = tonumber(value) or 0
    if minVal and n < minVal then return minVal end
    if maxVal and n > maxVal then return maxVal end
    return n
end

function CQ.Util.kmh(mps)
    return (tonumber(mps) or 0) * 3.6
end

function CQ.Util.mph(mps)
    return (tonumber(mps) or 0) * 2.236936
end

function CQ.Util.drawText(x, y, text, opts)
    opts = opts or {}
    local font = opts.font or 4
    local scale = opts.scale or 0.5
    local scaleX = type(scale) == 'table' and (scale[1] or 0.5) or scale
    local scaleY = type(scale) == 'table' and (scale[2] or scaleX) or scale
    local color = opts.color or { 255, 255, 255, 255 }

    SetTextFont(font)
    SetTextProportional(0)
    SetTextScale(scaleX, scaleY)
    SetTextColour(color[1] or 255, color[2] or 255, color[3] or 255, color[4] or 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(tostring(text or ''))
    DrawText(x or 0.0, y or 0.0)
end

local function rotationToDirection(rot)
    local radZ = math.rad(rot.z)
    local radX = math.rad(rot.x)
    local cosX = math.cos(radX)
    return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

function CQ.Util.getCamDir()
    return rotationToDirection(GetGameplayCamRot(2))
end

function CQ.Util.getHeadingDirection(heading)
    local h = (tonumber(heading) or 0.0) % 360.0
    if h >= 315 or h < 45 then return "North"
    elseif h >= 45 and h < 135 then return "East"
    elseif h >= 135 and h < 225 then return "South"
    else return "West" end
end

function CQ.Util.getStreetAndZone(coords)
    local x, y, z = coords.x, coords.y, coords.z
    local zone = GetNameOfZone(x, y, z)
    local zoneName = GetLabelText(zone)
    local s1, s2 = GetStreetNameAtCoord(x, y, z)
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    return zoneName, street1, street2
end

function CQ.Util.makeLocationText(coords, heading)
    local zoneName, street1, street2 = CQ.Util.getStreetAndZone(coords)
    local direction = CQ.Util.getHeadingDirection(heading or 0.0)
    local text = zoneName
    if street1 ~= "" then
        text = text .. " | " .. street1
        if street2 ~= "" then
            text = text .. " / " .. street2
        end
    end
    text = text .. " | " .. direction
    return text
end

function CQ.Util.formatClock(hour, minute)
    return string.format("%02d:%02d", math.floor(tonumber(hour) or 0), math.floor(tonumber(minute) or 0))
end

function CQ.Util.loadModel(modelOrHash, timeoutMs)
    local hash = modelOrHash
    if type(modelOrHash) == 'string' then
        hash = GetHashKey(modelOrHash)
    end
    RequestModel(hash)
    local waited = 0
    local limit = tonumber(timeoutMs) or 5000
    while not HasModelLoaded(hash) and waited < limit do
        Wait(10)
        waited = waited + 10
    end
    return HasModelLoaded(hash), hash
end

CQ.Util.IB = CQ.Util.IB or {}

function CQ.Util.IB.show(buttons)
    TriggerEvent('cq-admin:ib:show', buttons)
end

function CQ.Util.IB.hide()
    TriggerEvent('cq-admin:ib:hide')
end

function CQ.Util.disableControls(list)
    if type(list) ~= 'table' then return end
    for _, control in ipairs(list) do
        DisableControlAction(0, control, true)
    end
end

function CQ.Util.notify(type_, message)
    local t = type_ or 'info'
    local cfg = rawget(_G, 'CQAdmin_Config')
    local quiet = type(cfg) == 'table' and (cfg.quietNotifications ~= false)
    if quiet and t == 'info' then return end
    if type(_G.notify) == 'function' then
        _G.notify(t, message or '')
    else
        SendNUIMessage({ action = 'cq:menu:notify', type = t, message = message or '' })
    end
end
