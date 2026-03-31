config = {}

config.cayo_perico = true   -- master switch

config.disable_prologue_snow = true   -- disable snow coming from north yankton
config.disable_emitters = true          -- disable arena wars emitters

config.peds = true              -- enable island peds
config.ambient_zone = true      -- enable ambient zone (birds, insects, etc)

config.vault_entity_set = 'pink_diamond_set' -- options: 'panther_set', 'pearl_necklace_set', 'pink_diamond_set', nil (disables the entity set)
config.hangar_open = true        -- open the hangar
config.gate_open = true         -- open the gate to the mansion
config.underwater_gate_closed = false -- enable the closed underwater gate
config.sea_mines = true          -- enable sea mines around the island
config.shark = true          -- enable dead shark
config.whale = true          -- enable beached whale

-- [*] I highly suggest that if not using 'compact', you leave this to off and use
-- extra-map-tiles to load textures for Cayo Perico. It is faster, better and more
-- customizable.
-- https://forum.cfx.re/t/release-extra-map-tiles-v2-add-extra-textured-tiles-on-the-pause-menu-map-and-minimap-new-and-revamped-version 

config.minimap_type = 'scaleform' -- options: 'compact', 'scaleform', 'off'
config.disable_radio = false

config.gps = true               -- enable gps route on cayo perico (disables LS gps if dynamic_path_nodes is not true)
config.dynamic_path_nodes = true   -- dynamically enable/disable path nodes when entering/exiting Cayo Perico
config.dynamic_path_nodes_delay = 3000 -- delay in ms for updating path nodes state
