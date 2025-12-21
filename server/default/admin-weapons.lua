--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

RegisterNetEvent('cq-admin:sv:getAllWeapons', function()
    local src = source
    local group = GROUPS.getAllWeapons
    if not hasGroup(src, group) then return deny(src, 'getAllWeapons', group) end
    issueGrant(src, 'getAllWeapons', 'cq-admin:cl:getAllWeapons')
end)

RegisterNetEvent('cq-admin:sv:removeAllWeapons', function()
    local src = source
    local group = GROUPS.removeAllWeapons
    if not hasGroup(src, group) then return deny(src, 'removeAllWeapons', group) end
    issueGrant(src, 'removeAllWeapons', 'cq-admin:cl:removeAllWeapons')
end)

RegisterNetEvent('cq-admin:sv:spawnWeaponByName', function(weapon)
    local src = source
    local group = GROUPS.spawnWeaponByName
    if not hasGroup(src, group) then return deny(src, 'spawnWeaponByName', group) end
    if type(weapon) ~= 'string' or weapon == '' then
        return notify(src, 'error', 'Invalid weapon name', false)
    end
    local weap = weapon
    if not weap:find('WEAPON_', 1, true) then
        weap = ('WEAPON_%s'):format(weap:upper())
    end
    -- Basic server-side validation: ensure only WEAPON_* with safe charset
    if not weap:match('^WEAPON_[A-Z0-9_]+$') then
        return notify(src, 'error', 'Invalid weapon name', false)
    end
    issueGrant(src, 'spawnWeaponByName', 'cq-admin:cl:spawnWeaponByName', weap)
end)

RegisterNetEvent('cq-admin:sv:refillAmmo', function()
    local src = source
    local group = GROUPS.refillAmmo
    if not hasGroup(src, group) then return deny(src, 'refillAmmo', group) end
    issueGrant(src, 'refillAmmo', 'cq-admin:cl:refillAmmo')
end)

RegisterNetEvent('cq-admin:sv:setAmmo', function(amount)
    local src = source
    local group = GROUPS.setAmmo
    if not hasGroup(src, group) then return deny(src, 'setAmmo', group) end
    local n = tonumber(amount) or 250
    if n < 0 then n = 0 end
    if n > 9999 then n = 9999 end
    issueGrant(src, 'setAmmo', 'cq-admin:cl:setAmmo', n)
end)

RegisterNetEvent('cq-admin:sv:unlimitedAmmo', function(enabled)
    local src = source
    local group = GROUPS.unlimitedAmmo
    if not hasGroup(src, group) then return deny(src, 'unlimitedAmmo', group) end
    issueGrant(src, 'unlimitedAmmo', 'cq-admin:cl:unlimitedAmmo', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:noReload', function(enabled)
    local src = source
    local group = GROUPS.noReload
    if not hasGroup(src, group) then return deny(src, 'noReload', group) end
    issueGrant(src, 'noReload', 'cq-admin:cl:noReload', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:giveParachute', function()
    local src = source
    local group = GROUPS.giveParachute
    if not hasGroup(src, group) then return deny(src, 'giveParachute', group) end
    issueGrant(src, 'giveParachute', 'cq-admin:cl:giveParachute')
end)

RegisterNetEvent('cq-admin:sv:autoParachute', function(enabled)
    local src = source
    local group = GROUPS.autoParachute
    if not hasGroup(src, group) then return deny(src, 'autoParachute', group) end
    issueGrant(src, 'autoParachute', 'cq-admin:cl:autoParachute', enabled and true or false)
end)
