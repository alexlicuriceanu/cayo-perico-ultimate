local cayo_perico_coords = vector3(4700.0, -5150.0, 0.0)

local function enable_ipl_subset(ipl_subset, enable)
    for _, ipl in pairs(_cayo_ipls[ipl_subset]) do
        if enable then
            RequestIpl(ipl)
        else
            RemoveIpl(ipl)
        end
    end
end

local function enable_cayo_perico(enable)
    enable_ipl_subset('main', enable)
    enable_ipl_subset('shark', enable)
    enable_ipl_subset('whale', enable)
    enable_ipl_subset('sea_mines', enable)

    if config.gate_open then
        enable_ipl_subset('gate_open', enable)
    elseif config.gate_open == false then
        enable_ipl_subset('gate_closed', enable)
    end

    if config.hangar_open then
        enable_ipl_subset('hangar_open', enable)
    elseif config.hangar_open == false then
        enable_ipl_subset('hangar_closed', enable)
    end
end

Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
    end

    -- load cayo perico ipls
    enable_cayo_perico(true)

    -- misc natives
    if config.gps then
        SetAiGlobalPathNodesType(1)
    end

    --LoadGlobalWaterType(1)
    SetZoneEnabled(GetZoneFromNameId("PrLog"), not config.disable_prologue_snow or false)
    
    SetScenarioGroupEnabled('Heist_Island_Peds', config.peds or true)

    -- audio stuff
    SetAudioFlag('PlayerOnDLCHeist4Island', true)
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
end)


Citizen.CreateThread(function()
    SetUseIslandMap(false)

    if config.minimap_type == 'off' then
       return
    end

    if config.minimap_type == 'compact' then
        SetUseIslandMap(true)
    end

    local hash = GetHashKey("h4_fake_islandx")
    local x, y, z = table.unpack(cayo_perico_coords)
    
    while true do
        SetRadarAsExteriorThisFrame()
        SetRadarAsInteriorThisFrame(hash, x, y, z, 0)
        Citizen.Wait(0)
    end
end)


Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    -- disable arena wars emitters
    SetStaticEmitterEnabled('SE_DLC_AW_ARENA_CONSTRUCTION_01', config.disable_emitters or false)
    SetStaticEmitterEnabled('SE_DLC_AW_ARENA_CROWD_BACKGROUND_MAIN', config.disable_emitters or false)
    SetStaticEmitterEnabled('SE_DLC_AW_CROWD_EXTERIOR_LOBBY', config.disable_emitters or false)
    SetStaticEmitterEnabled('SE_DLC_AW_CROWD_INTERIOR_LOBBY', config.disable_emitters or false)
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    local cayo_perico_ipls = get_keys(_cayo_ipls)
    for _, ipl_subset in pairs(cayo_perico_ipls) do
        enable_ipl_subset(ipl_subset, false)
    end
end)