-- early exit script if migration mode is not enabled
if not settings.startup["maraxsis-migration-mode"].value then return end

-- list of items to recycle and their constituent ingredients to recycle into
local recycling_items = {
    ["maraxsis-geothermal-generator"] = data.raw.recipe["maraxsis-geothermal-generator"].ingredients,
    ["maraxsis-empty-research-vessel"] = {
        {type = "item", name = "maraxsis-glass-panes", amount = 10},
        {type = "item", name = "steel-plate", amount = 10},
    },
}

-- add filled vessel variants to the list
for name in pairs(data.raw.item) do
    local science = name:match("^maraxsis%-(.+)%-research%-vessel$")
    if science and data.raw.item[science] then
        recycling_items[name] = {
            {type = "item", name = science, amount = 100},
            {type = "item", name = "maraxsis-empty-research-vessel", amount = 1},
        }
    end
end

-- creates perfectly efficient recycling recipe based on ingredients
local function add_recycling_recipe(item_name, ingredients)
    local item = data.raw.item[item_name]
    if not item then return end

    -- convert the original item ingredients into recipe results
    local results = {}
    for _, ingredient in pairs(ingredients) do
        if ingredient.type == "item" then
            results[#results + 1] = {
                type = "item",
                name = ingredient.name,
                amount = ingredient.amount,
            }
        end
    end

    -- create the recycling icon, preserving layered/tinted item icons
    local icons = {{icon = "__recycler__/graphics/icons/recycling.png"}}
    local item_icons = item.icons or {{icon = item.icon, icon_size = item.icon_size}}
    for _, source in pairs(item_icons) do
        local layer = table.deepcopy(source)
        local icon_size = layer.icon_size or item.icon_size or defines.constant.default_icon_size
        layer.scale = (layer.scale or 1) * (0.5 * defines.constant.default_icon_size / icon_size) * 0.8
        icons[#icons + 1] = layer
    end
    icons[#icons + 1] = {icon = "__recycler__/graphics/icons/recycling-top.png"}

    -- finally create the new recycling recipe
    data:extend {{
        type = "recipe",
        name = item_name .. "-recycling",
        categories = {"recycling"},
        ingredients = {{type = "item", name = item_name, amount = 1}},
        results = results,
        icons = icons,
        subgroup = item.subgroup or "intermediate-product",
        localised_name = {"recipe-name.recycling", item.localised_name or {"item-name." .. item_name}},
        energy_required = 0.5,
        enabled = true,
        hidden = true,
        hidden_in_factoriopedia = true,
        unlock_results = false,
        allow_decomposition = false,
        allow_productivity = false,
        auto_recycle = false,
    }}
end

-- for every legacy/migration mod item we have added to the list..
for item_name, ingredients in pairs(recycling_items) do
    add_recycling_recipe(item_name, ingredients)
end
