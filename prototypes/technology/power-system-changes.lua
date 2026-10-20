-- early exit if geothermal generator is not enabled; default tech is salt reactor
if settings.startup["maraxsis-power-system"].value ~= "geothermal-generator" then return end

-- disable Classic salt reactor technology
data.raw.technology["maraxsis-salt-reactor"].hidden = true
data.raw.technology["maraxsis-salt-reactor"].enabled = false

-- enable Modern geothermal generator technology
data.raw.technology["maraxsis-geothermal-energy"].hidden = false
data.raw.technology["maraxsis-geothermal-energy"].enabled = true

-- replace prereq tech for wyrm confinement
local prerequisites = data.raw.technology["maraxsis-wyrm-confinement"].prerequisites
for i, name in ipairs(prerequisites) do
    if name == "maraxsis-salt-reactor" then
        prerequisites[i] = "maraxsis-geothermal-energy"
        break
    end
end
