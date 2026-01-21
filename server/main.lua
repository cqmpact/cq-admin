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

local GROUPS = {
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
local _menuOpen = {}
local _actionCooldown = {}
local _logQueue = {}
local _logFlushAt = 0
local _denyCooldown = {}
local _openMenuAt = {}
local _ackAt = {}
local _useAt = {}
local CAP_REQ_WINDOW_MS = GetConvarInt('cqadmin_cap_req_window_ms', 2000)
local DENY_COOLDOWN_MS = GetConvarInt('cqadmin_deny_cooldown_ms', 2000)
local OPEN_MENU_WINDOW_MS = GetConvarInt('cqadmin_open_menu_window_ms', 1000)
local HANDSHAKE_WINDOW_MS = GetConvarInt('cqadmin_grant_handshake_window_ms', 50)
local CAP_OPEN_WINDOW_MS = GetConvarInt('cqadmin_cap_open_window_ms', 300000)
local LOG_INTERVAL_MS = GetConvarInt('cqadmin_log_interval_ms', 30000)
local DISCORD_WEBHOOK = GetConvar('cqadmin_discord_webhook', '')

local ACTION_COOLDOWNS = {
    spawnObject = GetConvarInt('cqadmin_cd_spawn_object_ms', 1000),
    spawnObjectAt = GetConvarInt('cqadmin_cd_spawn_object_at_ms', 1000),
    deleteNearby = GetConvarInt('cqadmin_cd_delete_nearby_ms', 2000),
    spawnVehicle = GetConvarInt('cqadmin_cd_spawn_vehicle_ms', 2000),
    spawnVehicleGizmo = GetConvarInt('cqadmin_cd_spawn_vehicle_gizmo_ms', 2000),
    spawnVehicleAt = GetConvarInt('cqadmin_cd_spawn_vehicle_at_ms', 2000),
    spawnWeaponByName = GetConvarInt('cqadmin_cd_spawn_weapon_ms', 500),
    giveWeapon = GetConvarInt('cqadmin_cd_give_weapon_ms', 500),
    removeAllWeapons = GetConvarInt('cqadmin_cd_remove_weapons_ms', 2000),
}

local function _truncate(s, maxLen)
    if type(s) ~= 'string' then s = tostring(s or '') end
    if #s <= maxLen then return s end
    return s:sub(1, maxLen) .. '...'
end

local function _nowLocal()
    return os.time()
end

local function _cleanValue(v)
    local s = _truncate(tostring(v or ''), 300)
    s = s:gsub('`', "'")
    return s
end

local function _summarizePayload(value)
    if type(value) == 'table' then
        local ok, encoded = pcall(json.encode, value)
        if ok and type(encoded) == 'string' then
            return _truncate(encoded, 300)
        end
    end
    return _truncate(tostring(value or ''), 300)
end

local function _queueLog(severity, msg, meta)
    local sev = tostring(severity or 'info'):lower()
    if sev ~= 'info' and sev ~= 'warn' and sev ~= 'error' then sev = 'info' end
    local entry = {
        ts_unix = _nowLocal(),
        sev = sev,
        msg = tostring(msg or ''),
        meta = meta,
    }
    _logQueue[#_logQueue + 1] = entry
end

local function _sevRank(sev)
    if sev == 'error' then return 3 end
    if sev == 'warn' then return 2 end
    return 1
end

local function _formatLogLine(e)
    local icon = (e.sev == 'error' and ':red_circle:') or (e.sev == 'warn' and ':warning:') or ':white_circle:'
    local ts = tonumber(e.ts_unix) or _nowLocal()
    local timeTag = ('<t:%d:F>'):format(ts)
    local meta = type(e.meta) == 'table' and e.meta or {}
    local actionOrMsg = meta.action or e.msg or ''
    local name = meta.name or ''
    local line1 = ('%s %s'):format(icon, timeTag)
    local line2 = ('%s - %s'):format(e.sev:upper(), _cleanValue(actionOrMsg))
    if name ~= '' then
        line2 = line2 .. (' - %s'):format(_cleanValue(name))
    end

    local parts = {}
    if meta.src ~= nil and meta.src ~= '' then parts[#parts + 1] = ('src=`%s`'):format(_cleanValue(meta.src)) end
    if meta.reqId ~= nil and meta.reqId ~= '' then parts[#parts + 1] = ('reqId=`%s`'):format(_cleanValue(meta.reqId)) end
    if meta.group ~= nil and meta.group ~= '' then parts[#parts + 1] = ('group=`%s`'):format(_cleanValue(meta.group)) end
    if meta.reason ~= nil and meta.reason ~= '' then parts[#parts + 1] = ('reason=`%s`'):format(_cleanValue(meta.reason)) end
    if meta.payload ~= nil and meta.payload ~= '' then parts[#parts + 1] = ('payload=`%s`'):format(_cleanValue(meta.payload)) end
    if meta.action and meta.action ~= e.msg and e.msg and e.msg ~= '' then
        parts[#parts + 1] = ('msg=`%s`'):format(_cleanValue(e.msg))
    end
    local line3 = ''
    if #parts > 0 then
        line3 = table.concat(parts, '\n')
    end

    local block = line1 .. '\n' .. line2
    if line3 ~= '' then
        block = block .. '\n' .. line3
    end
    return _truncate(block, 1800), _sevRank(e.sev)
end

local function _flushLogs()
    if type(DISCORD_WEBHOOK) ~= 'string' or DISCORD_WEBHOOK == '' then
        _logQueue = {}
        return
    end
    if #_logQueue == 0 then return end
    local messages = {}
    local current = ''
    for i = 1, #_logQueue do
        local entry = _logQueue[i]
        local line = _formatLogLine(entry)
        if current == '' then
            current = line
        elseif (#current + 2 + #line) > 1900 then
            messages[#messages + 1] = current
            current = line
        else
            current = current .. '\n\n' .. line
        end
    end
    if current ~= '' then messages[#messages + 1] = current end
    _logQueue = {}
    for _, msg in ipairs(messages) do
        PerformHttpRequest(DISCORD_WEBHOOK, function() end, 'POST',
            json.encode({ content = msg }), { ['Content-Type'] = 'application/json' })
    end
end

local function hasGroup(src, group)
    local isAllowed = IsPlayerAceAllowed(src, group)
    if GetConvarInt('cqadmin_debug', 0) == 1 then
        print(('Check group %s for src %d -> %s'):format(group, tonumber(src) or -1, tostring(isAllowed)))
    end
    return isAllowed
end

local function notify(src, level, msg, ok)
    TriggerClientEvent('cq-admin:cl:notify', src, { type = level or 'info', message = msg or '', ok = ok })
end

local function deny(src, action, group)
    local now = GetGameTimer()
    local last = _denyCooldown[src] or 0
    if (now - last) >= DENY_COOLDOWN_MS then
        notify(src, 'error', ('Permission denied: %s (requires group %s)'):format(action, group), false)
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Denied %s for %s (requires group %s)'):format(action, GetPlayerName(src) or ('src '..tostring(src)), group))
        end
        _queueLog('warn', 'Permission denied', { action = action, group = group, src = src, name = GetPlayerName(src) or '' })
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

local function issueGrant(src, action, clientEvent, ...)
    if type(action) == 'string' and ACTION_COOLDOWNS[action] and ACTION_COOLDOWNS[action] > 0 then
        _actionCooldown[src] = _actionCooldown[src] or {}
        local now = GetGameTimer()
        local last = _actionCooldown[src][action] or 0
        if (now - last) < ACTION_COOLDOWNS[action] then
            if GetConvarInt('cqadmin_debug', 0) == 1 then
                print(('[cq-admin] Throttled %s from src %d'):format(action, src))
            end
            _queueLog('warn', 'Action throttled', { action = action, src = src, name = GetPlayerName(src) or '' })
            notify(src, 'error', 'Too many pending actions, please wait a moment', false)
            return
        end
        _actionCooldown[src][action] = now
    end
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
        _queueLog('warn', 'Grant refused: capacity exceeded', { action = action, src = src, name = GetPlayerName(src) or '' })
        notify(src, 'error', 'Too many pending actions, please wait a moment', false)
        return
    end
    _grants[reqId] = { src = src, action = action, clientEvent = clientEvent, payload = payload, otp = otp, exp = expiresAt, ready = false }
    _grantCountBySrc[src] = bySrc + 1
    _grantsTotalCount = _grantsTotalCount + 1
    TriggerClientEvent('cq-admin:cl:grant', src, reqId, action, otp)
    if type(action) == 'string' then
        local parts = {}
        for i = 1, #payload do
            parts[#parts + 1] = _summarizePayload(payload[i])
        end
        _queueLog('info', 'Grant issued', {
            action = action,
            src = src,
            name = GetPlayerName(src) or '',
            reqId = reqId,
            payload = table.concat(parts, ', ')
        })
    end
end

RegisterNetEvent('cq-admin:sv:ack', function(reqId, otp)
    local src = source
    local now = GetGameTimer()
    local last = _ackAt[src] or 0
    if (now - last) < HANDSHAKE_WINDOW_MS then return end
    _ackAt[src] = now

    local grant = _grants[reqId]
    if not grant then
        _queueLog('warn', 'Grant ack rejected', { reason = 'missing', src = src, name = GetPlayerName(src) or '', reqId = reqId })
        return
    end
    if grant.src ~= src then
        _queueLog('warn', 'Grant ack rejected', { reason = 'wrong_src', src = src, name = GetPlayerName(src) or '', reqId = reqId })
        _grantRemove(reqId)
        return
    end
    if grant.otp ~= otp then
        _queueLog('warn', 'Grant ack rejected', { reason = 'bad_otp', src = src, name = GetPlayerName(src) or '', reqId = reqId })
        _grantRemove(reqId)
        return
    end
    if grant.exp and grant.exp < now then
        _queueLog('warn', 'Grant ack rejected', { reason = 'expired', src = src, name = GetPlayerName(src) or '', reqId = reqId })
        _grantRemove(reqId)
        return
    end
    grant.ready = true
    TriggerClientEvent(grant.clientEvent, src, reqId, table.unpack(grant.payload or {}))
    _queueLog('info', 'Grant acknowledged', { action = grant.action, src = src, name = GetPlayerName(src) or '', reqId = reqId })
end)

CQAdmin = CQAdmin or {}
CQAdmin._internal = CQAdmin._internal or {}
CQAdmin._internal.hasGroup = hasGroup
CQAdmin._internal.deny = deny
CQAdmin._internal.issueGrant = issueGrant
CQAdmin._internal.notify = notify
CQAdmin._internal.GROUPS = GROUPS

RegisterNetEvent('cq-admin:sv:use', function(reqId, action)
    local src = source
    local now = GetGameTimer()
    local last = _useAt[src] or 0
    if (now - last) < HANDSHAKE_WINDOW_MS then
        _queueLog('warn', 'Grant use throttled', { action = action, src = src, name = GetPlayerName(src) or '', reqId = reqId })
        TriggerClientEvent('cq-admin:cl:used', src, reqId, false)
        return
    end
    _useAt[src] = now

    local grant = _grants[reqId]
    local ok = false
    if grant and grant.src == src and grant.ready and (not grant.exp or grant.exp >= now) then
        if type(action) ~= 'string' or action == '' or action ~= grant.action then
            _grantRemove(reqId)
            TriggerClientEvent('cq-admin:cl:used', src, reqId, false)
            return
        end
        ok = true
        _grantRemove(reqId)
    end
    if ok then
        local name = GetPlayerName(src) or ('src '..tostring(src))
        _queueLog('info', 'Action used', { action = action, src = src, name = name, reqId = reqId })
        if action == 'openMenu' then
            _menuOpen[src] = GetGameTimer() + CAP_OPEN_WINDOW_MS
        end
    else
        _queueLog('warn', 'Action failed', { action = action, src = src, name = GetPlayerName(src) or '', reqId = reqId })
    end
    TriggerClientEvent('cq-admin:cl:used', src, reqId, ok)
end)



RegisterNetEvent('cq-admin:sv:requestCapabilities', function()
    local src = source
    local now = GetGameTimer()
    local last = _capReqAt[src] or 0
    local allowUntil = _menuOpen[src] or 0
    if allowUntil < now then
        _queueLog('warn', 'Capabilities request blocked', { src = src, name = GetPlayerName(src) or '' })
        return
    end
    if (now - last) < CAP_REQ_WINDOW_MS then
        if GetConvarInt('cqadmin_debug', 0) == 1 then
            print(('[cq-admin] Throttled requestCapabilities from src %d'):format(src))
        end
        _queueLog('warn', 'Capabilities request throttled', { src = src, name = GetPlayerName(src) or '' })
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
    _queueLog('info', 'Capabilities delivered', { src = src, name = GetPlayerName(src) or '' })
end)

RegisterNetEvent('cq-admin:sv:menuOpened', function()
    local src = source
    _menuOpen[src] = GetGameTimer() + CAP_OPEN_WINDOW_MS
    _queueLog('info', 'Menu opened', { src = src, name = GetPlayerName(src) or '' })
end)

RegisterNetEvent('cq-admin:sv:menuClosed', function()
    local src = source
    _menuOpen[src] = nil
    _queueLog('info', 'Menu closed', { src = src, name = GetPlayerName(src) or '' })
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
        _queueLog('warn', 'openMenu throttled', { src = src, name = GetPlayerName(src) or '' })
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
        _queueLog('warn', 'openMenu denied', { src = src, name = GetPlayerName(src) or '' })
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
    _menuOpen[src] = nil
    _actionCooldown[src] = nil
    for id, g in pairs(_grants) do
        if g.src == src then
            _grantRemove(id)
        end
    end
    _grantCountBySrc[src] = nil
end)

CreateThread(function()
    while true do
        Wait(500)
        local now = GetGameTimer()
        if (now - _logFlushAt) >= LOG_INTERVAL_MS then
            _logFlushAt = now
            _flushLogs()
        end
    end
end)
