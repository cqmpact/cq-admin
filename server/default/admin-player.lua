--[[
SPDX-License-Identifier: MPL-2.0
Author: cqmpact <https://github.com/cqmpact>

Contributors
| Name    | Profile                     | Notes  |
|-------- |-----------------------------|--------|
| cqmpact | https://github.com/cqmpact  | Author |
|         |                             |        |
]]

RegisterNetEvent('cq-admin:sv:healSelf', function()
    local src = source
    local group = GROUPS.healSelf
    if not hasGroup(src, group) then return deny(src, 'healSelf', group) end
    issueGrant(src, 'healSelf', 'cq-admin:cl:healSelf')
end)

RegisterNetEvent('cq-admin:sv:giveArmor', function(amount)
    local src = source
    local group = GROUPS.giveArmor
    if not hasGroup(src, group) then return deny(src, 'giveArmor', group) end
    local n = tonumber(amount) or 100
    if n < 0 then n = 0 end
    if n > 100 then n = 100 end
    issueGrant(src, 'giveArmor', 'cq-admin:cl:giveArmor', n)
end)

RegisterNetEvent('cq-admin:sv:revive', function()
    local src = source
    local group = GROUPS.revive
    if not hasGroup(src, group) then return deny(src, 'revive', group) end
    issueGrant(src, 'revive', 'cq-admin:cl:revive')
end)

RegisterNetEvent('cq-admin:sv:teleportToWaypoint', function()
    local src = source
    local group = GROUPS.teleport
    if not hasGroup(src, group) then return deny(src, 'teleportToWaypoint', group) end
    issueGrant(src, 'teleportToWaypoint', 'cq-admin:cl:teleportToWaypoint')
end)

RegisterNetEvent('cq-admin:sv:giveWeapon', function(weapon, ammo)
    local src = source
    local group = GROUPS.giveWeapon
    if not hasGroup(src, group) then return deny(src, 'giveWeapon', group) end
    if type(weapon) ~= 'string' or weapon == '' then
        return notify(src, 'error', 'Invalid weapon', false)
    end
    local weap = weapon
    if not weap:find('WEAPON_', 1, true) then
        weap = ('WEAPON_%s'):format(weap:upper())
    end
    if not weap:match('^WEAPON_[A-Z0-9_]+$') then
        return notify(src, 'error', 'Invalid weapon', false)
    end
    local nAmmo = tonumber(ammo) or 250
    if nAmmo < 0 then nAmmo = 0 end
    if nAmmo > 9999 then nAmmo = 9999 end
    issueGrant(src, 'giveWeapon', 'cq-admin:cl:giveWeapon', weap, nAmmo)
end)

local _NC_STATE = {}

RegisterNetEvent('cq-admin:sv:noclip', function(enabled)
    local src = source
    local group = GROUPS.noclip
    if not hasGroup(src, group) then return deny(src, 'noclip', group) end
    local en = enabled and true or false
    _NC_STATE[src] = en
    issueGrant(src, 'noclip', 'cq-admin:cl:noclip', en)
end)

RegisterNetEvent('cq-admin:sv:noclip:toggle', function()
    local src = source
    local group = GROUPS.noclip
    if not hasGroup(src, group) then return deny(src, 'noclip', group) end
    local newState = (_NC_STATE[src] ~= true)
    _NC_STATE[src] = newState
    issueGrant(src, 'noclip', 'cq-admin:cl:noclip', newState)
end)

AddEventHandler('playerDropped', function()
    local src = source
    _NC_STATE[src] = nil
end)

