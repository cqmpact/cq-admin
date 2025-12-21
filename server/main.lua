--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

-- luacheck: globals GetRandomIntInRange GetCloudTimeAsInt

local VERSION_CHECK_URL = 'https://raw.githubusercontent.com/cqmpact/cq-admin/refs/heads/main/fxmanifest.lua'

local function parseVersionFromFxmanifest(text)
    if GetConvarInt('cqadmin_debug', 0) == 1 then
        print('Parsing remote fxmanifest for version...')
    end
    for line in text:gmatch("[^\r\n]+") do
        local v = line:match("^%s*version%s*['\"]([^'\"]+)['\"]")
        if v then
            if GetConvarInt('cqadmin_debug', 0) == 1 then
                print(('Parsed remote version: %s'):format(v))
            end
            return v
        end
    end
    return nil
end


local function getLocalVersion()
    local res = GetCurrentResourceName()
    local v = GetResourceMetadata(res, 'version', 0)
    if v == nil or v == '' then return nil end
    return v
end

local function compareSemver(a, b)
    if not a or not b then return 0 end
    local function splitNums(s)
        local t = {}
        for n in tostring(s):gmatch('(%d+)') do t[#t+1] = tonumber(n) or 0 end
        return t
    end
    local A, B = splitNums(a), splitNums(b)
    local len = math.max(#A, #B)
    for i = 1, len do
        local x, y = A[i] or 0, B[i] or 0
        if x < y then return -1 end
        if x > y then return 1 end
    end
    return 0
end

local function checkForUpdates()
    if GetConvarInt('cqadmin_versioncheck', 0) ~= 1 then
        return
    end
    local localVer = getLocalVersion()
    if not localVer then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print('Version check: local version missing from fxmanifest')
        end
    end
    if GetConvarInt('cqadmin_debug', 0) == 1 then
        print(('Version: %s'):format(localVer or 'unknown'))
    end

    PerformHttpRequest(VERSION_CHECK_URL, function(status, body, _headers)
        if status ~= 200 or type(body) ~= 'string' or #body == 0 then
            if GetConvarInt('cqadmin_debug', 0) == 1 then
                print(('Version check failed (HTTP %s)'):format(tostring(status)))
            end
            return
        end
        local remoteVer = parseVersionFromFxmanifest(body)
        if not remoteVer then
            if GetConvarInt('cqadmin_debug', 0) == 1 then
                print('Version check: unable to parse remote version')
            end
            return
        end
        if not localVer then
            print(('Upstream version is %s'):format(remoteVer))
            return
        end
        local cmp = compareSemver(localVer, remoteVer)
        if cmp < 0 then
            print(('Update available: local %s < upstream %s'):format(localVer, remoteVer))
        elseif cmp > 0 then
            if GetConvarInt('cqadmin_debug', 0) == 1 then
                print(('Local version %s is ahead of upstream %s'):format(localVer, remoteVer))
            end
        end
    end, 'GET')
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    Wait(500)
    checkForUpdates()
end)

GROUPS = {
    spawnVehicle = 'admin.vehicles',
    fixVehicle   = 'admin.vehicles',
    cleanVehicle = 'admin.vehicles',
    deleteVeh    = 'admin.vehicles',
    flipVeh      = 'admin.vehicles',
    warpVeh      = 'admin.vehicles',
    godMode      = 'admin.vehicles',
    toggleEngine = 'admin.vehicles',
    vehicleInvisible = 'admin.vehicles',
    maxPerformance = 'admin.vehicles',
    setLicensePlate = 'admin.vehicles',
    openAllDoors = 'admin.vehicles',
    closeAllDoors = 'admin.vehicles',
    popAllWindows = 'admin.vehicles',
    setNeonColor = 'admin.vehicles',
    enableNeon   = 'admin.vehicles',
    setPrimaryColor = 'admin.vehicles',
    setSecondaryColor = 'admin.vehicles',

    healSelf     = 'admin.player',
    giveArmor    = 'admin.player',
    revive       = 'admin.player',
    teleport     = 'admin.player',
    noclip       = 'admin.player',
    giveWeapon   = 'admin.player',
    invisible    = 'admin.player',
    unlimitedStamina = 'admin.player',
    fastRun      = 'admin.player',
    fastSwim     = 'admin.player',
    superJump    = 'admin.player',
    noRagdoll    = 'admin.player',
    neverWanted  = 'admin.player',
    everyoneIgnore = 'admin.player',
    stayInVehicle = 'admin.player',
    freezePlayer = 'admin.player',
    setWantedLevel = 'admin.player',
    cleanPlayer  = 'admin.player',
    dryPlayer    = 'admin.player',
    wetPlayer    = 'admin.player',
    clearBlood   = 'admin.player',
    suicide      = 'admin.player',

    getAllWeapons = 'admin.weapons',
    removeAllWeapons = 'admin.weapons',
    spawnWeaponByName = 'admin.weapons',
    refillAmmo   = 'admin.weapons',
    setAmmo      = 'admin.weapons',
    unlimitedAmmo = 'admin.weapons',
    noReload     = 'admin.weapons',
    giveParachute = 'admin.weapons',
    autoParachute = 'admin.weapons',

    spawnObject  = 'admin.world',
    spawnObjectAt= 'admin.world',
    delNearby    = 'admin.world',
    timeWeather  = 'admin.world',

    freezeTime   = 'admin.time_weather',
    setTime      = 'admin.time_weather',
    setWeather   = 'admin.time_weather',

    speedoKMH    = 'admin.misc',
    speedoMPH    = 'admin.misc',
    showCoords   = 'admin.misc',
    hideHUD      = 'admin.misc',
    hideRadar    = 'admin.misc',
    showLocation = 'admin.misc',
    showTime     = 'admin.misc',
    nightVision  = 'admin.misc',
    thermalVision = 'admin.misc',
    lockCamX     = 'admin.misc',
    lockCamY     = 'admin.misc',
    clearArea    = 'admin.misc',

    spawnPedByName = 'admin.appearance',
    resetPed     = 'admin.appearance',
    setPedPreset = 'admin.appearance',

    debugToggle  = 'admin.debug',
}

local _capReqAt = {}
local _denyCooldown = {}
local _openMenuAt = {}
local _ackAt = {}
local _useAt = {}
local CAP_REQ_WINDOW_MS = GetConvarInt('cqadmin_cap_req_window_ms', 2000)
local DENY_COOLDOWN_MS = GetConvarInt('cqadmin_deny_cooldown_ms', 2000)
local OPEN_MENU_WINDOW_MS = GetConvarInt('cqadmin_open_menu_window_ms', 1000)
local HANDSHAKE_WINDOW_MS = GetConvarInt('cqadmin_grant_handshake_window_ms', 50)

function hasGroup(src, group)
    local isAllowed = IsPlayerAceAllowed(src, group)
    if GetConvarInt('cqadmin_debug', 0) == 1 then
        print(('Check group %s for src %d -> %s'):format(group, tonumber(src) or -1, tostring(isAllowed)))
    end
    return isAllowed
end

function notify(src, level, msg, ok)
    TriggerClientEvent('cq-admin:cl:notify', src, { type = level or 'info', message = msg or '', ok = ok })
end

function deny(src, action, group)
    local now = GetGameTimer()
    local last = _denyCooldown[src] or 0
    if (now - last) >= DENY_COOLDOWN_MS then
        notify(src, 'error', ('Permission denied: %s (requires group %s)'):format(action, group), false)
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Denied %s for %s (requires group %s)'):format(action, GetPlayerName(src) or ('src '..tostring(src)), group))
        end
        _denyCooldown[src] = now
    end
end

local _grants = {}
local _grantCountBySrc = {}
local _grantsTotalCount = 0
local MAX_GRANTS_PER_SRC = GetConvarInt('cqadmin_max_grants_per_src', 32)
local MAX_GRANTS_TOTAL = GetConvarInt('cqadmin_max_grants_total', 1024)

local function _randHex(n)
    local s = {}
    local hasNativeRand = (type(GetRandomIntInRange) == 'function')
    for i = 1, n do
        local v = hasNativeRand and GetRandomIntInRange(0, 15) or math.random(0, 15)
        s[i] = ("%x"):format(v)
    end
    return table.concat(s)
end

local function _newReqId()
    local now = GetGameTimer()
    local cloud = (GetCloudTimeAsInt and GetCloudTimeAsInt()) or 0
    return ("%d-%d-%s-%s"):format(now, cloud, _randHex(16), _randHex(16))
end

local function _newOtp()
    return ("%s%s%s%s"):format(_randHex(8), _randHex(8), _randHex(8), _randHex(8))
end

local function _grantRemove(id)
    local g = _grants[id]
    if not g then return end
    _grants[id] = nil
    local s = g.src
    if s then _grantCountBySrc[s] = math.max(0, (_grantCountBySrc[s] or 0) - 1) end
    _grantsTotalCount = math.max(0, _grantsTotalCount - 1)
end

function issueGrant(src, action, clientEvent, ...)
    local payload = { ... }
    local reqId = _newReqId()
    local otp = _newOtp()
    local expiresAt = GetGameTimer() + 15000
    local bySrc = _grantCountBySrc[src] or 0
    if bySrc >= MAX_GRANTS_PER_SRC or _grantsTotalCount >= MAX_GRANTS_TOTAL then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Refusing grant (%s) for src %d: capacity exceeded (src=%d/%d, total=%d/%d)')
                :format(action or 'unknown', tonumber(src) or -1, bySrc, MAX_GRANTS_PER_SRC, _grantsTotalCount, MAX_GRANTS_TOTAL))
        end
        notify(src, 'error', 'Too many pending actions, please wait a moment', false)
        return
    end
    _grants[reqId] = { src = src, action = action, clientEvent = clientEvent, payload = payload, otp = otp, exp = expiresAt, ready = false }
    _grantCountBySrc[src] = bySrc + 1
    _grantsTotalCount = _grantsTotalCount + 1
    TriggerClientEvent('cq-admin:cl:grant', src, reqId, action, otp)
