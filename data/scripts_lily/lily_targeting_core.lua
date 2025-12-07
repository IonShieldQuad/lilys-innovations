local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment


local defNOCTRL = Hyperspace.StatBoostDefinition()
defNOCTRL.stat = Hyperspace.CrewStat.CONTROLLABLE
defNOCTRL.value = false
defNOCTRL.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOCTRL.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOCTRL.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOCTRL.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOCTRL.duration = 99
defNOCTRL.priority = 9999
defNOCTRL.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOCTRL)

local defNOTGT = Hyperspace.StatBoostDefinition()
defNOTGT.stat = Hyperspace.CrewStat.VALID_TARGET
defNOTGT.value = false
defNOTGT.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOTGT.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOTGT.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOTGT.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOTGT.duration = 99
defNOTGT.priority = 9999
defNOTGT.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOTGT)

local defNOAI = Hyperspace.StatBoostDefinition()
defNOAI.stat = Hyperspace.CrewStat.NO_AI
defNOAI.value = true
defNOAI.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOAI.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOAI.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOAI.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOAI.duration = 99
defNOAI.priority = 9999
defNOAI.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOAI)

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


local activationTimer = {}
activationTimer[0] = 1
activationTimer[1] = 1
local sfxPlayed = true
local loadComplete = {}
--loadComplete[0] = false
--loadComplete[1] = false

local skillTimers = {}
skillTimers[0] = Hyperspace.TimerHelper(true)
skillTimers[1] = Hyperspace.TimerHelper(true)

--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_targeting_core(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core") then
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_system_disabled") .. "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_targeting_core_manning")
            end
            return string.format(Hyperspace.Text:GetText("tooltip_lily_targeting_core_level"), tostring(level + 1)) ..
                "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_targeting_core_manning")
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_targeting_core_level"), tostring(level + 1))
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_targeting_core)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_targeting_core(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_targeting_core" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_targeting_core_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_targeting_core" and not systemBox.bPlayerUI
end


local lily_targeting_coreButtonOffset_x = 35  --35
local lily_targeting_coreButtonOffset_y = -49 ---40
--Handles initialization of custom system box
local function lily_targeting_core_construct_system_box(systemBox)
    if is_lily_targeting_core(systemBox) then
        systemBox.extend.xOffset = 54
        local activateButton = Hyperspace.Button()
        activateButton:OnInit("systemUI/button_neutralizer2",
            Hyperspace.Point(lily_targeting_coreButtonOffset_x, lily_targeting_coreButtonOffset_y))
        activateButton.hitbox.x = 11
        activateButton.hitbox.y = 36
        activateButton.hitbox.w = 20
        activateButton.hitbox.h = 30
        systemBox.table.activateButton = activateButton
    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, lily_targeting_core_construct_system_box)

--Handles mouse movement
local function lily_targeting_core_mouse_move(systemBox, x, y)
    if is_lily_targeting_core(systemBox) then
        local activateButton = systemBox.table.activateButton
        activateButton:MouseMove(x - lily_targeting_coreButtonOffset_x, y - lily_targeting_coreButtonOffset_y,
            false)
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_MOVE, lily_targeting_core_mouse_move)

local function lily_targeting_core_click(systemBox, shift)
    if is_lily_targeting_core(systemBox) then
        local activateButton = systemBox.table.activateButton
        if activateButton.bHover and activateButton.bActive then
            local shipManager = Hyperspace.ships.player
            local lily_targeting_core_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_targeting_core"))
            userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = true
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_CLICK, lily_targeting_core_click)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_R_BUTTON_DOWN, function(x, y)
    local shipManager = Hyperspace.ships.player
    userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
end)

local lastKeyDown = nil


script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_KEY_DOWN, function(systemBox, key, shift)
    if Hyperspace.metaVariables.lily_targeting_core_hotkey_enabled == 0 and ((not lastKeyDown) or lastKeyDown ~= key) and is_lily_targeting_core(systemBox) then
        lastKeyDown = key
        --print("press key:"..key.." shift:"..tostring(shift))
        local shipManager = Hyperspace.ships.player
        if not Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) then return end
        if key == 105 then
            if activationTimer[1] >= 1 then
                userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = true
            end
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(key)
    lastKeyDown = nil
end)


--Utility function to see if the system is ready for use
local function lily_targeting_core_ready(shipSystem)
    return not shipSystem:GetLocked() and shipSystem:Functioning() and shipSystem.iHackEffect <= 1
end