RegisterNetEvent('cq-admin:sv:godMode', function(enabled)
    local src = source
    local group = GROUPS.godMode
    if not hasGroup(src, group) then return deny(src, 'godMode', group) end
    issueGrant(src, 'godMode', 'cq-admin:cl:godMode', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:invisible', function(enabled)
    local src = source
    local group = GROUPS.invisible
    if not hasGroup(src, group) then return deny(src, 'invisible', group) end
    issueGrant(src, 'invisible', 'cq-admin:cl:invisible', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:unlimitedStamina', function(enabled)
    local src = source
    local group = GROUPS.unlimitedStamina
    if not hasGroup(src, group) then return deny(src, 'unlimitedStamina', group) end
    issueGrant(src, 'unlimitedStamina', 'cq-admin:cl:unlimitedStamina', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:fastRun', function(enabled)
    local src = source
    local group = GROUPS.fastRun
    if not hasGroup(src, group) then return deny(src, 'fastRun', group) end
    issueGrant(src, 'fastRun', 'cq-admin:cl:fastRun', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:fastSwim', function(enabled)
    local src = source
    local group = GROUPS.fastSwim
    if not hasGroup(src, group) then return deny(src, 'fastSwim', group) end
    issueGrant(src, 'fastSwim', 'cq-admin:cl:fastSwim', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:superJump', function(enabled)
    local src = source
    local group = GROUPS.superJump
    if not hasGroup(src, group) then return deny(src, 'superJump', group) end
    issueGrant(src, 'superJump', 'cq-admin:cl:superJump', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:noRagdoll', function(enabled)
    local src = source
    local group = GROUPS.noRagdoll
    if not hasGroup(src, group) then return deny(src, 'noRagdoll', group) end
    issueGrant(src, 'noRagdoll', 'cq-admin:cl:noRagdoll', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:neverWanted', function(enabled)
    local src = source
    local group = GROUPS.neverWanted
    if not hasGroup(src, group) then return deny(src, 'neverWanted', group) end
    issueGrant(src, 'neverWanted', 'cq-admin:cl:neverWanted', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:everyoneIgnore', function(enabled)
    local src = source
    local group = GROUPS.everyoneIgnore
    if not hasGroup(src, group) then return deny(src, 'everyoneIgnore', group) end
    issueGrant(src, 'everyoneIgnore', 'cq-admin:cl:everyoneIgnore', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:stayInVehicle', function(enabled)
    local src = source
    local group = GROUPS.stayInVehicle
    if not hasGroup(src, group) then return deny(src, 'stayInVehicle', group) end
    issueGrant(src, 'stayInVehicle', 'cq-admin:cl:stayInVehicle', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:freezePlayer', function(enabled)
    local src = source
    local group = GROUPS.freezePlayer
    if not hasGroup(src, group) then return deny(src, 'freezePlayer', group) end
    issueGrant(src, 'freezePlayer', 'cq-admin:cl:freezePlayer', enabled and true or false)
end)

RegisterNetEvent('cq-admin:sv:setWantedLevel', function(level)
    local src = source
    local group = GROUPS.setWantedLevel
    if not hasGroup(src, group) then return deny(src, 'setWantedLevel', group) end
    local n = tonumber(level) or 0
    if n < 0 then n = 0 end
    if n > 5 then n = 5 end
    issueGrant(src, 'setWantedLevel', 'cq-admin:cl:setWantedLevel', n)
end)

RegisterNetEvent('cq-admin:sv:cleanPlayer', function()
    local src = source
    local group = GROUPS.cleanPlayer
    if not hasGroup(src, group) then return deny(src, 'cleanPlayer', group) end
    issueGrant(src, 'cleanPlayer', 'cq-admin:cl:cleanPlayer')
end)

RegisterNetEvent('cq-admin:sv:dryPlayer', function()
    local src = source
    local group = GROUPS.dryPlayer
    if not hasGroup(src, group) then return deny(src, 'dryPlayer', group) end
    issueGrant(src, 'dryPlayer', 'cq-admin:cl:dryPlayer')
end)

RegisterNetEvent('cq-admin:sv:wetPlayer', function()
    local src = source
    local group = GROUPS.wetPlayer
    if not hasGroup(src, group) then return deny(src, 'wetPlayer', group) end
    issueGrant(src, 'wetPlayer', 'cq-admin:cl:wetPlayer')
end)

RegisterNetEvent('cq-admin:sv:clearBlood', function()
    local src = source
    local group = GROUPS.clearBlood
    if not hasGroup(src, group) then return deny(src, 'clearBlood', group) end
    issueGrant(src, 'clearBlood', 'cq-admin:cl:clearBlood')
end)

RegisterNetEvent('cq-admin:sv:suicide', function()
    local src = source
    local group = GROUPS.suicide
    if not hasGroup(src, group) then return deny(src, 'suicide', group) end
    issueGrant(src, 'suicide', 'cq-admin:cl:suicide')
end)
