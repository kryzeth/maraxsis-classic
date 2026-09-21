local table = require("lib.table")

function table_contains(tbl, x)
    if not tbl then
        return false
    end
    for _, v in pairs(tbl) do
        if v == x then
            return true
        end
    end
    return false
end

local collision_mask_util = require("collision-mask-util")

require "prototypes.research-vessel"
require "prototypes.collision-mask"
require "prototypes.swimming"
-- recycling recipes for migration mode
require "prototypes.migration.recycling"

require "compat.5-dim"
require "compat.alien-biomes"
require "compat.visible-planets-in-space"
require "compat.rocket-silo-construction"
require "compat.combat-mechanics-overhaul"
require "compat.castra"
require "compat.krastorio-2-final-fixes"
require "compat.water-refining"

if not data.raw["mining-drill"]["electric-mining-drill"].next_upgrade then
    if mods["SchallAlienTech"] and data.raw["mining-drill"]["Schall-uranium-mining-drill"] then
        data.raw["mining-drill"]["electric-mining-drill"].next_upgrade = "Schall-uranium-mining-drill"
    end
end

for extractor in pairs(maraxsis_constants.MARAXSIS_SAND_EXTRACTORS) do
    local mask = collision_mask_util.get_mask(data.raw["mining-drill"][extractor])
    mask.layers[maraxsis_dome_collision_mask] = true

    -- https://github.com/notnotmelon/maraxsis/issues/342
    -- https://github.com/notnotmelon/maraxsis/issues/368
    local seen = {extractor}
    local function update_collision_masks(mining_drill)
        if type(mining_drill) ~= "string" then return end
        for _, v in pairs(seen) do
            if v == mining_drill then return end
        end
        seen[#seen+1] = mining_drill
        mining_drill = data.raw["mining-drill"][mining_drill]
        if not mining_drill then return end
        mining_drill.collision_mask = mask
        update_collision_masks(mining_drill.next_upgrade)
        for _, drill in pairs(data.raw.mining_drill) do
            if drill.next_upgrade == mining_drill then
                update_collision_masks(drill.name)
            end
        end
    end

    update_collision_masks(extractor)
    update_collision_masks(extractor .. "-sand-extractor")
end

if data.raw["technology"]["maraxsis-promethium-productivity"] then
    data.raw["technology"]["maraxsis-promethium-productivity"].unit.ingredients = table.deepcopy(data.raw["technology"]["research-productivity"].unit.ingredients)
end

for _, recipe in pairs(data.raw.recipe) do
    if table_contains(recipe.categories,"maraxsis-hydro-plant") then
        recipe.always_show_made_in = true
    end
end

data.raw["equipment-grid"]["maraxsis-diesel-submarine-equipment-grid"].equipment_categories = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"].equipment_categories)
data.raw["equipment-grid"]["maraxsis-nuclear-submarine-equipment-grid"].equipment_categories = table.deepcopy(data.raw["equipment-grid"]["spidertron-equipment-grid"].equipment_categories)

local ducts = table.invert {
    "duct-small",
    "duct",
    "duct-long",
    "duct-t-junction",
    "duct-curve",
    "duct-cross",
    "maraxsis-trench-duct-lower",
}

for name in pairs(ducts) do
    local entity = data.raw["storage-tank"][name] or data.raw["pump"][name] or data.raw["pipe-to-ground"][name]
    entity.collision_mask = {layers = {object = true, train = true, is_object = true, is_lower_object = true}}
end

ducts["maraxsis-trench-duct"] = true

do
    -- allow rocket fuel and nuclear fuel to be used in submarines
    local fuel_category = table.deepcopy(data.raw["fuel-category"]["chemical"])
    fuel_category.name = "rocket-fuel"
    fuel_category.localised_name = {"fuel-category-name.chemical"}
    data:extend {fuel_category}
    local fuel_category = table.deepcopy(data.raw["fuel-category"]["chemical"])
    fuel_category.name = "nuclear-fuel"
    fuel_category.localised_name = {"fuel-category-name.chemical"}
    data:extend {fuel_category}

    PlanetsLib.rro.soft_insert(data.raw.item["rocket-fuel"].fuel_categories,"rocket-fuel")
    PlanetsLib.rro.soft_insert(data.raw.item["nuclear-fuel"].fuel_categories, "nuclear-fuel")

    
end

local sand_mask = collision_mask_util.get_mask(data.raw.tile["sand-1-underwater"])
local hydro_plant_mask = collision_mask_util.get_mask(data.raw["assembling-machine"]["maraxsis-hydro-plant"])
if collision_mask_util.masks_collide(sand_mask, hydro_plant_mask) then
    error(
        "Hydro plant cannot be built on maraxsis. Is there a mod conflict? Sand mask: "
        .. serpent.line(sand_mask)
        .. " Hydro plant mask: "
        .. serpent.line(hydro_plant_mask)
    )
end

--- Prevent Nauvis nuke effects on Maraxsis (keyed by pressure, so all planets
--- with sufficient pressure).
if data.raw["explosion"]["nuke-effects-nauvis"] then
    PlanetsLib.restrict_surface_conditions(
        data.raw["explosion"]["nuke-effects-nauvis"],
        {property = "pressure", max = 50000}
    )
end

--- The trench's lava glow is made possible by these lamps. This prevents them
--- from being able to be destroyed, including by damage types added by other
--- mods.
local lava_lamp = data.raw["simple-entity"]["maraxsis-lava-lamp"]
lava_lamp.resistances = {}
for damage_type in pairs(data.raw["damage-type"]) do
    table.insert(lava_lamp.resistances, {type = damage_type, percent = 100})
end
