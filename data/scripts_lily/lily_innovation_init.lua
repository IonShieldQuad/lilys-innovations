
if not mods.lilyinno then
    mods.lilyinno = {}
end

mods.lilyinno.checkVarsOK = function ()
    return Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilyinno_init_check"] == 1
end

script.on_init(function(newGame)
    if newGame then
        Hyperspace.playerVariables["mods_lilyinno_init_check"] = 1
    end
end)
