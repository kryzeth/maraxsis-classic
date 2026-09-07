-- early exit script if Science Group mod is not enabled
if not mods["science-tab"] then return end

if mods["Krastorio2-spaced-out"] or mods["Krastorio2"] then
    data.raw["item-subgroup"]["kr-tech-cards-cooling"].group = "science"
else
    data.raw["item-subgroup"]["maraxsis-deepsea-research"].group = "science"
    data.raw["item-subgroup"]["maraxsis-empty-research-vessel"].group = "science"
    data.raw["item-subgroup"]["maraxsis-fill-research-vessel"].group = "science"
end