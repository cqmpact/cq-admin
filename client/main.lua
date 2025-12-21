--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

CQAdminCategories = CQAdminCategories or {}
function RegisterAdminCategory(key, mod)
    if type(key) == 'string' and type(mod) == 'table' then
        CQAdminCategories[key] = mod
    end
end

local isOpen = false
local capabilities = nil
local freeControl = false

CQAdmin_DebugRadius = CQAdmin_DebugRadius or 50.0
function CQAdmin_GetDebugRadius()
    return CQAdmin_DebugRadius
end
function CQAdmin_SetDebugRadius(radius)
    CQAdmin_DebugRadius = tonumber(radius) or CQAdmin_DebugRadius
end

local IB = {
    handle = nil,
    active = false,
    drawing = false,
}

local _grants = {}
local _grantedUse = {}

local function _grantAdd(reqId, ttlMs)
    if type(reqId) ~= 'string' or reqId == '' then return end
    _grants[reqId] = (GetGameTimer() + (ttlMs or 15000))
end

local function _grantConsume(reqId)
    if type(reqId) ~= 'string' then return false end
    local exp = _grants[reqId]
    if not exp then return false end
    _grants[reqId] = nil
    if exp < GetGameTimer() then return false end
    return true
end

local function _validateGrant(reqId)
    if not _grantConsume(reqId) then return false end
    _grantedUse[reqId] = nil
    TriggerServerEvent('cq-admin:sv:use', reqId)
    local start = GetGameTimer()
    while _grantedUse[reqId] == nil and (GetGameTimer() - start) < 2000 do
        Wait(0)
    end
    local ok = _grantedUse[reqId] == true
    _grantedUse[reqId] = nil
    return ok
end
_G._validateGrant = _validateGrant

local function _moduleEnabled(name)
    local cfg = rawget(_G, 'CQAdmin_Config')
    local enabled = (type(cfg) == 'table' and type(cfg.enabledModules) == 'table') and cfg.enabledModules[name]
    if enabled == nil then return true end
    return enabled and true or false
end

local function ibUnload()
    if IB.handle then
        SetScaleformMovieAsNoLongerNeeded(IB.handle)
        IB.handle = nil
    end
    IB.active = false
end

local function ibEnsureHandle()
    if IB.handle then return IB.handle end
    local h = RequestScaleformMovie('INSTRUCTIONAL_BUTTONS')
    while not HasScaleformMovieLoaded(h) do
        Wait(0)
    end
    IB.handle = h
    return h
end

function DisplayInstructionalButtons(buttons)
    local h = ibEnsureHandle()

    CallScaleformMovieMethod(h, 'CLEAR_ALL')
    CallScaleformMovieMethodWithNumber(h, 'TOGGLE_MOUSE_BUTTONS', 0)

    if type(buttons) == 'table' then
        local idx = 0
        for _, btn in ipairs(buttons) do
            local control = (type(btn) == 'table' and (btn.control or btn.key or btn.icon)) or ''
            local label = (type(btn) == 'table' and (btn.label or btn.text)) or ''
            if control ~= '' and label ~= '' then
                BeginScaleformMovieMethod(h, 'SET_DATA_SLOT')
                ScaleformMovieMethodAddParamInt(idx)
                ScaleformMovieMethodAddParamPlayerNameString(control)
                ScaleformMovieMethodAddParamPlayerNameString(label)
                EndScaleformMovieMethod()
                idx = idx + 1
            end
        end
    end

    CallScaleformMovieMethod(h, 'DRAW_INSTRUCTIONAL_BUTTONS')
    IB.active = true

    if not IB.drawing then
        IB.drawing = true
        CreateThread(function()
            while IB.active do
                DrawScaleformMovieFullscreen(IB.handle, 255, 255, 255, 255, 0)
                Wait(0)
            end
            IB.drawing = false
        end)
    end
end

function HideInstructionalButtons()
    IB.active = false
    ibUnload()
end

RegisterNetEvent('cq-admin:ib:show', function(payload)
    if type(payload) ~= 'table' then return end
    DisplayInstructionalButtons(payload)
end)

RegisterNetEvent('cq-admin:ib:hide', function()
    HideInstructionalButtons()
end)

local function _quietMode()
    local cfg = rawget(_G, 'CQAdmin_Config')
    return type(cfg) == 'table' and (cfg.quietNotifications ~= false)
end

