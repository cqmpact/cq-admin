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
debugState = debugState or {
    coords = false,
    ids = false,
    bbox = false,
    radius = 50.0,
    _thread = false,
    _outlined = nil
}

local function startDebugThread()
    if debugState._thread then return end
    debugState._thread = true

    CreateThread(function()
        while debugState._thread do
            Wait(0)

            local ped = PlayerPedId()
            local pCoords = GetEntityCoords(ped)

            local function drawText3D(x, y, z, text, scale)
                local onScreen, _x, _y = World3dToScreen2d(x, y, z)
                if onScreen then
                    SetTextFont(0)
                    SetTextProportional(0)
                    SetTextScale(scale or 0.28, scale or 0.28)
                    SetTextColour(255, 255, 255, 200)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(1, 0, 0, 0, 255)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString(text)
                    DrawText(_x, _y)
                end
            end

            if debugState.coords then
                local vel = GetEntitySpeed(ped) * 3.6
                local txt = ("x: %.2f y: %.2f z: %.2f | heading: %.1f | speed: %.1f km/h")
                    :format(pCoords.x, pCoords.y, pCoords.z, GetEntityHeading(ped), vel)

                SetTextFont(0)
                SetTextProportional(0)
                SetTextScale(0.35, 0.35)
                SetTextColour(255, 255, 255, 200)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextDropShadow()
                SetTextOutline()
                SetTextEntry("STRING")
                AddTextComponentString(txt)
                DrawText(0.35, 0.02)
            end

            if debugState.ids or debugState.bbox then
                local seenOutlined = {}
                local outlineVisible = {}

                local handle, veh = FindFirstVehicle()
                local okVeh = true
                repeat
                    if DoesEntityExist(veh) then
                        local vCoords = GetEntityCoords(veh)
                        if #(vCoords - pCoords) <= debugState.radius then
                            if debugState.ids then
                                DrawMarker(2, vCoords.x, vCoords.y, vCoords.z + 1.2, 0,0,0, 0,0,0, 0.2,0.2,0.2, 86,145,235,150, false, true, 2, nil, nil, false)
                                local model = GetEntityModel(veh)
                                local name = GetDisplayNameFromVehicleModel(model)
                                local label = name and name ~= "CARNOTFOUND" and name or ("0x%X"):format(model)
                                local dist = #(vCoords - pCoords)
                                drawText3D(vCoords.x, vCoords.y, vCoords.z + 1.45, ("Vehicle #%d\nModel: %s\n%.1fm"):format(veh, label, dist), 0.30)
                            end

                            if debugState.bbox then
                                outlineVisible[#outlineVisible + 1] = veh
                                seenOutlined[veh] = true
                            end
                        end
                    end
                    okVeh, veh = FindNextVehicle(handle)
                until not okVeh
                EndFindVehicle(handle)

                local h2, obj = FindFirstObject()
                local okObj = true
                repeat
                    if DoesEntityExist(obj) then
                        local oCoords = GetEntityCoords(obj)
                        if #(oCoords - pCoords) <= debugState.radius then
                            if debugState.ids then
                                DrawMarker(2, oCoords.x, oCoords.y, oCoords.z + 1.0, 0,0,0, 0,0,0, 0.15,0.15,0.15, 200,200,200,140, false, true, 2, nil, nil, false)
                                local model = GetEntityModel(obj)
                                local dist = #(oCoords - pCoords)
                                drawText3D(
                                    oCoords.x, oCoords.y, oCoords.z + 1.15,
                                    ("Object: #%d\nModel: 0x%X\n%.1fm"):format(obj, model, dist),
                                    0.28
                                )
                            end

                            if debugState.bbox then
                                outlineVisible[#outlineVisible + 1] = obj
                                seenOutlined[obj] = true
                            end
                        end
                    end
                    okObj, obj = FindNextObject(h2)
                until not okObj
                EndFindObject(h2)

                if debugState.bbox then
                    SetEntityDrawOutlineColor(80, 255, 100, 200)
                    for i = 1, #outlineVisible do
                        SetEntityDrawOutline(outlineVisible[i], true)
                    end
                end

                local hPed, p = FindFirstPed()
                local okPed = true
                repeat
                    if DoesEntityExist(p) and p ~= ped then
                        local c = GetEntityCoords(p)
                        if #(c - pCoords) <= debugState.radius then
                            if debugState.ids then
                                DrawMarker(2, c.x, c.y, c.z + 1.0, 0,0,0, 0,0,0, 0.12,0.12,0.12, 235,120,120,150, false, true, 2, nil, nil, false)
                                local model = GetEntityModel(p)
                                local dist = #(c - pCoords)
                                drawText3D(c.x, c.y, c.z + 1.18, ("Ped #%d\n0x%X\n%.1fm"):format(p, model, dist), 0.28)
                            end
                        end
                    end
                    okPed, p = FindNextPed(hPed)
                until not okPed
                EndFindPed(hPed)

                if not debugState.bbox then
                    if debugState._outlined then
                        for ent, _ in pairs(debugState._outlined) do
                            if DoesEntityExist(ent) then
                                SetEntityDrawOutline(ent, false)
                            end
                        end
                    end
                    debugState._outlined = nil
                else
                    if not debugState._outlined then debugState._outlined = {} end

                    for ent, _ in pairs(debugState._outlined) do
                        if (not seenOutlined[ent]) then
                            if DoesEntityExist(ent) then
                                SetEntityDrawOutline(ent, false)
                            end
                            debugState._outlined[ent] = nil
                        end
                    end

                    for ent, _ in pairs(seenOutlined) do
                        debugState._outlined[ent] = true
                    end
                end
            end
        end

        if debugState._outlined then
            for ent, _ in pairs(debugState._outlined) do
                if DoesEntityExist(ent) then
                    SetEntityDrawOutline(ent, false)
                end
            end
            debugState._outlined = nil
        end
    end)
end

RegisterNetEvent('cq-admin:cl:debugToggle', function(reqId, kind, enabled, radius)
    if not ValidateGrant(reqId, 'debugToggle') then return end
    if kind == 'coords' then debugState.coords = enabled
    elseif kind == 'ids' then debugState.ids = enabled
    elseif kind == 'bbox' then debugState.bbox = enabled
    end
    if radius then debugState.radius = radius end
    if (debugState.coords or debugState.ids or debugState.bbox) then
        startDebugThread()
    else
        debugState._thread = nil
    end
    if kind == 'bbox' and not enabled and debugState._outlined then
        for ent, _ in pairs(debugState._outlined) do
            if DoesEntityExist(ent) then SetEntityDrawOutline(ent, false) end
        end
        debugState._outlined = nil
    end
end)

RegisterAdminCategory('debug', {
    build = function()
        return {
            id = "debug_tools",
            label = "Debug",
            sub = "Draw debug overlays",
            enabled = true,
            groups = {
                {
                    id = "debug_draw",
                    type = "group",
                    label = "Draw overlays",
                    children = {
                        { label = "Show coords/heading/speed", type = "toggle", key = "dbg_coords", callback = "cq-admin:cb:debugToggle", default = false, meta = { kind = "coords" } },
                        { label = "Show nearby entity IDs & hashes", type = "toggle", key = "dbg_ids", callback = "cq-admin:cb:debugToggle", default = false, meta = { kind = "ids" } },
                        { label = "Show entity bounding boxes", type = "toggle", key = "dbg_bbox", callback = "cq-admin:cb:debugToggle", default = false, meta = { kind = "bbox" } },
                        { label = "Debug radius (m)", type = "slider", key = "dbg_radius", min = 5, max = 200, step = 5, default = CQAdmin_GetDebugRadius() or 50, callback = "cq-admin:cb:debugRadius" },
                    }
                }
            }
        }
    end
})

RegisterNUICallback('cq-admin:cb:debugToggle', function(data, cb)
    local kind = nil
    if type(data) == 'table' then
        kind = data.kind or (data.meta and data.meta.kind) or nil
    end
    local enabled = false
    if type(data) == 'table' then
        if data.value ~= nil then enabled = data.value and true or false end
        if data.enabled ~= nil then enabled = data.enabled and true or false end
    end
    if not kind or kind == '' then
        if notify then notify('error', 'Debug toggle missing kind') end
        cb({ ok = false, message = 'missing kind' })
        return
    end
    TriggerServerEvent('cq-admin:sv:debugToggle', kind, enabled, CQAdmin_GetDebugRadius())
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:debugRadius', function(data, cb)
    local r = tonumber(data and (data.value or data.radius)) or 50
    CQAdmin_SetDebugRadius(r)
    TriggerServerEvent('cq-admin:sv:debugToggle', 'radius', true, r)
    cb({ ok = true })
end)


