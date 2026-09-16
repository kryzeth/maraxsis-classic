require "scripts.constants"
_G.maraxsis = {}
_G.maraxsis_constants = prototypes.mod_data["maraxsis-constants"].data
require "lib.lib"

-- migrate storage cleanly between Classic and Modern branches
require "scripts.storage-migration"

require "scripts.map-gen.maraxsis"
require "scripts.map-gen.maraxsis-trench"
require "scripts.submarine"
require "scripts.nightvision"
require "scripts.pressure-dome"
require "scripts.trench-foundation"
require "scripts.nukes"
require "scripts.swimming"
require "scripts.trench-duct"
require "scripts.abyssal-diving-gear"
require "scripts.remote"
require "scripts.fishing-tower"
require "scripts.drowning"
require "scripts.sonar"
require "scripts.sand-extractor"
require "scripts.salt-reactor"
-- used for downgrading from modern/experimental versions of Maraxsis (v1.33.2+)
-- handles items and entities that did not exist in v1.33.0
require "scripts.downgrade"

require "compat.call-plumber"

maraxsis.finalize_events()
