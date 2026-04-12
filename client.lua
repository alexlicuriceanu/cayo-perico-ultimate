local cayo_perico_coords = vector3(4700.0, -5150.0, 0.0)    -- island center coordinates
local cayo_perico_radius = 1500.0   -- distance from the center of the island to the farthest point

local dummy_blip = nil      -- minimap bounds dummy blip handle
local dummy_blip_coords = vector3(5721.93, -6051.38, 0.0)   -- dummy blip coordinates (bottom right corner of the minimap)

local custom_water_loaded = false

local function enable_ipl_subset(ipl_subset, enable)
    for _, ipl in pairs(_cayo_ipls[ipl_subset]) do
        if enable then
            RequestIpl(ipl)
        else
            RemoveIpl(ipl)
        end
    end
end

-- function that loads the water file specified in the config
local function load_custom_water()
    local custom_water_name = config.custom_water_name
    local custom_water_resource_name = config.custom_water[custom_water_name].resource_name
    local custom_water_path = config.custom_water[custom_water_name].path
    local global_water_type = config.custom_water[custom_water_name].global_water_type
    local deep_ocean_scaler = config.custom_water[custom_water_name].deep_ocean_scaler

    LoadWaterFromPath(custom_water_resource_name, custom_water_path)
    LoadGlobalWaterType(global_water_type)
    SetDeepOceanScaler(deep_ocean_scaler)
end

local function load_ls_water()
    LoadGlobalWaterType(0)
    SetDeepOceanScaler(config.dynamic_waves and config.dynamic_waves_scaler or 0.0)
end

local function load_cayo_perico_water()
    LoadGlobalWaterType(1)
    SetDeepOceanScaler(0.0)
end

local function disable_emitters(_disable)
    SetStaticEmitterEnabled('se_dlc_aw_arena_construction_01', not _disable)
    SetStaticEmitterEnabled('se_dlc_aw_arena_crowd_background_main', not _disable)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_exterior_lobby', not _disable)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_interior_lobby', not _disable)
end

--[[
    Main thread
]]
Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    -- load cayo perico ipls
    enable_ipl_subset('main', true)
    enable_ipl_subset('shark', config.shark)
    enable_ipl_subset('whale', config.whale)
    enable_ipl_subset('sea_mines', config.sea_mines)
    enable_ipl_subset('gate_open', config.gate_open)
    enable_ipl_subset('gate_closed', config.gate_open == false)
    enable_ipl_subset('hangar_open', config.hangar_open)
    enable_ipl_subset('hangar_closed', config.hangar_open == false)
    enable_ipl_subset('drug_plants', config.drug_plants)


    -- misc natives
    if config.gps then
        SetAiGlobalPathNodesType(1)
    else
        SetAiGlobalPathNodesType(0)
    end

    SetZoneEnabled(GetZoneFromNameId("PrLog"), not config.disable_prologue_snow or false)
    SetScenarioGroupEnabled('Heist_Island_Peds', config.peds or true)

    -- audio stuff
    SetAudioFlag('PlayerOnDLCHeist4Island', config.disable_radio)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', config.ambient_zone or true, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', not config.ambient_zone or false, true)

    disable_emitters(config.disable_emitters)

    -- vault entity set
    local vault_interior_id = 280065

    if config.vault_entity_set then
        ActivateInteriorEntitySet(vault_interior_id, config.vault_entity_set)
        SetInteriorEntitySetColor(vault_interior_id, config.vault_entity_set, 1)
        RefreshInterior(vault_interior_id)
    else
        DeactivateInteriorEntitySet(vault_interior_id, 'pearl_necklace_set')
        DeactivateInteriorEntitySet(vault_interior_id, 'pink_diamond_set')
        DeactivateInteriorEntitySet(vault_interior_id, 'panther_set')
        RefreshInterior(vault_interior_id)
    end
end)


--[[
    Minimap thread
]]
Citizen.CreateThread(function()
    SetUseIslandMap(false)

    if config.minimap_type == 'off' then
       return
    end

    if config.minimap_type == 'compact' then
        SetUseIslandMap(true)
    end


    -- set dummy blip
    local blip_x, blip_y, blip_z = table.unpack(dummy_blip_coords)
    dummy_blip = AddBlipForCoord(blip_x, blip_y, blip_z)
    SetBlipAlpha(dummy_blip, 0)

    local hash = GetHashKey("h4_fake_islandx")
    local x, y, z = table.unpack(cayo_perico_coords)
    
    while true do
        SetRadarAsExteriorThisFrame()
        SetRadarAsInteriorThisFrame(hash, x, y, z, 0)
        Citizen.Wait(0)
    end
end)

--[[
    Water thread
]]
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(config.dynamic_actions_delay)

        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)

            local distance = #(coords - cayo_perico_coords)

            if distance > cayo_perico_radius then
                -- handle water
                if not custom_water_loaded then
                    if config.custom_water_name then
                        load_custom_water()
                    else
                        load_ls_water()
                    end

                    custom_water_loaded = true
                end

                -- handle path nodes
                if config.dynamic_path_nodes then
                    SetAiGlobalPathNodesType(0)
                end
            else
                -- handle water
                if custom_water_loaded then
                    load_cayo_perico_water()
                    custom_water_loaded = false
                end

                -- handle path nodes
                if config.dynamic_path_nodes then
                    SetAiGlobalPathNodesType(1)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
       return
    end

    SetUseIslandMap(false)

    if dummy_blip then
        RemoveBlip(dummy_blip)
    end

    _keys = get_keys(_cayo_ipls)

    for _, ipl_subset in pairs(_keys) do
        enable_ipl_subset(ipl_subset, false)
    end

    disable_emitters(false)
end)
