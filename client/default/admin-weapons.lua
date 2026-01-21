--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

-- luacheck: max_line_length 300
-- luacheck: globals CQAdmin
local ValidateGrant = (CQAdmin and CQAdmin._internal and CQAdmin._internal.validateGrant) or function() return false end
RegisterAdminCategory('weapons', {
    build = function()
        return {
            id = "weapons_mgmt",
            label = "Weapon Management",
            sub = "Manage weapons, ammo, and loadouts",
            enabled = true,
            groups = {
                {
                    id = "weapon_actions",
                    type = "group",
                    label = "Weapon actions",
                    children = {
                        { label = "Get all weapons", type = "button", buttonLabel = "Get All", callback = "cq-admin:cb:getAllWeapons" },
                        { label = "Remove all weapons", type = "button", buttonLabel = "Remove All", callback = "cq-admin:cb:removeAllWeapons" },
                        { label = "Spawn weapon by name", type = "inputButton", placeholder = "WEAPON_PISTOL", buttonLabel = "Spawn", callback = "cq-admin:cb:spawnWeaponByName", payloadKey = "weapon" },
                        { label = "Refill all ammo", type = "button", buttonLabel = "Refill", callback = "cq-admin:cb:refillAmmo" },
                        { label = "Set ammo count", type = "inputButton", placeholder = "250", buttonLabel = "Set", callback = "cq-admin:cb:setAmmo", payloadKey = "amount" },
                    }
                },
                {
                    id = "weapon_modes",
                    type = "group",
                    label = "Weapon modes",
                    children = {
                        { label = "Unlimited Ammo", type = "toggle", key = "unlimited_ammo_t", callback = "cq-admin:cb:unlimitedAmmo", default = false },
                        { label = "No Reload", type = "toggle", key = "no_reload_t", callback = "cq-admin:cb:noReload", default = false },
                    }
                },
                {
                    id = "parachute_options",
                    type = "group",
                    label = "Parachute options",
                    children = {
                        { label = "Give parachute", type = "button", buttonLabel = "Give", callback = "cq-admin:cb:giveParachute" },
                        { label = "Auto equip parachute in aircraft", type = "toggle", key = "auto_parachute_t", callback = "cq-admin:cb:autoParachute", default = false },
                    }
                }
            }
        }
    end
})

local U = CQ and CQ.Util or {}
local function pedId()
    return (U and U.ped and U.ped()) or PlayerPedId()
end

RegisterNUICallback('cq-admin:cb:getAllWeapons', function(_, cb)
    TriggerServerEvent('cq-admin:sv:getAllWeapons')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:getAllWeapons', function(reqId)
    if not ValidateGrant(reqId, 'getAllWeapons') then return end
    local ped = pedId()

    local weapons = {
        'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL', 'WEAPON_PISTOL50',
        'WEAPON_SNSPISTOL', 'WEAPON_HEAVYPISTOL', 'WEAPON_VINTAGEPISTOL', 'WEAPON_MARKSMANPISTOL',
        'WEAPON_REVOLVER', 'WEAPON_DOUBLEACTION',

        'WEAPON_MICROSMG', 'WEAPON_SMG', 'WEAPON_ASSAULTSMG', 'WEAPON_COMBATPDW',
        'WEAPON_MACHINEPISTOL', 'WEAPON_MINISMG',

        'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
        'WEAPON_BULLPUPSHOTGUN', 'WEAPON_HEAVYSHOTGUN', 'WEAPON_DBSHOTGUN', 'WEAPON_AUTOSHOTGUN',

        'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_ADVANCEDRIFLE',
        'WEAPON_SPECIALCARBINE', 'WEAPON_BULLPUPRIFLE', 'WEAPON_COMPACTRIFLE',

        'WEAPON_MG', 'WEAPON_COMBATMG', 'WEAPON_GUSENBERG',

        'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER', 'WEAPON_MARKSMANRIFLE',

        'WEAPON_RPG', 'WEAPON_GRENADELAUNCHER', 'WEAPON_MINIGUN', 'WEAPON_FIREWORK',
        'WEAPON_RAILGUN', 'WEAPON_HOMINGLAUNCHER', 'WEAPON_COMPACTLAUNCHER',

        'WEAPON_GRENADE', 'WEAPON_STICKYBOMB', 'WEAPON_PROXMINE', 'WEAPON_BZGAS',
        'WEAPON_MOLOTOV', 'WEAPON_FLARE', 'WEAPON_BALL', 'WEAPON_SNOWBALL',

        'WEAPON_KNIFE', 'WEAPON_NIGHTSTICK', 'WEAPON_HAMMER', 'WEAPON_BAT',
        'WEAPON_GOLFCLUB', 'WEAPON_CROWBAR', 'WEAPON_BOTTLE', 'WEAPON_DAGGER',
        'WEAPON_HATCHET', 'WEAPON_KNUCKLE', 'WEAPON_MACHETE', 'WEAPON_SWITCHBLADE',
        'WEAPON_BATTLEAXE', 'WEAPON_POOLCUE', 'WEAPON_WRENCH', 'WEAPON_FLASHLIGHT',
    }

    for _, weapon in ipairs(weapons) do
        local hash = GetHashKey(weapon)
        GiveWeaponToPed(ped, hash, 9999, false, false)
    end

    if notify then notify('success', 'All weapons given') end
end)

