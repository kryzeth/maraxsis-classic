-- early exit script if migration mode is not enabled
if not settings.startup["maraxsis-migration-mode"].value then return end

-- moved all research vessel logic from separate files into one single file
local item_sounds = require("__base__.prototypes.item_sounds")
data:extend {
    {
        type = "item-subgroup",
        name = "maraxsis-empty-research-vessel",
        group = "intermediate-products",
        order = "gff",
    },
    {
        type = "item-subgroup",
        name = "maraxsis-fill-research-vessel",
        group = "intermediate-products",
        order = "gfff",
    },
    {
        type = "item",
        name = "maraxsis-empty-research-vessel",
        icon = "__maraxsis-classic__/graphics/icons/research-vessel-tipped.png",
        icon_size = 64,
        stack_size = 20,
        weight = 1000000 / 100,
        subgroup = "intermediate-product",
        order = "a[basic-intermediates]-d-b[empty-research-vessel]",
        default_import_location = "maraxsis",
        inventory_move_sound = item_sounds.metal_large_inventory_move,
        pick_sound = item_sounds.metal_large_inventory_pickup,
        drop_sound = item_sounds.metal_large_inventory_move,
        hidden = true,
        hidden_in_factoriopedia = true,
        auto_recycle = false,
    },
}

local science_pack_colors = {
    ["automation-science-pack"] = {212, 94, 94},
    ["logistic-science-pack"] = {105, 222, 109},
    ["military-science-pack"] = {100, 100, 100},
    ["chemical-science-pack"] = {112, 208, 237},
    ["production-science-pack"] = {190, 105, 238},
    ["utility-science-pack"] = {255, 202, 96},
    ["space-science-pack"] = {1, 1, 1},
    ["metallurgic-science-pack"] = {255, 172, 50},
    ["electromagnetic-science-pack"] = {242, 88, 182},
    ["agricultural-science-pack"] = {205, 246, 43},
    ["cryogenic-science-pack"] = {80, 105, 213},
    ["hydraulic-science-pack"] = {2, 147, 255},
    ["promethium-science-pack"] = {20, 20, 20},
    ["spoilage"] = {86, 110, 4},
}

local function science_pack_color(science_pack)
    if science_pack_colors[science_pack.name] then
        return science_pack_colors[science_pack.name]
    end

    science_pack_colors[science_pack.name] = {
        math.random(),
        math.random(),
        math.random(),
    }

    return science_pack_color(science_pack)
end

local function pressurize(science_pack_name)
    local science_pack = data.raw.item[science_pack_name]
    if not science_pack then return end

    if science_pack.spoil_result and science_pack.spoil_result ~= "spoilage" then
        return
    end

    local fill_name = "maraxsis-" .. science_pack_name .. "-research-vessel"
    if data.raw.item[fill_name] then return end

    local spoil_result
    if science_pack.spoil_result then
        spoil_result = "maraxsis-" .. science_pack.spoil_result .. "-research-vessel"
    end

    data:extend {{
        type = "item",
        name = fill_name,
        icons = {
            {
                icon = "__maraxsis-classic__/graphics/icons/research-vessel.png",
                icon_size = 64,
            },
            {
                icon = "__maraxsis-classic__/graphics/icons/research-vessel-mask.png",
                tint = science_pack_color(science_pack),
                icon_size = 64,
            },
        },
        stack_size = 20,
        localised_name = {
            "item-name.maraxsis-full-research-vessel",
            science_pack.localised_name or {"item-name." .. science_pack_name},
        },
        localised_description = {"item-description.maraxsis-full-research-vessel"},
        spoil_result = spoil_result,
        spoil_ticks = science_pack.spoil_ticks,
        spoil_to_trigger_result = science_pack.spoil_to_trigger_result,
        spoil_level = science_pack.spoil_level,
        default_import_location = science_pack.default_import_location,
        weight = 1000000 / 100,
        order = science_pack.order,
        inventory_move_sound = item_sounds.metal_large_inventory_move,
        pick_sound = item_sounds.metal_large_inventory_pickup,
        drop_sound = item_sounds.metal_large_inventory_move,
        subgroup = "maraxsis-fill-research-vessel",
        hidden = true,
        hidden_in_factoriopedia = true,
        auto_recycle = false,
    }}

    if science_pack.spoil_result == "spoilage" then
        pressurize("spoilage")
    end
end

for _, science_pack_name in pairs(data.raw.lab.biolab.inputs) do
    pressurize(science_pack_name)
end

local spoiled = data.raw.item["maraxsis-spoilage-research-vessel"]
local agricultural = data.raw.item["maraxsis-agricultural-science-pack-research-vessel"]

if spoiled and agricultural then
    spoiled.order = agricultural.order .. "z"
end