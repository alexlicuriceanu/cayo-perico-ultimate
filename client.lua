Citizen.CreateThread(function()
    if not config.cayo_perico then
        return
    end

    -- load cayo perico ipls
    for _, ipl in pairs(_cayo_ipls) do
        RequestIpl(ipl)
    end

    -- misc natives
    if config.gps then
        SetAiGlobalPathNodesType(1)
    end

    --LoadGlobalWaterType(1)
    SetZoneEnabled(GetZoneFromNameId("PrLog"), config.disable_prologue_snow or true)
    SetScenarioGroupEnabled('Heist_Island_Peds', config.peds or true)

    -- audio stuff
    SetAudioFlag('PlayerOnDLCHeist4Island', true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Zones', config.ambient_zone or true, true)
    SetAmbientZoneListStatePersistent('AZL_DLC_Hei4_Island_Disabled_Zones', not config.ambient_zone or false, true)
end)

Citizen.CreateThread(function()
    while not NetworkIsSessionStarted() do
        Citizen.Wait(0)
    end

    -- disable arena wars emitters
    SetStaticEmitterEnabled('SE_DLC_AW_ARENA_CONSTRUCTION_01', false)
    SetStaticEmitterEnabled('SE_DLC_AW_ARENA_CROWD_BACKGROUND_MAIN', false)
    SetStaticEmitterEnabled('SE_DLC_AW_CROWD_EXTERIOR_LOBBY', false)
    SetStaticEmitterEnabled('SE_DLC_AW_CROWD_INTERIOR_LOBBY', false)
end)