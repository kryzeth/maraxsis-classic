-- required helpers for the pressure dome rebuilding
local pressure_dome_helpers = require "scripts.pressure-dome-helpers"
local dome_octagon_size = pressure_dome_helpers.octagon_size
local mobile_entities = pressure_dome_helpers.mobile_entities
local count_points_in_dome = pressure_dome_helpers.count_points_in_dome
local update_dome_combinator = pressure_dome_helpers.update_combinator
local update_dome_minable_flag = pressure_dome_helpers.update_dome_minable_flag
local rerender_all_domes = pressure_dome_helpers.rerender_all_domes

-- locate pre-existing super turbines and re-link the hidden assemblers
local function rebuild_oversized_steam_turbines()
    local rebuilt = 0
    local missing = 0
    -- super turbines can technically be placed anywhere,
    -- so must scan all surfaces for turbines just to be safe
    for _, surface in pairs(game.surfaces) do
        for _, turbine in pairs(surface.find_entities_filtered {
            name = "maraxsis-oversized-steam-turbine"
        }) do   -- check all hidden assemblers in same position
            local assemblers = surface.find_entities_filtered {
                name = "maraxsis-oversized-steam-turbine-hidden-assembling-machine",
                position = turbine.position,
                force = turbine.force,
            }
            -- there should only be one matching hidden assembler here
            local assembler = assemblers[1]
            if assembler and assembler.valid then
                storage.oversized_steam_turbines[turbine.unit_number] = assembler
                rebuilt = rebuilt + 1
            else    -- this shouldn't fail, but count it just in case
                missing = missing + 1
            end
        end
    end
    -- finally, log the final result of rebuilt/missing entities
    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " oversized steam turbine pairings; " .. missing
        .. " missing helpers")
end

-- same deal with the trench ducts, link the lower to the upper
local function rebuild_trench_ducts()
    -- they can only be placed on Maraxsis and its trench
    local maraxsis_surface = game.surfaces[maraxsis_constants.MARAXSIS_SURFACE_NAME]
    local trench_surface = game.surfaces[maraxsis_constants.TRENCH_SURFACE_NAME]
    -- so we can skip scanning if one of these surfaces doesn't exist
    if not maraxsis_surface or not trench_surface then
        log("Maraxsis Classic migration: rebuilt 0 trench duct pairings; 0 missing lower ducts")
        return
    end

    local rebuilt = 0
    local missing = 0

    -- start by searching the main suface for upper ducts
    for _, surface_duct in pairs(maraxsis_surface.find_entities_filtered {
        name = "maraxsis-trench-duct"
    }) do   -- then attempt to locate lower duct in the trench at same position
        local lower_ducts = trench_surface.find_entities_filtered {
            name = "maraxsis-trench-duct-lower",
            position = surface_duct.position,
            force = surface_duct.force,
        }
        -- there should only be one matching result
        local trench_duct = lower_ducts[1]
        if trench_duct and trench_duct.valid then
            local trench_duct_data = {
                surface_duct = surface_duct,
                trench_duct = trench_duct,
                surface_duct_unit_number = surface_duct.unit_number,
                trench_duct_unit_number = trench_duct.unit_number,
            }
            storage.trench_ducts[surface_duct.unit_number] = trench_duct_data
            storage.trench_ducts[trench_duct.unit_number] = trench_duct_data
            rebuilt = rebuilt + 1
        else    -- this shouldn't fail, but count it just in case
            missing = missing + 1
        end
    end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " trench duct pairings; " .. missing
        .. " missing lower ducts")
end

