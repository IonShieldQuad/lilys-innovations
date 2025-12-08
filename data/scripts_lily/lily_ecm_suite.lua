local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment
mods.lilyinno.ecmsuite = {}
-- Find ID of a room at the given location
local function get_room_at_location(shipManager, location, includeWalls)
    return Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId):GetSelectedRoom(location.x, location.y, includeWalls)
end




-- written by kokoro
local function convertMousePositionToEnemyShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local position = combatControl.position
    local targetPosition = combatControl.targetPosition
    local enemyShipOriginX = position.x + targetPosition.x
    local enemyShipOriginY = position.y + targetPosition.y
    return Hyperspace.Point(mousePosition.x - enemyShipOriginX, mousePosition.y - enemyShipOriginY)
end

local function convertMousePositionToPlayerShipPosition(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

---@param orig Hyperspace.Point
---@return Hyperspace.Point
local function convertEnemyShipPositionToGlobalPosition(orig)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local position = combatControl.position
    local targetPosition = combatControl.targetPosition
    local enemyShipOriginX = position.x + targetPosition.x
    local enemyShipOriginY = position.y + targetPosition.y
    return Hyperspace.Point(orig.x + enemyShipOriginX, orig.y + enemyShipOriginY)
end

local function global_pos_to_player_pos(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

-- Returns a table where the indices are the IDs of all rooms adjacent to the given room
-- and the values are the rooms' coordinates
local function get_adjacent_rooms(shipId, roomId, diagonals)
    local shipGraph = Hyperspace.ShipGraph.GetShipInfo(shipId)
    local roomShape = shipGraph:GetRoomShape(roomId)
    local adjacentRooms = {}
    local currentRoom = nil
    local function check_for_room(x, y)
        currentRoom = shipGraph:GetSelectedRoom(x, y, false)
        if currentRoom > -1 and not adjacentRooms[currentRoom] then
            adjacentRooms[currentRoom] = Hyperspace.Pointf(x, y)
        end
    end
    for offset = 0, roomShape.w - 35, 35 do
        check_for_room(roomShape.x + offset + 17, roomShape.y - 17)
        check_for_room(roomShape.x + offset + 17, roomShape.y + roomShape.h + 17)
    end
    for offset = 0, roomShape.h - 35, 35 do
        check_for_room(roomShape.x - 17, roomShape.y + offset + 17)
        check_for_room(roomShape.x + roomShape.w + 17, roomShape.y + offset + 17)
    end
    if diagonals then
        check_for_room(roomShape.x - 17, roomShape.y - 17)
        check_for_room(roomShape.x + roomShape.w + 17, roomShape.y - 17)
        check_for_room(roomShape.x + roomShape.w + 17, roomShape.y + roomShape.h + 17)
        check_for_room(roomShape.x - 17, roomShape.y + roomShape.h + 17)
    end
    return adjacentRooms
end


--[[
local function vter(cvec)
    local i = -1
    local n = cvec:size()
    return function()
        i = i + 1
        if i < n then return cvec[i] end
    end
end
--]]



local vter = mods.multiverse.vter

local extraAnimations = {}
local rechargeTimer = {}
rechargeTimer[0] = 0
rechargeTimer[1] = 0
local loadComplete = {}
loadComplete[0] = false
loadComplete[1] = false


--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_ecm_suite(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite") then
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_disabled")
            end
            local maxlvl = Hyperspace.ships.player:GetSystem(systemId).healthState.second
            return string.format(Hyperspace.Text:GetText("tooltip_lily_ecm_suite_level"), tostring(maxlvl + 2),
                tostring(level <= 3 and (7.5 - level * 1.5) or (6 / (level - 1))))
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_ecm_suite_level"), tostring(level + 2),
            tostring(level <= 3 and (7.5 - level * 1.5) or (6 / (level - 1))))
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_ecm_suite)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_ecm_suite(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_ecm_suite" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_ecm_suite_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_ecm_suite" and not systemBox.bPlayerUI
end


local function get_button_tooltip_text(name)
    return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_button_" .. name)
end

---Returns the tooltip for jamming a given system
---@param system Hyperspace.ShipSystem?
---@return string tooltip
local function get_system_jamming_tooltip_text(system)
    if not system then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_misc")
    end
    local id = system:GetId()

    if id == Hyperspace.ShipSystem.NameToSystemId("shields") then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_shields")
    elseif id == Hyperspace.ShipSystem.NameToSystemId("weapons") then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_weapons")
    elseif id == Hyperspace.ShipSystem.NameToSystemId("artillery") then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_artillery")
    elseif id == Hyperspace.ShipSystem.NameToSystemId("drones") then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_drones")
    elseif id == Hyperspace.ShipSystem.NameToSystemId("oxygen") then
        return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_oxygen")
    end

    return Hyperspace.Text:GetText("tooltip_lily_ecm_suite_jammer_misc")
end

---Returns maximum number of charges the ECM system can hold
---@param shipManager Hyperspace.ShipManager
---@return integer maxCharges ranging from 0 to 8
local function get_max_ecm_charges(shipManager)
    if not shipManager then return 0 end
    local system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))
    if not system then return 0 end

    if not system:Functioning() == 0 then return 0 end

    return math.floor(math.max(0, math.min(8, system.healthState.first + 2 + (shipManager:HasAugmentation("UPG_LILY_ECM_CAPACITY") + shipManager:HasAugmentation("EX_LILY_ECM_CAPACITY")))))

end


---@enum selectmode
local selectmode = {
    none = 0,
    jammer = 1,
    electro = 2,

}

local abilities = {
    offdrones = 1,
    defdrones = 2,
    missiles = 3,
    counter = 4,
    jammer = 5,
    electro = 6,
    supercharge = 7,
    --supercharge_locked = "supercharge_locked",
}

---@alias abilities
---| "offdrones"
---| "defdrones"
---| "missiles"
---| "counter"
---| "jammer"
---| "electro"
---| "supercharge"

---@alias buttonNames
---| "offdrones"
---| "defdrones"
---| "missiles"
---| "counter"
---| "jammer"
---| "electro"
---| "supercharge"
---| "supercharge_locked"

-- -13, 64
local lily_ecm_suiteBaseOffset_x = 37      --35
local lily_ecm_suiteBaseOffset_y = -77     ---40
local lily_ecm_suiteButtonOffset_x = 37 + 8    --35
local lily_ecm_suiteButtonOffset_y = -77 + 8   ---40
local lily_ecm_suiteButtonOffset_x_2 = 26   --35
local lily_ecm_suiteButtonOffset_y_2 = 25 ---40

---@type table<buttonNames, Hyperspace.Point>
local buttonOffsets = {}
---@type table<buttonNames, Hyperspace.Button>
local buttons = {}

---@type table<buttonNames, Graphics.GL_Primitive>
local activeButtons = {}
---@type table<buttonNames, Graphics.GL_Primitive>
local cooldownButtons = {}
---@type table<buttonNames, Graphics.GL_Primitive>
local hoverButtons = {}

---@type table<string, Graphics.GL_Primitive>
local superchargebars = {}

---@type table<abilities, number>
local cooldownTimeDefaults =
{
    offdrones = 5,
    defdrones = 5,
    missiles = 10,
    counter = 10,
    jammer = 15,
    electro = 10,
    supercharge = 20,
}

---@type table<abilities, number>
local activationTimeDefaults =
{
    offdrones = 10,
    defdrones = 10,
    missiles = 5,
    counter = 20,
    jammer = 10,
    electro = 20,
    supercharge = 10,
}

---@type table<abilities, number>
local chargeCostDefaults =
{
    offdrones = 2,
    defdrones = 3,
    missiles = 2,
    counter = 1,
    jammer = 2,
    electro = 4,
    supercharge = 0,
}

---@type table<integer, string>
local powerUpSounds = {
    "lily_ecm_suite_power_up_1",
    "lily_ecm_suite_power_up_2",
    "lily_ecm_suite_power_up_3",
    "lily_ecm_suite_power_up_4",
    "lily_ecm_suite_power_up_5",
    "lily_ecm_suite_power_up_6",
    "lily_ecm_suite_power_up_7",
    "lily_ecm_suite_power_up_8",
    "lily_ecm_suite_power_up_9",
}

---@type table<integer, string>
local powerDownSounds = {
    "lily_ecm_suite_power_down_1",
    "lily_ecm_suite_power_down_2",
    "lily_ecm_suite_power_down_3",
}


---Gets current state of ability of ECM Suite for given ship
---@param shipManager Hyperspace.ShipManager
---@param ability abilities Name of the ability
---@return number 0 is ready/unactive, positive number are active duration in seconds, negative numbers are cooldown in seconds
mods.lilyinno.ecmsuite.getState = function(shipManager, ability)
    if not shipManager then return 0 end
    return userdata_table(shipManager, "mods.lilyinno.ecmsuite")[ability .. "State"] or 0
end

---Gets current states of all abilities of ECM Suite for given ship
---@param shipManager Hyperspace.ShipManager
---@return table<abilities, number> states 0 is ready/unactive, positive number are active duration in seconds, negative numbers are cooldown in seconds
mods.lilyinno.ecmsuite.getStateTable = function(shipManager)
    local states = {}
    for name, _ in pairs(abilities) do
        states[name] = mods.lilyinno.ecmsuite.getState(shipManager, name)
    end
    return states
end

