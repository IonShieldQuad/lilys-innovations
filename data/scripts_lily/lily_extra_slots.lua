
local lastModifiedShipName = nil
local lastModifiedShipValue = 0
local loadComplete = false

local function resetLastBonus()
    --print("RESET")
    if lastModifiedShipName then
        local def0 = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(lastModifiedShipName)
        def0.systemLimit = lastModifiedShipValue
        lastModifiedShipName = nil
        lastModifiedShipValue = 0
        --print("RESET DONE")
    end
end

---@param shipManager Hyperspace.ShipManager
---@param bonus integer
---@param load boolean
local function applySystemBonus(shipManager, bonus, load)
    resetLastBonus()
    if bonus ~= 0 then
        local def = Hyperspace.CustomShipSelect.GetInstance():GetDefinition(shipManager.myBlueprint.blueprintName)
        lastModifiedShipName = shipManager.myBlueprint.blueprintName
        lastModifiedShipValue = def.systemLimit
        def.systemLimit = def.systemLimit + bonus
    end
    if not load then
        Hyperspace.playerVariables["mods_lilyinno_systemslotbonus"] = bonus
        --print("SET: ", bonus)
    end
end

script.on_init(function (newGame)
    resetLastBonus()
    if newGame then
        Hyperspace.playerVariables["mods_lilyinno_init_check"] = 1
    end
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
            --print("BONUS: ", bonus)
            applySystemBonus(shipManager, bonus, true)
            --print("LOADED")
            loadComplete = true
        end
    end
end)

script.on_game_event("LILYINNO_EXTRA_SYSSLOT", false, function()
    --print("EVENT")
    applySystemBonus(Hyperspace.ships.player, 1, false)
end)