-- and again with the sonar and their two attached lights
-- I think you get the idea; this is brain-dead simple,
-- so I'm not gonna bother with many more comments
local function rebuild_sonars()
    local rebuilt = 0
    local missing = 0

    for _, surface in pairs(game.surfaces) do
        for _, sonar in pairs(surface.find_entities_filtered {
            name = "maraxsis-sonar"
        }) do
            local x = sonar.position.x
            local y = sonar.position.y

            local light_1 = surface.find_entities_filtered {
                name = "maraxsis-sonar-light-1",
                position = {x, y + 1},
                force = sonar.force,
            }[1]

            local light_2 = surface.find_entities_filtered {
                name = "maraxsis-sonar-light-2",
                position = {x, y - 1},
                force = sonar.force,
            }[1]

            if light_1 and light_1.valid and light_2 and light_2.valid then
                storage.composite_entities[sonar.unit_number] = {
                    light_1,
                    light_2,
                }
                rebuilt = rebuilt + 1
            else
                missing = missing + 1
            end
        end
    end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " sonar composites; ".. missing
        .. " missing helpers")
end

-- fishing tower generates a hidden fish spawner
-- this spawner must be registered for destruction when the fishing tower is removed
local function rebuild_fishing_towers()
    local rebuilt = 0
    local missing = 0

    for _, surface in pairs(game.surfaces) do
        for _, tower in pairs(surface.find_entities_filtered {
            name = "maraxsis-fishing-tower"
        }) do
            local spawner = surface.find_entities_filtered {
                name = "maraxsis-fish-spawner",
                position = tower.position,
            }[1]

            if spawner and spawner.valid then
                local registration_number = script.register_on_object_destroyed(tower)
                storage.fishing_tower_spawners[registration_number] = spawner
                rebuilt = rebuilt + 1
            else
                missing = missing + 1
            end
        end
    end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " fishing tower registrations; " .. missing
        .. " missing spawners")
end

-- simply locate all exhaust ducts and add to storage
-- this is needed for super-steam safety checks (see: scripts/salt-reactor)
local function rebuild_duct_exhausts()
    local rebuilt = 0

    for _, surface in pairs(game.surfaces) do
        for _, exhaust in pairs(surface.find_entities_filtered {
            name = "duct-exhaust"
        }) do
            storage.duct_exhausts[exhaust.unit_number] = exhaust
            rebuilt = rebuilt + 1
        end
    end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " duct exhaust registrations")
end

-- relatively simple as well; locate all subs, add to storage
-- this is needed for out-of-fuel alerts (see: scripts/submarine)
local function rebuild_submarines()
    local submarine_names = {}

    for name in pairs(maraxsis_constants.SUBMARINES) do
        submarine_names[#submarine_names + 1] = name
    end

    local rebuilt = 0

    for _, surface in pairs(game.surfaces) do
        for _, submarine in pairs(surface.find_entities_filtered {
            name = submarine_names,
        }) do
            storage.submarines[submarine.unit_number] = submarine
            rebuilt = rebuilt + 1
        end
    end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " submarine registrations")
end

-- little more complex here
-- salt reactors have some custom rendering things for their glow effects
local function rebuild_salt_reactors()
    local rebuilt = 0

    for _, surface in pairs(game.surfaces) do
        for _, reactor in pairs(surface.find_entities_filtered {
            name = "maraxsis-salt-reactor"
        }) do
            local animation = rendering.draw_animation {
                animation = "maraxsis-salt-reactor-animation",
                render_layer = "object",
                target = reactor,
                surface = reactor.surface_index,
                animation_speed = 0.5,
            }

            local glow = rendering.draw_animation {
                animation = "maraxsis-salt-reactor-animation-glow",
                render_layer = "object",
                target = reactor,
                surface = reactor.surface_index,
                animation_speed = 0.5,
                color = {0, 0, 0, 0},
            }

            storage.not_fully_active_reactors[reactor.unit_number] = {
                reactor,
                animation,
                glow,
            }

            storage.fully_active_reactors[reactor.unit_number] = nil

            rebuilt = rebuilt + 1
        end
    end

    log("Maraxsis Classic migration: rebuilt ".. rebuilt
        .. " salt reactor runtime states")
end

