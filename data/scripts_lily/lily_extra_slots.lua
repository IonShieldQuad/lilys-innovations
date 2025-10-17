
local lastModifiedShipName = nil
local lastModifiedShipSlots = 0
local lastModifiedShipHull = 0
local loadComplete = false


---@param shipManager Hyperspace.ShipManager
local function resetLastBonus(shipManager)
    --print("RESET")
    if lastModifiedShipName then
        local def0 = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(lastModifiedShipName)
        if shipManager.myBlueprint.blueprintName == lastModifiedShipName then
            shipManager.ship.hullIntegrity.second = math.max(1, lastModifiedShipHull)
        end
        def0.systemLimit = lastModifiedShipSlots
        def0.hpCap = lastModifiedShipHull
        lastModifiedShipName = nil
        lastModifiedShipSlots = 0
        lastModifiedShipHull = 0
        --print("RESET DONE")
    end
end

---@param shipManager Hyperspace.ShipManager
---@param bonus integer
---@param load boolean
local function applySystemBonus(shipManager, bonus, applyPenalty, load)
    resetLastBonus(shipManager)
    if bonus ~= 0 then
        local def = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(shipManager.myBlueprint.blueprintName)
        lastModifiedShipName = shipManager.myBlueprint.blueprintName
        lastModifiedShipSlots = def.systemLimit
        lastModifiedShipHull = shipManager.ship.hullIntegrity.second --def.hpCap
        def.systemLimit = def.systemLimit + bonus
        if applyPenalty then
            shipManager.ship.hullIntegrity.second = math.max(1, math.ceil((lastModifiedShipHull * 2) / 3.0))
            shipManager.ship.hullIntegrity.first = math.min(shipManager.ship.hullIntegrity.first,
            shipManager.ship.hullIntegrity.second)
            def.hpCap = math.ceil((def.hpCap * 2) / 3.0)
        end
    end
    if not load then
        local def = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(shipManager.myBlueprint.blueprintName)
        Hyperspace.playerVariables["mods_lilyinno_systemslotbonus"] = bonus
        Hyperspace.playerVariables["mods_lilyinno_systemhullcap"] = def.hpCap
        --print("SET: ", bonus)
    end
end

script.on_init(function(newGame)
    --resetLastBonus()
    --local ok = Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilyinno_init_check"] == 1
    --print("OK: ", ok and true or false)
    loadComplete = false
end)


script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager and shipManager.iShipId == 0 then
        local ok = Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilyinno_init_check"] == 1
        --print("OKL: ", ok and true or false)

        if ok and not loadComplete then
            local bonus = Hyperspace.playerVariables["mods_lilyinno_systemslotbonus"]
            local def = Hyperspace.CustomShipSelect.GetInstance() and
            Hyperspace.CustomShipSelect.GetInstance():GetDefinition(shipManager.myBlueprint.blueprintName)
            if def then
                --print("BONUS: ", bonus)
                applySystemBonus(shipManager, bonus, true, true)
                --print("LOADED")
                loadComplete = true
            end
        end
    end
end)

script.on_game_event("LILYINNO_EXTRA_SYSSLOT", false, function()
    --print("EVENT")
    applySystemBonus(Hyperspace.ships.player, 1, true, false)
end)

