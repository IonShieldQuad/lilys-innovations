
if not mods.lilyinno then
    mods.lilyinno = {}
end

mods.lilyinno.startOk = false
mods.lilyinno.startTimer = Hyperspace.TimerHelper(false)

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
end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    
    --print("ok", mods.lilyinno.checkStartOK())
    --print("t", mods.lilyinno.startTimer.currTime)
    if shipManager and shipManager.iShipId == 0 and mods.lilyinno.checkVarsOK() and mods.lilyinno.startOk == false then
        if not mods.lilyinno.startTimer:Running() then
            mods.lilyinno.startTimer.currTime = 0.0
            mods.lilyinno.startTimer:Start_Float(0.5)
        end

        mods.lilyinno.startTimer:Update()

        if mods.lilyinno.startTimer:Done() then
            mods.lilyinno.startOk = true
        end
    end

end)