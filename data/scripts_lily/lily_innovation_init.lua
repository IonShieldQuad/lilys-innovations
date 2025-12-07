
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

---Source: https://gist.github.com/cpeosphoros/0aa286c6b39c1e452d9aa15d7537ac95
mods.lilyinno.deepCopy = function(value, cache, promises, copies)
    cache    = cache or {}
    promises = promises or {}
    copies   = copies or {}
    local copy
    if type(value) == 'table' then
        if (cache[value]) then
            copy = cache[value]
        else
            promises[value] = promises[value] or {}
            copy = {}
            for k, v in next, value, nil do
                local nKey     = promises[k] or mods.lilyinno.deepCopy(k, cache, promises, copies)
                local nValue   = promises[v] or mods.lilyinno.deepCopy(v, cache, promises, copies)
                copies[nKey]   = type(k) == "table" and k or nil
                copies[nValue] = type(v) == "table" and v or nil
                copy[nKey]     = nValue
            end
            local mt = getmetatable(value)
            if mt then
                setmetatable(copy, mt.__immutable and mt or mods.lilyinno.deepCopy(mt, cache, promises, copies))
            end
            cache[value] = copy
        end
    else -- number, string, boolean, etc
        copy = value
    end
    for k, v in pairs(copies) do
        if k == cache[v] then
            copies[k] = nil
        end
    end
    local function correctRec(tbl)
        if type(tbl) ~= "table" then return tbl end
        if copies[tbl] and cache[copies[tbl]] then
            return cache[copies[tbl]]
        end
        local new = {}
        for k, v in pairs(tbl) do
            local oldK = k
            k, v = correctRec(k), correctRec(v)
            if k ~= oldK then
                tbl[oldK] = nil
                new[k] = v
            else
                tbl[k] = v
            end
        end
        for k, v in pairs(new) do
            tbl[k] = v
        end
        return tbl
    end
    correctRec(copy)
    return copy
end
return mods.lilyinno.deepCopy
