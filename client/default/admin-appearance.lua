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
RegisterAdminCategory('appearance', {
    build = function()
        return {
            id = "appearance_mgmt",
            label = "Player Appearance",
            sub = "Change ped model and appearance",
            enabled = true,
            groups = {
                {
                    id = "ped_model",
                    type = "group",
                    label = "Ped model",
                    children = {
                        { label = "Spawn ped by name", type = "inputButton", placeholder = "a_m_y_hipster_01", buttonLabel = "Spawn", callback = "cq-admin:cb:spawnPedByName", payloadKey = "model" },
                        { label = "Reset to default ped", type = "button", buttonLabel = "Reset", callback = "cq-admin:cb:resetPed" },
                    }
                },
                {
                    id = "ped_presets",
                    type = "group",
                    label = "Quick presets",
                    children = {
                        {
                            label = "Select preset",
                            type = "dropdown",
                            key = "ped_preset",
                            callback = "cq-admin:cb:setPedPresetDropdown",
                            options = {
                                "Michael:player_zero",
                                "Franklin:player_one",
                                "Trevor:player_two",
                                "Police Officer:s_m_y_cop_01",
                                "Sheriff:s_m_y_sheriff_01",
                                "SWAT:s_m_y_swat_01",
                                "Firefighter:s_m_y_fireman_01",
                                "Paramedic:s_m_m_paramedic_01",
                                "Army:s_m_y_armymech_01",
                                "Business Man:a_m_y_business_01",
                                "Beach Male:a_m_y_beach_01",
                                "Beach Female:a_f_y_beach_01"
                            },
                            default = "Michael:player_zero"
                        },
                        { label = "Apply preset", type = "button", buttonLabel = "Apply", callback = "cq-admin:cb:applyPedPreset", stateKeys = {"ped_preset"} },
                    }
                },
                {
                    id = "ped_animals",
                    type = "group",
                    label = "Animals",
                    children = {
                        {
                            label = "Select animal",
                            type = "dropdown",
                            key = "ped_animal",
                            callback = "cq-admin:cb:setPedAnimalDropdown",
                            options = {
                                "Chimp:a_c_chimp",
                                "Chop (Dog):a_c_chop",
                                "Cat:a_c_cat_01",
                                "Cow:a_c_cow",
                                "Deer:a_c_deer",
                                "Retriever:a_c_retriever",
                                "Hen:a_c_hen",
                                "Mountain Lion:a_c_mtlion",
                                "Pig:a_c_pig",
                                "Rabbit:a_c_rabbit_01"
                            },
                            default = "Chimp:a_c_chimp"
                        },
                        { label = "Apply animal", type = "button", buttonLabel = "Apply", callback = "cq-admin:cb:applyPedAnimal", stateKeys = {"ped_animal"} },
                    }
                }
            }
        }
    end
})

local U = CQ and CQ.Util or {}
local loadModel = (U and U.loadModel) or function(modelOrHash, timeoutMs)
    local hash = modelOrHash
    if type(modelOrHash) == 'string' then
        hash = GetHashKey(modelOrHash)
    end
    RequestModel(hash)
    local waited, limit = 0, tonumber(timeoutMs) or 5000
    while not HasModelLoaded(hash) and waited < limit do
        Wait(10)
        waited = waited + 10
    end
    return HasModelLoaded(hash), hash
end

RegisterNUICallback('cq-admin:cb:spawnPedByName', function(data, cb)
    local model = data and (data.model or data.value) or nil
    TriggerServerEvent('cq-admin:sv:spawnPedByName', model)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:spawnPedByName', function(reqId, model)
    if not ValidateGrant(reqId, 'spawnPedByName') then return end
    if not model or model == '' then
        return (notify and notify('error', 'Invalid ped model'))
    end

    local ok, hash = loadModel(model, 5000)
    if not ok then
        return (notify and notify('error', ('Model failed to load: %s'):format(model)))
    end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    if notify then notify('success', ('Ped model set to: %s'):format(model)) end
end)

RegisterNUICallback('cq-admin:cb:resetPed', function(_, cb)
    TriggerServerEvent('cq-admin:sv:resetPed')
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:resetPed', function(reqId)
    if not ValidateGrant(reqId, 'resetPed') then return end
    local defaultModel = 'mp_m_freemode_01'
    local ok, hash = loadModel(defaultModel)
    if ok then
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
    else
        if notify then notify('error', ('Model failed to load: %s'):format(defaultModel)) end
    end

    if notify then notify('success', 'Ped reset to default') end
end)

RegisterNUICallback('cq-admin:cb:setPedPreset', function(data, cb)
    local ped = data and data.meta and data.meta.ped or nil
    TriggerServerEvent('cq-admin:sv:setPedPreset', ped)
    cb({ ok = true })
end)

local function extractModelFromPreset(preset)
    if not preset or preset == '' then return nil end
    local colonPos = string.find(preset, ':')
    if colonPos then
        return string.sub(preset, colonPos + 1)
    end
    return preset
end

RegisterNUICallback('cq-admin:cb:setPedPresetDropdown', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:applyPedPreset', function(data, cb)
    local preset = data and data.ped_preset or 'player_zero'
    local model = extractModelFromPreset(preset)
    TriggerServerEvent('cq-admin:sv:setPedPreset', model)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:setPedAnimalDropdown', function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback('cq-admin:cb:applyPedAnimal', function(data, cb)
    local preset = data and data.ped_animal or 'a_c_chimp'
    local model = extractModelFromPreset(preset)
    TriggerServerEvent('cq-admin:sv:setPedPreset', model)
    cb({ ok = true })
end)

RegisterNetEvent('cq-admin:cl:setPedPreset', function(reqId, model)
    if not ValidateGrant(reqId, 'setPedPreset') then return end
    if not model or model == '' then
        return (notify and notify('error', 'Invalid ped model'))
    end

    local ok, hash = loadModel(model, 5000)
    if not ok then
        return (notify and notify('error', ('Model failed to load: %s'):format(model)))
    end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)

    if notify then notify('success', ('Ped model set to: %s'):format(model)) end
end)


