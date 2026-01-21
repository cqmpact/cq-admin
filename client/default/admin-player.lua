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
RegisterAdminCategory('player', {
    build = function()
        return {
            id = "player_mgmt",
            label = "Player Management",
            sub = "Heal, give armor, revive, teleport, weapons, noclip",
            enabled = true,
            groups = {
                {
                    id = "player_actions",
                    type = "group",
                    label = "Player actions",
                    children = {
                        { label = "Heal self", type = "button", buttonLabel = "Heal", callback = "cq-admin:cb:healSelf" },
                        { label = "Give armor (0-100)", type = "inputButton", placeholder = "100", buttonLabel = "Give", callback = "cq-admin:cb:giveArmor", payloadKey = "amount" },
                        { label = "Revive", type = "button", buttonLabel = "Revive", callback = "cq-admin:cb:revive" },
                        { label = "Teleport to waypoint", type = "button", buttonLabel = "Teleport", callback = "cq-admin:cb:teleportToWaypoint" },
                        { label = "Give weapon (name)", type = "inputButton", placeholder = "WEAPON_CARBINERIFLE", buttonLabel = "Give", callback = "cq-admin:cb:giveWeapon", payloadKey = "weapon" },
                        { label = "No-clip", type = "toggle", key = "noclip_t", callback = "cq-admin:cb:noclip", default = false },
                    }
                },
                {
                    id = "player_modes",
                    type = "group",
                    label = "Player modes",
                    children = {
                        { label = "God Mode", type = "toggle", key = "godmode_t", callback = "cq-admin:cb:godMode", default = false },
                        { label = "Invisible", type = "toggle", key = "invisible_t", callback = "cq-admin:cb:invisible", default = false },
                        { label = "Unlimited Stamina", type = "toggle", key = "stamina_t", callback = "cq-admin:cb:unlimitedStamina", default = false },
                        { label = "Fast Run", type = "toggle", key = "fastrun_t", callback = "cq-admin:cb:fastRun", default = false },
                        { label = "Fast Swim", type = "toggle", key = "fastswim_t", callback = "cq-admin:cb:fastSwim", default = false },
                        { label = "Super Jump", type = "toggle", key = "superjump_t", callback = "cq-admin:cb:superJump", default = false },
                        { label = "No Ragdoll", type = "toggle", key = "noragdoll_t", callback = "cq-admin:cb:noRagdoll", default = false },
                        { label = "Never Wanted", type = "toggle", key = "neverwanted_t", callback = "cq-admin:cb:neverWanted", default = false },
                        { label = "Everyone Ignore Player", type = "toggle", key = "ignored_t", callback = "cq-admin:cb:everyoneIgnore", default = false },
                        { label = "Stay In Vehicle", type = "toggle", key = "stayinveh_t", callback = "cq-admin:cb:stayInVehicle", default = false },
                        { label = "Freeze Player", type = "toggle", key = "freeze_t", callback = "cq-admin:cb:freezePlayer", default = false },
                    }
                },
                {
                    id = "player_utility",
                    type = "group",
                    label = "Player utility",
                    children = {
                        { label = "Set wanted level (0-5)", type = "inputButton", placeholder = "0", buttonLabel = "Set", callback = "cq-admin:cb:setWantedLevel", payloadKey = "level" },
                        { label = "Clean player", type = "button", buttonLabel = "Clean", callback = "cq-admin:cb:cleanPlayer" },
                        { label = "Dry player clothes", type = "button", buttonLabel = "Dry", callback = "cq-admin:cb:dryPlayer" },
                        { label = "Wet player clothes", type = "button", buttonLabel = "Wet", callback = "cq-admin:cb:wetPlayer" },
                        { label = "Clear blood", type = "button", buttonLabel = "Clear", callback = "cq-admin:cb:clearBlood" },
                        { label = "Suicide", type = "button", buttonLabel = "Suicide", callback = "cq-admin:cb:suicide" },
                    }
                }
            }
        }
    end
})


RegisterNUICallback('cq-admin:cb:healSelf', function(_, cb)
    TriggerServerEvent('cq-admin:sv:healSelf')
    cb({ ok = true })
end)

local C = CQ and CQ.Controls or {}
local U = CQ and CQ.Util or {}
local GetCamDir = (CQ and CQ.Util and CQ.Util.getCamDir) or function()
    local r = GetGameplayCamRot(2)
    local radZ, radX = math.rad(r.z), math.rad(r.x)
    local cosX = math.cos(radX)
    return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