RegisterNUICallback('cq-admin:cb:removeAllWeapons', function(_, cb)
    TriggerServerEvent('cq-admin:sv:removeAllWeapons')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:removeAllWeapons', function(reqId)
    if not ValidateGrant(reqId, 'removeAllWeapons') then return end
    RemoveAllPedWeapons(pedId(), true)
    if notify then notify('success', 'All weapons removed') end
end)

RegisterNUICallback('cq-admin:cb:spawnWeaponByName', function(data, cb)
    local weapon = data and (data.weapon or data.value) or nil
    TriggerServerEvent('cq-admin:sv:spawnWeaponByName', weapon)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:spawnWeaponByName', function(reqId, weapon)
    if not ValidateGrant(reqId, 'spawnWeaponByName') then return end
    local ped = pedId()
    if not weapon or weapon == '' then return (notify and notify('error', 'Invalid weapon name')) end

    local weaponName = weapon
    if not weaponName:find('WEAPON_', 1, true) then
        weaponName = ('WEAPON_%s'):format(weaponName:upper())
    end

    local hash = GetHashKey(weaponName)
    GiveWeaponToPed(ped, hash, 500, false, true)
    if notify then notify('success', ('Gave weapon: %s'):format(weaponName)) end
end)

RegisterNUICallback('cq-admin:cb:refillAmmo', function(_, cb)
    TriggerServerEvent('cq-admin:sv:refillAmmo')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:refillAmmo', function(reqId)
    if not ValidateGrant(reqId, 'refillAmmo') then return end
    local ped = pedId()

    for i = 0, 50 do
        local wep = GetHashKey(GetWeapontypeModel(i))
        if HasPedGotWeapon(ped, wep, false) then
            SetPedAmmo(ped, wep, 9999)
        end
    end

    if notify then notify('success', 'All ammo refilled') end
end)

RegisterNUICallback('cq-admin:cb:setAmmo', function(data, cb)
    local amount = tonumber(data and (data.amount or data.value)) or 250
    TriggerServerEvent('cq-admin:sv:setAmmo', amount)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setAmmo', function(reqId, amount)
    if not ValidateGrant(reqId, 'setAmmo') then return end
    local ped = PlayerPedId()
    local ammoCount = tonumber(amount) or 250

    for i = 0, 50 do
        local wep = GetHashKey(GetWeapontypeModel(i))
        if HasPedGotWeapon(ped, wep, false) then
            SetPedAmmo(ped, wep, ammoCount)
        end
    end

    if notify then notify('success', ('Ammo set to: %d'):format(ammoCount)) end
end)

local _unlimitedAmmo = false
local _noReload = false

RegisterNUICallback('cq-admin:cb:unlimitedAmmo', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:unlimitedAmmo', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:unlimitedAmmo', function(reqId, enabled)
    if not ValidateGrant(reqId, 'unlimitedAmmo') then return end
    _unlimitedAmmo = enabled and true or false
    if notify then notify('info', ('Unlimited Ammo: %s'):format(_unlimitedAmmo and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _unlimitedAmmo then
            SetPedInfiniteAmmoClip(pedId(), true)
        end
    end
end)

RegisterNUICallback('cq-admin:cb:noReload', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:noReload', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:noReload', function(reqId, enabled)
    if not ValidateGrant(reqId, 'noReload') then return end
    _noReload = enabled and true or false
    if notify then notify('info', ('No Reload: %s'):format(_noReload and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _noReload then
            local ped = pedId()
            if IsPedShooting(ped) then
                local _, currentWeapon = GetCurrentPedWeapon(ped, true)
                local maxAmmo = GetMaxAmmo(ped, currentWeapon)
                SetPedAmmo(ped, currentWeapon, maxAmmo)
            end
        end
    end
end)

RegisterNUICallback('cq-admin:cb:giveParachute', function(_, cb)
    TriggerServerEvent('cq-admin:sv:giveParachute')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:giveParachute', function(reqId)
    if not ValidateGrant(reqId, 'giveParachute') then return end
    GiveWeaponToPed(pedId(), GetHashKey('GADGET_PARACHUTE'), 1, false, false)
    if notify then notify('success', 'Parachute given') end
end)

local _autoParachute = false

RegisterNUICallback('cq-admin:cb:autoParachute', function(data, cb)
    local enabled = data and data.value and true or false
    TriggerServerEvent('cq-admin:sv:autoParachute', enabled)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:autoParachute', function(reqId, enabled)
    if not ValidateGrant(reqId, 'autoParachute') then return end
    _autoParachute = enabled and true or false
    if notify then notify('info', ('Auto Parachute: %s'):format(_autoParachute and 'ON' or 'OFF')) end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if _autoParachute then
            local ped = pedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                local vehClass = GetVehicleClass(veh)
                if vehClass == 15 or vehClass == 16 then
                    if not HasPedGotWeapon(ped, GetHashKey('GADGET_PARACHUTE'), false) then
                        GiveWeaponToPed(ped, GetHashKey('GADGET_PARACHUTE'), 1, false, false)
                    end
                end
            end
        end
    end
end)


