local BLAST_RADIUS = 12

local TRENCH_FLOOR = {
    "volcanic-folds-underwater",
    "volcanic-cracks-hot-underwater",
    "volcanic-cracks-warm-underwater",
    "nuclear-ground-underwater",
}

local OCEAN_FLOOR = {
    "sand-1-underwater",
    "sand-2-underwater",
    "sand-3-underwater",
    "dirt-5-underwater",
    "lowland-cream-red-underwater",
    "lowland-red-vein-2-underwater",
}

local function set_tiles(surface, tiles)
    if tiles[1] then
        surface.set_tiles(tiles, true, false, true, false)
    end
end

local function nuke_trench(surface, center)
    local tiles = {}
    for _, tile in pairs(surface.find_tiles_filtered {position = center, radius = BLAST_RADIUS, name = TRENCH_FLOOR}) do
        tiles[#tiles + 1] = {name = "nuclear-ground-underwater", position = tile.position}
    end
    set_tiles(surface, tiles)
end

local function nuke_ocean(surface, center)
    local tiles = {}
    for _, tile in pairs(surface.find_tiles_filtered {position = center, radius = BLAST_RADIUS, name = OCEAN_FLOOR}) do
        tiles[#tiles + 1] = {name = "nuclear-ground-underwater", position = tile.position}
    end
    set_tiles(surface, tiles)

    -- Coral's a resource, so it won't get removed unless we do it.
    for _, coral in pairs(surface.find_entities_filtered {position = center, radius = BLAST_RADIUS, name = "maraxsis-coral"}) do
        coral.destroy()
    end
end

--- Raised by the explosions in `prototypes/nuke-effects.lua`, which only appear
--- on Maraxsis and in the trench.
maraxsis.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "maraxsis-nuke-effects" then return end

    -- the event has no positions, only the explosion itself
    local explosion = event.target_entity
    if not explosion or not explosion.valid then return end
    local surface, center = explosion.surface, explosion.position

    if surface.name == maraxsis_constants.TRENCH_SURFACE_NAME then
        nuke_trench(surface, center)
    elseif surface.name == maraxsis_constants.MARAXSIS_SURFACE_NAME then
        nuke_ocean(surface, center)
    end
end)
