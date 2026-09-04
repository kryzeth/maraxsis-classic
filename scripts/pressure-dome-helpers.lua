local pressure_dome_helpers = {}

local octagon_size = 16.5
local check_size = octagon_size - 0.01

local DOME_POLYGON = {
    7, check_size,
    -7, check_size,
    -check_size, 7,
    -check_size, -7,
    -7, -check_size,
    7, -check_size,
    check_size, -7,
    check_size, 7,
}

local mobile_entities = {
    ["unit"] = true,
    ["spider-unit"] = true,
    ["car"] = true,
    ["spider-vehicle"] = true,
    ["cargo-wagon"] = true,
    ["fluid-wagon"] = true,
    ["locomotive"] = true,
    ["artillery-wagon"] = true,
    ["logistic-robot"] = true,
    ["construction-robot"] = true,
    ["combat-robot"] = true,
    ["character"] = true,
    ["segmented-unit"] = true,
    ["segment"] = true,
    ["spider-leg"] = true,
    ["fish"] = true,
    ["elevated-curved-rail-a"] = true,
    ["elevated-curved-rail-b"] = true,
    ["elevated-half-diagonal-rail"] = true,
    ["elevated-straight-rail"] = true,
}

local DOME_EXCLUDED_FROM_DISABLE = maraxsis_constants.DOME_EXCLUDED_FROM_DISABLE

-- Private helpers
-- By Pedro Gimeno, donated to the public domain
local function is_point_in_polygon(x, y)
    if x > octagon_size or x < -octagon_size or y > octagon_size or y < -octagon_size then
        return false
    end

    local x1, y1, x2, y2
    local len = #DOME_POLYGON
    x2, y2 = DOME_POLYGON[len - 1], DOME_POLYGON[len]
    local wn = 0

    for idx = 1, len, 2 do
        x1, y1 = x2, y2
        x2, y2 = DOME_POLYGON[idx], DOME_POLYGON[idx + 1]

        if y1 > y then
            if (y2 <= y) and (x1 - x) * (y2 - y) < (x2 - x) * (y1 - y) then
                wn = wn + 1
            end
        else
            if (y2 > y) and (x1 - x) * (y2 - y) > (x2 - x) * (y1 - y) then
                wn = wn - 1
            end
        end
    end

    return wn % 2 ~= 0 -- even/odd rule
end

local function get_four_corners(entity)
    local position = entity.position
    local x, y = position.x, position.y
    local collision_box = entity.prototype.collision_box
    local orientation = entity.orientation

    if entity.type == "straight-rail" then
        orientation = (orientation + 0.25) % 1
    elseif entity.type == "cliff" then
        collision_box = {
            left_top = {x = -2, y = -2},
            right_bottom = {x = 2, y = 2},
        }
    else -- expand the collision box to the actual tile size
        collision_box = {
            left_top = {
                x = math.floor(collision_box.left_top.x * 2) / 2,
                y = math.floor(collision_box.left_top.y * 2) / 2,
            },
            right_bottom = {
                x = math.ceil(collision_box.right_bottom.x * 2) / 2,
                y = math.ceil(collision_box.right_bottom.y * 2) / 2,
            },
        }
    end

    local left_top = collision_box.left_top
    local right_bottom = collision_box.right_bottom

    if orientation == 0 then
        return {
            {x = x + left_top.x,     y = y + left_top.y},
            {x = x + right_bottom.x, y = y + left_top.y},
            {x = x + right_bottom.x, y = y + right_bottom.y},
            {x = x + left_top.x,     y = y + right_bottom.y},
        }
    end

    local cos = math.cos(orientation * 2 * math.pi)
    local sin = math.sin(orientation * 2 * math.pi)

    local corners = {}

    for _, corner in pairs {
        {x = left_top.x,     y = left_top.y},
        {x = right_bottom.x, y = left_top.y},
        {x = right_bottom.x, y = right_bottom.y},
        {x = left_top.x,     y = right_bottom.y},
    } do
        local corner_x, corner_y = corner.x, corner.y

        corners[#corners + 1] = {
            x = x + corner_x * cos - corner_y * sin,
            y = y + corner_x * sin + corner_y * cos,
        }
    end

    return corners
end

local function create_dome_light(pressure_dome_data)
    local surface = pressure_dome_data.surface
    if not surface.valid then return end

    local light = surface.create_entity {
        name = "maraxsis-pressure-dome-lamp",
        position = pressure_dome_data.position,
        force = pressure_dome_data.force_index,
        quality = pressure_dome_data.quality,
        create_build_effect_smoke = false,
    }

    light.minable_flag = false
    light.destructible = false

    local control_behavior = light.get_or_create_control_behavior()
    control_behavior.use_colors = true

    pressure_dome_data.light = light
end