end

RegisterNetEvent('cq-admin:cl:healSelf', function(reqId)
    if not ValidateGrant(reqId, 'healSelf') then return end
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    if notify then notify('success', 'Healed and armor set') end
end)

RegisterNetEvent('cq-admin:cl:giveArmor', function(reqId, amount)
    if not ValidateGrant(reqId, 'giveArmor') then return end
    local ped = PlayerPedId()
    local clamp = (CQ and CQ.Util and CQ.Util.clamp) or function(v,min,max)
        v = tonumber(v) or 0; if v < min then return min elseif v > max then return max else return v end
    end
    SetPedArmour(ped, clamp(amount, 0, 100))
    if notify then notify('success', 'Armor set') end
end)

RegisterNetEvent('cq-admin:cl:revive', function(reqId)
    if not ValidateGrant(reqId, 'revive') then return end
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    if notify then notify('success', 'Revived') end
end)

RegisterNetEvent('cq-admin:cl:giveWeapon', function(reqId, weapon, ammo)
    if not ValidateGrant(reqId, 'giveWeapon') then return end
    local ped = PlayerPedId()
    if not weapon or weapon == '' then return (notify and notify('error', 'Invalid weapon')) end
    local hash = GetHashKey(weapon)
    GiveWeaponToPed(ped, hash, tonumber(ammo) or 250, false, true)
    if notify then notify('success', ('Gave weapon: %s'):format(weapon)) end
end)

RegisterNetEvent('cq-admin:cl:teleportToWaypoint', function(reqId)
    if not ValidateGrant(reqId, 'teleportToWaypoint') then return end
    local blip = GetFirstBlipInfoId(8)
    if blip == 0 then return (notify and notify('error', 'No waypoint set')) end
    local coords = GetBlipInfoIdCoord(blip)
    local x, y, z = coords.x, coords.y, coords.z
    local groundZ, success
    for i = 1, 1000, 25 do
        success, groundZ = GetGroundZFor_3dCoord(x, y, i + 0.0, false)
        if success then z = groundZ + 1.0 break end
    end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        SetEntityCoordsNoOffset(veh, x, y, z, false, false, false)
    else
        SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    end
    if notify then notify('success', 'Teleported to waypoint') end
end)

local _noclipEnabled = false
local _noclipThread = false
local _noclipSpeedIndex = 2
local _noclipSpeeds = { 0.5, 1.0, 2.0, 5.0, 10.0 }

local function _noclipIB()
    return {
        { control = GetControlInstructionalButton(0, C.MOVE_RIGHT_ONLY or 35, true), label = "Right" },
        { control = GetControlInstructionalButton(0, C.MOVE_LEFT_ONLY or 34, true), label = "Left" },
        { control = GetControlInstructionalButton(0, C.MOVE_DOWN_ONLY or 33, true), label = "Backward" },
        { control = GetControlInstructionalButton(0, C.MOVE_UP_ONLY or 32, true), label = "Forward" },
        { control = GetControlInstructionalButton(0, C.PICKUP or 38, true), label = "Descend" },
        { control = GetControlInstructionalButton(0, C.COVER or 44, true), label = "Ascend" },
        { control = GetControlInstructionalButton(0, C.SCROLL_UP or 241, true), label = "Speed" },
        { control = GetControlInstructionalButton(0, C.SPRINT or 21, true), label = "x4" },
        { control = GetControlInstructionalButton(0, C.DUCK or 36, true), label = "x0.5" },
        { control = GetControlInstructionalButton(0, C.CHARACTER_WHEEL or 19, true), label = "x0.1" },
    }
end

-- Controls to disable during noclip (from utils)
local DISABLE = (CQ and CQ.NoclipDisableControls) or {
    30,31,24,257,140,141,142,143,263,25,37,16,17,261,262,44,38,45,32,33,34,35
}