end

RegisterNetEvent('cq-admin:sv:ack', function(reqId, otp)
    local src = source
    local now = GetGameTimer()
    local last = _ackAt[src] or 0
    if (now - last) < HANDSHAKE_WINDOW_MS then return end
    _ackAt[src] = now

    local grant = _grants[reqId]
    if not grant then return end
    if grant.src ~= src then _grantRemove(reqId); return end
    if grant.otp ~= otp then _grantRemove(reqId); return end
    if grant.exp and grant.exp < now then _grantRemove(reqId); return end
    grant.ready = true
    TriggerClientEvent(grant.clientEvent, src, reqId, table.unpack(grant.payload or {}))
end)

RegisterNetEvent('cq-admin:sv:use', function(reqId)
    local src = source
    local now = GetGameTimer()
    local last = _useAt[src] or 0
    if (now - last) < HANDSHAKE_WINDOW_MS then
        TriggerClientEvent('cq-admin:cl:used', src, reqId, false)
        return
    end
    _useAt[src] = now

    local grant = _grants[reqId]
    local ok = false
    if grant and grant.src == src and grant.ready and (not grant.exp or grant.exp >= now) then
        ok = true
        _grantRemove(reqId)
    end
    TriggerClientEvent('cq-admin:cl:used', src, reqId, ok)
end)