local buttonBase
local crosshair
local roomEffect
local roomEffect2
local roomEffectLoading = {}
local buttonCharging
local buttonChargingTex
script.on_init(function()
    buttonBase = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_cloaking2_base.png",
        lily_targeting_coreButtonOffset_x, lily_targeting_coreButtonOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    crosshair = Hyperspace.Resources:CreateImagePrimitiveString("misc/crosshairs_placed_lily_targeting_core.png",
        -20, -20, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    buttonCharging = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_cloaking2_charging_on.png",
        lily_targeting_coreButtonOffset_x, lily_targeting_coreButtonOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    buttonChargingTex = Hyperspace.Resources:GetImageId("systemUI/button_cloaking2_charging_on.png")

    roomEffect = Hyperspace.Resources:CreateImagePrimitiveString("misc/lily_target_mark.png",
        -18, -18, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    roomEffect2 = Hyperspace.Resources:CreateImagePrimitiveString("misc/lily_target_mark_2.png",
        -18, -18, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

    for i = 1, 12, 1 do
        roomEffectLoading[i] = Hyperspace.Resources:CreateImagePrimitiveString("misc/lily_targeting_".. i ..".png",
            -18, -18, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    end

    activationTimer[0] = 1
    activationTimer[1] = 1
    sfxPlayed = true

    for i = 0, 1, 1 do
        loadComplete[i] = false
        --print("LOAD:", i, Hyperspace.metaVariables["mods_lilyinno_targetingcore_" .. i])
        --print("mods_lilyinno_targetingcore_" .. i)
    end
    --print("Loaded:", loadValues[0])
end)

--Handles custom rendering
local function lily_targeting_core_render(systemBox, ignoreStatus)
    if is_lily_targeting_core(systemBox) then
        local activateButton = systemBox.table.activateButton
        local shipManager = Hyperspace.ships.player
        local otherShipManager = Hyperspace.ships.enemy
        local lily_targeting_core_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
        "lily_targeting_core"))
        activateButton.bActive = (not lily_targeting_core_system:CompletelyDestroyed()) and
            (activationTimer[shipManager.iShipId] >= 1) and (otherShipManager and otherShipManager._targetable.hostile) and true or false

        if activateButton.bHover then
            if activateButton.bActive then
                if Hyperspace.metaVariables.lily_targeting_core_hotkey_enabled == 0 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = string.format(Hyperspace.Text:GetText("tooltip_lily_targeting_core_button"), "I")
                    
                else
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = string.format(Hyperspace.Text:GetText("tooltip_lily_targeting_core_button"), "N/A")
                end
            elseif activationTimer[shipManager.iShipId] < 1 then
                Hyperspace.Mouse.bForceTooltip = true
                Hyperspace.Mouse.tooltip = Hyperspace.Text:GetText("tooltip_lily_targeting_core_button_notready")
            else
                Hyperspace.Mouse.bForceTooltip = true
                Hyperspace.Mouse.tooltip = Hyperspace.Text:GetText("tooltip_lily_targeting_core_button_noship")
            end

        end
        Graphics.CSurface.GL_RenderPrimitive(buttonBase)
        if activationTimer[0] < 1 then
            local height = math.ceil(activationTimer[0] * 31)
            --[[Graphics.CSurface.GL_BlitImagePartial(buttonChargingTex, lily_targeting_coreButtonOffset_x,
                lily_targeting_coreButtonOffset_y, 20, 31, lily_targeting_coreButtonOffset_x,
                lily_targeting_coreButtonOffset_x + 20, lily_targeting_coreButtonOffset_y + height,
                lily_targeting_coreButtonOffset_y + 31, 1, Graphics.GL_Color(1, 1, 1, 1), false)--]]
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_SET, 1, 1)
            Graphics.CSurface.GL_DrawRect(lily_targeting_coreButtonOffset_x + 10, --+10
                lily_targeting_coreButtonOffset_y - height + 67,                  --+67
                20,
                height,
                Graphics.GL_Color(1, 1, 1, 1))
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_USE, 1, 1)
            Graphics.CSurface.GL_RenderPrimitive(buttonCharging)
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_IGNORE, 1, 1)
        else
            systemBox.table.activateButton:OnRender()
        end
    end
end
script.on_render_event(Defines.RenderEvents.SYSTEM_BOX,
    function(systemBox, ignoreStatus)
        return Defines.Chain.CONTINUE
    end, lily_targeting_core_render)


script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    activationTimer[0] = 1
    activationTimer[1] = 1
end)

local playerCursorRestore
local playerCursorRestoreInvalid

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player


    if shipManager and userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode then
        if not playerCursorRestore then
            playerCursorRestore = Hyperspace.Mouse.validPointer
            playerCursorRestoreInvalid = Hyperspace.Mouse.invalidPointer
        end
        Hyperspace.Mouse.validPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_targeting_core_valid.png")
        Hyperspace.Mouse.invalidPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_targeting_core.png")
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

    if shipManager and otherShipManager and userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode and not (commandGui.event_pause or commandGui.menu_pause) then
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
        Hyperspace.Mouse.valid = shipAtMouse > 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and
        combatControl.selectedRoom > -1
        --print(shipAtMouse .. " " .. roomAtMouse)
        if shipAtMouse > 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and combatControl.selectedRoom > -1 then
            local targetPosition = convertEnemyShipPositionToGlobalPosition(Hyperspace.Point(0, 0))
            local roomc = otherShipManager:GetRoomCenter(roomAtMouse)
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(targetPosition.x, targetPosition.y, 0)
            Graphics.CSurface.GL_Translate(roomc.x, roomc.y, 0)
            Graphics.CSurface.GL_RenderPrimitive(crosshair)
            Graphics.CSurface.GL_PopMatrix()
        end
    end
