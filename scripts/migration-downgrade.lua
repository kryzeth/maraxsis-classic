-- Detects migration from any version of the original Maraxsis to Maraxsis Classic.
-- This info is only available during on_configuration_changed event.
local function get_migration_source_version(event)
    -- if no changes were made, simply return
    local mod_changes = event.mod_changes
    if not mod_changes then return end

    -- if Maraxsis did not exist when this save file was made, simply return
    local old_maraxsis = mod_changes["maraxsis"]
    if not old_maraxsis
        or not old_maraxsis.old_version
        or old_maraxsis.new_version
    then return end

    -- otherwise, return the previous version of Maraxsis in case of special handling
    return old_maraxsis.old_version
end

local function downgrade_geothermal_generators()
    local downgraded = 0
    -- for each pre-existing geothermal entity we find..
    for _, surface in pairs(game.surfaces) do
        for _, generator in pairs(surface.find_entities_filtered {
            name = "maraxsis-geothermal-generator"
        }) do
            local position = generator.position
            local box = generator.bounding_box
            local force = generator.force
            local quality = generator.quality

            -- locate any nearby inserters targetting this generator, mark them for deconstruction
            -- this prevents inserters from throwing items into the lava underneath
            local inserters = surface.find_entities_filtered {
                type = "inserter",
                area = {
                    {box.left_top.x - 4, box.left_top.y - 4},
                    {box.right_bottom.x + 4, box.right_bottom.y + 4},
                },
            }
            for _, inserter in pairs(inserters) do
                if inserter.drop_target == generator then
                    inserter.order_deconstruction(inserter.force)
                end
            end
            
            -- clear any in-progress recipe, and spill the returned ingredients
            local returned_items = generator.set_recipe(nil)
            for _, stack in pairs(returned_items) do
                surface.spill_item_stack {
                    position = position,
                    stack = stack,
                    force = force,
                }
            end

            -- then grab the input, output, and module inventories
            -- and spill everything out of those as well
            local inventories = {
                generator.get_inventory(defines.inventory.crafter_input),
                generator.get_output_inventory(),
                generator.get_module_inventory(),
            }
            for _, inventory in pairs(inventories) do
                if inventory and not inventory.is_empty() then
                    surface.spill_inventory {
                        position = position,
                        inventory = inventory,
                        force = force,
                    }
                end
            end

            -- finally destroy the generator entity itself
            -- and spill a copy of the item, in its original quality
            generator.destroy()
            surface.spill_item_stack {
                position = position,
                stack = {
                    name = "maraxsis-geothermal-generator",
                    count = 1,
                    quality = quality,
                },
                enable_looted = true,
                force = force,
            }

            downgraded = downgraded + 1
        end
    end

    log("Maraxsis Classic migration: downgraded " .. downgraded
        .. " geothermal generators")
end

maraxsis.on_configuration_changed_only(function(event)
    local source_version = get_migration_source_version(event)
    if not source_version then return end

    -- store the version data in case we need to migrate something specific in future
    storage.migrated_from_maraxsis_version = source_version

    log("Maraxsis Classic migration: detected original Maraxsis " .. source_version)

    -- downgrade only needs to run on versions of Maraxsis above 1.33.2
    if helpers.compare_versions(source_version, "1.33.2") >= 0 then
        downgrade_geothermal_generators()
    end
end)