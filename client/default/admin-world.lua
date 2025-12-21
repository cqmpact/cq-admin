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
-- luacheck: globals _validateGrant

RegisterAdminCategory('world', {
    build = function()
        return {
            id = "world_mgmt",
            label = "World Management",
            sub = "Spawn objects, delete nearby entities",
            enabled = true,
            groups = {
                {
                    id = "world_spawn",
                    type = "group",
                    label = "Spawn & cleanup",
                    children = {
                        { label = "Spawn object (prop model)", type = "inputButton", placeholder = "prop_roadcone02a", buttonLabel = "Spawn", callback = "cq-admin:cb:spawnObject", payloadKey = "model" },
                        { label = "Delete nearby objects (radius m)", type = "inputButton", placeholder = "30", buttonLabel = "Delete", callback = "cq-admin:cb:deleteNearbyObjects", payloadKey = "radius" },
                        { label = "Delete nearby vehicles (radius m)", type = "inputButton", placeholder = "50", buttonLabel = "Delete", callback = "cq-admin:cb:deleteNearbyVehicles", payloadKey = "radius" },
                        { label = "Delete nearby peds (radius m)", type = "inputButton", placeholder = "30", buttonLabel = "Delete", callback = "cq-admin:cb:deleteNearbyPeds", payloadKey = "radius" },
                    }
                }
            }
        }
    end
})


RegisterNUICallback('cq-admin:cb:deleteNearbyObjects', function(data, cb)
    local radius = data and (data.radius or data.value) or 30
    TriggerServerEvent('cq-admin:sv:deleteNearby', 'objects', radius)
    cb({ ok = true })
end)


local function deleteEntitiesOfType(entType, radius)
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local count = 0
    radius = tonumber(radius) or 30.0
    if entType == 'vehicles' then
        local handle, veh = FindFirstVehicle(); local vehOk = true
        repeat
            if DoesEntityExist(veh) and #(GetEntityCoords(veh) - pCoords) <= radius then
                SetEntityAsMissionEntity(veh, true, true)
                DeleteEntity(veh)
                count = count + 1
            end
            vehOk, veh = FindNextVehicle(handle)
        until not vehOk
        EndFindVehicle(handle)
    elseif entType == 'peds' then
        local handle, p = FindFirstPed(); local pedOk = true
        repeat
            if DoesEntityExist(p) and p ~= ped and #(GetEntityCoords(p) - pCoords) <= radius then
                SetEntityAsMissionEntity(p, true, true)
                DeleteEntity(p)
                count = count + 1
            end
            pedOk, p = FindNextPed(handle)
        until not pedOk
        EndFindPed(handle)
    else
        local handle, obj = FindFirstObject(); local objOk = true
        repeat
            if DoesEntityExist(obj) and #(GetEntityCoords(obj) - pCoords) <= radius then
                SetEntityAsMissionEntity(obj, true, true)
                DeleteEntity(obj)
                count = count + 1
            end
            objOk, obj = FindNextObject(handle)
        until not objOk
        EndFindObject(handle)
    end
    return count
end

RegisterNetEvent('cq-admin:cl:deleteNearby', function(reqId, entType, radius)
    if not _validateGrant(reqId) then return end
    local cnt = deleteEntitiesOfType(entType, radius)
    if notify then notify('success', ('Deleted %d %s within %.0fm'):format(cnt, entType, tonumber(radius) or 0)) end
end)

RegisterNUICallback('cq-admin:cb:deleteNearbyVehicles', function(data, cb)
    local radius = data and (data.radius or data.value) or 50
    TriggerServerEvent('cq-admin:sv:deleteNearby', 'vehicles', radius)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:deleteNearbyPeds', function(data, cb)
    local radius = data and (data.radius or data.value) or 30
    TriggerServerEvent('cq-admin:sv:deleteNearby', 'peds', radius)
    cb({ ok = true })
end)
