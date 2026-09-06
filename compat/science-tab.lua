-- early exit script if Science Group mod is not enabled
if not mods["science-tab"] then return end

data.raw["item-subgroup"]["maraxsis-deepsea-research"].group = "science"
data.raw["item-subgroup"]["maraxsis-empty-research-vessel"].group = "science"
data.raw["item-subgroup"]["maraxsis-fill-research-vessel"].group = "science"