function notify(type_, message)
    local t = type_ or 'info'
    if _quietMode() and t == 'info' then return end
    SendNUIMessage({ action = 'cq:menu:notify', type = t, message = message or '' })
end

RegisterNetEvent('cq-admin:cl:notify', function(msg)
    if type(msg) == 'table' then
        notify(msg.type or (msg.ok == false and 'error' or 'info'), msg.message or msg.msg or msg.notify or '')
    elseif type(msg) == 'string' then
        notify('info', msg)
    end
end)

RegisterNetEvent('cq-admin:cl:grant', function(reqId, _action, otp)
    if type(reqId) ~= 'string' or reqId == '' or type(otp) ~= 'string' or otp == '' then return end
    _grantAdd(reqId, 15000)
    TriggerServerEvent('cq-admin:sv:ack', reqId, otp)
end)

RegisterNetEvent('cq-admin:cl:used', function(reqId, ok)
    _grantedUse[reqId] = ok and true or false
end)

RegisterNetEvent('cq-admin:cl:setCapabilities', function(caps)
    capabilities = caps or {}
    if isOpen then
        local data = (function()
            local effects = {}
            local function add(name)
                local mod = CQAdminCategories[name]
                if mod and type(mod.build) == 'function' then
                    local ok, res = pcall(mod.build)
                    if ok and type(res) == 'table' then
                        effects[#effects+1] = res
                    end
                end
            end

            if capabilities.player and _moduleEnabled('player') then add('player') end
            if capabilities.weapons and _moduleEnabled('weapons') then add('weapons') end
            if capabilities.vehicles and _moduleEnabled('vehicles') then add('vehicles') end
            if capabilities.appearance and _moduleEnabled('appearance') then add('appearance') end
            if capabilities.time_weather and _moduleEnabled('time_weather') then add('time_weather') end
            if capabilities.misc and _moduleEnabled('misc') then add('misc') end
            if capabilities.world and _moduleEnabled('world') then add('world') end
            if capabilities.debug and _moduleEnabled('debug') then add('debug') end

            local data = {
                title = "Admin Menu",
                effects = effects,
                globalGroups = {},
                callbacks = {
                    close = "cq-admin:cb:closeMenu",
                    reload = "cq-admin:cb:reload"
                }
            }
            return data
        end)()

        data.quiet = _quietMode()

        if #data.effects == 0 then
            SendNUIMessage({ action = "cq:menu:open", data = data })
            notify('error', 'You do not have access to any admin sections')
        else
            SendNUIMessage({ action = "cq:menu:open", data = data })
        end
    end
end)



RegisterCommand('admin', function()
    if isOpen then
        if freeControl then
            freeControl = false
            SetNuiFocus(true, true)
            SendNUIMessage({ action = 'cq:menu:setFreeControl', enabled = false })
        end
        return
    end
    TriggerServerEvent('cq-admin:sv:openMenuRequest')
end, false)

RegisterKeyMapping('admin', '(Admin) Open Menu', 'keyboard', 'F10')

RegisterCommand('noclip', function()
    TriggerServerEvent('cq-admin:sv:noclip:toggle')
end, false)

RegisterKeyMapping('noclip', '(Admin) Noclip', 'keyboard', 'F2')

RegisterNetEvent('cq-admin:cl:open', function()
    if isOpen then return end
    isOpen = true
    freeControl = false
    SetNuiFocus(true, true)
    TriggerServerEvent('cq-admin:sv:requestCapabilities')
end)

RegisterNetEvent('cq-admin:cl:close', function()
    if not isOpen then return end
    isOpen = false
    freeControl = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'cq:menu:close' })
end)

RegisterNUICallback('cq-admin:cb:closeMenu', function(_, cb)
    isOpen = false
    freeControl = false
    SetNuiFocus(false, false)
    cb({})
end)

RegisterNUICallback('cq-admin:cb:reload', function(_, cb)
    if isOpen then
        TriggerServerEvent('cq-admin:sv:requestCapabilities')
    end
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:toggleFreeControl', function(data, cb)
    local enabled = data and (data.enabled == true)
    freeControl = enabled and true or false
    if freeControl then
        SetNuiFocus(false, false)
    else
        if isOpen then
            SetNuiFocus(true, true)
        end
    end
    SendNUIMessage({ action = 'cq:menu:setFreeControl', enabled = freeControl })
    cb({ ok = true })
end)


AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if isOpen then
        isOpen = false
        freeControl = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'cq:menu:close' })
    end
    HideInstructionalButtons()
end)