---Sets current state of ability of ECM Suite for given ship
---@param shipManager Hyperspace.ShipManager
---@param ability abilities  Name of the ability
---@param value number 0 is ready/unactive, positive number are active duranion in seconds, negative numbers are cooldown in seconds
mods.lilyinno.ecmsuite.setState = function (shipManager, ability, value)
    if not shipManager then return 0 end
    userdata_table(shipManager, "mods.lilyinno.ecmsuite")[ability .. "State"] = value
end


---Resets state of ECM abilites of given ship
---@param shipManager Hyperspace.ShipManager
---@param resetCooldowns boolean Shound the cooldowns be reset or stay as they are?
---@param resetSupercharge boolean Should the supercharge ability be reset or left as is?
---@param forceCooldown boolean Shound the acrive abilities be forced to go on cooldown?
mods.lilyinno.ecmsuite.resetStates = function(shipManager, resetCooldowns, resetSupercharge, forceCooldown)
    ---@type table<abilities, number>
    local states = {}
    for name, _ in pairs(abilities) do
        states[name] = mods.lilyinno.ecmsuite.getState(shipManager, name)
    end
    for name, _ in pairs(abilities) do
        if _ ~= abilities.supercharge or resetSupercharge then
            if states[name] > 0 or resetCooldowns then
                if forceCooldown and not resetCooldowns and states[name] > 0 then
                    if _ == abilities.offdrones or _ == abilities.defdrones then
                        if (shipManager:HasAugmentation("UPG_LILY_ECM_ANTIDRONE") + shipManager:HasAugmentation("EX_LILY_ECM_ANTIDRONE") > 0) then
                            mods.lilyinno.ecmsuite.setState(shipManager, name, 0)
                        else
                            mods.lilyinno.ecmsuite.setState(shipManager, name, -cooldownTimeDefaults[name])
                        end
                    else
                        mods.lilyinno.ecmsuite.setState(shipManager, name, -cooldownTimeDefaults[name])
                    end
                else
                    mods.lilyinno.ecmsuite.setState(shipManager, name, 0)
                end
            end
        end
    end
end

