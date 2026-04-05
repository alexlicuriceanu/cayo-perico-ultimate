local cayo_perico_coords = vector3(4700.0, -5150.0, 0.0)
local cayo_perico_radius = 1500.0

local dummy_blip = nil
local dummy_blip_coords = vector3(5721.93, -6051.38, 0.0)

local function enable_ipl_subset(ipl_subset, enable)
    for _, ipl in pairs(_cayo_ipls[ipl_subset]) do
        if enable then
            RequestIpl(ipl)
        else
            RemoveIpl(ipl)
        end
    end
end

Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
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


    -- handle loading custom water
    if config.custom_water_name and config.custom_water[config.custom_water_name] then
        local custom_water_name = config.custom_water_name
        local custom_water = config.custom_water[custom_water_name]
        
        LoadWaterFromPath(custom_water.resource_name, custom_water.path)
        LoadGlobalWaterType(custom_water.global_water_type)
        SetDeepOceanScaler(custom_water.deep_ocean_scaler)
    end
end)


Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
    end

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

Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
    end

    if not config.dynamic_path_nodes and not config.dynamic_waves then
        return
    end

    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        local distance = #(coords - cayo_perico_coords)

        if distance < cayo_perico_radius then
            if config.dynamic_path_nodes then
                SetAiGlobalPathNodesType(1)
            end

            if config.dynamic_waves then
                SetDeepOceanScaler(0.0)
            end

            LoadGlobalWaterType(1)
        else
            if config.dynamic_path_nodes then
                SetAiGlobalPathNodesType(0)
            end

            if config.dynamic_waves then
                SetDeepOceanScaler(config.dynamic_waves_scaler)
            end

            LoadGlobalWaterType(0)
        end

        Citizen.Wait(config.dynamic_actions_delay)
    end
end)


Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
    end

    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    SetStaticEmitterEnabled('se_dlc_aw_arena_construction_01', not config.disable_emitters)
    SetStaticEmitterEnabled('se_dlc_aw_arena_crowd_background_main', not config.disable_emitters)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_exterior_lobby', not config.disable_emitters)
    SetStaticEmitterEnabled('se_dlc_aw_crowd_interior_lobby', not config.disable_emitters)

end)
