local function spill_inventory(entity, inventory)
    if inventory and inventory.valid and not inventory.is_empty() then
        entity.surface.spill_inventory {
            position = entity.position,
            inventory = inventory,
            force = entity.force,
        }
    end
end

local function spill_item(entity, stack)
    entity.surface.spill_item_stack {
        position = entity.position,
        stack = stack,
        force = entity.force,
        enable_looted = true,
    }
end

local function dismantle(entity)
    local surface = entity.surface
    local box = entity.bounding_box
    local position = entity.position
    local name = entity.name
    local quality = entity.quality
    local force = entity.force

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
        if inserter.drop_target == entity then
            inserter.order_deconstruction(inserter.force)
        end
    end
    
    if name == "maraxsis-geothermal-generator" then
        -- clear any in-progress recipe, and spill the returned ingredients
        for _, stack in pairs(entity.set_recipe(nil) or {}) do
            spill_item(entity, stack)
        end
        spill_inventory(entity, entity.get_inventory(defines.inventory.crafter_input))
        spill_inventory(entity, entity.get_output_inventory())
        spill_inventory(entity, entity.get_module_inventory())
    elseif name == "maraxsis-salt-reactor" then
        -- spill the fuel cell currently being burned, if any
        local burner = entity.burner
        if burner and burner.currently_burning then
            local fuel = burner.currently_burning
            spill_item(entity, {
                name = fuel.name,
                count = 1,
                quality = fuel.quality,
            })
        end
        -- spill unused fuel, spent fuel and any other stored items
        spill_inventory(entity, entity.get_fuel_inventory())
        spill_inventory(entity, entity.get_burnt_result_inventory())
        spill_inventory(entity, entity.get_inventory(defines.inventory.crafter_input))
        spill_inventory(entity, entity.get_output_inventory())
        spill_inventory(entity, entity.get_module_inventory())

        -- clear entity's tracked animations and storage table references
        local reactors = {storage.fully_active_reactors or {}, storage.not_fully_active_reactors or {} }
        for _, reactors in pairs (reactors) do
            local tracked = reactors[entity.unit_number]
            if tracked then
                for i = 2, 3 do
                    local animation = tracked[i]
                    if animation and animation.valid then
                        animation.destroy()
                    end
                end
                reactors[entity.unit_number] = nil
            end
        end
        if storage.salt_reactors then
            storage.salt_reactors[entity.unit_number] = nil
        end
    end

    -- finally destroy the entity itself and spill a copy of the item, in its original quality
    entity.destroy()
    surface.spill_item_stack {
        position = position,
        stack = {name = name, count = 1, quality = quality},
        force = force,
        enable_looted = true,
    }
end

-- dismantle salt reactor or geothermal generator based on setting
maraxsis.on_event(maraxsis.events.on_init(), function(event)
    -- locally cache the setting, only run migration when this changes
    local selected = settings.startup["maraxsis-power-system"].value
    if storage.power_system == selected then return end
    -- if geothermal is selected, drop salt reactors, and vice-versa
    local name
    if selected == "geothermal-generator" then
        name = "maraxsis-salt-reactor"
    else
        name = "maraxsis-geothermal-generator"
    end

    local count = 0
    for _, surface in pairs(game.surfaces) do
        -- remove any ghosts with matching entity name
        for _, ghost in pairs(surface.find_entities_filtered {name = "entity-ghost", ghost_name = name}) do
            ghost.destroy() -- do not add to count
        end
        -- then dismantle any real entities to drop their contents
        for _, entity in pairs(surface.find_entities_filtered {name = name}) do
            dismantle(entity)
            count = count + 1
        end
    end
    -- debug log for posterity
    storage.power_system = selected
    log("Maraxsis Classic: dismantled " .. count .. " " .. name .. " entities")
end)

-- prevents new ghosts from being built for the wrong entity
maraxsis.on_event(maraxsis.events.on_built(), function(event)
    local entity = event.entity
    if not entity or not entity.valid or entity.name ~= "entity-ghost" then return end
    local name = settings.startup["maraxsis-power-system"].value == "geothermal-generator"
        and "maraxsis-salt-reactor" or "maraxsis-geothermal-generator"
    if entity.ghost_name == name then
        entity.destroy()
    end
end)