end, function() end)

---Click on a room to select it
---@param shipManager Hyperspace.ShipManager
---@param roomId integer
local function selectRoom(shipManager, roomId)
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    if (not otherShipManager) or roomId == -1 or roomId >= otherShipManager.ship.vRoomList:size() then
        userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom = nil
        userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
        userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms = {}
    else
        userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom = roomId
        userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
        local adjRooms = get_adjacent_rooms(otherShipManager.iShipId, roomId, false)

        userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms = adjRooms
    end
    return userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
end


script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player
    local otherShipManager = Hyperspace.ships.enemy

    if shipManager and otherShipManager and userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode and not (commandGui.event_pause or commandGui.menu_pause) then
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
        if shipAtMouse ~= 0 and roomAtMouse > -1 and combatControl and combatControl.selectedRoom and combatControl.selectedRoom > -1 then
            selectRoom(shipManager, roomAtMouse)
            userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
            activationTimer[shipManager.iShipId] = 0
            if not (Hyperspace.metaVariables.lily_targeting_core_sounds_disabled and Hyperspace.metaVariables.lily_targeting_core_sounds_disabled > 0) then
                Hyperspace.Sounds:PlaySoundMix("lily_targeting_core_locking_on", -1, false)
            end
        end
    end
    return Defines.Chain.CONTINUE
end)

---Returns effective level including manning bonues
---@param targetingCore Hyperspace.ShipSystem
---@return number
local function getEffectiveTargetingLevel(targetingCore)

    if targetingCore:GetEffectivePower() == 0 then return 0 end

    local manningLevel = targetingCore.iActiveManned
    local manningBonus = 0
    if manningLevel > 0 then
        manningBonus = 0.5 + 0.25 * (manningLevel - 1)
    end

    return targetingCore:GetEffectivePower() + 1 + manningBonus
end