local function create_dome_combinator(pressure_dome_data)
    local light = pressure_dome_data.light

    if not light or not light.valid then
        create_dome_light(pressure_dome_data)
        light = pressure_dome_data.light
    end

    local combinator = light.surface.create_entity {
        name = "maraxsis-pressure-dome-combinator",
        position = light.position,
        force = light.force,
        quality = light.quality,
        create_build_effect_smoke = false,
    }

    combinator.minable_flag = false
    combinator.destructible = false
    combinator.operable = false

    local red = combinator.get_wire_connector(defines.wire_connector_id.circuit_red, true)
    local green = combinator.get_wire_connector(defines.wire_connector_id.circuit_green, true)
    local light_red = light.get_wire_connector(defines.wire_connector_id.circuit_red, false)
    local light_green = light.get_wire_connector(defines.wire_connector_id.circuit_green, false)

    local red_success = red.connect_to(light_red, false)
    local green_success = green.connect_to(light_green, false)

    assert(red_success, "Failed to connect red wire to the dome light. Please report this!")
    assert(green_success, "Failed to connect green wire to the dome light. Please report this!")

    pressure_dome_data.combinator = combinator
end

-- Shared helpers
local function count_points_in_dome(pressure_dome_data, entity)
    local dome_position = pressure_dome_data.position
    local x, y = dome_position.x, dome_position.y

    local count = 0

    for _, entity_corner in pairs(get_four_corners(entity)) do
        if is_point_in_polygon(entity_corner.x - x, entity_corner.y - y) then
            count = count + 1
        end
    end

    return count
end

local function update_combinator(pressure_dome_data)
    local combinator = pressure_dome_data.combinator

    if not combinator or not combinator.valid then
        create_dome_combinator(pressure_dome_data)
        combinator = pressure_dome_data.combinator
    end

    local all_machines_inside = {}

    for _, e in pairs(pressure_dome_data.contained_entities) do
        if e.valid then
            local quality = e.quality.name

            for _, item_to_place in pairs(e.prototype.items_to_place_this or {}) do
                all_machines_inside[item_to_place.name] = all_machines_inside[item_to_place.name] or {}

                all_machines_inside[item_to_place.name][quality] =
                    (all_machines_inside[item_to_place.name][quality] or 0) + 1
            end
        end
    end

    local control_behavior = combinator.get_or_create_control_behavior()

    if not control_behavior.get_section(1) then
        control_behavior.add_section()
    end

    local section = control_behavior.get_section(1)
    section.group = ""

    local parameters = {}

    for name, by_quality in pairs(all_machines_inside) do
        for quality, count in pairs(by_quality) do
            parameters[#parameters + 1] = {
                value = {
                    type = "item",
                    name = name,
                    quality = quality,
                },
                min = count,
                max = count,
            }
        end
    end

    section.filters = parameters
end

local function update_dome_minable_flag(pressure_dome_data)
    local minable_flag = true

    for _, entity in pairs(pressure_dome_data.contained_entities) do
        if entity.valid and not DOME_EXCLUDED_FROM_DISABLE[entity.name] then
            minable_flag = false
            break
        end
    end

    for _, collision_box in pairs(pressure_dome_data.collision_boxes) do
        if collision_box.valid then
            collision_box.minable_flag = minable_flag
        end
    end
end

--- Sorts all domes by y position and re-draws.
--- This prevents Z-fighting.
--- https://github.com/notnotmelon/maraxsis/issues/174
local function rerender_all_domes()
    local sorted_by_y_position = {}

    for _, pressure_dome_data in pairs(storage.pressure_domes) do
        table.insert(sorted_by_y_position, pressure_dome_data)
    end

    table.sort(sorted_by_y_position, function(a, b)
        return a.position.y < b.position.y
    end)

    storage.pressure_domes = {}

    for _, pressure_dome_data in pairs(sorted_by_y_position) do
        local surface = pressure_dome_data.surface

        if surface.valid then
            pressure_dome_data.entity.destroy()

            pressure_dome_data.opacity = pressure_dome_data.opacity or 255
            local opacity = pressure_dome_data.opacity

            local entity = rendering.draw_sprite {
                sprite = "maraxsis-pressure-dome-sprite",
                render_layer = "higher-object-above",
                target = pressure_dome_data.position,
                surface = pressure_dome_data.surface,
            }

            entity.color = {opacity, opacity, opacity, opacity}

            pressure_dome_data.entity = entity
            storage.pressure_domes[entity.id] = pressure_dome_data
        elseif pressure_dome_data.entity.valid then
            storage.pressure_domes[pressure_dome_data.entity.id] = nil
        end
    end
end

-- Public API

pressure_dome_helpers.octagon_size = octagon_size
pressure_dome_helpers.DOME_POLYGON = DOME_POLYGON
pressure_dome_helpers.mobile_entities = mobile_entities

pressure_dome_helpers.is_point_in_polygon = is_point_in_polygon
pressure_dome_helpers.count_points_in_dome = count_points_in_dome
pressure_dome_helpers.create_dome_light = create_dome_light
pressure_dome_helpers.update_combinator = update_combinator
pressure_dome_helpers.update_dome_minable_flag = update_dome_minable_flag
pressure_dome_helpers.rerender_all_domes = rerender_all_domes

return pressure_dome_helpers