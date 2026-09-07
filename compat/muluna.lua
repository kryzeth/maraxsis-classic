-- https://github.com/notnotmelon/maraxsis/issues/417

if not mods["planet-muluna"] then return end

for surface in pairs(maraxsis_constants.MARAXSIS_SURFACES) do
    PlanetsLib.create_planet_entity_variant(
        surface,
        data.raw["rocket-silo"]["muluna-big-rocket-silo"],
        {
            name = "maraxsis-muluna-big-rocket-silo",
            localised_name = {"entity-name.muluna-big-rocket-silo"},
            localised_description = {"entity-description.muluna-big-rocket-silo"},
            rocket_entity = "maraxsis-rocket-silo-rocket",
            fixed_recipe = "maraxsis-rocket-part",
            disabled_when_recipe_not_researched = true,
            placeable_by = {{item = "muluna-big-rocket-silo", count = 1}},
            flags = {"placeable-player", "player-creation", "not-in-made-in"},
            hidden = true,
            hidden_in_factoriopedia = true,
        },
        "maraxsis-runtime-entity-replacement",
        "muluna-big-rocket-silo"
    )
end

-- Adapted from Muluna's data-updates (hopefully should no longer require dependency)
-- Modifies values of gas fluids in Maraxsis entities to follow Factorio 2.0's convention of
--  gas fluid units having 1/10 the matter of liquid fluid units (as in water vs. steam)
for name, regulator in pairs(data.raw["assembling-machine"]) do
    if name:find("^maraxsis%-regulator%-fluidbox%-") then
        regulator.energy_source.fluid_box.volume =
            regulator.energy_source.fluid_box.volume * 10
    end
end

-- Additional data stage changes adapted from Muluna's prototypes/atmosphere
-- This should hopefully no longer require an optional dependency
data.raw["recipe"]["maraxsis-atmosphere"].results[1].amount = 1000
data.raw["recipe"]["maraxsis-atmosphere"].energy_required = 1