---Updates the state of ECM abilites of given ship, for use in SHIP_LOOP
---@param shipManager Hyperspace.ShipManager
mods.lilyinno.ecmsuite.update = function(shipManager)
    ---@type table<abilities, number>
    local states = {}
    for name, _ in pairs(abilities) do
        states[name] = mods.lilyinno.ecmsuite.getState(shipManager, name)
    end
    local dt = time_increment()
    for name, state in pairs(states) do
        if state > 0 then
            if state - dt <= 0 then
                if (name =="offdrones" or name == "defdrones") and (shipManager:HasAugmentation("UPG_LILY_ECM_ANTIDRONE") + shipManager:HasAugmentation("UPG_LILY_ECM_ANTIDRONE") > 0) then
                    mods.lilyinno.ecmsuite.setState(shipManager, name, 0)
                else
                    mods.lilyinno.ecmsuite.setState(shipManager, name, -cooldownTimeDefaults[name] - (state - dt))
                end

                if not (Hyperspace.metaVariables.lily_ecm_suite_sounds_disabled and Hyperspace.metaVariables.lily_ecm_suite_sounds_disabled > 0) then
                    if name == "supercharge" then
                        Hyperspace.Sounds:PlaySoundMix("lily_ecm_suite_supercharge_down", -1, false)
                    else
                        Hyperspace.Sounds:PlaySoundMix(powerDownSounds[math.random(#powerDownSounds)], -1, false)
                    end
                end
            else
                mods.lilyinno.ecmsuite.setState(shipManager, name, state - dt)
            end
        end
        if state < 0 then
            mods.lilyinno.ecmsuite.setState(shipManager, name, math.min(0, state + dt))
        end
    end
end


---Sets the state of a given ability to active. Plays sounds / animations, substracts charges
---@param shipManager Hyperspace.ShipManager
---@param ability abilities Ability name
mods.lilyinno.ecmsuite.activateAbility = function(shipManager, ability)
    ---@type table<abilities, number>
    local states = {}
    for name, _ in pairs(abilities) do
        states[name] = mods.lilyinno.ecmsuite.getState(shipManager, name)
    end

    local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))
    local charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges or 0

    if sys and sys:Functioning() and states[ability] == 0 then
        local reqCharges = chargeCostDefaults[ability]
        local strength = 1
        if ability == "jammer" then
            while reqCharges + chargeCostDefaults[ability] <= charges do
                reqCharges = reqCharges + chargeCostDefaults[ability]
                strength = strength + 1
            end
        end
        if charges >= reqCharges then
            if ability == "supercharge" then
               mods.lilyinno.ecmsuite.resetStates(shipManager, false, false, true)
            end
            charges = charges - reqCharges
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = charges
            mods.lilyinno.ecmsuite.setState(shipManager, ability, activationTimeDefaults[ability])
            if ability == "jammer" then
                userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerStrength = strength
            end
            mods.lilyinno.ecmsuite.playAbilityEffects(shipManager, ability)
        end
    end
end

---Plays ability sounds / animations
---@param shipManager Hyperspace.ShipManager
---@param ability abilities Ability name
mods.lilyinno.ecmsuite.playAbilityEffects = function(shipManager, ability)
    if not (Hyperspace.metaVariables.lily_ecm_suite_sounds_disabled and Hyperspace.metaVariables.lily_ecm_suite_sounds_disabled > 0) then
        if ability == "supercharge" then
            Hyperspace.Sounds:PlaySoundMix("lily_ecm_suite_supercharge_up", -1, false)
        else
            Hyperspace.Sounds:PlaySoundMix(powerUpSounds[math.random(#powerUpSounds)], -1, false)
        end
    end

    local room = shipManager:GetSystemRoom(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))
    if ability ~= "supercharge" and room then
        local center = shipManager:GetRoomCenter(room)
        local anim = Hyperspace.Animations:GetAnimation("lily_ecm_wave")
        anim.position = Hyperspace.Pointf(center.x - anim.info.frameWidth / 2, center.y - anim.info.frameHeight / 2)
        anim:Start(false)
        table.insert(extraAnimations, { anim = anim, id = shipManager.iShipId })
    end
end

---Saves states of the system in player variables
---@param shipManager Hyperspace.ShipManager
mods.lilyinno.ecmsuite.saveStates = function(shipManager)
    if mods.lilyinno.checkVarsOK() then
        Hyperspace.playerVariables["mods_lilyinno_ecmsuite_charges_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
        (userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges or 0) + 1
        local states = mods.lilyinno.ecmsuite.getStateTable(shipManager)
        for name, value in pairs(states) do
            Hyperspace.playerVariables["mods_lilyinno_ecmsuite_state_" .. name .. "_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
                math.ceil(value * 100)
        end
        Hyperspace.playerVariables["mods_lilyinno_ecmsuite_jammertarget_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
        (userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerTargetroom or 0) + 1
        Hyperspace.playerVariables["mods_lilyinno_ecmsuite_jammerstrength_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
        (userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerStrength or 0) + 1
        Hyperspace.playerVariables["mods_lilyinno_ecmsuite_electrotarget_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
        (userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroTargetroom or 0) + 1
    end
end

---Loads states of the system from player variables
---@param shipManager Hyperspace.ShipManager
mods.lilyinno.ecmsuite.loadStates = function(shipManager)
    if mods.lilyinno.checkVarsOK() then
        local v = (Hyperspace.playerVariables["mods_lilyinno_ecmsuite_charges_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0)
        if v > 0 then
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = v - 1
        end
        for name, _ in pairs(abilities) do
            mods.lilyinno.ecmsuite.setState(shipManager, name,
            (Hyperspace.playerVariables["mods_lilyinno_ecmsuite_state_" .. name .. "_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0) / 100)
        end
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerTargetroom =
        (Hyperspace.playerVariables["mods_lilyinno_ecmsuite_jammertarget_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0) - 1
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerStrength =
        (Hyperspace.playerVariables["mods_lilyinno_ecmsuite_jammerstrength_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0) - 1
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroTargetroom =
        (Hyperspace.playerVariables["mods_lilyinno_ecmsuite_electrotarget_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0) - 1
    end
end


--Handles initialization of custom system box
local function lily_ecm_suite_construct_system_box(systemBox)
    if is_lily_ecm_suite(systemBox) then
        systemBox.extend.xOffset = 80

        buttonOffsets["offdrones"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 0,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 0)
        buttonOffsets["defdrones"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 1,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 0)
        buttonOffsets["missiles"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 0,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 1)
        buttonOffsets["counter"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 1,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 1)
        buttonOffsets["jammer"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 0,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 2)
        buttonOffsets["electro"] = Hyperspace.Point(
            lily_ecm_suiteButtonOffset_x + lily_ecm_suiteButtonOffset_x_2 * 1,
            lily_ecm_suiteButtonOffset_y + lily_ecm_suiteButtonOffset_y_2 * 2)
        buttonOffsets["supercharge"] = Hyperspace.Point(
            lily_ecm_suiteBaseOffset_x + 27,
            lily_ecm_suiteBaseOffset_y + 82)
        buttonOffsets["supercharge_locked"] = Hyperspace.Point(
            lily_ecm_suiteBaseOffset_x + 27,
            lily_ecm_suiteBaseOffset_y + 82)

        local activateButtonOffdrones = Hyperspace.Button()
        activateButtonOffdrones:OnInit("systemUI/lily_ecm_suite_button_offdrones",
            buttonOffsets["offdrones"])
        activateButtonOffdrones.hitbox.x = 1
        activateButtonOffdrones.hitbox.y = 1
        activateButtonOffdrones.hitbox.w = 20
        activateButtonOffdrones.hitbox.h = 19
        systemBox.table.activateButtonOffdrones = activateButtonOffdrones

        buttons["offdrones"] = activateButtonOffdrones

        local activateButtonDefdrones = Hyperspace.Button()
        activateButtonDefdrones:OnInit("systemUI/lily_ecm_suite_button_defdrones",
            buttonOffsets["defdrones"])
        activateButtonDefdrones.hitbox.x = 1
        activateButtonDefdrones.hitbox.y = 1
        activateButtonDefdrones.hitbox.w = 20
        activateButtonDefdrones.hitbox.h = 19
        systemBox.table.activateButtonDefdrones = activateButtonDefdrones

        buttons["defdrones"] = activateButtonDefdrones

        local activateButtonMissiles = Hyperspace.Button()
        activateButtonMissiles:OnInit("systemUI/lily_ecm_suite_button_missiles",
            buttonOffsets["missiles"])
        activateButtonMissiles.hitbox.x = 1
        activateButtonMissiles.hitbox.y = 1
        activateButtonMissiles.hitbox.w = 20
        activateButtonMissiles.hitbox.h = 19
        systemBox.table.activateButtonMissiles = activateButtonMissiles

        buttons["missiles"] = activateButtonMissiles

        local activateButtonCounter = Hyperspace.Button()
        activateButtonCounter:OnInit("systemUI/lily_ecm_suite_button_counter",
            buttonOffsets["counter"])
        activateButtonCounter.hitbox.x = 1
        activateButtonCounter.hitbox.y = 1
        activateButtonCounter.hitbox.w = 20
        activateButtonCounter.hitbox.h = 19
        systemBox.table.activateButtonCounter = activateButtonCounter

        buttons["counter"] = activateButtonCounter

        local activateButtonJammer = Hyperspace.Button()
        activateButtonJammer:OnInit("systemUI/lily_ecm_suite_button_jammer",
            buttonOffsets["jammer"])
        activateButtonJammer.hitbox.x = 1
        activateButtonJammer.hitbox.y = 1
        activateButtonJammer.hitbox.w = 20
        activateButtonJammer.hitbox.h = 19
        systemBox.table.activateButtonJammer = activateButtonJammer

        buttons["jammer"] = activateButtonJammer

        local activateButtonElectro = Hyperspace.Button()
        activateButtonElectro:OnInit("systemUI/lily_ecm_suite_button_electro",
            buttonOffsets["electro"])
        activateButtonElectro.hitbox.x = 1
        activateButtonElectro.hitbox.y = 1
        activateButtonElectro.hitbox.w = 20
        activateButtonElectro.hitbox.h = 19
        systemBox.table.activateButtonElectro = activateButtonElectro

        buttons["electro"] = activateButtonElectro

        local activateButtonSupercharge = Hyperspace.Button()
        activateButtonSupercharge:OnInit("systemUI/lily_ecm_suite_button_supercharge",
            buttonOffsets["supercharge"])
        activateButtonSupercharge.hitbox.x = 1
        activateButtonSupercharge.hitbox.y = 1
        activateButtonSupercharge.hitbox.w = 8
        activateButtonSupercharge.hitbox.h = 10
        systemBox.table.activateButtonSupercharge = activateButtonSupercharge

        buttons["supercharge"] = activateButtonSupercharge

        local activateButtonSuperchargeLocked = Hyperspace.Button()
        activateButtonSuperchargeLocked:OnInit("systemUI/lily_ecm_suite_button_supercharge_locked",
            buttonOffsets["supercharge_locked"])
        activateButtonSuperchargeLocked.hitbox.x = 1
        activateButtonSuperchargeLocked.hitbox.y = 1
        activateButtonSuperchargeLocked.hitbox.w = 8
        activateButtonSuperchargeLocked.hitbox.h = 10
        systemBox.table.activateButtonSupercharge = activateButtonSuperchargeLocked

        buttons["supercharge_locked"] = activateButtonSuperchargeLocked

        --active and cooldown button icons
        for name, _ in pairs(buttons) do
            if name ~= "supercharge" and name ~= "supercharge_locked" then
                activeButtons[name] = Hyperspace.Resources:CreateImagePrimitiveString(
                "systemUI/lily_ecm_suite_button_" .. name .. "_active.png", buttonOffsets[name].x, buttonOffsets[name].y,
                    0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
                cooldownButtons[name] = Hyperspace.Resources:CreateImagePrimitiveString(
                "systemUI/lily_ecm_suite_button_" .. name .. "_cooldown.png", buttonOffsets[name].x,
                    buttonOffsets[name].y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
                hoverButtons[name] = Hyperspace.Resources:CreateImagePrimitiveString(
                    "systemUI/lily_ecm_suite_button_" .. name .. "_select2.png", buttonOffsets[name].x,
                    buttonOffsets[name].y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
            end
        end

        --superchargebars
        superchargebars.on = Hyperspace.Resources:CreateImagePrimitiveString(
            "systemUI/lily_ecm_suite_button_supercharge_active.png",
            buttonOffsets["supercharge"].x, buttonOffsets["supercharge"].y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        superchargebars.off = Hyperspace.Resources:CreateImagePrimitiveString(
            "systemUI/lily_ecm_suite_button_supercharge_cooldown.png",
            buttonOffsets["supercharge"].x, buttonOffsets["supercharge"].y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)

    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, lily_ecm_suite_construct_system_box)

--Handles mouse movement
local function lily_ecm_suite_mouse_move(systemBox, x, y)
    if is_lily_ecm_suite(systemBox) then
        for name, activateButton in pairs(buttons) do
            activateButton:MouseMove(x - buttonOffsets[name].x, y - buttonOffsets[name].y,
                false)
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_MOVE, lily_ecm_suite_mouse_move)

local function lily_ecm_suite_click(systemBox, shift)
    if is_lily_ecm_suite(systemBox) then
        for name, activateButton in pairs(buttons) do
            ---@type Hyperspace.Button
            activateButton = activateButton
            local shipManager = Hyperspace.ships.player


            if activateButton.bHover and activateButton.bActive then
                local lily_ecm_suite_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                    "lily_ecm_suite"))
                if name ~= "supercharge_locked" then

                    ---@cast name abilities

                    if name ~= "jammer" and name ~= "electro" then
                        mods.lilyinno.ecmsuite.activateAbility(shipManager, name)
                    else
                        if name == "jammer" then
                            userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.jammer
                        elseif name == "electro" then
                            userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.electro
                        end
                    end
                end
            end
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_CLICK, lily_ecm_suite_click)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_R_BUTTON_DOWN, function(x, y)
    local shipManager = Hyperspace.ships.player
    userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.none
end)


--Utility function to see if the system is ready for use
local function lily_ecm_suite_ready(shipSystem)
    return shipSystem:Functioning() and shipSystem.iHackEffect <= 1
end

---@type table<integer, Graphics.GL_Primitive>
local buttonBase = {}
local lines =
{
    disabled = nil,
    off = nil,
    ---@type table<integer, Graphics.GL_Primitive>
    on = {}
}
local chargeimg =
{
    ---@type table<integer, Graphics.GL_Primitive>
    locked = {},
    ---@type table<integer, Graphics.GL_Primitive>
    empty = {},
    ---@type table<integer, Graphics.GL_Primitive>
    full = {},
    ---@type table<integer, Graphics.GL_Primitive>
    selected = {},
    ---@type table<integer, Graphics.GL_Primitive>
    error = {},
}
local chargebars =
{
    empty = nil,
    full = nil,
    super_empty = nil,
    super_full = nil,
}
---@type table<integer, Graphics.GL_Primitive>
local cooldownbars = {}
---@type table<integer, Graphics.GL_Primitive>
local durationbars = {}

---@type table<selectmode, Graphics.GL_Primitive>
local crosshairs = {}


script.on_init(function()
    --base box
    buttonBase[1] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/lily_ecm_suite_base.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    --lines
    lines.disabled = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/lily_ecm_suite_lines_disabled.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    lines.off = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/lily_ecm_suite_lines_off.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    for i = 1, 6, 1 do
        lines.on[i] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/lily_ecm_suite_lines_on_" .. i .. ".png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
    end

    --charges
    for i = 1, 8, 1 do
        chargeimg.locked[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_charge_" .. i .. "_locked.png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        chargeimg.empty[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_charge_" .. i .. "_empty.png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        chargeimg.full[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_charge_" .. i .. "_full.png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        chargeimg.selected[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_charge_" .. i .. "_select.png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        chargeimg.error[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_charge_" .. i .. "_error.png",
            lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
    end

    --chargebars
    chargebars.empty = Hyperspace.Resources:CreateImagePrimitiveString(
    "systemUI/lily_ecm_suite_chargebar_empty.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    chargebars.full = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_chargebar_full.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    chargebars.super_empty = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_chargebar_super_empty.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    chargebars.super_full = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/lily_ecm_suite_chargebar_super_full.png",
        lily_ecm_suiteBaseOffset_x, lily_ecm_suiteBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)



    --cooldownbars and durationbars
    for i = 1, 8, 1 do
        durationbars[i] = Hyperspace.Resources:CreateImagePrimitiveString(
            "systemUI/lily_ecm_suite_active_" .. i .. ".png",
            0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        cooldownbars[i] = Hyperspace.Resources:CreateImagePrimitiveString(
            "systemUI/lily_ecm_suite_cooldown_" .. i .. ".png",
            0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
            false)

    end

    crosshairs[selectmode.none] = Hyperspace.Resources:CreateImagePrimitiveString("",
        -20, -20, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    crosshairs[selectmode.jammer] = Hyperspace.Resources:CreateImagePrimitiveString("misc/crosshairs_placed_lily_ecm_suite_jammer.png",
        -20, -20, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    crosshairs[selectmode.electro] = Hyperspace.Resources:CreateImagePrimitiveString("misc/crosshairs_placed_lily_ecm_suite_electro.png",
        -20, -20, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)


    for i = 0, 1, 1 do
        loadComplete[i] = false
        --print("Loaded:", "mods_lilyinno_ecmsuite_" .. i,
        --    Hyperspace.metaVariables["mods_lilyinno_ecmsuite_" .. i])
    end
end)




script.on_render_event(Defines.RenderEvents.SHIP, function() end, function(ship)
    local commandGui = Hyperspace.App.gui
    for key, value in pairs(extraAnimations) do
        ---@type Hyperspace.Animation
        local anim = value.anim
        if anim and ship.iShipId == value.id then
            Graphics.CSurface.GL_PushMatrix()
            anim:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            if not (commandGui.bPaused or commandGui.event_pause or commandGui.menu_pause) then
                anim:Update()
            end
            if anim:Done() then
                table.remove(extraAnimations, key)
            end
            Graphics.CSurface.GL_PopMatrix()
        end
    end
end)

---Renders graphics for the room
---@param room Hyperspace.Room
---@param tileAnim? Hyperspace.Animation
---@---@param wallAnim? table<string, Hyperspace.Animation>
---@---@param roomIconImage? Graphics.GL_Primitive
local function render_room(room, tileAnim, wallAnim, roomIconImage)
    local opacity = 0.5
    local x = room.rect.x
    local y = room.rect.y
    local w = math.floor(room.rect.w / 35)
    local h = math.floor(room.rect.h / 35)
    local size = w * h
    --print("room:"..room.iRoomId.." gasLevel:"..gasLevel.." w:"..w.." h:"..h.." size:"..size)
    if tileAnim then

        for i = 0, size - 1 do
            local xOff = x + (i % w) * 35
            local yOff = y + math.floor(i / w) * 35
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(xOff, yOff, 0)
            tileAnim:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            --Graphics.CSurface.GL_RenderPrimitiveWithAlpha(tileImage, opacity)
            Graphics.CSurface.GL_PopMatrix()
        end
    end
    opacity = 1
    if wallAnim then
        -- top and bottom edge
        for i = 0, w - 1 do
            local xOff = x + i * 35
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(xOff, y, 0)
            wallAnim.up:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            --Graphics.CSurface.GL_RenderPrimitiveWithAlpha(wallImage.up, opacity)
            Graphics.CSurface.GL_PopMatrix()

            local yOff = y + (h - 1) * 35
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(xOff, yOff, 0)
            --Graphics.CSurface.GL_RenderPrimitiveWithAlpha(wallImage.down, opacity)
            wallAnim.down:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            Graphics.CSurface.GL_PopMatrix()
        end
        -- left and right edge
        for i = 0, h - 1 do
            local yOff = y + i * 35
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(x, yOff, 0)
            --Graphics.CSurface.GL_RenderPrimitiveWithAlpha(wallImage.left, opacity)
            wallAnim.left:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            Graphics.CSurface.GL_PopMatrix()

            local xOff = x + (w - 1) * 35
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(xOff, yOff, 0)
            --Graphics.CSurface.GL_RenderPrimitiveWithAlpha(wallImage.right, opacity)
            wallAnim.right:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            Graphics.CSurface.GL_PopMatrix()
        end
    end
    if roomIconImage then
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(x, y, 0)
        Graphics.CSurface.GL_RenderPrimitive(roomIconImage)
        Graphics.CSurface.GL_PopMatrix()
    end
end

script.on_render_event(Defines.RenderEvents.SHIP_BREACHES, function() end, function(ship)
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships(ship.iShipId)
    local otherShipManager = Hyperspace.ships(1 - ship.iShipId)

    if shipManager and otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
        local states = mods.lilyinno.ecmsuite.getStateTable(otherShipManager)
        if states["jammer"] > 0 then
            local room = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerTargetroom
            if room and room >= 0 then
                local anim = userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerAnim
                if not anim then
                    --local center = shipManager:GetRoomCenter(room)
                    --local center = {x = 0, y = 0}
                    --anim.position = Hyperspace.Pointf(center.x - anim.info.frameWidth / 2, center.y - anim.info.frameHeight / 2)
                    anim = {}
                    anim.up = Hyperspace.Animations:GetAnimation("lily_ecm_jamming_t")
                    anim.down = Hyperspace.Animations:GetAnimation("lily_ecm_jamming_b")
                    anim.left = Hyperspace.Animations:GetAnimation("lily_ecm_jamming_l")
                    anim.right = Hyperspace.Animations:GetAnimation("lily_ecm_jamming_r")
                    anim.up:Start(true)
                    anim.down:Start(true)
                    anim.left:Start(true)
                    anim.right:Start(true)
                    anim.up.tracker:SetLoop(true, 0)
                    anim.down.tracker:SetLoop(true, 0)
                    anim.left.tracker:SetLoop(true, 0)
                    anim.right.tracker:SetLoop(true, 0)
                    userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerAnim = anim
                end
                local animprim = {
                    up = anim.up.primitive,
                    down = anim.down.primitive,
                    left = anim.left.primitive,
                    right = anim.right.primitive,
                }
                if room >= 0 and room < ship.vRoomList:size() then
                    render_room(ship.vRoomList[room], nil, anim, nil)
                end
                anim.up:Update()
                anim.down:Update()
                anim.left:Update()
                anim.right:Update()
            end
        end
        if states["electro"] > 0 then
            local room = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").electroTargetroom
            if room and room >= 0 then
                local anim = userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroAnim
                if not anim then
                    --local center = shipManager:GetRoomCenter(room)
                    --local center = { x = 0, y = 0 }
                    --anim.position = Hyperspace.Pointf(center.x - anim.info.frameWidth / 2, center.y - anim.info.frameHeight / 2)
                    anim = Hyperspace.Animations:GetAnimation("lily_ecm_electro")
                    anim.tracker:SetLoop(true, 0)
                    anim:Start(true)
                    userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroAnim = anim
                end
                local animprim = anim.primitive
                animprim = Hyperspace.Resources:CreateImagePrimitiveString(
                    "effects_lily/ecm_electro.png", 0,
                    0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
                if room >= 0 and room < ship.vRoomList:size() then
                    render_room(ship.vRoomList[room], anim, nil, nil)
                end
                anim:Update()
            end
        end
    end
end)


---Renders charges needed to activate currrently hovered ability
---@param maxCharges integer maximum charges that the system can hold
---@param currCharges integer charges that the system currently has
---@param neededCharges integer charges required 
local function display_charges(maxCharges, currCharges, neededCharges)
    if neededCharges <= 0 then
        for i = 1, 8, 1 do
            if i <= currCharges then
                Graphics.CSurface.GL_RenderPrimitive(chargeimg.full[i])
            else
                if i > maxCharges then
                    Graphics.CSurface.GL_RenderPrimitive(chargeimg.locked[i])
                else
                    Graphics.CSurface.GL_RenderPrimitive(chargeimg.empty[i])
                end
            end
        end
    else
        local s = 1
        local e = 1
        if currCharges >= neededCharges then
            s = currCharges - neededCharges + 1
            e = currCharges
        else
            s = 1
            e = neededCharges
        end

        for i = 1, 8, 1 do
            if i < s or i > e then
                if i <= currCharges then
                    Graphics.CSurface.GL_RenderPrimitive(chargeimg.full[i])
                else
                    if i > maxCharges then
                        Graphics.CSurface.GL_RenderPrimitive(chargeimg.locked[i])
                    else
                        Graphics.CSurface.GL_RenderPrimitive(chargeimg.empty[i])
                    end
                end
            end
        end

        for i = s, e, 1 do
            if i <= currCharges then
                Graphics.CSurface.GL_RenderPrimitive(chargeimg.selected[i])
            else
                Graphics.CSurface.GL_RenderPrimitive(chargeimg.error[i])
            end
        end
    end
end


--Handles custom rendering
---@param systemBox Hyperspace.SystemBox
---@param ignoreStatus boolean
local function lily_ecm_suite_render(systemBox, ignoreStatus)
    if is_lily_ecm_suite(systemBox) then
        local shipManager = Hyperspace.ships.player
        local activateButtons = {}
        activateButtons[1] = buttons["offdrones"]
        activateButtons[2] = buttons["defdrones"]
        activateButtons[3] = buttons["missiles"]
        activateButtons[4] = buttons["counter"]
        activateButtons[5] = buttons["jammer"]
        activateButtons[6] = buttons["electro"]
        local superchargeUnlocked = false
        if shipManager and (shipManager:HasAugmentation("UPG_LILY_ECM_SUPERCHARGE") > 0 or shipManager:HasAugmentation("EX_LILY_ECM_SUPERCHARGE") > 0) then
            activateButtons[7] = buttons["supercharge"]
            superchargeUnlocked = true
        else
            activateButtons[7] = buttons["supercharge_locked"]
        end
        local lily_ecm_suite_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_ecm_suite"))

        local level = lily_ecm_suite_system.healthState.second

        --Render the base box
        Graphics.CSurface.GL_RenderPrimitive(buttonBase[1])

        ---@type integer
        local maxCharges = get_max_ecm_charges(shipManager)
        ---@type integer
        local charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges or 0
        local states = mods.lilyinno.ecmsuite.getStateTable(shipManager)
        local neededCharges = 0

        --[[
        if (shipManager:HasAugmentation("EX_DEFENSE_SCRAMBLER") > 0 or shipManager:HasAugmentation("UPG_TECH_SCRAMBLER") > 0) and states.defdrones <= 0 then
            states.defdrones = activationTimeDefaults.defdrones
        end
        --]]
        if shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 then
            states.offdrones = activationTimeDefaults.offdrones
            states.defdrones = activationTimeDefaults.defdrones
        end
        --]]

        --draw base lines
        if states["supercharge"] > 0 then
            Graphics.CSurface.GL_RenderPrimitive(lines.disabled)
        else
            Graphics.CSurface.GL_RenderPrimitive(lines.off)
        end

        --draw activation lines
        for name, _ in pairs(abilities) do
            if states[name] > 0 then
                Graphics.CSurface.GL_RenderPrimitive(lines.on[_])
            end
        end


        --make buttons active or inactive
        for name, button in pairs(buttons) do
            ---@type Hyperspace.Button
            button = button
            button.bActive = false
            if (name ~= "supercharge_locked" and name ~= "supercharge") and states["supercharge"] <= 0 and lily_ecm_suite_system:Functioning() then
                button.bActive = lily_ecm_suite_ready(lily_ecm_suite_system) and (charges >= chargeCostDefaults[name] and states[name] == 0)
            elseif (name == "supercharge" and superchargeUnlocked) and states["supercharge"] == 0 and lily_ecm_suite_system:Functioning() then
                button.bActive = lily_ecm_suite_ready(lily_ecm_suite_system)
            end
        end

        --draw buttons
        for _, button in ipairs(activateButtons) do
            ---@type Hyperspace.Button
            button = button


            if button.bHover then
                if _ == 1 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("offdrones")
                    neededCharges = chargeCostDefaults["offdrones"]
                elseif _ == 2 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("defdrones")
                    neededCharges = chargeCostDefaults["defdrones"]
                elseif _ == 3 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("missiles")
                    neededCharges = chargeCostDefaults["missiles"]
                elseif _ == 4 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("counter")
                    neededCharges = chargeCostDefaults["counter"]
                elseif _ == 5 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("jammer")
                    neededCharges = chargeCostDefaults["jammer"]
                    while neededCharges + chargeCostDefaults["jammer"] <= charges do
                        neededCharges = neededCharges + chargeCostDefaults["jammer"]
                    end
                elseif _ == 6 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_button_tooltip_text("electro")
                    neededCharges = chargeCostDefaults["electro"]
                elseif _ == 7 then
                    if superchargeUnlocked then
                        Hyperspace.Mouse.bForceTooltip = true
                        Hyperspace.Mouse.tooltip = get_button_tooltip_text("supercharge")
                    else
                        Hyperspace.Mouse.bForceTooltip = true
                        Hyperspace.Mouse.tooltip = get_button_tooltip_text("supercharge_locked")
                    end
                end
            end
            button:OnRender()
        end

        local mode = shipManager and
        (userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode or selectmode.none) or selectmode.none
        if mode == selectmode.jammer then
            if neededCharges == 0 then
                neededCharges = chargeCostDefaults["jammer"]
                while neededCharges + chargeCostDefaults["jammer"] <= charges do
                    neededCharges = neededCharges + chargeCostDefaults["jammer"]
                end
            end
            Graphics.CSurface.GL_RenderPrimitive(hoverButtons["jammer"])
        elseif mode == selectmode.electro then
            if neededCharges == 0 then
                neededCharges = chargeCostDefaults["electro"]
            end
            Graphics.CSurface.GL_RenderPrimitive(hoverButtons["electro"])
        end


        --draw button timers
        for name, _ in pairs(abilities) do
            if _ ~= abilities.supercharge then
                if states[name] > 0 then
                    ---@type number
                    local fraction = states[name] / activationTimeDefaults[name]
                    ---@type integer
                    local index = math.max(0, math.min(8, math.ceil(fraction * 8)))
                    Graphics.CSurface.GL_RenderPrimitive(activeButtons[name])
                    Graphics.CSurface.GL_Translate(buttonOffsets[name].x, buttonOffsets[name].y, 0)
                    Graphics.CSurface.GL_RenderPrimitive(durationbars[index])
                    Graphics.CSurface.GL_Translate(-buttonOffsets[name].x, -buttonOffsets[name].y, 0)
                elseif states[name] < 0 then
                    ---@type number
                    local fraction = -states[name] / cooldownTimeDefaults[name]
                    ---@type integer
                    local index = math.max(0, math.min(8, math.ceil(fraction * 8)))
                    Graphics.CSurface.GL_RenderPrimitive(cooldownButtons[name])
                    Graphics.CSurface.GL_Translate(buttonOffsets[name].x, buttonOffsets[name].y, 0)
                    Graphics.CSurface.GL_RenderPrimitive(cooldownbars[index])
                    Graphics.CSurface.GL_Translate(-buttonOffsets[name].x, -buttonOffsets[name].y, 0)
                end
            elseif superchargeUnlocked then
                if states[name] ~= 0 then
                    local maxHeight = 12
                    local width = 10
                    local progress = states[name] > 0 and (states[name] / activationTimeDefaults[name]) or (-states[name] / cooldownTimeDefaults[name])
                    progress = math.min(1, math.max(0, progress))
                    local height = math.ceil(progress * maxHeight)

                    ---@diagnostic disable-next-line: param-type-mismatch
                    Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_SET, 1, 1)
                    Graphics.CSurface.GL_DrawRect(buttonOffsets[name].x, buttonOffsets[name].y + maxHeight - height, width, height,
                    Graphics.GL_Color(1, 1, 1, 1))

                    ---@diagnostic disable-next-line: param-type-mismatch
                    Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_USE, 1, 1)
                        Graphics.CSurface.GL_RenderPrimitiveWithColor(states[name] > 0 and superchargebars.on or superchargebars.off,
                            Graphics.GL_Color(1, 1, 1, 1))

                    ---@diagnostic disable-next-line: param-type-mismatch
                    Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_IGNORE, 1, 1)
                end
            end
        end

        --draw charges
        display_charges(maxCharges, charges, neededCharges)

        --draw recharge bar base
        if states["supercharge"] > 0 then
            Graphics.CSurface.GL_RenderPrimitive(chargebars.super_empty)
        else
            Graphics.CSurface.GL_RenderPrimitive(chargebars.empty)
        end

        --draw recharge bar
        if rechargeTimer[0] < 1 then
            local maxWidth = 26
            local width = math.ceil(rechargeTimer[0] * maxWidth)
            local height = 5
            local offset_x = 19
            local offset_y = 93

            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_SET, 1, 1)
            Graphics.CSurface.GL_DrawRect(lily_ecm_suiteBaseOffset_x + offset_x, lily_ecm_suiteBaseOffset_y + offset_y, width, height, Graphics.GL_Color(1, 1, 1, 1))
            if width > 1 then
                Graphics.CSurface.GL_DrawRect(lily_ecm_suiteBaseOffset_x + offset_x - 2,
                lily_ecm_suiteBaseOffset_y + offset_y, 2, height, Graphics.GL_Color(1, 1, 1, 1))
            end
            if width > maxWidth - 1 then
                Graphics.CSurface.GL_DrawRect(lily_ecm_suiteBaseOffset_x + offset_x + maxWidth,
                    lily_ecm_suiteBaseOffset_y + offset_y, 2, height, Graphics.GL_Color(1, 1, 1, 1))
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_USE, 1, 1)
            if systemBox.pSystem.iHackEffect > 1 then
                if states["supercharge"] > 0 then
                    Graphics.CSurface.GL_RenderPrimitiveWithColor(chargebars.super_full, Graphics.GL_Color(0.75, 0.15, 1, 1))
                else
                    Graphics.CSurface.GL_RenderPrimitiveWithColor(chargebars.full, Graphics.GL_Color(0.75, 0.15, 1, 1))
                end
            else
                if states["supercharge"] > 0 then
                    Graphics.CSurface.GL_RenderPrimitiveWithColor(chargebars.super_full, Graphics.GL_Color(1, 1, 1, 1))
                else
                    Graphics.CSurface.GL_RenderPrimitiveWithColor(chargebars.full, Graphics.GL_Color(1, 1, 1, 1))
                end
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_IGNORE, 1, 1)
        end

    end
end
script.on_render_event(Defines.RenderEvents.SYSTEM_BOX,
    function(systemBox, ignoreStatus)
        return Defines.Chain.CONTINUE
    end, lily_ecm_suite_render)


local playerCursorRestore
local playerCursorRestoreInvalid

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player
    local mode = shipManager and (userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode or selectmode.none) or selectmode.none

    if shipManager and mode > 0 then
        if not playerCursorRestore then
            playerCursorRestore = Hyperspace.Mouse.validPointer
            playerCursorRestoreInvalid = Hyperspace.Mouse.invalidPointer
        end
        if mode == selectmode.jammer then
            Hyperspace.Mouse.validPointer = Hyperspace.Resources:GetImageId(
            "mouse/mouse_lily_ecm_suite_jammer_valid.png")
            Hyperspace.Mouse.invalidPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_ecm_suite_jammer.png")
        elseif mode == selectmode.electro then
            Hyperspace.Mouse.validPointer = Hyperspace.Resources:GetImageId(
            "mouse/mouse_lily_ecm_suite_electro_valid.png")
            Hyperspace.Mouse.invalidPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_ecm_suite_electro.png")
        end
    elseif playerCursorRestore then
        Hyperspace.Mouse.validPointer = playerCursorRestore
        Hyperspace.Mouse.invalidPointer = playerCursorRestoreInvalid
        playerCursorRestore = nil
        playerCursorRestoreInvalid = nil
    end
end)

script.on_render_event(Defines.RenderEvents.MOUSE_CONTROL, function()
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player
    local otherShipManager = Hyperspace.ships.enemy
    local mode = shipManager and (userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode or selectmode.none) or selectmode.none

    if shipManager and otherShipManager and mode > 0 and not (commandGui.event_pause or commandGui.menu_pause) then
        local mousePos = Hyperspace.Mouse.position
        local mousePosLocal = convertMousePositionToEnemyShipPosition(mousePos)
        local shipAtMouse = 0
        local roomAtMouse = -1

        local combatControl = Hyperspace.App.gui.combatControl
        --print("MOUSE POS X:"..mousePos.x.." Y:"..mousePos.y.." LOCAL X:"..mousePosLocal.x.." Y:"..mousePosLocal.y)
        roomAtMouse = get_room_at_location(otherShipManager, mousePosLocal, true)
        if roomAtMouse >= 0 then
            shipAtMouse = 1
        end
        Hyperspace.Mouse.valid = (shipAtMouse > 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and
        combatControl.selectedRoom > -1 and otherShipManager and otherShipManager:GetSystemInRoom(roomAtMouse)) and true or false
        --print(shipAtMouse .. " " .. roomAtMouse)
        if (shipAtMouse > 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and
            combatControl.selectedRoom > -1 and otherShipManager and otherShipManager:GetSystemInRoom(roomAtMouse)) and true or false then
            local targetPosition = convertEnemyShipPositionToGlobalPosition(Hyperspace.Point(0, 0))
            local roomc = otherShipManager:GetRoomCenter(roomAtMouse)
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(targetPosition.x, targetPosition.y, 0)
            Graphics.CSurface.GL_Translate(roomc.x, roomc.y, 0)
            Graphics.CSurface.GL_RenderPrimitive(crosshairs[mode])
            Graphics.CSurface.GL_PopMatrix()
            if mode == selectmode.jammer then
                Hyperspace.Mouse.tooltip = get_system_jamming_tooltip_text(otherShipManager:GetSystemInRoom(roomAtMouse))
            end
        end
    end
end, function() end)

---Click on a room to select it
---@param shipManager Hyperspace.ShipManager
---@param roomId integer
---@param mode selectmode
local function selectRoom(shipManager, roomId, mode)
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    if (not mode or mode == selectmode.none) or (not otherShipManager) or roomId == -1 or roomId >= otherShipManager.ship.vRoomList:size() then
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerTargetroom = nil
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroTargetroom = nil
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.none
    else
        if mode == selectmode.jammer then
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").jammerTargetroom = roomId
        elseif mode == selectmode.electro then
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroTargetroom = roomId
        end
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.none
    end
    return userdata_table(shipManager, "mods.lilyinno.ecmsuite").targetroom
end


script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
        local lily_ecm_suite_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_ecm_suite"))


        if not userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges then
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = 0
        end
        local charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges

        local level = lily_ecm_suite_system.healthState.second
        local level2 = lily_ecm_suite_system.healthState.first
        local efflevel = lily_ecm_suite_system:GetEffectivePower()

        ---@type integer
        local maxCharges = get_max_ecm_charges(shipManager)

        Hyperspace.playerVariables["mods_lilyinno_ecmsuite_asb_disabled"] = 0

        mods.lilyinno.ecmsuite.resetStates(shipManager, true, true, false)

        charges = math.floor(math.max(0, maxCharges / 2))
        userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = charges

        rechargeTimer[0] = 0
        rechargeTimer[1] = 0
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player
    local otherShipManager = Hyperspace.ships.enemy
    local mode = shipManager and (userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode or selectmode.none) or
    selectmode.none

    if shipManager and otherShipManager and mode > 0 and not (commandGui.event_pause or commandGui.menu_pause) then
        local mousePos = Hyperspace.Mouse.position
        local mousePosLocal = convertMousePositionToEnemyShipPosition(mousePos)
        local shipAtMouse = 0
        local roomAtMouse = -1
        --print("MOUSE POS X:"..mousePos.x.." Y:"..mousePos.y.." LOCAL X:"..mousePosLocal.x.." Y:"..mousePosLocal.y)
        local combatControl = Hyperspace.App.gui.combatControl
        roomAtMouse = get_room_at_location(otherShipManager, mousePosLocal, true)
        if roomAtMouse >= 0 then
            shipAtMouse = 1
        end
        --print(shipAtMouse .. " " .. roomAtMouse)
        --print("Count: " .. count)
        local charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges
        local reqcharges = (mode == selectmode.jammer and math.max(chargeCostDefaults["jammer"], chargeCostDefaults["jammer"] * math.floor(charges / chargeCostDefaults["jammer"])) or chargeCostDefaults["electro"])
        if ((shipAtMouse > 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and
                combatControl.selectedRoom > -1 and otherShipManager and otherShipManager:GetSystemInRoom(roomAtMouse)) and true or false) and charges >= reqcharges then
            selectRoom(shipManager, roomAtMouse, mode)
            if mode == selectmode.jammer then
                mods.lilyinno.ecmsuite.activateAbility(shipManager, "jammer")
            elseif mode == selectmode.electro then
                mods.lilyinno.ecmsuite.activateAbility(shipManager, "electro")
            end
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").selectmode = selectmode.none
        end
    end
    return Defines.Chain.CONTINUE
end)


script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
        local lily_ecm_suite_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))


        --if lily_ecm_suite_system:CompletelyDestroyed() then
        --    rechargeTimer[shipManager.iShipId] = 0
        --end

        if not userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges then
            userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = 0
        end
        local charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges
        charges = math.floor(charges)
        ---@cast charges integer

        local states = mods.lilyinno.ecmsuite.getStateTable(shipManager)

        lily_ecm_suite_system.bBoostable = false
        local level = lily_ecm_suite_system.healthState.second
        local level2 = lily_ecm_suite_system.healthState.first
        local efflevel = lily_ecm_suite_system:GetEffectivePower()
        local multiplier = 1 / (efflevel <= 3 and (7.5 - efflevel * 1.5) or (6 / (efflevel - 1)))
        if efflevel == 0 then
            multiplier = 0
        end

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_ecm_suite = level
        end

        if shipManager:HasAugmentation("UPG_LILY_ECM_JAMMER_FIELD") > 0 or shipManager:HasAugmentation("EX_LILY_ECM_JAMMER_FIELD") > 0 then
            multiplier = multiplier * 0.75
        end
        if shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 then
            multiplier = multiplier * 1.25
        end

        if states["supercharge"] > 0 then
            multiplier = multiplier * 2
        end
        
        ---@type integer
        local maxCharges = get_max_ecm_charges(shipManager)



        if mods.lilyinno.checkVarsOK() and not loadComplete[shipManager.iShipId] then
            mods.lilyinno.ecmsuite.loadStates(shipManager)
            charges = userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges
            states = mods.lilyinno.ecmsuite.getStateTable(shipManager)
            loadComplete[shipManager.iShipId] = true
        end

        charges = math.max(0, math.min(8, charges))

        if lily_ecm_suite_system.iHackEffect == 1 then
            multiplier = multiplier * 0.75
        end
        if lily_ecm_suite_system.iHackEffect > 1 then
            multiplier = -0.5
        end
        if charges > maxCharges then
            multiplier = -2
        end


        if not mods.lilyinno.checkVarsOK() then
            multiplier = 0
        end

        if (charges >= maxCharges and multiplier >= 0) or (charges == 0 and multiplier < 0) then
            multiplier = 0
            rechargeTimer[shipManager.iShipId] = 0
        end

        if charges > 0 and multiplier < 0 then
            if rechargeTimer[shipManager.iShipId] <= 0 then
                rechargeTimer[shipManager.iShipId] = 1
                charges = charges - 1
            end
        end

        --print("maxcharges", maxCharges)
        --print("functioning", lily_ecm_suite_system:Functioning())
        --print("powerStateFirst", lily_ecm_suite_system.powerState.first)
        --print("charges", charges)
        --print("multiplier", multiplier)
        --print("timer", rechargeTimer[shipManager.iShipId])

        rechargeTimer[shipManager.iShipId] = math.max(0, math.min(1, rechargeTimer[shipManager.iShipId] + multiplier * Hyperspace.FPS.SpeedFactor / 16))
        if rechargeTimer[shipManager.iShipId] >= 1 and multiplier > 0 and charges < maxCharges then
            charges = charges + 1
            rechargeTimer[shipManager.iShipId] = 0
            Hyperspace.Sounds:PlaySoundMix("lily_ecm_suite_recharge", -1, false)
        end

        userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = charges

        if charges >= maxCharges then
            mods.lilyinno.ecmsuite.setState(shipManager, "supercharge", math.min(0.01, states["supercharge"]))
        end

        if not lily_ecm_suite_system:Functioning() then
            mods.lilyinno.ecmsuite.resetStates(shipManager, false, true, true)
        end

        if lily_ecm_suite_system.iHackEffect > 1 and states.counter <= 0 then
            mods.lilyinno.ecmsuite.resetStates(shipManager, false, true, true)
        end

        local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)

        if mods.lilyinno.checkVarsOK() then
            mods.lilyinno.ecmsuite.update(shipManager)
        end


        if states.offdrones > 0 or shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 then
            local spaceManager = Hyperspace.App.world.space
            for drone in vter(spaceManager.drones) do
                ---@cast drone Hyperspace.SpaceDrone
                local isHackingDrone = otherShipManager and otherShipManager.hackingSystem and
                    otherShipManager.hackingSystem.drone.currentLocation == drone.currentLocation and
                    otherShipManager.hackingSystem.drone.arrived
                if drone and drone.deployed and not isHackingDrone and drone.iShipId ~= shipManager.iShipId and drone.currentSpace == shipManager.iShipId then
                    drone.targetLocation = Hyperspace.Pointf(math.random(-1000, 1000), math.random(-1000, 1000))
                    drone.destinationLocation = drone.destinationLocation + Hyperspace.Pointf(math.random(-50, 50), math.random(-50, 50))
                    drone.pointTarget = Hyperspace.Pointf(math.random(-1000, 1000), math.random(-1000, 1000))
                    drone.current_angle = math.random() * 360

                    --if drone.powered then
                    --    drone:SetPowered(false)
                    --    otherShipManager.droneSystem:ForceDecreasePower(drone:GetRequiredPower())
                    --
                end
            end
        end
        if states.defdrones > 0 or shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 then
            if shipManager:HasAugmentation("LILY_ECM_TMP_SCRAMBLER") + shipManager:HasAugmentation("HIDDEN LILY_ECM_TMP_SCRAMBLER") < 1 then
                shipManager:AddAugmentation("HIDDEN LILY_ECM_TMP_SCRAMBLER")
            end

            local spaceManager = Hyperspace.App.world.space
            for drone in vter(spaceManager.drones) do
                ---@cast drone Hyperspace.SpaceDrone
                local isHackingDrone = otherShipManager and otherShipManager.hackingSystem and
                    otherShipManager.hackingSystem.drone.currentLocation == drone.currentLocation and
                otherShipManager.hackingSystem.drone.arrived
                if drone and drone.deployed and drone.iShipId ~= shipManager.iShipId and drone.currentSpace ~= shipManager.iShipId and not drone:GetBoardingDrone() and not isHackingDrone then
                    drone.targetLocation = Hyperspace.Pointf(math.random(-1000, 1000), math.random(-1000, 1000))
                    drone.destinationLocation = drone.destinationLocation + Hyperspace.Pointf(math.random(-50, 50), math.random(-50, 50))
                    drone.pointTarget = Hyperspace.Pointf(math.random(-1000, 1000), math.random(-1000, 1000))
                    drone.current_angle = math.random() * 360
                    drone.additionalPause = math.max(15, drone.additionalPause)
                    --drone:SetWeaponTarget(drone._targetable)
                    --drone.weaponCooldown = 0
                    --if drone.powered then
                    --    drone:SetPowered(false)
                    --    otherShipManager.droneSystem:ForceDecreasePower(drone:GetRequiredPower())
                    --end
                end
            end
        else
            if shipManager:HasAugmentation("LILY_ECM_TMP_SCRAMBLER") + shipManager:HasAugmentation("HIDDEN LILY_ECM_TMP_SCRAMBLER") > 0 then
                shipManager:RemoveAugmentation("HIDDEN LILY_ECM_TMP_SCRAMBLER")
                shipManager:RemoveAugmentation("LILY_ECM_TMP_SCRAMBLER")
            end
        end
        if states.missiles > 0 then
            local spaceManager = Hyperspace.App.world.space
            for proj in vter(spaceManager.projectiles) do
                ---@cast proj Hyperspace.Projectile
                if proj and proj.ownerId ~= shipManager.iShipId and proj.currentSpace == shipManager.iShipId and proj.destinationSpace == shipManager.iShipId then
                    if not (proj:GetType() == 2 or proj:GetType() == 4 or proj:GetType() == 5) then
                        local missileconfirmed = --[[proj:GetType() == 3 or--]] proj:GetType() == 6
                        local blueprint = Hyperspace.Blueprints:GetWeaponBlueprint(proj.extend.name)
                        if not missileconfirmed then
                            missileconfirmed = blueprint.missiles > 0
                        end
                        if not missileconfirmed then
                            missileconfirmed = proj.damage.iShieldPiercing > 2 and proj:GetType() == 3
                        end
                        if not missileconfirmed then
                            local recyclers = Hyperspace.Blueprints:GetBlueprintList("LIST_CHECK_RECYCLER")
                            for name in vter(recyclers) do
                                ---@cast name string
                                if blueprint.name == name then
                                    missileconfirmed = true
                                end
                            end
                        end
                        if not missileconfirmed then
                            local list = Hyperspace.Blueprints:GetBlueprintList("BLUELIST_MISSILES_ALL")
                            for name in vter(list) do
                                ---@cast name string
                                if blueprint.name == name then
                                    missileconfirmed = true
                                end
                            end
                        end
                        if not missileconfirmed then
                            local list = Hyperspace.Blueprints:GetBlueprintList("BLUELIST_MINELAUNCHERS_ALL")
                            for name in vter(list) do
                                ---@cast name string
                                if blueprint.name == name then
                                    missileconfirmed = true
                                end
                            end
                        end

                        if missileconfirmed then
                            --print("Missile!")
                            if shipManager:HasAugmentation("UPG_LILY_ECM_RETARGET") > 0 or shipManager:HasAugmentation("EX_LILY_ECM_RETARGET") > 0 then
                                local returnShip = otherShipManager
                                local pType = blueprint.typeName
                                if returnShip and not (proj.death_animation and proj.death_animation.tracker.running) then
                                    if proj:GetType() == 3 then
                                        local missile = spaceManager:CreateMissile(
                                            blueprint,
                                            proj.position,
                                            proj.currentSpace,
                                            (1 - proj.ownerId),
                                            returnShip:GetRandomRoomCenter(),
                                            proj.ownerId,
                                            proj.heading)
                                    end
                                    if proj:GetType() == 1 then
                                        local missile = spaceManager:CreateLaserBlast(
                                            blueprint,
                                            proj.position,
                                            proj.currentSpace,
                                            (1 - proj.ownerId),
                                            returnShip:GetRandomRoomCenter(),
                                            proj.ownerId,
                                            proj.heading)
                                    end
                                    if proj:GetType() == 6 and ((shipManager.ship:GetSelectedRoomId(proj.target.x, proj.target.y, true) > -1) or shipManager:HasAugmentation("UPG_LILY_ECM_ASB_SCRAMBLER") > 0 or shipManager:HasAugmentation("EX_LILY_ECM_ASB_SCRAMBLER") > 0 or shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0) then
                                        local missile = spaceManager:CreatePDSFire(
                                            blueprint,
                                            Hyperspace.Point(math.floor(proj.position.x), math.floor(proj.position.y)),
                                            returnShip:GetRandomRoomCenter(),
                                            returnShip.iShipId,
                                            false)
                                    end
                                end
                                proj:Kill()
                            else
                                if (not (proj.death_animation and proj.death_animation.tracker.running)) and (not (proj.extend and proj.extend.customDamage and proj.extend.customDamage.accuracyMod < -100)) then
                                    if math.random() > 0.5 then
                                        proj.death_animation:Start(true)
                                        Hyperspace.Sounds:PlaySoundMix(proj.hitSolidSound, -1, false)
                                        print("Boom!")
                                    else
                                        proj.extend.customDamage.accuracyMod = -200
                                        local theta = math.random() * 2 * math.pi
                                        proj.target.x = proj.target.x + 100 * math.cos(theta)
                                        proj.target.y = proj.target.y + 100 * math.sin(theta)
                                        print("Woosh!")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        --[[local enemyECM = otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))
        local enemyHacking = otherShipManager.hackingSystem
        local enemyMind = otherShipManager.mindSystem
        if enemyHacking then
            print(enemyHacking.effectTimer.first, enemyHacking.effectTimer.second)
        end
        if enemyMind then
            print(enemyMind.controlTimer.first, enemyMind.controlTimer.second)
        end--]]
        if states.counter > 0 and otherShipManager then
            local enemyECM = otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite"))
            local enemyHacking = otherShipManager.hackingSystem
            local enemyMind = otherShipManager.mindSystem
            --[[if enemyHacking then
                print(enemyHacking.effectTimer.first, enemyHacking.effectTimer.second)
            end
            if enemyMind then
                print(enemyMind.controlTimer.first, enemyMind.controlTimer.second)
            end--]]
            if enemyHacking and enemyHacking:Functioning() and enemyHacking.effectTimer and enemyHacking.effectTimer.first < enemyHacking.effectTimer.second - 0.01 and charges >= 3 then
                charges = charges - 3
                enemyHacking.effectTimer.first = enemyHacking.effectTimer.second - 0.01
                enemyHacking:ForceDecreasePower(enemyHacking.healthState.first)
                mods.lilyinno.ecmsuite.playAbilityEffects(shipManager, "counter")
            end
            if enemyMind and enemyMind:Functioning() and enemyMind.controlTimer and enemyMind.controlTimer.first < enemyMind.controlTimer.second - 0.01 and charges >= 2 then
                charges = charges - 2
                enemyMind.controlTimer.first = enemyMind.controlTimer.second - 0.01
                enemyMind:ForceDecreasePower(enemyMind.healthState.first)
                mods.lilyinno.ecmsuite.playAbilityEffects(shipManager, "counter")
            end
            if enemyECM then
                local enemyStates = mods.lilyinno.ecmsuite.getStateTable(otherShipManager)
                for ability, value in pairs(enemyStates) do
                    if value > 0 and ability ~= "counter" and ability ~= "supercharge" then
                        if ability == "jammer" then
                            local strength = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerStrength or 1
                            if charges >= chargeCostDefaults[ability] * strength then
                                mods.lilyinno.ecmsuite.setState(otherShipManager, ability, 0.01)
                                charges = charges - chargeCostDefaults[ability] * strength
                                mods.lilyinno.ecmsuite.playAbilityEffects(shipManager, "counter")
                            end
                        else
                            if charges >= chargeCostDefaults[ability] then
                                mods.lilyinno.ecmsuite.setState(otherShipManager, ability, 0.01)
                                charges = charges - chargeCostDefaults[ability]
                                mods.lilyinno.ecmsuite.playAbilityEffects(shipManager, "counter")
                            end
                        end
                    end
                end
            end
        end
        if states.electro > 0 and otherShipManager then
            local targetroom = userdata_table(shipManager, "mods.lilyinno.ecmsuite").electroTargetroom or -1
            if targetroom >= 0 then
                local sys = otherShipManager:GetSystemInRoom(targetroom)
                if sys and sys.iLockCount > 0 then
                    sys.lockTimer.currTime = sys.lockTimer.currTime - 0.5 * time_increment()
                end
            end
        end


        userdata_table(shipManager, "mods.lilyinno.ecmsuite").charges = math.floor(charges)

        if mods.lilyinno.checkVarsOK() and loadComplete[shipManager.iShipId] then
            mods.lilyinno.ecmsuite.saveStates(shipManager)
        end
    end


    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    if otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and mods.lilyinno.ecmsuite.getState(otherShipManager, "jammer") > 0 then
        local targetroom = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerTargetroom or -1
        local strength = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerStrength or 1
        local system = shipManager:GetSystemInRoom(targetroom)
        if system then
            local id = system:GetId()
            local limitby = 0

            if id == Hyperspace.ShipSystem.NameToSystemId("shields") then
                limitby = 0
            elseif id == Hyperspace.ShipSystem.NameToSystemId("weapons") then
                limitby = 0
            elseif id == Hyperspace.ShipSystem.NameToSystemId("artillery") then
                limitby = strength * 2
            elseif id == Hyperspace.ShipSystem.NameToSystemId("drones") then
                limitby = strength * 2
            elseif id == Hyperspace.ShipSystem.NameToSystemId("oxygen") then
                limitby = math.min(strength, system.healthState.second - 1)
            else
                if system.healthState.second >= 3 then
                    limitby = math.min(strength, system.healthState.second - 1)
                else
                    limitby = strength
                end
            end

            if (mods.lilyinno.ecmsuite.getState(otherShipManager, "jammer") - time_increment()) <= 0 then
                limitby = 0
            end

            system.extend.additionalPowerLoss = system.extend.additionalPowerLoss + limitby
            system:CheckMaxPower()
            system:CheckForRepower()
        end
    end
end)


script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(shipManager, augment, value)
    if augment == "SHIELD_RECHARGE" or augment == "AUTO_COOLDOWN" or augment == "ION_ARMOR" then

        local otherShipManager = shipManager ~= nil and Hyperspace.ships(1 - shipManager.iShipId) or nil

        if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
            if augment == "DEFENSE_SCRAMBLER" and mods.lilyinno.ecmsuite.getState(shipManager, "defdrones") > 0 then
                value = value + 1
            end
        end

        if augment == "SHIELD_RECHARGE" and otherShipManager and otherShipManager:HasAugmentation("BOON_LILY_ECM_SUITE") > 0 then
            value = value - 0.2
        end
        if augment == "AUTO_COOLDOWN" and otherShipManager and otherShipManager:HasAugmentation("BOON_LILY_ECM_SUITE") > 0 then
            value = value - 0.1
        end


        if otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
            if augment == "ION_ARMOR" and otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (otherShipManager:HasAugmentation("UPG_LILY_ECM_ELECTRO_FIELD") > 0 or otherShipManager:HasAugmentation("EX_LILY_ECM_ELECTRO_FIELD") > 0) then
                value = value - 0.5
            end
            if augment == "ION_ARMOR" and otherShipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 then
                value = value - 0.5
            end


            if mods.lilyinno.ecmsuite.getState(otherShipManager, "jammer") > 0 then
                --print("jamming")
                local targetroom = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerTargetroom or -1
                local strength = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerStrength or 1
                local system = shipManager:GetSystemInRoom(targetroom)
                if system then
                    local id = system:GetId()

                    if id == Hyperspace.ShipSystem.NameToSystemId("shields") and augment == "SHIELD_RECHARGE" then
                        --print("shields")
                        value = value + 1
                        for i = 1, strength, 1 do
                            value = value * 0.70
                        end
                        value = value - 1
                        --print(value)
                    elseif id == Hyperspace.ShipSystem.NameToSystemId("weapons") and augment == "AUTO_COOLDOWN" then
                        --print("weapons")
                        value = value + 1
                        for i = 1, strength, 1 do
                            value = value * 0.75
                        end
                        value = value - 1
                        --print(value)
                    end
                end
            end

            if augment == "SHIELD_RECHARGE" and otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (otherShipManager:HasAugmentation("UPG_LILY_ECM_JAMMER_FIELD") > 0 or otherShipManager:HasAugmentation("EX_LILY_ECM_JAMMER_FIELD") > 0) then
                value = value - 0.2
            end
            if augment == "AUTO_COOLDOWN" and otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (otherShipManager:HasAugmentation("UPG_LILY_ECM_JAMMER_FIELD") > 0 or otherShipManager:HasAugmentation("EX_LILY_ECM_JAMMER_FIELD") > 0) then
                value = value - 0.15
            end

        end
    end
    return Defines.Chain.CONTINUE, value
end)

---@diagnostic disable-next-line: undefined-field
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, function(crew, stat, def, amount, value)
    ---@cast crew Hyperspace.CrewMember
    ---@cast stat Hyperspace.CrewStat
    if crew:IsDrone() and crew.iShipId ~= crew.currentShipId and mods.lilyinno.checkStartOK() then
        local shipManager = Hyperspace.ships(crew.iShipId)
        local otherShipManager = Hyperspace.ships(1 - crew.iShipId)

        if shipManager and otherShipManager then
            if otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
                if otherShipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 or mods.lilyinno.ecmsuite.getState(otherShipManager, "offdrones") > 0 then
                    if stat == Hyperspace.CrewStat.NO_AI then
                        value = true
                    elseif stat == Hyperspace.CrewStat.CONTROLLABLE then
                        value = false
                    elseif stat == Hyperspace.CrewStat.CAN_FIGHT then
                        value = false
                    elseif stat == Hyperspace.CrewStat.CAN_MOVE then
                        value = false
                    elseif stat == Hyperspace.CrewStat.CAN_SABOTAGE then
                        value = false
                    elseif stat == Hyperspace.CrewStat.CAN_REPAIR then
                        value = false
                    elseif stat == Hyperspace.CrewStat.SILENCED then
                        value = true
                    end
                end
            end
        end
    end
    return Defines.Chain.CONTINUE, amount, value
end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    if projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (otherShipManager:HasAugmentation("UPG_LILY_ECM_JAMMER_FIELD") > 0 or otherShipManager:HasAugmentation("EX_LILY_ECM_JAMMER_FIELD") > 0) then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 10
            end
            if otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and (otherShipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0) then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 15
            end

            if otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
                if mods.lilyinno.ecmsuite.getState(otherShipManager, "jammer") > 0 then
                    local targetroom = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerTargetroom or -1
                    local strength = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerStrength or 1
                    local system = shipManager:GetSystemInRoom(targetroom)
                    if system then
                        local id = system:GetId()

                        if id == Hyperspace.ShipSystem.NameToSystemId("artillery") then
                            projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 10 * strength
                        elseif id == Hyperspace.ShipSystem.NameToSystemId("weapons") then
                            projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 5 * strength
                        end
                    end
                end
            end
        end
    end
end, 64)

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, spacedrone)
    if projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (otherShipManager:HasAugmentation("UPG_LILY_ECM_JAMMER_FIELD") > 0 or otherShipManager:HasAugmentation("EX_LILY_ECM_JAMMER_FIELD") > 0) then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 10
            end
            if otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and (otherShipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0) then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod - 15
            end

            if otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) then
                if mods.lilyinno.ecmsuite.getState(otherShipManager, "jammer") > 0 then
                    local targetroom = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerTargetroom or -1
                    local strength = userdata_table(otherShipManager, "mods.lilyinno.ecmsuite").jammerStrength or 1
                    local system = shipManager:GetSystemInRoom(targetroom)
                    if system then
                        local id = system:GetId()

                        if id == Hyperspace.ShipSystem.NameToSystemId("drones") then
                            projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod -
                            10 * strength
                        end
                    end
                end
            end
        end
    end
end, 64)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_INITIALIZE, function(projectile)
    local destination = projectile.destinationSpace
    local ship = Hyperspace.ships(destination)
    if ship and (ship:HasAugmentation("AUG_LILY_ULTRA_ECM") > 0 or (ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")):Functioning() and (ship:HasAugmentation("UPG_LILY_ECM_ASB_SCRAMBLER") > 0 or ship:HasAugmentation("EX_LILY_ECM_ASB_SCRAMBLER") > 0))) and projectile:GetType() == 6 and projectile.destinationSpace == ship.iShipId then
        projectile.target = Hyperspace.Pointf(-400, projectile.target.y)
        projectile:ComputeHeading()
    end
end)

mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")] = mods.multiverse
    .register_system_icon("lily_ecm_suite")



