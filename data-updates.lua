require "prototypes.vanilla-changes"
require "prototypes.item-weight"
require "prototypes.default-import-location"
require "prototypes.item-sounds"
require "prototypes.entity.regulator-fluidbox"
require "prototypes.fluid-void"

require "prototypes.recipe.deepsea-research"

require "compat.aai-industry"
require "compat.aai-signal-transmission"
require "compat.editor-extensions"
require "compat.transport-ring-teleporter"
require "compat.quality-seeds"
require "compat.modules-t4"
require "compat.5-dim-automation"
require "compat.rcu-restored"
require "compat.aircraft-space-age"
require "compat.corrundum"
require "compat.aai-programmable-structures"
require "compat.science-tab"

local function try_add_barrel_fuel_value(fluid, value)
    fluid = data.raw.fluid[fluid]
    if not fluid then return end
    fluid.barrel_fuel_value = value
end

try_add_barrel_fuel_value("crude-oil", "300kJ")
try_add_barrel_fuel_value("petroleum-gas", "600kJ")
try_add_barrel_fuel_value("hydrogen", "450kJ")
try_add_barrel_fuel_value("heavy-oil", "500kJ")
try_add_barrel_fuel_value("light-oil", "600kJ")

for _, fluid in pairs(data.raw.fluid) do
    local fuel_value = fluid.fuel_value or fluid.barrel_fuel_value
    if not fuel_value or type(fuel_value) ~= "string" then goto continue end
    local barrel = data.raw.item[fluid.name .. "-barrel"]
    if not barrel then goto continue end

    local number_part, unit = fuel_value:match("^(%d+)(.*)")
    number_part = tonumber(number_part)
    if not number_part then goto continue end

    barrel.fuel_value = barrel.fuel_value or (tostring(number_part * 50 * 5) .. unit) -- 50 fluid per barrel, 5x multiplier as fluid fuel values are rather low
    barrel.fuel_categories = barrel.fuel_categories or {}
    PlanetsLib.rro.soft_insert(barrel.fuel_categories, "maraxsis-diesel")
    barrel.fuel_acceleration_multiplier = barrel.fuel_acceleration_multiplier or data.raw.item["rocket-fuel"].fuel_acceleration_multiplier
    barrel.fuel_top_speed_multiplier = barrel.fuel_top_speed_multiplier or data.raw.item["rocket-fuel"].fuel_top_speed_multiplier
    barrel.fuel_emissions_multiplier = barrel.fuel_emissions_multiplier or data.raw.item["rocket-fuel"].fuel_emissions_multiplier
    barrel.fuel_glow_color = barrel.fuel_glow_color or data.raw.item["rocket-fuel"].fuel_glow_color
    barrel.fuel_acceleration_multiplier_quality_bonus = barrel.fuel_acceleration_multiplier_quality_bonus or data.raw.item["rocket-fuel"].fuel_acceleration_multiplier_quality_bonus
    barrel.fuel_top_speed_multiplier_quality_bonus = barrel.fuel_top_speed_multiplier_quality_bonus or data.raw.item["rocket-fuel"].fuel_top_speed_multiplier_quality_bonus
    barrel.burnt_result = barrel.burnt_result or "barrel"

    ::continue::
end

local nightvision_to_extend = {}
for _, nightvision in pairs(data.raw["night-vision-equipment"]) do
    if nightvision.name == "ee-super-night-vision-equipment" then goto continue end

    local disabled = table.deepcopy(nightvision)
    disabled.take_result = nightvision.take_result or nightvision.name
    disabled.name = nightvision.name .. "-disabled"
    disabled.darkness_to_turn_on = 1
    disabled.localised_name = nightvision.localised_name or {"equipment-name." .. nightvision.name}

    disabled.localised_description = {"",
        nightvision.localised_description or {"?", {"", {"equipment-description." .. nightvision.name}, "\n"}, {"", {"item-description." .. nightvision.name}, "\n"}, ""},
        {"equipment-description.nightvision-disabled-underwater"}
    }

    nightvision_to_extend[#nightvision_to_extend + 1] = disabled

    ::continue::
end
data:extend(nightvision_to_extend)

data:extend {{
    type = "item-subgroup",
    name = "maraxsis-atmosphere-barreling",
    order = "ff",
    group = "intermediate-products",
}}

for recipe, category in pairs {
    ["empty-maraxsis-atmosphere-barrel"] = "chemistry",
    ["maraxsis-atmosphere-barrel"] = "chemistry",
    ["empty-maraxsis-liquid-atmosphere-barrel"] = "cryogenics",
    ["maraxsis-liquid-atmosphere-barrel"] = "cryogenics",
} do
    local recipe = data.raw.recipe[recipe]
    recipe.hidden_in_factoriopedia = false
    recipe.categories = {category}
    recipe.subgroup = "maraxsis-atmosphere-barreling"
end
data.raw.recipe["empty-maraxsis-atmosphere-barrel"].results[1].temperature = 25

require "prototypes.item-subgroups"

if mods["assembler-pipe-passthrough"] then
    appmod.blacklist["maraxsis-hydro-plant"] = true
    appmod.blacklist["maraxsis-hydro-plant-extra-module-slots"] = true
end

-- salt reactor localised description, only needed with quality enabled
if mods["quality"] then
    local electricity_description = {""}

    for _, quality in pairs(data.raw.quality) do
        if quality.hidden then goto continue end

        local quality_name = quality.localised_name or {"quality-name." .. quality.name}
        local quality_level = quality.level
        local fluid_amount = 50 * quality_level * quality_level + 50

        table.insert(electricity_description, {
            "recipe-description.molten-salt-quality-description",
            quality.name,
            quality_name,
            tostring(fluid_amount)
        })
        table.insert(electricity_description, "\n")
        ::continue::
    end

    electricity_description[#electricity_description] = nil
    electricity_description = maraxsis.shorten_localised_string(electricity_description)

    data.raw.recipe["molten-salt"].localised_description = {
        "recipe-description.molten-salt-quality",
        electricity_description
    }
end

-- regulator factoriopedia description

local function add_quality_factoriopedia_info(entity, factoriopedia_info)
    local factoriopedia_description

    for _, factoriopedia_info in pairs(factoriopedia_info or {}) do
        local header, factoriopedia_function = unpack(factoriopedia_info)
        local localised_string = {"", "[font=default-semibold]", header, "[/font]"}

        for _, quality in pairs(data.raw.quality) do
            if quality.hidden then goto continue end

            local quality_buff = factoriopedia_function(entity, quality)
            if type(quality_buff) ~= "table" then quality_buff = tostring(quality_buff) end
            table.insert(localised_string, {"", "\n[img=quality." .. quality.name .. "] ", {"quality-name." .. quality.name}, ": [font=default-semibold]", quality_buff, "[/font]"})
            ::continue::
        end

        if factoriopedia_description then
            factoriopedia_description[#factoriopedia_description + 1] = "\n\n"
            factoriopedia_description[#factoriopedia_description + 1] = maraxsis.shorten_localised_string(localised_string)
        else
            factoriopedia_description = localised_string
        end
    end

    entity.factoriopedia_description = maraxsis.shorten_localised_string(factoriopedia_description)
end

add_quality_factoriopedia_info(data.raw["roboport"]["maraxsis-regulator"], {
    {{"quality-tooltip.atmosphere-consumption"}, function(entity, quality_level)
        local consumption_per_second = maraxsis.atmosphere_consumption(quality_level)
        return tostring(consumption_per_second) .. "/s"
    end}
})
