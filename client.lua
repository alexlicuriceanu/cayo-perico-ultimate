local cayo_perico_coords = vector3(4700.0, -5150.0, 0.0)    -- island center coordinates
local cayo_perico_radius = 1500.0   -- distance from the center of the island to the farthest point

local dummy_blip = nil      -- minimap bounds dummy blip handle
local dummy_blip_coords = vector3(5721.93, -6051.38, 0.0)   -- dummy blip coordinates (bottom right corner of the minimap)

local global_ai_path_nodes = nil    -- to keep track of the current state of the global path nodes, since no "get" function exists for it

-- thread control variables
local minimap_thread_active = false
local misc_thread_active = false



-- loads the specified IPL subset if enable is true, otherwise unloads it
-- @param: ipl_subset string: the key of the IPL subset in the CAYO_IPLS table
-- @param: enable boolean: whether to load or unload the IPL subset
-- @return: nil
local function enable_ipl_subset(ipl_subset, enable)
    for _, ipl in pairs(CAYO_IPLS[ipl_subset]) do
        if enable then
            RequestIpl(ipl)
        else
            RemoveIpl(ipl)
        end
    end
end


-- loads the specified water type and wave scaler, and applies custom water file if specified
-- @param: water_type integer: the water type to load, corresponds to the water types in the game files
-- @param: waves_scaler float: the wave scaler to set, where 1.0 is the default wave intensity
-- @param [optional]: resource_name string: the name of the resource containing the custom water file
-- @param [optional]: water_path string: the path to the custom water file within the resource, including the file extension
-- @return: nil
local function load_water(water_type, waves_scaler, resource_name, water_path)
    LoadGlobalWaterType(water_type)
    SetDeepOceanScaler(waves_scaler * 1.0)

    if resource_name and water_path then
        LoadWaterFromPath(resource_name, water_path)
    end
end


-- enable or disable arena wars emitters based on the provided boolean value
-- @param: enable boolean: true to enable emitters, false to disable emitters
-- @return: nil
local function enable_emitters(enable)
    SetStaticEmitterEnabled('se_dlc_aw_arena_construction_01', enable)
    SetStaticEmitterEnabled('se_dlc_aw_arena_crowd_background_main', enable)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_exterior_lobby', enable)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_interior_lobby', enable)
end


-- enable or disable the specified vault interior entity set, or disable if entity_set is nil
-- @param: entity_set string: the name of the entity set to enable
-- @return: nil
local function enable_vault_interior(entity_set)
    local vault_interior_id = 280065

    if entity_set then
        ActivateInteriorEntitySet(vault_interior_id, entity_set)
        SetInteriorEntitySetColor(vault_interior_id, entity_set, 1)
        RefreshInterior(vault_interior_id)
    else
        DeactivateInteriorEntitySet(vault_interior_id, 'pearl_necklace_set')
        DeactivateInteriorEntitySet(vault_interior_id, 'pink_diamond_set')
        DeactivateInteriorEntitySet(vault_interior_id, 'panther_set')
        RefreshInterior(vault_interior_id)
    end
end

-- enables Cayo Perico IPLs, peds, and other misc stuff
-- @param: enable boolean: true to enable Cayo Perico, false to disable Cayo Perico
-- @return: nil
local function enable_cayo_perico(enable)
    -- IPLs
    enable_ipl_subset('main', enable)

    enable_ipl_subset('shark', enable and config.shark)
    enable_ipl_subset('whale', enable and config.whale)
    enable_ipl_subset('sea_mines', enable and config.sea_mines)
    enable_ipl_subset('drug_plants', enable and config.drug_plants)

    enable_ipl_subset('gate_open', enable and config.gate_open)
    enable_ipl_subset('gate_closed', enable and not config.gate_open)

    enable_ipl_subset('hangar_open', enable and config.hangar_open)
    enable_ipl_subset('hangar_closed', enable and not config.hangar_open)

    -- snow from North Yankton
    SetZoneEnabled(GetZoneFromNameId("PrLog"), not enable or not config.disable_prologue_snow)

    -- peds on the island
    SetScenarioGroupEnabled('Heist_Island_Peds', enable and config.peds)

    -- car radio
    SetAudioFlag('PlayerOnDLCHeist4Island', enable and config.disable_radio)

    -- ambient zones
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', enable and config.ambient_zone, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', not enable or not config.ambient_zone, true)

    -- emitters
    enable_emitters(enable and not config.disable_emitters)

    -- vault interior
    enable_vault_interior(enable and config.vault_entity_set or nil)
end