RegisterNetEvent('cq-admin:sv:requestCapabilities', function()
    local src = source
    local now = GetGameTimer()
    local last = _capReqAt[src] or 0
    if (now - last) < CAP_REQ_WINDOW_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled requestCapabilities from src %d'):format(src))
        end
        return
    end
    _capReqAt[src] = now
    local caps = {
        player = hasGroup(src, 'admin.player') or false,
        world = hasGroup(src, 'admin.world') or false,
        debug = hasGroup(src, 'admin.debug') or false,
        vehicles = hasGroup(src, 'admin.vehicles') or false,
        weapons = hasGroup(src, 'admin.weapons') or false,
        time_weather = hasGroup(src, 'admin.time_weather') or false,
        misc = hasGroup(src, 'admin.misc') or false,
        appearance = hasGroup(src, 'admin.appearance') or false,
    }
    TriggerClientEvent('cq-admin:cl:setCapabilities', src, caps)
end)

RegisterNetEvent('cq-admin:sv:openMenuRequest', function(srcOverride)
    local src = source
    if not src or src <= 0 then
        src = tonumber(srcOverride) or 0
    end
    if not src or src <= 0 then return end
    local now = GetGameTimer()
    local last = _openMenuAt[src] or 0
    if (now - last) < OPEN_MENU_WINDOW_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled openMenuRequest from src %d'):format(src))
        end
        return
    end
    _openMenuAt[src] = now
    local caps = {
        hasGroup(src, 'admin.player'),
        hasGroup(src, 'admin.world'),
        hasGroup(src, 'admin.debug'),
        hasGroup(src, 'admin.vehicles'),
        hasGroup(src, 'admin.weapons'),
        hasGroup(src, 'admin.time_weather'),
        hasGroup(src, 'admin.misc'),
        hasGroup(src, 'admin.appearance'),
    }
    local allowed = false
    for _, v in ipairs(caps) do if v then allowed = true break end end
    if not allowed then
        deny(src, 'openMenu', 'any admin.* group')
        return
    end
    issueGrant(src, 'openMenu', 'cq-admin:cl:open')
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = GetGameTimer()
        for k, v in pairs(_grants) do
            if v.exp and v.exp < now then _grantRemove(k) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    _capReqAt[src] = nil
    _denyCooldown[src] = nil
    _openMenuAt[src] = nil
    _ackAt[src] = nil
    _useAt[src] = nil
    for id, g in pairs(_grants) do
        if g.src == src then
            _grantRemove(id)
        end
    end
    _grantCountBySrc[src] = nil
end)
