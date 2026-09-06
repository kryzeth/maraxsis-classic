require "scripts.constants"
_G.maraxsis = {}
_G.maraxsis_constants = prototypes.mod_data["maraxsis-constants"].data
require "lib.lib"

require "scripts.map-gen.maraxsis"
require "scripts.map-gen.maraxsis-trench"
require "scripts.submarine"
require "scripts.nightvision"
require "scripts.pressure-dome"
require "scripts.swimming"
require "scripts.trench-duct"
require "scripts.abyssal-diving-gear"
require "scripts.remote"
require "scripts.fishing-tower"
require "scripts.drowning"
require "scripts.sonar"
require "scripts.sand-extractor"
require "scripts.salt-reactor"
-- migrate from old Maraxsis (v1.33.0 and below)
-- also rebuilds storage table from any versions of Maraxsis
require "scripts.migration-rebuild"
-- migrate from experimental versions of Maraxsis (v1.33.2+)
-- handles entities/items that did not exist in v1.33.0
require "scripts.migration-downgrade"

require "compat.call-plumber"

maraxsis.finalize_events()