-- enables/disables the Cayo Perico minimap based on the config settings
-- @param enable boolean: true to enable Cayo Perico minimap, false to disable Cayo Perico minimap
-- @return nil
local function enable_cayo_perico_minimap(enable)
    -- signal any minimap threads to stop
    minimap_thread_active = false

    -- reset minimap to default state
    SetUseIslandMap(false)
    
    -- remove the dummy blip if it exists
    if dummy_blip then
        RemoveBlip(dummy_blip)
        dummy_blip = nil
    end

    -- early exit if toggle boolean is disabled
    if not enable then
        return
    end

    -- no minimap
    if config.minimap_type == 'off' then
        return
    end

    -- compact minimap; GTAO Cayo Perico minimap
    if config.minimap_type == 'compact' then
        SetUseIslandMap(true)
        return
    end

    -- create a dummy blip to extend the minimap bounds to include the entire island
    local blip_x, blip_y, blip_z = table.unpack(dummy_blip_coords)
    dummy_blip = AddBlipForCoord(blip_x, blip_y, blip_z)
    
    -- make blip invisible
    SetBlipAlpha(dummy_blip, 0)

    -- signal the thread to start
    minimap_thread_active = true

    Citizen.CreateThread(function()
        local hash = GetHashKey("h4_fake_islandx")
        local x, y, z = table.unpack(cayo_perico_coords)
        
        while minimap_thread_active do
            SetRadarAsExteriorThisFrame()
            SetRadarAsInteriorThisFrame(hash, x, y, z, 0)
            Citizen.Wait(0)
        end
    end)
end

-- enables/disables various misc features on Cayo Perico based on the config settings, such as dynamic path nodes, dynamic water, and dynamic waves
-- @param enable boolean: true to enable Cayo Perico misc features, false to disable Cayo Perico misc features
-- @return nil
local function enable_cayo_perico_misc(enable)
    -- signal any misc thread to stop
    misc_thread_active = false
    
    -- reset path nodes to default state
    if global_ai_path_nodes ~= 0 then
        SetAiGlobalPathNodesType(0)
        global_ai_path_nodes = 0
    end

    -- reset water to default state
    if GetGlobalWaterType() == 1 then
        load_water(0, config.dynamic_waves_scaler, nil, nil)
    end

    -- reset waves scaler to default state
    if GetDeepOceanScaler() ~= config.dynamic_waves_scaler then
        SetDeepOceanScaler(config.dynamic_waves_scaler * 1.0)
    end

    -- turning off, exit early
    if not enable then
        return
    end

    -- optimization: early exit if all dynamic features are disabled in the config
    if not config.dynamic_path_nodes and not config.dynamic_water and not config.dynamic_waves then
        return
    end

    -- signal the thread to start
    misc_thread_active = true

    Citizen.CreateThread(function()
        while not NetworkIsSessionStarted() do
            Citizen.Wait(0)
        end

        while misc_thread_active do
            local ped = PlayerPedId()

            if DoesEntityExist(ped) and not IsEntityDead(ped) then
                local coords = GetEntityCoords(ped)
                local distance = #(coords - cayo_perico_coords)

                -- in Los Santos 
                if distance > cayo_perico_radius then
                    -- handle water
                    if config.dynamic_water and GetGlobalWaterType() == 1 then
                        load_water(0, config.dynamic_waves_scaler, nil, nil)
                    end

                    -- handle path nodes
                    if config.dynamic_path_nodes and global_ai_path_nodes ~= 0 then
                        SetAiGlobalPathNodesType(0)
                        global_ai_path_nodes = 0
                    end

                    -- handle waves scaler
                    if config.dynamic_waves and GetDeepOceanScaler() ~= config.dynamic_waves_scaler then
                        SetDeepOceanScaler(config.dynamic_waves_scaler * 1.0)
                    end

                -- in Cayo Perico
                else
                    -- handle water
                    if config.dynamic_water and GetGlobalWaterType() == 0 then
                        load_water(1, 0.0, nil, nil)
                    end

                    -- handle path nodes
                    if config.dynamic_path_nodes and global_ai_path_nodes ~= 1 then
                        SetAiGlobalPathNodesType(1)
                        global_ai_path_nodes = 1
                    end

                    -- handle waves scaler
                    if config.dynamic_waves and GetDeepOceanScaler() ~= 0.0 then
                        SetDeepOceanScaler(0.0)
                    end
                end
            end
            
            Citizen.Wait(config.dynamic_actions_delay)
        end
    end)
end

-- driver thread
Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    enable_cayo_perico(true)
    enable_cayo_perico_minimap(true)
    enable_cayo_perico_misc(true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
       return
    end

    enable_cayo_perico(false)
    enable_cayo_perico_minimap(false)
    enable_cayo_perico_misc(false)
end)

-- exports
exports("enable_cayo_perico", enable_cayo_perico)
exports("enable_cayo_perico_minimap", enable_cayo_perico_minimap)
exports("enable_cayo_perico_misc", enable_cayo_perico_misc)