-- the most complex thing to rebuild; there are so many moving parts here
-- this also requires some geometry functions originally defined within scripts/pressure-dome
-- they have since been moved into scripts/pressure-dome-helpers, defined at top of file
local function rebuild_pressure_domes()
    local rebuilt = 0
    local incomplete = 0

    for _, surface in pairs(game.surfaces) do
        for _, regulator in pairs(surface.find_entities_filtered {
            name = "maraxsis-regulator",
        }) do
            local position = regulator.position
            local x, y = position.x, position.y
            local force_index = regulator.force_index
            local quality = regulator.quality

            local regulator_fluidbox = surface.find_entities_filtered {
                name = "maraxsis-regulator-fluidbox-" .. quality.name,
                position = position,
                force = force_index,
            }[1]

            local light = surface.find_entities_filtered {
                name = "maraxsis-pressure-dome-lamp",
                position = position,
                force = force_index,
            }[1]

            local combinator = surface.find_entities_filtered {
                name = "maraxsis-pressure-dome-combinator",
                area = {
                    {x - 1, y - 1},
                    {x + 1, y + 1},
                },
                force = force_index,
            }[1]

            local collision_boxes = surface.find_entities_filtered {
                name = "maraxsis-pressure-dome-collision",
                area = {
                    {x - dome_octagon_size, y - dome_octagon_size},
                    {x + dome_octagon_size, y + dome_octagon_size},
                },
                force = force_index,
            }

            -- combinators are optional; not required for validity
            -- they also get rebuilt later, via update_combinator()
            if not regulator_fluidbox
                or not regulator_fluidbox.valid
                or not light
                or not light.valid
                or #collision_boxes ~= 8
            then
                incomplete = incomplete + 1

                log("Maraxsis Classic migration: incomplete pressure dome at "
                    .. serpent.line(position) .. " on surface " .. surface.name
                    .. "; fluidbox=" .. tostring(regulator_fluidbox and regulator_fluidbox.valid)
                    .. ", light=" .. tostring(light and light.valid)
                    .. ", combinator=" .. tostring(combinator and combinator.valid)
                    .. ", collision_boxes=" .. #collision_boxes)
                goto continue
            end

            local contained_entities = {}

            local entities_inside_square = surface.find_entities_filtered {
                area = {
                    {x - dome_octagon_size, y - dome_octagon_size},
                    {x + dome_octagon_size, y + dome_octagon_size},
                },
            }

            for _, entity in pairs(entities_inside_square) do
                if entity.valid
                    and not mobile_entities[entity.type]
                    and entity ~= regulator
                    and entity ~= regulator_fluidbox
                    and entity ~= light
                    and entity ~= combinator
                    and entity.name ~= "maraxsis-pressure-dome-collision"
                then
                    local points_in_dome = count_points_in_dome(
                        {position = position},
                        entity
                    )

                    if points_in_dome == 4 then
                        contained_entities[#contained_entities + 1] = entity
                    end
                end
            end

            local dome_sprite = rendering.draw_sprite {
                sprite = "maraxsis-pressure-dome-sprite",
                render_layer = "higher-object-above",
                target = position,
                surface = surface,
            }

            local pressure_dome_data = {
                entity = dome_sprite,
                position = position,
                surface = surface,
                quality = quality,
                contained_entities = contained_entities,
                force_index = force_index,
                collision_boxes = collision_boxes,
                regulator = regulator,
                regulator_fluidbox = regulator_fluidbox,
                light = light,
                combinator = combinator,
            }

            storage.pressure_domes[dome_sprite.id] = pressure_dome_data

            update_dome_combinator(pressure_dome_data)
            update_dome_minable_flag(pressure_dome_data)

            rebuilt = rebuilt + 1

            ::continue::
        end
    end

    if rebuilt > 0 then rerender_all_domes() end

    log("Maraxsis Classic migration: rebuilt " .. rebuilt
        .. " pressure dome runtime states; " .. incomplete
        .. " incomplete domes")
end

-- finally, add all the migration functions to the init only script
-- we don't need to rebuild this on config changed, after all
maraxsis.on_init_only(function()
    rebuild_oversized_steam_turbines()
    rebuild_trench_ducts()
    rebuild_sonars()
    rebuild_fishing_towers()
    rebuild_duct_exhausts()
    rebuild_submarines()
    rebuild_salt_reactors()
    rebuild_pressure_domes()
end)