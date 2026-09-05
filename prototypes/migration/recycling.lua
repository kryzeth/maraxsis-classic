-- early exit script if migration mode is not enabled 
if not settings.startup["maraxsis-migration-mode"].value then return end

-- grab the original recipe and prepare to convert ingedients to results table
local recipe = data.raw.recipe["maraxsis-geothermal-generator"]
local item = data.raw.item["maraxsis-geothermal-generator"]
local results = {}

-- for each item ingredient in the recipe, store into results table
for _, ingredient in pairs(recipe.ingredients) do
    -- recycler cannot produce fluids, so we ignore them entirely
    if ingredient.type == "item" then
        results[#results + 1] = {
            type = "item",
            name = ingredient.name,
            amount = ingredient.amount
        }
    end
end

-- then manually generate new recycling recipe with original ingredients stored as results table
data:extend {{
    type = "recipe",
    name = "maraxsis-geothermal-generator-recycling",
    categories = {"recycling"},

    ingredients = {{
        type = "item",
        name = "maraxsis-geothermal-generator",
        amount = 1
    }},
    results = results,

    hidden = true,
    hidden_in_factoriopedia = true,

    -- disable various things on the recipe
    enabled = true,
    unlock_results = false,
    allow_decomposition = false,
    allow_productivity = false,
    auto_recycle = false,

    localised_name = {
        "recipe-name.recycling",
        {"item-name.maraxsis-geothermal-generator"}
    },

    -- make sure the icon uses the recycling outline around the item image
    icons = {
        {
            icon = "__recycler__/graphics/icons/recycling.png"
        },
        {
            icon = item.icon,
            icon_size = item.icon_size,
            scale = (0.5 * defines.constant.default_icon_size
                / (item.icon_size or defines.constant.default_icon_size)) * 0.8
        },
        {
            icon = "__recycler__/graphics/icons/recycling-top.png"
        },
    },

    -- short recycle time so we can get rid of them as reasonably quickly as possible
    energy_required = 0.5,
}}