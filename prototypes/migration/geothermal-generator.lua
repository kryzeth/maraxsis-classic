-- early exit script if migration mode is not enabled
if not settings.startup["maraxsis-migration-mode"].value then return end

data:extend {
    {   -- geothermal generator item
        type = "item",
        name = "maraxsis-geothermal-generator",
        icon = "__maraxsis-classic__/graphics/migration/geothermal-generator.png",
        hidden = true,
        icon_size = 64,
        stack_size = 5,
        -- no place_result so that its entity form cannot be placed again
    },
    {   -- geothermal generator entity
        type = "assembling-machine",
        name = "maraxsis-geothermal-generator",
        icon = "__maraxsis-classic__/graphics/migration/geothermal-generator.png",
        icon_size = 64,
        localised_description = {"description.legacy-item"},
        hidden_in_factoriopedia = true,
        -- retain minability just in case
        minable = {
            mining_time = 0.5,
            results = {
                {
                    type = "item",
                    name = "maraxsis-geothermal-generator",
                    amount = 1
                }
            }
        },
        -- kept only fields which might be important to retain in-progress crafting
        -- discarded all graphics and other likely unnecessary fields
        max_health = 600,
        fast_replaceable_group = "maraxsis-geothermal-generator",
        circuit_connector = circuit_connector_definitions["maraxsis-hydro-plant"],
        circuit_wire_max_distance = _G.default_circuit_wire_max_distance,
        heating_energy = "2000kW",
        module_slots = 5,
        use_mirroring = true,
        allowed_effects = {
            "consumption",
            "speed",
            "productivity",
            "pollution",
            "quality"
        },
        collision_box = {{-2.9, -2.9}, {2.9, 2.9}},
        selection_box = {{-3.0, -3.0}, {3.0, 3.0}},
        drawing_box_vertical_extension = 1,
        fluid_boxes_off_when_no_fluid_recipe = false,
        fluid_boxes = {
            {
                production_type = "input",
                volume = 100,
                pipe_connections = {
                    {
                        connection_category = "ducts",
                        direction = defines.direction.south,
                        flow_direction = "input-output",
                        position = {0, 2.5}
                    },
                },
            },
            {
                production_type = "input",
                volume = 100,
                pipe_connections = {
                    {
                        connection_category = "ducts",
                        direction = defines.direction.north,
                        flow_direction = "input-output",
                        position = {0, -2.5}
                    },
                },
            },
            {
                production_type = "output",
                volume = 100,
                pipe_connections = {
                    {
                        connection_category = "ducts",
                        direction = defines.direction.east,
                        flow_direction = "input-output",
                        position = {2.5, 0}
                    }
                },
            },
            {
                production_type = "output",
                volume = 100,
                pipe_connections = {
                    {
                        connection_category = "ducts",
                        direction = defines.direction.west,
                        flow_direction = "input-output",
                        position = {-2.5, 0}
                    },
                },
            },
        },
        off_when_no_fluid_recipe = true,
        crafting_categories = {"maraxsis-geothermal-generator",},
        scale_entity_info_icon = true,
        crafting_speed = 1,
        energy_source = {type = "void",},
        energy_usage = "1W",
        collision_mask = {layers = { object = true, ground_tile = true } },
        -- make sure we retain ingredients after clearing any in-progress recipe
        return_ingredients_on_change = true,
    },
    {   -- geothermal generator recipe
        type = "recipe",
        name = "maraxsis-geothermal-generator",
        enabled = false,    -- cannot be unlocked or crafted
        hidden = true,      -- will not appear in any menus
        hidden_in_factoriopedia = true,   -- backup to hide it even further
        energy_required = 10,   -- preserve the original crafting time
        ingredients = {     -- preserve the original ingredients
            {type = "item", name = "maraxsis-glass-panes", amount = 200},
            {type = "item", name = "tungsten-plate", amount = 50},
            {type = "item", name = "processing-unit", amount = 25},
            {type = "item", name = "maraxsis-trench-duct", amount = 1},
        },
        results = {
            {type = "item", name = "maraxsis-geothermal-generator", amount = 1},
        },
        auto_recycle = false,   -- do not create a standard recycling recipe
        categories = {"maraxsis-hydro-plant"},
        surface_conditions = maraxsis.surface_conditions(),
    },
    {   -- category for recipes craftable only via geothermal generator
        type = "recipe-category",
        name = "maraxsis-geothermal-generator"
    },
    {   -- sulfur recipe (taken from v1.34.51)
        type = "recipe",
        name = "maraxsis-geothermal-sulfur",
        enabled = false,
        hidden = true,
        hidden_in_factoriopedia = true,
        ingredients = {
            {type = "fluid", name = "maraxsis-supercritical-steam", amount = 100},
            {type = "fluid", name = "lava", amount = 100},
        },
        results = {
            {type = "item", name = "sulfur", amount = 2},
        },
        energy_required = 3,
        categories = {"maraxsis-geothermal-generator"},
        icon = "__maraxsis-classic__/graphics/migration/geothermal-sulfur.png",
        icon_size = 64,
        allow_productivity = true,
    }
}