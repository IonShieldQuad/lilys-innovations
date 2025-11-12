
if not mods.lilyinno then
    mods.lilyinno = {}
end

local time_increment = mods.multiverse.time_increment

mods.lilyinno.startOk = false
mods.lilyinno.startTimer = 0

mods.lilyinno.checkVarsOK = function ()
    return Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilyinno_init_check"] == 1
end

mods.lilyinno.checkStartOK = function()
    return mods.lilyinno.startOk
end

script.on_init(function(newGame)
    if newGame then
        Hyperspace.playerVariables["mods_lilyinno_init_check"] = 1
    end
    mods.lilyinno.startOk = false
    mods.lilyinno.startTimer = 0
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    
    --print("ok", mods.lilyinno.checkStartOK())
    --print("t", mods.lilyinno.startTimer.currTime)
    if shipManager and shipManager.iShipId == 0 and mods.lilyinno.checkVarsOK() and mods.lilyinno.startOk == false then
        mods.lilyinno.startTimer = (mods.lilyinno.startTimer or 0) + time_increment()

        if mods.lilyinno.startTimer > 0.5 then
            mods.lilyinno.startOk = true
        end
    end

end)