script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) then
        local lily_targeting_core_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_targeting_core"))

        local targetroom = userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
        if mods.lilyinno.checkVarsOK() and not loadComplete[shipManager.iShipId] and (otherShipManager or mods.lilyinno.checkStartOK()) then
                local v = Hyperspace.playerVariables["mods_lilyinno_targetingcore_" .. (shipManager.iShipId > 0.5 and "1" or "0")] or 0
                --print("v", v)
                if v > 0 then
                    selectRoom(shipManager, v - 1)
                    --targetroom = v - 1
                    --userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom = targetroom
                end
                loadComplete[shipManager.iShipId] = true
            end
        --print("room", targetroom or "nil")

        if lily_targeting_core_system:CompletelyDestroyed() or not lily_targeting_core_system:Functioning() then
            activationTimer[shipManager.iShipId] = 0
            selectRoom(shipManager, -1)
            if shipManager.iShipId == 0 then
                sfxPlayed = true
            end
        end

        ---@type Hyperspace.CrewMember
        local manningCrew = nil
        for crew in vter(shipManager.vCrewList) do
            if crew.bActiveManning and crew.currentSystem == lily_targeting_core_system then
                lily_targeting_core_system.iActiveManned = crew:GetSkillLevel(3)
                manningCrew = crew
            end
        end

        ---@type Hyperspace.TimerHelper
        local skillTimer = skillTimers[shipManager.iShipId]
        --print("Timer:", skillTimer.currTime, skillTimer.currGoal, skillTimer:Running())
        if manningCrew and targetroom and targetroom > 0 then
            if not skillTimer:Running() then
                skillTimer:Start_Float(6.0)
            end
            skillTimer:Update()
            if skillTimer:Done() then
                manningCrew:IncreaseSkill(3)
                skillTimer.currTime = 0
                skillTimer:Stop()
                skillTimer:Start_Float(6.0)
            end
        else
            skillTimer.currTime = 0
            skillTimer:Stop()
        end

        --Reset the target if no hostile ship present
        if not (otherShipManager and otherShipManager._targetable.hostile) then
            userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom = nil
            userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
            userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms = {}
        end

        local level = lily_targeting_core_system.healthState.second
        local efflevel = getEffectiveTargetingLevel(lily_targeting_core_system)
        local multiplier = 1 / 6.0

        if shipManager:HasAugmentation("UPG_LILY_TARGETING_OVERCLOCK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_OVERCLOCK") > 0 then
            multiplier = 1 / 1.5
        end


        if lily_targeting_core_system.iHackEffect > 1 then
            multiplier = multiplier * -1
        end

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_targeting_core = level
        end

        --if not mods.lilyinno.checkVarsOK() then
        --    loadComplete[shipManager.iShipId] = false
        --end




        activationTimer[shipManager.iShipId] = math.max(0,
            math.min(1, activationTimer[shipManager.iShipId] + multiplier * Hyperspace.FPS.SpeedFactor / 16))
        if activationTimer[0] < 1 then
            sfxPlayed = false
        end
        if activationTimer[0] >= 1 and not sfxPlayed then
            if otherShipManager and targetroom and targetroom > -1 then
                if not (Hyperspace.metaVariables.lily_targeting_core_sounds_disabled and Hyperspace.metaVariables.lily_targeting_core_sounds_disabled > 0) then
                    Hyperspace.Sounds:PlaySoundMix("lily_targeting_core_locked_on", -1, false)
                end
            end
            sfxPlayed = true
        end

        -- Auto target cloaking
        if shipManager and (shipManager:HasAugmentation("UPG_LILY_TARGETING_AUTOLOCK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_AUTOLOCK") > 0) then
            if otherShipManager and otherShipManager._targetable.hostile and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("cloaking")) and not (targetroom and targetroom > -1) and activationTimer[shipManager.iShipId] >= 1 then
                selectRoom(shipManager, otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("cloaking")).roomId)
                userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
                --activationTimer[shipManager.iShipId] = 0
                if not (Hyperspace.metaVariables.lily_targeting_core_sounds_disabled and Hyperspace.metaVariables.lily_targeting_core_sounds_disabled > 0) then
                    Hyperspace.Sounds:PlaySoundMix("lily_targeting_core_locked_on", -1, false)
                end
            elseif otherShipManager and otherShipManager._targetable.hostile and not (targetroom and targetroom > -1) and activationTimer[shipManager.iShipId] >= 1 then
                local systems = {}
                for system in vter(otherShipManager.vSystemList) do
                    ---@type Hyperspace.ShipSystem
                    system = system
                    systems[#systems+1] = system:GetId()
                end

                if #systems > 0 then
                    selectRoom(shipManager, otherShipManager:GetSystem(systems[math.random(#systems)]).roomId)
                    userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
                    
                    --activationTimer[shipManager.iShipId] = 0
                    if not (Hyperspace.metaVariables.lily_targeting_core_sounds_disabled and Hyperspace.metaVariables.lily_targeting_core_sounds_disabled > 0) then
                        Hyperspace.Sounds:PlaySoundMix("lily_targeting_core_locked_on", -1, false)
                    end
                end
            end

        end


        if shipManager and shipManager.iShipId == 1 then
            if otherShipManager and shipManager._targetable.hostile and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("cloaking")) and not (targetroom and targetroom > -1) and activationTimer[shipManager.iShipId] >= 1 then
                selectRoom(shipManager, otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("cloaking")).roomId)
                userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false
                activationTimer[shipManager.iShipId] = 0
            elseif otherShipManager and shipManager._targetable.hostile and not (targetroom and targetroom > -1) and activationTimer[shipManager.iShipId] >= 1 then
                local systems = {}
                for system in vter(otherShipManager.vSystemList) do
                    ---@type Hyperspace.ShipSystem
                    system = system
                    systems[#systems + 1] = system:GetId()
                end

                if #systems > 0 then
                    selectRoom(shipManager, otherShipManager:GetSystem(systems[math.random(#systems)]).roomId)
                    userdata_table(shipManager, "mods.lilyinno.targetingcore").selectmode = false

                    activationTimer[shipManager.iShipId] = 0
                end
            end
        end

        if userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram then
            ---@type Hyperspace.CrewMember
            local holo = userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram
            if not holo or holo.bDead or holo:IsDead() then
                userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram = nil
            end
        end

        if otherShipManager and targetroom and targetroom >= 0 then
            if activationTimer[shipManager.iShipId] >= 1 then
                local sys = otherShipManager:GetSystemInRoom(targetroom)
                --print("Set:", sys and Hyperspace.ShipSystem.SystemIdToName(sys:GetId()) or "empty" )
                otherShipManager.ship:SetRoomBlackout(targetroom, false)
                if otherShipManager.cloakSystem and otherShipManager.cloakSystem.bTurnedOn and (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                    if not userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram then
                        local holo = otherShipManager:AddCrewMemberFromString("Hologram", "hologram", true, targetroom, true, false)
                        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(
                            Hyperspace.StatBoost(defNOCTRL), holo)
                        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(
                            Hyperspace.StatBoost(defNOTGT), holo)
                        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(
                            Hyperspace.StatBoost(defNOAI), holo)
                        userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram = holo
                    end
                else
                    if userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram then
                        ---@type Hyperspace.CrewMember
                        local holo = userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram
                        if holo then
                            holo.health.first = 0
                        end
                    end
                end
            else
                if userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram then
                    ---@type Hyperspace.CrewMember
                    local holo = userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram
                    if holo then
                        holo.health.first = 0
                    end
                end
            end
        else
            if userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram then
                ---@type Hyperspace.CrewMember
                local holo = userdata_table(shipManager, "mods.lilyinno.targetingcore").hologram
                if holo  then
                    holo.health.first = 0
                end
            end
        end



        local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
        --[[if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0) then
            for id, coord in pairs(bonusrooms) do
                local sys = shipManager:GetSystemInRoom(id)
                local deionizationBoost = 0.5 * activationTimer[shipManager.iShipId] * efflevel * 0.15
                if sys and sys.iLockCount > 0 then
                    sys.lockTimer.currTime = sys.lockTimer.currTime +
                    (Hyperspace.FPS.SpeedFactor / 16) * deionizationBoost
                end
            end
        end--]]
        if mods.lilyinno.checkVarsOK() and loadComplete[shipManager.iShipId] then
            Hyperspace.playerVariables["mods_lilyinno_targetingcore_" .. (shipManager.iShipId > 0.5 and "1" or "0")] = (targetroom and (targetroom + 1) or 0)
            --print("set", (targetroom + 1 or 0))
        end
    end



    --For Enemy Ship!
    if otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) then
        local lily_targeting_core_system = otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_targeting_core"))


        if lily_targeting_core_system:CompletelyDestroyed() then
            activationTimer[shipManager.iShipId] = 0
        end



        local targetroom = userdata_table(otherShipManager, "mods.lilyinno.targetingcore").targetroom
        if targetroom and targetroom >= 0 then
            if (true or otherShipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or otherShipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                if activationTimer[otherShipManager.iShipId] > 0 then
                    shipManager.ship:SetRoomBlackout(targetroom, false)
                end
                if activationTimer[otherShipManager.iShipId] >= 1 then
                    local adjRooms = get_adjacent_rooms(shipManager.iShipId, targetroom, false) or {}
                    for id, coord in pairs(adjRooms) do
                        shipManager.ship:SetRoomBlackout(id, false)
                    end
                end
                --shipManager.ship.bCloaked = false
            else
                if activationTimer[otherShipManager.iShipId] >= 1 then
                    --print("Set:", sys and Hyperspace.ShipSystem.SystemIdToName(sys:GetId()) or "empty" )
                    shipManager.ship:SetRoomBlackout(targetroom, false)
                end
            end
        end
        local bonusrooms = userdata_table(otherShipManager, "mods.lilyinno.targetingcore").bonusrooms
        if bonusrooms and (otherShipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or otherShipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
            for id, coord in pairs(bonusrooms) do
                if (true or otherShipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or otherShipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                    if activationTimer[otherShipManager.iShipId] > 0 then
                        shipManager.ship:SetRoomBlackout(id, false)
                    end
                    if activationTimer[otherShipManager.iShipId] >= 1 then
                        local adjRooms = get_adjacent_rooms(shipManager.iShipId, id, false) or {}
                        for id2, coord2 in pairs(adjRooms) do
                            shipManager.ship:SetRoomBlackout(id2, false)
                        end
                    end
                else
                    if activationTimer[otherShipManager.iShipId] >= 1 then
                        --print("Set:", sys and Hyperspace.ShipSystem.SystemIdToName(sys:GetId()) or "empty" )
                        shipManager.ship:SetRoomBlackout(id, false)
                    end
                end
            end
        end

    end
end)

script.on_internal_event(Defines.InternalEvents.PROJECTILE_FIRE, function(projectile, weapon)
    if projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if shipManager:HasAugmentation("BOON_LILY_TARGETING_CORE") > 0 then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10
            end


            local targetroom = userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
            --print("TGT:", targetroom or "nil")
            if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and targetroom and targetroom > -1 then
                local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
                local efflevel = getEffectiveTargetingLevel(sys)

                local projTargetRoom = get_room_at_location(otherShipManager, projectile.target, true)
                --print("TGT2:", projTargetRoom or "nil")

                if targetroom and activationTimer[shipManager.iShipId] >= 1 and weapon and weapon.blueprint and (shipManager:HasAugmentation("UPG_LILY_TARGETING_HOMING") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_HOMING") > 0) then
                    local bp = weapon.blueprint
                    local hitBonusRoom = false
                    local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
                    if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                        for id, coord in pairs(bonusrooms) do
                            if projTargetRoom == id then
                                hitBonusRoom = true
                            end
                        end
                    end
                    if not hitBonusRoom and bp.radius > 0 then
                        local maxdev = bp.radius * 2
                        local correctionMag = math.min(maxdev, (efflevel * 5 + efflevel * 10 * math.random())) 

                        local dev = otherShipManager:GetRoomCenter(targetroom) - projectile.target
                        local devLength = math.sqrt(dev.x * dev.x + dev.y * dev.y)

                        correctionMag = math.min(correctionMag, devLength)

                        local correctionDir = (otherShipManager:GetRoomCenter(targetroom) - projectile.target):Normalize()

                        local correctionVec = Hyperspace.Pointf(correctionDir.x * correctionMag, correctionDir.y * correctionMag)

                        projectile.target = projectile.target + correctionVec
                    end

                    --print("TGTLOC:", otherShipManager:GetRoomCenter(targetroom).x, otherShipManager:GetRoomCenter(targetroom).y)
                    --print("TGT2LOC:", projectile.target.x, projectile.target.y)
                end
                projTargetRoom = get_room_at_location(otherShipManager, projectile.target, true)
                if targetroom == projTargetRoom then
                    projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod +
                    5 * efflevel * activationTimer[shipManager.iShipId] * activationTimer[shipManager.iShipId]
                    if otherShipManager.cloakSystem and otherShipManager.cloakSystem.bTurnedOn and (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                        projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10 +
                        5 * efflevel * activationTimer[shipManager.iShipId] * activationTimer[shipManager.iShipId]
                    end
                end
                local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
                if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                    for id, coord in pairs(bonusrooms) do
                        if projTargetRoom == id then
                            projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod +
                                5 * efflevel * activationTimer[shipManager.iShipId] *
                                activationTimer[shipManager.iShipId]
                            if otherShipManager.cloakSystem and otherShipManager.cloakSystem.bTurnedOn and (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10 +
                                    5 * efflevel * (activationTimer[shipManager.iShipId] >= 1 and 1 or 0)
                            end
                        end
                    end
                end
                --print("Acc:", projectile.extend.customDamage.accuracyMod)
            end
        end
    end
end, 128)

script.on_internal_event(Defines.InternalEvents.DRONE_FIRE, function(projectile, spacedrone)
    if projectile then
        local shipManager = Hyperspace.ships(projectile.ownerId)
        local otherShipManager = Hyperspace.ships(1 - projectile.ownerId)
        if shipManager and otherShipManager then
            if shipManager:HasAugmentation("BOON_LILY_TARGETING_CORE") > 0 then
                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10
            end
            local targetroom = userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
            --print("TGT:", targetroom or "nil")
            if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and targetroom and targetroom > -1 then
                local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
                local efflevel = getEffectiveTargetingLevel(sys)

                local projTargetRoom = get_room_at_location(otherShipManager, projectile.target, true)
                --print("TGT2:", projTargetRoom or "nil")

                if targetroom then
                    --print("TGTLOC:", otherShipManager:GetRoomCenter(targetroom).x, otherShipManager:GetRoomCenter(targetroom).y)
                    --print("TGT2LOC:", projectile.target.x, projectile.target.y)
                end
                if targetroom == projTargetRoom then
                    projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod +
                        5 * efflevel * activationTimer[shipManager.iShipId] * activationTimer[shipManager.iShipId]
                    if otherShipManager.cloakSystem and otherShipManager.cloakSystem.bTurnedOn and (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                        projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10 +
                        5 * efflevel * activationTimer[shipManager.iShipId] * activationTimer[shipManager.iShipId]
                    end
                end
                local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
                if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                    for id, coord in pairs(bonusrooms) do
                        if projTargetRoom == id then
                            projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod +
                                5 * efflevel * activationTimer[shipManager.iShipId] *
                                activationTimer[shipManager.iShipId]
                            if otherShipManager.cloakSystem and otherShipManager.cloakSystem.bTurnedOn and (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) then
                                projectile.extend.customDamage.accuracyMod = projectile.extend.customDamage.accuracyMod + 10 +
                                    5 * efflevel * (activationTimer[shipManager.iShipId] >= 1 and 1 or 0)
                            end
                        end
                    end
                end
                --print("Acc:", projectile.extend.customDamage.accuracyMod)
            end
        end
    end
    if spacedrone then
        local shipManager = Hyperspace.ships(spacedrone.iShipId)
        local otherShipManager = Hyperspace.ships(1 - spacedrone.iShipId)
        if shipManager and otherShipManager and spacedrone.deployed and spacedrone.currentSpace == otherShipManager.iShipId then
            local targetroom = userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
            if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and targetroom and targetroom > -1 and activationTimer[shipManager.iShipId] >= 1 then
                local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
                local efflevel = getEffectiveTargetingLevel(sys)
                local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
                if math.random() < 0.5 then
                    spacedrone.targetLocation = otherShipManager:GetRoomCenter(targetroom)
                elseif bonusrooms and (shipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                    local list = {}
                    for id, coord in pairs(bonusrooms or {}) do
                        list[#list+1] = id
                    end
                    spacedrone.targetLocation = otherShipManager:GetRoomCenter(list[math.random(#list)])
                end
            end
        end
    end
end, 128)


script.on_internal_event(Defines.InternalEvents.PROJECTILE_INITIALIZE, function(projectile)
    --print("INIT")
    if projectile and projectile:GetOwnerId() and projectile:GetOwnerId() >= 0 then
        local ownerShip = Hyperspace.ships(projectile:GetOwnerId())
        --print("ID:", projectile:GetOwnerId())
        if ownerShip and ownerShip:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and (ownerShip:HasAugmentation("UPG_LILY_TARGETING_STATUS") > 0 or ownerShip:HasAugmentation("EX_LILY_TARGETING_STATUS") > 0) then
            local sys = ownerShip:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
            --print("SYS:", sys and "OK" or "FAIL")
            --print("STR:", getEffectiveTargetingLevel(sys))
            if projectile.damage.breachChance > 0 then
                projectile.damage.breachChance = projectile.damage.breachChance +
                math.ceil(getEffectiveTargetingLevel(sys) * 0.5)
                ---print("BR:", projectile.damage.breachChance)
            end
            if projectile.damage.fireChance > 0 then
                projectile.damage.fireChance = projectile.damage.fireChance +
                math.ceil(getEffectiveTargetingLevel(sys) * 0.5)
                --print("FI:", projectile.damage.fireChance)
            end
            if projectile.damage.stunChance > 0 then
                projectile.damage.stunChance = projectile.damage.stunChance +
                math.ceil(getEffectiveTargetingLevel(sys) * 0.5)
                --print("ST:", projectile.damage.stunChance)
            end
            
        end
    end
end)


-- Cloak charging
script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    if shipManager and otherShipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) then

        -- Check for cloak charge
        local cloakCharge = (true or shipManager:HasAugmentation("UPG_LILY_TARGETING_ANTICLOAK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_ANTICLOAK") > 0) and
            otherShipManager and
            otherShipManager.cloakSystem and
            otherShipManager.cloakSystem.bTurnedOn

        -- Manually charge weapons
        if cloakCharge then
            local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
            local effPower = getEffectiveTargetingLevel(sys)
            local mult = effPower * 0.2 * (1 + shipManager:GetAugmentationValue("AUTO_COOLDOWN"))
            local manning = 1.0
            if shipManager.weaponSystem and shipManager.weaponSystem.iActiveManned > 0 then
                manning = math.max(0.1, 1 - 0.05 - 0.05 * shipManager.weaponSystem.iActiveManned)
            end
            mult = mult / manning

            if shipManager.weaponSystem and shipManager.weaponSystem.weapons and shipManager.weaponSystem.iHackEffect < 2 then
                for weapon in vter(shipManager.weaponSystem.weapons) do
                    ---@type Hyperspace.ProjectileFactory
                    weapon = weapon
                    if weapon.powered and weapon.subCooldown.second <= weapon.subCooldown.first and not weapon.table["mods.multiverse.manualDecharge"] then
                        local oldFirst = weapon.cooldown.first
                        local oldSecond = weapon.cooldown.second
    
                        weapon.cooldown.first = weapon.cooldown.first + mult * time_increment()
                        weapon.cooldown.first = math.min(weapon.cooldown.first, weapon.cooldown.second)
    
                        if weapon.cooldown.second == weapon.cooldown.first and oldFirst < oldSecond and weapon.chargeLevel < weapon.blueprint.chargeLevels then
                            weapon.chargeLevel = weapon.chargeLevel + 1
                            weapon.weaponVisual.boostLevel = 0
                            weapon.weaponVisual.boostAnim:SetCurrentFrame(0)
                            if weapon.chargeLevel < weapon.blueprint.chargeLevels then weapon.cooldown.first = 0 end
                        else
                            weapon.subCooldown.first = weapon.subCooldown.first + time_increment()
                            weapon.subCooldown.first = math.min(weapon.subCooldown.first, weapon.subCooldown.second)
                        end
                    end
                end
            end
            local artilleries = shipManager.artillerySystems
            for artillery in vter(artilleries) do
                ---@type Hyperspace.ArtillerySystem
                artillery = artillery

                if artillery.iHackEffect < 2 and artillery:GetEffectivePower() > 0 then
                    local mult2 = 1 / math.max(0.05, 1.5 - 0.25 * artillery:GetEffectivePower())
                    local weapon = artillery.projectileFactory
                    if weapon then
                        if weapon.powered and weapon.subCooldown.second <= weapon.subCooldown.first and not weapon.table["mods.multiverse.manualDecharge"] then
                            local oldFirst = weapon.cooldown.first
                            local oldSecond = weapon.cooldown.second

                            weapon.cooldown.first = weapon.cooldown.first + mult * mult2 * time_increment()
                            weapon.cooldown.first = math.min(weapon.cooldown.first, weapon.cooldown.second)

                            if weapon.cooldown.second == weapon.cooldown.first and oldFirst < oldSecond and weapon.chargeLevel < weapon.blueprint.chargeLevels then
                                weapon.chargeLevel = weapon.chargeLevel + 1
                                weapon.weaponVisual.boostLevel = 0
                                weapon.weaponVisual.boostAnim:SetCurrentFrame(0)
                                if weapon.chargeLevel < weapon.blueprint.chargeLevels then weapon.cooldown.first = 0 end
                            else
                                weapon.subCooldown.first = weapon.subCooldown.first + time_increment()
                                weapon.subCooldown.first = math.min(weapon.subCooldown.first, weapon.subCooldown.second)
                            end
                        end
                    end
                end
            end
        end
    end
end, 128)

script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(shipManager, augment, value)
    if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and (shipManager:HasAugmentation("UPG_LILY_TARGETING_RELOAD") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_RELOAD") > 0) then
        local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))

        if sys then
            local level = getEffectiveTargetingLevel(sys)
            if augment == "AUTO_COOLDOWN" then
                value = value + level * 0.05
            end
        end
    end
    return Defines.Chain.CONTINUE, value
end)

mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")] = mods.multiverse
    .register_system_icon("lily_targeting_core")



script.on_render_event(Defines.RenderEvents.SHIP_SPARKS, function(ship)
    local shipManager = Hyperspace.ships(ship.iShipId)
    local otherShipManager = Hyperspace.ships(1 - ship.iShipId)
    --print("render_ok")

    if shipManager and otherShipManager and otherShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) then
        local targetroom = userdata_table(otherShipManager, "mods.lilyinno.targetingcore").targetroom
        local level = otherShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
        :GetEffectivePower()
        if otherShipManager and level > 0 and targetroom and targetroom > -1 then
            local cApp = Hyperspace.Global.GetInstance():GetCApp()
            local combatControl = cApp.gui.combatControl
            local position = combatControl.position
            local pposition = combatControl.playerShipPosition
            local targetPosition = combatControl.targetPosition
            local enemyShipOriginX = position.x + targetPosition.x
            local enemyShipOriginY = position.y + targetPosition.y

            local offset-- = convertEnemyShipPositionToGlobalPosition(Hyperspace.Point(0, 0))

            if ship.iShipId == 0 then
                offset = combatControl.playerShipPosition
            else
                offset = combatControl.targetPosition
            end
            --print(ship.iShipId)
            --print("Offset", offset.x, offset.y)
            local roomc = shipManager:GetRoomCenter(targetroom)
            --print("PPos", pposition.x, pposition.y)
            --print("Pos", position.x, position.y)
            --print("Tpos", targetPosition.x, targetPosition.y)
            --print("Roomc", roomc.x, roomc.y)
            --Graphics.CSurface.GL_PushMatrix()
            --Graphics.CSurface.GL_Translate(-pposition.x, -pposition.y, 0)
            --Graphics.CSurface.GL_Translate(offset.x, offset.y, 0)
            Graphics.CSurface.GL_Translate(roomc.x, roomc.y, 0)
            if activationTimer[otherShipManager.iShipId] >= 1 then
                Graphics.CSurface.GL_RenderPrimitiveWithAlpha(roomEffect, 1)
            else
                local index = math.ceil(12.0 * activationTimer[otherShipManager.iShipId])
                if index > 0 and index <= 12 then
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(roomEffectLoading[index], 1)
                end
            end

            Graphics.CSurface.GL_Translate(-roomc.x, -roomc.y, 0)
            --Graphics.CSurface.GL_PopMatrix()


            local bonusrooms = userdata_table(otherShipManager, "mods.lilyinno.targetingcore").bonusrooms
            if bonusrooms and activationTimer[otherShipManager.iShipId] >= 1 and (otherShipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or otherShipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                for id, coords in pairs(bonusrooms or {}) do
                    local c2 = shipManager:GetRoomCenter(id)
                    Graphics.CSurface.GL_Translate(c2.x, c2.y)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(roomEffect2, 0.5)
                    Graphics.CSurface.GL_Translate(-c2.x, -c2.y)
                end
            end
        end
    end
end, function() end)


---@diagnostic disable-next-line: undefined-field
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_PRE, function(crew, stat, def, amount, value)
    if mods.lilyinno.checkVarsOK() and mods.lilyinno.checkStartOK() then
        
        ---@type Hyperspace.CrewMember
        crew = crew
        ---@type Hyperspace.CrewStat
        stat = stat
        
        local shipManager = Hyperspace.ships(crew.iShipId)
        local otherShipManager = Hyperspace.ships(1 - crew.iShipId)
        
        if shipManager and otherShipManager then
            if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core")) and (shipManager:HasAugmentation("UPG_LILY_TARGETING_UPLINK") > 0 or shipManager:HasAugmentation("EX_LILY_TARGETING_UPLINK") > 0) and activationTimer[shipManager.iShipId] >= 1 then
                if crew.currentShipId == otherShipManager.iShipId then
                    local inRoom = false
                    local targetroom = userdata_table(shipManager, "mods.lilyinno.targetingcore").targetroom
                    local bonusrooms = userdata_table(shipManager, "mods.lilyinno.targetingcore").bonusrooms
                    if targetroom and crew.iRoomId == targetroom then
                        inRoom = true
                    end
                    if bonusrooms and activationTimer[otherShipManager.iShipId] >= 1 and (otherShipManager:HasAugmentation("UPG_LILY_TARGETING_MULTITHREAD") > 0 or otherShipManager:HasAugmentation("EX_LILY_TARGETING_MULTITHREAD") > 0) then
                        for id, coords in pairs(bonusrooms or {}) do
                            if crew.iRoomId == id then
                                inRoom = true
                            end
                        end
                    end

                    if inRoom then
                        local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core"))
                        local effPower = getEffectiveTargetingLevel(sys)
                        if stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER then
                            amount = amount * (1 + effPower * 0.1)
                        end
                        if stat == Hyperspace.CrewStat.DAMAGE_ENEMIES_AMOUNT then
                            amount = amount * (1 + effPower * 0.1)
                        end
                        if stat == Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER then
                            amount = amount * (1 + effPower * 0.2)
                        end
                    end
                end
            end
        end
    end
    

return Defines.Chain.CONTINUE, amount, value
end)


script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(system)
    if system and system:GetId() == Hyperspace.ShipSystem.NameToSystemId("lily_targeting_core") then
        system.bNeedsPower = true
        system.bBoostable = true
        --system.bLevelBoostable = true
    end
end)