RegisterNetEvent('cq-admin:cl:noclip', function(reqId, enabled)
    if not ValidateGrant(reqId, 'noclip') then return end
    _noclipEnabled = enabled and true or false
    local ped = PlayerPedId()
    SetEntityInvincible(ped, _noclipEnabled)
    SetEntityVisible(ped, not _noclipEnabled, false)
    SetEntityCollision(ped, not _noclipEnabled, not _noclipEnabled)
    SetPedGravity(ped, not _noclipEnabled)
    SetPedCanRagdoll(ped, not _noclipEnabled)
    if _noclipEnabled then
        ClearPedTasksImmediately(ped)
        ClearPedSecondaryTask(ped)
        ResetPedMovementClipset(ped, 0.0)
        ResetPedStrafeClipset(ped)
        FreezeEntityPosition(ped, true)
        SetEntityDynamic(ped, false)
    end
    if _noclipEnabled then
        if U and U.IB and U.IB.show then
            U.IB.show(_noclipIB())
        else
            TriggerEvent('cq-admin:ib:show', _noclipIB())
        end
    else
        if U and U.IB and U.IB.hide then
            U.IB.hide()
        else
            TriggerEvent('cq-admin:ib:hide')
        end
    end
    if _noclipEnabled and not _noclipThread then
        _noclipThread = true
        CreateThread(function()
            while _noclipThread and _noclipEnabled do
                Wait(0)
                DisablePlayerFiring(PlayerId(), true)
                if U and U.disableControls then
                    U.disableControls(DISABLE)
                else
                    for _, control in ipairs(DISABLE) do
                        DisableControlAction(0, control, true)
                    end
                end

                local coords = GetEntityCoords(ped)
                local camDir = GetCamDir()
                local speed = _noclipSpeeds[_noclipSpeedIndex] or 1.0
                if IsDisabledControlPressed(0, C.SPRINT or 21) then speed = speed * 4.0 end   -- LShift: 4x
                if IsDisabledControlPressed(0, C.DUCK or 36) then speed = speed * 0.5 end     -- LCtrl: 0.5x
                if IsDisabledControlPressed(0, C.CHARACTER_WHEEL or 19) then speed = speed * 0.1 end   -- LAlt: 0.1x
                local delta = vector3(0.0, 0.0, 0.0)
                local fwdH = vector3(camDir.x, camDir.y, 0.0)
                local lenF = #(fwdH)
                if lenF > 0.0001 then fwdH = fwdH / lenF end
                local rightH = vector3(-fwdH.y, fwdH.x, 0.0)
                if IsDisabledControlPressed(0, C.MOVE_UP_ONLY or 32) then -- W
                    delta = delta + (fwdH * speed)
                end
                if IsDisabledControlPressed(0, C.MOVE_DOWN_ONLY or 33) then -- S
                    delta = delta - (fwdH * speed)
                end
                if IsDisabledControlPressed(0, C.MOVE_RIGHT_ONLY or 35) then -- D
                    delta = delta + (rightH * speed)
                end
                if IsDisabledControlPressed(0, C.MOVE_LEFT_ONLY or 34) then -- A
                    delta = delta - (rightH * speed)
                end
                local horiz = vector3(delta.x, delta.y, 0.0)
                local lenH = #(horiz)
                if lenH > speed and lenH > 0.0001 then
                    local scale = speed / lenH
                    delta = vector3(horiz.x * scale, horiz.y * scale, delta.z)
                end
                if IsDisabledControlPressed(0, C.PICKUP or 38) then -- E (descend)
                    delta = delta - vector3(0.0, 0.0, speed)
                end
                if IsDisabledControlPressed(0, C.COVER or 44) then -- Q (ascend)
                    delta = delta + vector3(0.0, 0.0, speed)
                end
                if delta.x ~= 0.0 or delta.y ~= 0.0 or delta.z ~= 0.0 then
                    local dest = coords + delta
                    SetEntityCoordsNoOffset(ped, dest.x, dest.y, dest.z, false, false, false)
                end
                if IsDisabledControlPressed(0, C.SCROLL_UP or 241) then -- Scroll up
                    _noclipSpeedIndex = math.min(#_noclipSpeeds, _noclipSpeedIndex + 1)
                    if notify then notify('info', ('Noclip speed: x%.1f'):format(_noclipSpeeds[_noclipSpeedIndex])) end
                elseif IsDisabledControlPressed(0, C.SCROLL_DOWN or 242) then -- Scroll down
                    _noclipSpeedIndex = math.max(1, _noclipSpeedIndex - 1)
                    if notify then notify('info', ('Noclip speed: x%.1f'):format(_noclipSpeeds[_noclipSpeedIndex])) end
                end
            end
        end)
    else
        _noclipThread = false

        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        SetPedGravity(ped, true)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        ActivatePhysics(ped)
        SetEntityDynamic(ped, true)

        TriggerEvent('cq-admin:ib:hide')

        if not IsPedInAnyVehicle(ped, false) then
            local c = GetEntityCoords(ped)
            RequestCollisionAtCoord(c.x, c.y, c.z)
            ClearPedTasksImmediately(ped)
            ClearPedSecondaryTask(ped)
            ResetPedMovementClipset(ped, 0.0)
            ResetPedStrafeClipset(ped)
            if ResetPedWeaponMovementClipset then ResetPedWeaponMovementClipset(ped) end
            ResetPedRagdollTimer(ped)
        end
    end
    if notify then notify('info', ('Noclip: %s'):format(_noclipEnabled and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:giveArmor', function(data, cb)
    local amount = data and (data.amount or data.value) or 100
    TriggerServerEvent('cq-admin:sv:giveArmor', amount)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:revive', function(_, cb)
    TriggerServerEvent('cq-admin:sv:revive')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:teleportToWaypoint', function(_, cb)
    TriggerServerEvent('cq-admin:sv:teleportToWaypoint')
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:giveWeapon', function(data, cb)
    local weapon = data and (data.weapon or data.value) or nil
    TriggerServerEvent('cq-admin:sv:giveWeapon', weapon, 250)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:noclip', function(data, cb)
    local enabled = false
    if type(data) == 'table' then
        if data.value ~= nil then enabled = data.value and true or false end
    end
    TriggerServerEvent('cq-admin:sv:noclip', enabled)
    cb({ ok = true })
end)

local _godModeEnabled = false
local _invisibleEnabled = false
local _unlimitedStamina = false
local _fastRun = false
local _fastSwim = false
local _superJump = false
local _noRagdoll = false
local _neverWanted = false
local _everyoneIgnore = false
local _stayInVehicle = false
local _freezePlayer = false

RegisterNUICallback('cq-admin:cb:godMode', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:godMode', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:godMode', function(reqId, enabled)
    if not ValidateGrant(reqId, 'godMode') then return end
    _godModeEnabled = enabled and true or false
    local ped = PlayerPedId()
    SetEntityInvincible(ped, _godModeEnabled)
    if notify then notify('info', ('God Mode: %s'):format(_godModeEnabled and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:invisible', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:invisible', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:invisible', function(reqId, enabled)
    if not ValidateGrant(reqId, 'invisible') then return end
    _invisibleEnabled = enabled and true or false
    local ped = PlayerPedId()
    SetEntityVisible(ped, not _invisibleEnabled, false)
    if notify then notify('info', ('Invisible: %s'):format(_invisibleEnabled and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:unlimitedStamina', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:unlimitedStamina', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:unlimitedStamina', function(reqId, enabled)
    if not ValidateGrant(reqId, 'unlimitedStamina') then return end
    _unlimitedStamina = enabled and true or false
    if notify then notify('info', ('Unlimited Stamina: %s'):format(_unlimitedStamina and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _unlimitedStamina then
            RestorePlayerStamina(PlayerId(), 1.0)
        end
    end
end)

RegisterNUICallback('cq-admin:cb:fastRun', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:fastRun', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:fastRun', function(reqId, enabled)
    if not ValidateGrant(reqId, 'fastRun') then return end
    _fastRun = enabled and true or false
    SetRunSprintMultiplierForPlayer(PlayerId(), _fastRun and 1.49 or 1.0)
    if notify then notify('info', ('Fast Run: %s'):format(_fastRun and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:fastSwim', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:fastSwim', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:fastSwim', function(reqId, enabled)
    if not ValidateGrant(reqId, 'fastSwim') then return end
    _fastSwim = enabled and true or false
    SetSwimMultiplierForPlayer(PlayerId(), _fastSwim and 1.49 or 1.0)
    if notify then notify('info', ('Fast Swim: %s'):format(_fastSwim and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:superJump', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:superJump', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:superJump', function(reqId, enabled)
    if not ValidateGrant(reqId, 'superJump') then return end
    _superJump = enabled and true or false
    if notify then notify('info', ('Super Jump: %s'):format(_superJump and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _superJump then
            SetSuperJumpThisFrame(PlayerId())
        end
    end
end)

RegisterNUICallback('cq-admin:cb:noRagdoll', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:noRagdoll', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:noRagdoll', function(reqId, enabled)
    if not ValidateGrant(reqId, 'noRagdoll') then return end
    _noRagdoll = enabled and true or false
    if notify then notify('info', ('No Ragdoll: %s'):format(_noRagdoll and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _noRagdoll then
            SetPedCanRagdoll(PlayerPedId(), false)
        end
    end
end)

RegisterNUICallback('cq-admin:cb:neverWanted', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:neverWanted', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:neverWanted', function(reqId, enabled)
    if not ValidateGrant(reqId, 'neverWanted') then return end
    _neverWanted = enabled and true or false
    if notify then notify('info', ('Never Wanted: %s'):format(_neverWanted and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(500)
        if _neverWanted then
            SetPlayerWantedLevel(PlayerId(), 0, false)
            SetPlayerWantedLevelNow(PlayerId(), false)
        end
    end
end)

RegisterNUICallback('cq-admin:cb:everyoneIgnore', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:everyoneIgnore', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:everyoneIgnore', function(reqId, enabled)
    if not ValidateGrant(reqId, 'everyoneIgnore') then return end
    _everyoneIgnore = enabled and true or false
    SetEveryoneIgnorePlayer(PlayerId(), _everyoneIgnore)
    SetPoliceIgnorePlayer(PlayerId(), _everyoneIgnore)
    if notify then notify('info', ('Everyone Ignore: %s'):format(_everyoneIgnore and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:stayInVehicle', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:stayInVehicle', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:stayInVehicle', function(reqId, enabled)
    if not ValidateGrant(reqId, 'stayInVehicle') then return end
    _stayInVehicle = enabled and true or false
    if notify then notify('info', ('Stay In Vehicle: %s'):format(_stayInVehicle and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _stayInVehicle then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                SetPedCanBeDraggedOut(ped, false)
            end
        end
    end
end)

RegisterNUICallback('cq-admin:cb:freezePlayer', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:freezePlayer', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:freezePlayer', function(reqId, enabled)
    if not ValidateGrant(reqId, 'freezePlayer') then return end
    _freezePlayer = enabled and true or false
    FreezeEntityPosition(PlayerPedId(), _freezePlayer)
    if notify then notify('info', ('Freeze Player: %s'):format(_freezePlayer and 'ON' or 'OFF')) end
end)

RegisterNUICallback('cq-admin:cb:setWantedLevel', function(data, cb)
    local level = tonumber(data and (data.level or data.value)) or 0
    TriggerServerEvent('cq-admin:sv:setWantedLevel', level)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setWantedLevel', function(reqId, level)
    if not ValidateGrant(reqId, 'setWantedLevel') then return end
    local wantedLevel = math.max(0, math.min(tonumber(level) or 0, 5))
    SetPlayerWantedLevel(PlayerId(), wantedLevel, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    if notify then notify('success', ('Wanted level set to: %d'):format(wantedLevel)) end
end)

RegisterNUICallback('cq-admin:cb:cleanPlayer', function(_, cb)
    TriggerServerEvent('cq-admin:sv:cleanPlayer')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:cleanPlayer', function(reqId)
    if not ValidateGrant(reqId, 'cleanPlayer') then return end
    local ped = PlayerPedId()
    ClearPedBloodDamage(ped)
    ClearPedWetness(ped)
    ClearPedEnvDirt(ped)
    ResetPedVisibleDamage(ped)
    if notify then notify('success', 'Player cleaned') end
end)

RegisterNUICallback('cq-admin:cb:dryPlayer', function(_, cb)
    TriggerServerEvent('cq-admin:sv:dryPlayer')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:dryPlayer', function(reqId)
    if not ValidateGrant(reqId, 'dryPlayer') then return end
    ClearPedWetness(PlayerPedId())
    if notify then notify('success', 'Player dried') end
end)

RegisterNUICallback('cq-admin:cb:wetPlayer', function(_, cb)
    TriggerServerEvent('cq-admin:sv:wetPlayer')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:wetPlayer', function(reqId)
    if not ValidateGrant(reqId, 'wetPlayer') then return end
    SetPedWetnessHeight(PlayerPedId(), 2.0)
    if notify then notify('success', 'Player wetted') end
end)

RegisterNUICallback('cq-admin:cb:clearBlood', function(_, cb)
    TriggerServerEvent('cq-admin:sv:clearBlood')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:clearBlood', function(reqId)
    if not ValidateGrant(reqId, 'clearBlood') then return end
    ClearPedBloodDamage(PlayerPedId())
    if notify then notify('success', 'Blood cleared') end
end)

RegisterNUICallback('cq-admin:cb:suicide', function(_, cb)
    TriggerServerEvent('cq-admin:sv:suicide')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:suicide', function(reqId)
    if not ValidateGrant(reqId, 'suicide') then return end
    SetEntityHealth(PlayerPedId(), 0)
    if notify then notify('info', 'Suicide executed') end
end)


