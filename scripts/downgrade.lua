-- Detects migration from any version of Modern back to Classic.
-- This info is only available during on_configuration_changed event.
local function get_migration_source_version(event)
    -- if no changes were made, simply return
    local mod_changes = event.mod_changes
    if not mod_changes then return end

    -- if Maraxsis did not exist when this save file was made, simply return
    local modern_maraxsis = mod_changes["maraxsis"]
    if not modern_maraxsis or not modern_maraxsis.old_version or modern_maraxsis.new_version
    then return end

    -- otherwise, return the previous version of Maraxsis in case of special handling
    return modern_maraxsis.old_version
end

maraxsis.on_event(maraxsis.events.on_init(), function(event)
    -- make sure this event only runs on configuration changed
    -- on_init does not return any event data
    if not event then return end

    local source_version = get_migration_source_version(event)
    if not source_version then return end

    -- store the version data in case we need to migrate something specific in future
    storage.migrated_from_maraxsis_version = source_version

    log("Maraxsis Classic migration: detected version of Modern Maraxsis " .. source_version)
end)