data:extend {
    {
        type = "bool-setting",
        name = "maraxsis-add-hydraulic-science",
        setting_type = "startup",
        default_value = true,
        order = "a"
    },
    {
        type = "double-setting",
        name = "maraxsis-water-opacity",
        setting_type = "startup",
        default_value = 255,
        minimum_value = 0,
        maximum_value = 255,
        order = "b"
    },
    {
        type = "bool-setting",
        name = "maraxsis-fish-rocket",
        setting_type = "startup",
        default_value = true,
        order = "c"
    },
    {
        type = "bool-setting",
        name = "maraxsis-migration-mode",
        setting_type = "startup",
        default_value = true,
        order = "d"
    },
    {
        type = "string-setting",
        name = "maraxsis-power-system",
        setting_type = "startup",
        default_value = "salt-reactor",
        allowed_values = {"salt-reactor", "geothermal-generator"},
        order = "e",
    },
    {
        type = "bool-setting",
        name = "maraxsis-runtime-entity-replacement",
        setting_type = "startup",
        default_value = true,
        order = "a",
        hidden = true,
        forced_value = true,
    }
}