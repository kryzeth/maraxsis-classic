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
    -- theoretically, if people update from 2.0 to 2.1 using Maraxsis Classic,
    -- this setting should end up disabled by default, just to reduce unnecessary prototypes
    {
        type = "bool-setting",
        name = "maraxsis-migration-mode",
        setting_type = "startup",
        hidden = true,
        default_value = false,
        forced_value = false,
        order = "d"
    },
}