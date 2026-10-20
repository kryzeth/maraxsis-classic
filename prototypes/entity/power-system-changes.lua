-- salt reactor is treated as the default setting
local geothermal = settings.startup["maraxsis-power-system"].value == "geothermal-generator"

-- mark as hidden, disabled, no auto_recycle, and remove their place_result and all fuel-related fields
local function hide_and_disable(prototype)
    prototype.hidden = true
    prototype.hidden_in_factoriopedia = true
    if prototype.type == "recipe" or prototype.type == "technology" then
        prototype.enabled = false
    end
    prototype.auto_recycle = false
    prototype.place_result = nil
    -- remove all fuel related values
    prototype.fuel_value = nil
    prototype.fuel_categories = nil
    prototype.fuel_acceleration_multiplier = nil
    prototype.fuel_top_speed_multiplier = nil
    prototype.fuel_emissions_multiplier = nil
    prototype.fuel_glow_color = nil
    prototype.fuel_acceleration_multiplier_quality_bonus = nil
    prototype.fuel_top_speed_multiplier_quality_bonus = nil
    prototype.fuel_emissions_multiplier_quality_bonus = nil
end

-- disable placement of power producer that is not currently enabled
-- also updates the localised description and removes its fuel value
if geothermal then
    local reactor = data.raw.item["maraxsis-salt-reactor"]
    local fuel = data.raw.item["msr-fuel-cell"]
    reactor.localised_description = {"description.legacy-item"}
    fuel.localised_description = {"description.legacy-item"}
    hide_and_disable(fuel)
    hide_and_disable(reactor)
    hide_and_disable(data.raw["fusion-reactor"]["maraxsis-salt-reactor"])
    hide_and_disable(data.raw.recipe["maraxsis-salt-reactor"])
    hide_and_disable(data.raw.recipe["molten-salt"])
    hide_and_disable(data.raw.fluid["molten-salt"])
    hide_and_disable(data.raw.recipe["msr-fuel-cell"])
else
    local generator = data.raw.item["maraxsis-geothermal-generator"]
    generator.localised_description = {"description.legacy-item"}
    hide_and_disable(generator)
    hide_and_disable(data.raw["assembling-machine"]["maraxsis-geothermal-generator"])
    hide_and_disable(data.raw.recipe["maraxsis-geothermal-generator"])
    hide_and_disable(data.raw.recipe["maraxsis-supercritical-steam"])
    hide_and_disable(data.raw.recipe["maraxsis-supercritical-steam-cooling"])
    hide_and_disable(data.raw.recipe["maraxsis-geothermal-sulfur"])
end

-- below changes are only needed with geothermal enabled
if not geothermal then return end

-- shorthand some variables
local steam = data.raw.fluid["maraxsis-supercritical-steam"]
local turbine = data.raw.generator["maraxsis-oversized-steam-turbine"]

-- Modern localised descriptions
steam.localised_description = {"fluid-description.maraxsis-supercritical-steam-geothermal"}
turbine.localised_description = {"entity-description.maraxsis-oversized-steam-turbine-geothermal"}

-- Modern geothermal generator values
steam.default_temperature = 0
steam.max_temperature = 2000
steam.heat_capacity = "0.3125kJ"
turbine.fluid_usage_per_tick = 80 / second
turbine.spent_fluid.amount = 78 / 80

-- Modern turbine duct connections
turbine.fluid_box.pipe_picture = require("prototypes.entity.duct-pipe-pictures")
turbine.fluid_box.pipe_picture_frozen = nil
turbine.fluid_box.pipe_covers = nil
turbine.fluid_box.max_pipeline_extent = require("__FluidMustFlow__.prototypes.constants").extent

turbine.fluid_box.pipe_connections = {
    {flow_direction = "input-output", direction = defines.direction.east, position = {1, 1.5}, connection_category = "ducts"},
    {flow_direction = "input-output", direction = defines.direction.west, position = {-1, -1.5}, connection_category = "ducts"},
}

-- Modern's additional southern water output
table.insert(turbine.output_fluid_box.pipe_connections, {
    flow_direction = "input-output",
    direction = defines.direction.south,
    position = {0, 4},
})

-- update to Modern's nuclear submarine recipe, replacing the molten salt reactor
for _, ingredient in pairs(data.raw.recipe["maraxsis-nuclear-submarine"].ingredients) do
    if ingredient.name == "maraxsis-salt-reactor" then
        ingredient.name = "nuclear-reactor"
        break
    end
end