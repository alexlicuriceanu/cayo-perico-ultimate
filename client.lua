local cayo_perico_coords = vector3(4700.0, -5150.0, 0.0)    -- island center coordinates
local cayo_perico_radius = 1500.0   -- distance from the center of the island to the farthest point

local dummy_blip = nil      -- minimap bounds dummy blip handle
local dummy_blip_coords = vector3(5721.93, -6051.38, 0.0)   -- dummy blip coordinates (bottom right corner of the minimap)

local global_ai_path_nodes = nil    -- to keep track of the current state of the global path nodes, since no "get" function exists for it

-- loads the specified IPL subset if enable is true, otherwise unloads it
-- @param: ipl_subset string: the key of the IPL subset in the _cayo_ipls table
-- @param: enable boolean: whether to load or unload the IPL subset
-- @return: nil
local function enable_ipl_subset(ipl_subset, enable)
    for _, ipl in pairs(_cayo_ipls[ipl_subset]) do
        if enable then
            RequestIpl(ipl)
        else
            RemoveIpl(ipl)
        end
    end
end

-- loads water configuration when not in Cayo Perico
--@return: nil
local function load_ls_water()
    LoadGlobalWaterType(0)
    SetDeepOceanScaler(config.dynamic_waves_scaler * 1.0)
end

-- loads water configuration when in Cayo Perico
-- @return: nil
local function load_cayo_perico_water()
    LoadGlobalWaterType(1)
    SetDeepOceanScaler(0.0)
end

-- enable or disable arena wars emitters based on the provided boolean value
-- @param: _disable boolean: true to disable emitters, false to enable emitters
-- @return: nil
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

    -- disable snow from North Yankton
    SetZoneEnabled(GetZoneFromNameId("PrLog"), not config.disable_prologue_snow or false)
    -- enable/disable peds on the island
    SetScenarioGroupEnabled('Heist_Island_Peds', config.peds or true)

    -- enable ambient sounds
    SetAudioFlag('PlayerOnDLCHeist4Island', config.disable_radio)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', config.ambient_zone or true, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', not config.ambient_zone or false, true)

    -- disable arena wars emitters
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

    -- don't load anything, exit early
    if config.minimap_type == 'off' then
       return
    end

    -- load compact minimap via native calls, then exit
    if config.minimap_type == 'compact' then
        SetUseIslandMap(true)
        return
    end

    -- load minimap via scaleform calls
    -- set up the dummy blip to extend minimap bounds
    if dummy_blip then
        RemoveBlip(dummy_blip)
    end
    
    local blip_x, blip_y, blip_z = table.unpack(dummy_blip_coords)
    dummy_blip = AddBlipForCoord(blip_x, blip_y, blip_z)

    -- make blip invisible
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
    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    -- handle path nodes on resource start
    if not config.dynamic_path_nodes then
        SetAiGlobalPathNodesType(0)
        global_ai_path_nodes = 0
    end

    -- handle static water if dynamic_water is false, then exit
    if not config.dynamic_water then
        LoadGlobalWaterType(config.static_water_type)
        SetDeepOceanScaler(config.static_waves_scaler * 1.0)
        return
    end

    while true do
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            local distance = #(coords - cayo_perico_coords)

            if distance > cayo_perico_radius then
                -- handle water
                if GetGlobalWaterType() == 1 then
                    load_ls_water()
                end

                -- handle path nodes
                if config.dynamic_path_nodes and global_ai_path_nodes ~= 0 then
                    SetAiGlobalPathNodesType(0)
                    global_ai_path_nodes = 0
                end
            else
                -- handle water
                if GetGlobalWaterType() == 0 then
                    load_cayo_perico_water()
                end

                -- handle path nodes
                if config.dynamic_path_nodes and global_ai_path_nodes ~= 1 then
                    SetAiGlobalPathNodesType(1)
                    global_ai_path_nodes = 1
                end
            end
        end
        
        Citizen.Wait(config.dynamic_actions_delay)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
       return
    end

    -- reset minimap
    SetUseIslandMap(false)

    -- remove the dummy blip
    if dummy_blip then
        RemoveBlip(dummy_blip)
    end

    -- unload all IPLs
    local _keys = get_keys(_cayo_ipls)

    for _, ipl_subset in pairs(_keys) do
        enable_ipl_subset(ipl_subset, false)
    end

    -- enable arena emitters
    disable_emitters(false)

    -- disable ambient sounds
    SetAudioFlag('PlayerOnDLCHeist4Island', false)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', false, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', true, true)

    -- reset path nodes
    SetAiGlobalPathNodesType(0)
    global_ai_path_nodes = 0
end)
