local SOURCE_MOD = "maraxsis"

maraxsis.on_event(maraxsis.events.on_init(), function(event)
    -- make sure this event only runs on_init (first load)
    -- on_init does not return any event data
    if event then return end

    -- check for migrated storage data from our pre-defined source mod
    local migrated = storage._migrated and storage._migrated[SOURCE_MOD]
    if not migrated then return end

    -- then assign all of their storage data into our own storage table
    for key, value in pairs(migrated) do
        -- ignore migration data inherited from the source mod (no loops)
        if key ~= "_migrated" then
            storage[key] = value
        end
    end

    log("Maraxsis Classic migration: transferred runtime storage from Modern Maraxsis")
end)