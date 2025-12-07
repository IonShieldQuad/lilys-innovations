local userdata_table = mods.multiverse.userdata_table

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
activationTimer[0] = 0
activationTimer[1] = 0
local sfxPlayed = false
local loadComplete = {}
loadComplete[0] = false
loadComplete[1] = false

--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_shock_neutralizer(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer") then
                if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_system_disabled")
            end
            return string.format(Hyperspace.Text:GetText("tooltip_lily_shock_neutralizer_level"), tostring(1 + level * .15), level)
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_shock_neutralizer_level"), tostring(1 + level * .15), level)
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_shock_neutralizer)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_shock_neutralizer(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_shock_neutralizer" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_shock_neutralizer_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_shock_neutralizer" and not systemBox.bPlayerUI
end


local lily_shock_neutralizerButtonOffset_x = 37--35
local lily_shock_neutralizerButtonOffset_y = -50---40
--Handles initialization of custom system box
local function lily_shock_neutralizer_construct_system_box(systemBox)
    if is_lily_shock_neutralizer(systemBox) then
        systemBox.extend.xOffset = 54
        local activateButton = Hyperspace.Button()
        activateButton:OnInit("systemUI/button_neutralizer2",
            Hyperspace.Point(lily_shock_neutralizerButtonOffset_x, lily_shock_neutralizerButtonOffset_y))
        activateButton.hitbox.x = 11
        activateButton.hitbox.y = 36
        activateButton.hitbox.w = 20
        activateButton.hitbox.h = 30
        systemBox.table.activateButton = activateButton
    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, lily_shock_neutralizer_construct_system_box)

--Handles mouse movement
local function lily_shock_neutralizer_mouse_move(systemBox, x, y)
    if is_lily_shock_neutralizer(systemBox) then
        local activateButton = systemBox.table.activateButton
        activateButton:MouseMove(x - lily_shock_neutralizerButtonOffset_x, y - lily_shock_neutralizerButtonOffset_y, false)
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_MOVE, lily_shock_neutralizer_mouse_move)

local function lily_shock_neutralizer_click(systemBox, shift)
    if is_lily_shock_neutralizer(systemBox) then
        local activateButton = systemBox.table.activateButton
        if activateButton.bHover and activateButton.bActive then
            local shipManager = Hyperspace.ships.player
            local lily_shock_neutralizer_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_shock_neutralizer"))
            userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = true
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_CLICK, lily_shock_neutralizer_click)

script.on_internal_event(Defines.InternalEvents.ON_MOUSE_R_BUTTON_DOWN, function (x, y)
    local shipManager = Hyperspace.ships.player
    userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = false
end)

local lastKeyDown = nil


script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_KEY_DOWN, function(systemBox, key, shift)
    if Hyperspace.metaVariables.lily_shock_neutralizer_hotkey_enabled == 0 and ((not lastKeyDown) or lastKeyDown ~= key) and is_lily_shock_neutralizer(systemBox) then
        lastKeyDown = key
        --print("press key:"..key.." shift:"..tostring(shift))
        local shipManager = Hyperspace.ships.player
        if not Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")) then return end
        if key == 98 then
            if activationTimer[1] >= 1 then
                userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = true
            end
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(key)
    lastKeyDown = nil
end)


--Utility function to see if the system is ready for use
local function lily_shock_neutralizer_ready(shipSystem)
    return not shipSystem:GetLocked() and shipSystem:Functioning() and shipSystem.iHackEffect <= 1
end

local buttonBase
local crosshair
local buttonCharging
local buttonChargingTex
local indicatorsSys = {}
local indicatorsSubsys = {}
script.on_init(function()
    buttonBase = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_cloaking2_base.png",
    lily_shock_neutralizerButtonOffset_x, lily_shock_neutralizerButtonOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    crosshair = Hyperspace.Resources:CreateImagePrimitiveString("misc/crosshairs_placed_lily_shock_neutralizer.png",
        -20, -20, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    buttonCharging = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_cloaking2_charging_on.png",
        lily_shock_neutralizerButtonOffset_x, lily_shock_neutralizerButtonOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    buttonChargingTex = Hyperspace.Resources:GetImageId("systemUI/button_cloaking2_charging_on.png")
    activationTimer[0] = 1
    activationTimer[1] = 1
    sfxPlayed = true

    local i = 1
    while i <= 8 do
        indicatorsSys[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/shock_neutralizer_main_" .. i .. ".png", 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        indicatorsSubsys[i] = Hyperspace.Resources:CreateImagePrimitiveString(
        "systemUI/shock_neutralizer_sub_" .. i .. ".png", 8, 8, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        i = i + 1
    end

    for i = 0, 1, 1 do
        loadComplete[i] = false
        --print("L:", i, Hyperspace.metaVariables["mods_lilyinno_shockneutralizer_" .. i])
        --print("mods_lilyinno_shockneutralizer_" .. i)
    end
    --print("Loaded:", loadValues[0])

end)

--Handles custom rendering
local function lily_shock_neutralizer_render(systemBox, ignoreStatus)
    if is_lily_shock_neutralizer(systemBox) then
        local activateButton = systemBox.table.activateButton
        local shipManager = Hyperspace.ships.player
        local lily_shock_neutralizer_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer"))
        activateButton.bActive = (not lily_shock_neutralizer_system:CompletelyDestroyed()) and activationTimer[shipManager.iShipId] >= 1

        if activateButton.bHover then
            if Hyperspace.metaVariables.lily_shock_neutralizer_hotkey_enabled == 0 and not Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("battery")) then
                Hyperspace.Mouse.bForceTooltip = true
                Hyperspace.Mouse.tooltip = string.format(Hyperspace.Text:GetText("tooltip_lily_shock_neutralizer_button"), "B")
            else
                Hyperspace.Mouse.bForceTooltip = true
                Hyperspace.Mouse.tooltip = string.format(Hyperspace.Text:GetText("tooltip_lily_shock_neutralizer_button"), "N/A")
            end
        end
        Graphics.CSurface.GL_RenderPrimitive(buttonBase)
        if activationTimer[0] < 1 then
            local height = math.ceil(activationTimer[0] * 31)
            --[[Graphics.CSurface.GL_BlitImagePartial(buttonChargingTex, lily_shock_neutralizerButtonOffset_x,
                lily_shock_neutralizerButtonOffset_y, 20, 31, lily_shock_neutralizerButtonOffset_x,
                lily_shock_neutralizerButtonOffset_x + 20, lily_shock_neutralizerButtonOffset_y + height,
                lily_shock_neutralizerButtonOffset_y + 31, 1, Graphics.GL_Color(1, 1, 1, 1), false)--]]
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_SET, 1, 1)
            Graphics.CSurface.GL_DrawRect(lily_shock_neutralizerButtonOffset_x + 10, --+10
                lily_shock_neutralizerButtonOffset_y - height + 67, --+67
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
    end, lily_shock_neutralizer_render)


script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
    activationTimer[0] = 1
    activationTimer[1] = 1
end)

local playerCursorRestore
local playerCursorRestoreInvalid

script.on_internal_event(Defines.InternalEvents.ON_TICK, function()
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player


    if shipManager and userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode then

        if not playerCursorRestore then
            playerCursorRestore = Hyperspace.Mouse.validPointer
            playerCursorRestoreInvalid = Hyperspace.Mouse.invalidPointer
        end
        Hyperspace.Mouse.validPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_shock_neutralizer_valid.png")
        Hyperspace.Mouse.invalidPointer = Hyperspace.Resources:GetImageId("mouse/mouse_lily_shock_neutralizer.png")
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

    if shipManager and userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode and not (commandGui.event_pause or commandGui.menu_pause) then
        local mousePos = Hyperspace.Mouse.position
        local mousePosLocal = convertMousePositionToPlayerShipPosition(mousePos)
        local shipAtMouse = 0
        local roomAtMouse = -1
        --print("MOUSE POS X:"..mousePos.x.." Y:"..mousePos.y.." LOCAL X:"..mousePosLocal.x.." Y:"..mousePosLocal.y)
        roomAtMouse = get_room_at_location(Hyperspace.ships.player, mousePosLocal, true)

        Hyperspace.Mouse.valid = shipAtMouse == 0 and roomAtMouse > -1
        --print(shipAtMouse .. " " .. roomAtMouse)
        --print(Hyperspace.playerVariables.lily_beam_active == 1 .. " " .. Hyperspace.playerVariables.lily_ion_active == 1)
        --print("Count: " .. count)
        if shipAtMouse == 0 and roomAtMouse > -1 then

            local cApp = Hyperspace.Global.GetInstance():GetCApp()
            local combatControl = cApp.gui.combatControl
            local playerPosition = combatControl.playerShipPosition
            local roomc = shipManager:GetRoomCenter(roomAtMouse)
            Graphics.CSurface.GL_PushMatrix()
            Graphics.CSurface.GL_Translate(playerPosition.x, playerPosition.y, 0)
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
    if roomId == -1 or roomId >= shipManager.ship.vRoomList:size() then
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom = nil
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = false
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms = {}
    else
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom = roomId
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = false
        --if shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0 then
        local adjRooms
        if (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") + shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE")) >= 2 then
            adjRooms = get_adjacent_rooms(shipManager.iShipId, roomId, true)
        else
            adjRooms = get_adjacent_rooms(shipManager.iShipId, roomId, false)
        end
        userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms = adjRooms
    end
end


script.on_internal_event(Defines.InternalEvents.ON_MOUSE_L_BUTTON_DOWN, function(x, y)
    local commandGui = Hyperspace.App.gui
    local shipManager = Hyperspace.ships.player

    if shipManager and userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode and not (commandGui.event_pause or commandGui.menu_pause) then
        local mousePos = Hyperspace.Mouse.position
        local mousePosLocal = convertMousePositionToPlayerShipPosition(mousePos)
        local shipAtMouse = 0
        local roomAtMouse = -1
        --print("MOUSE POS X:"..mousePos.x.." Y:"..mousePos.y.." LOCAL X:"..mousePosLocal.x.." Y:"..mousePosLocal.y)

        roomAtMouse = get_room_at_location(Hyperspace.ships.player, mousePosLocal, true)

        --print(shipAtMouse .. " " .. roomAtMouse)
        --print(Hyperspace.playerVariables.lily_beam_active == 1 .. " " .. Hyperspace.playerVariables.lily_ion_active == 1)
        --print("Count: " .. count)
        if shipAtMouse == 0 and roomAtMouse > -1 then
            selectRoom(shipManager, roomAtMouse)
            userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = false
            activationTimer[shipManager.iShipId] = 0
            Hyperspace.Sounds:PlaySoundMix("lily_shock_neutralizer_select_1", -1, false)
        end
    end
    return Defines.Chain.CONTINUE
end)


script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")) then
        local lily_shock_neutralizer_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
        "lily_shock_neutralizer"))

        --Remove ion if it has any
        if lily_shock_neutralizer_system.iLockCount > 0 then
            lily_shock_neutralizer_system.iLockCount = 0
            lily_shock_neutralizer_system.lockTimer.currTime = lily_shock_neutralizer_system.lockTimer.currGoal
        end

        if lily_shock_neutralizer_system:CompletelyDestroyed() then
            activationTimer[shipManager.iShipId] = 0
        end

        lily_shock_neutralizer_system.bNeedsPower = false
        lily_shock_neutralizer_system.bBoostable = false
        local level = lily_shock_neutralizer_system.healthState.second
        local efflevel = lily_shock_neutralizer_system:GetEffectivePower()
        local multiplier = 0.15
                 if lily_shock_neutralizer_system.iHackEffect > 1 then
            multiplier = -1
        end

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_shock_neutralizer = level
        end


        if mods.lilyinno.checkVarsOK() and not loadComplete[shipManager.iShipId] then
            local v = Hyperspace.playerVariables
            ["mods_lilyinno_shockneutralizer_" .. (shipManager.iShipId > 0.5 and "1" or "0")]
            if v > 0 then
                selectRoom(shipManager, v - 1)
            end
            loadComplete[shipManager.iShipId] = true
        end



        activationTimer[shipManager.iShipId] = math.max(0,
            math.min(1, activationTimer[shipManager.iShipId] + multiplier * Hyperspace.FPS.SpeedFactor / 16))
        if activationTimer[0] < 1 then
            sfxPlayed = false
        end
        if activationTimer[0] >= 1 and not sfxPlayed then
            Hyperspace.Sounds:PlaySoundMix("lily_shock_neutralizer_select_1", -1, false)
            sfxPlayed = true
        end

        local targetroom = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom
        if targetroom and targetroom >= 0 then
            local sys = shipManager:GetSystemInRoom(targetroom)

            local deionizationBoost = activationTimer[shipManager.iShipId] * efflevel * 0.15
            if sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("cloaking") or sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("cloaking") then
                deionizationBoost = deionizationBoost * 0.5
            end

            if sys and sys.iLockCount > 0 then

                sys.lockTimer.currTime = sys.lockTimer.currTime + Hyperspace.FPS.SpeedFactor / 16 * deionizationBoost

            end

        end
        local bonusrooms = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms
        if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0) then
            for id, coord in pairs(bonusrooms) do
                local sys = shipManager:GetSystemInRoom(id)
                local deionizationBoost = 0.5 * activationTimer[shipManager.iShipId] * efflevel * 0.15
                if sys and sys.iLockCount > 0 then
                    sys.lockTimer.currTime = sys.lockTimer.currTime + (Hyperspace.FPS.SpeedFactor / 16) * deionizationBoost
                end
            end
        end

        if shipManager:HasAugmentation("UPG_LILY_STUN_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_STUN_NEUTRALIZE") > 0 then
            local crewList = shipManager.vCrewList

            for crew in vter(crewList) do
                ---@type Hyperspace.CrewMember
                crew = crew
                if crew and crew.currentShipId == shipManager.iShipId and crew.stunned and (not crew.intruder) and not (crew.bMindControlled) then
                    if targetroom and crew:InsideRoom(targetroom) then
                        local deionizationBoost = activationTimer[shipManager.iShipId] * efflevel * 0.15
                        crew.fStunTime = math.max(0, crew.fStunTime - deionizationBoost * Hyperspace.FPS.SpeedFactor / 16)
                    end
                    if bonusrooms and bonusrooms[crew.iRoomId] then
                        local deionizationBoost = 0.5 * activationTimer[shipManager.iShipId] * efflevel * 0.15
                        crew.fStunTime = math.max(0, crew.fStunTime - deionizationBoost * Hyperspace.FPS.SpeedFactor / 16)
                    end
                end


            end
        end
        if mods.lilyinno.checkVarsOK() and loadComplete[shipManager.iShipId] then
            Hyperspace.playerVariables["mods_lilyinno_shockneutralizer_" .. (shipManager.iShipId > 0.5 and "1" or "0")] = targetroom + 1 or 0
        end

        if shipManager.iShipId == 1 then
            if targetroom == nil or targetroom == -1 or not shipManager:GetSystemInRoom(targetroom) or shipManager:GetSystemInRoom(targetroom).iLockCount == 0 then
                local systems = {}
                for system in vter(shipManager.vSystemList) do
                    ---@type Hyperspace.ShipSystem
                    system = system
                    if system.iLockCount > 0 then
                        systems[#systems + 1] = system:GetId()
                    end
                end

                if #systems > 0 then
                    selectRoom(shipManager, shipManager:GetSystem(math.random(#systems)).roomId)
                    activationTimer[shipManager.iShipId] = 0
                end

            end
        end


        --print(targetroom, Hyperspace.metaVariables["mods_lilyinno_shockneutralizer_" .. shipManager.iShipId])
        --print("mods_lilyinno_shockneutralizer_" .. shipManager.iShipId)
    end
end)

script.on_internal_event(Defines.InternalEvents.SET_BONUS_POWER, function(system, amount)
    local ship = Hyperspace.ships(system._shipObj.iShipId)
    local storm = Hyperspace.App.world.space.bStorm == true
    storm = storm or Hyperspace.App.world.space.pulsarLevel

    if storm and ship and ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")) then
        local targetroom = userdata_table(ship, "mods.lilyinno.shockneutralizer").targetroom
        if targetroom and targetroom >= 0 and targetroom == system:GetRoomId() then
            local lily_shock_neutralizer_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_shock_neutralizer"))
            local boost = math.floor(activationTimer[ship.iShipId] * lily_shock_neutralizer_system:GetEffectivePower())
            amount = amount + boost
        end

        local bonusrooms = userdata_table(ship, "mods.lilyinno.shockneutralizer").bonusrooms
        if bonusrooms and bonusrooms[system:GetRoomId()] and (ship:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or ship:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0) then
            local lily_shock_neutralizer_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_shock_neutralizer"))
            local boost = math.floor(0.5 * activationTimer[ship.iShipId] * lily_shock_neutralizer_system:GetEffectivePower())
            amount = amount + boost
        end
    end
    return Defines.Chain.CONTINUE, amount
end)


local function render_shock_neutralizer_effects(ship, experimental)
    local shipManager = Hyperspace.ships(ship.iShipId)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")) then
        local rooms = ship.vRoomList
        local targetroom = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom

        local level = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")):GetEffectivePower()

        if level > 0 then
            local yellow = false
            if shipManager:HasAugmentation("UPG_LILY_STUN_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_STUN_NEUTRALIZE") > 0 then
                yellow = true
            end

            if targetroom and targetroom >= 0 then
                local roomdata = rooms[targetroom]
                local rect = roomdata.rect
                local color1 = Graphics.GL_Color(68 / 255, math.min(1, (25 * level + 154) / 255), 136 / 255,
                activationTimer[shipManager.iShipId])
                local color2 = Graphics.GL_Color(68 / 255, math.min(1, (25 * level + 154) / 255), 136 / 255,
                0.4 * activationTimer[shipManager.iShipId])
                local color3 = Graphics.GL_Color((25 * level + 154) / 255, math.min(1, (25 * level + 154) / 255),
                40 / 255,
                    0.4 * activationTimer[shipManager.iShipId])

                Graphics.CSurface.GL_PushMatrix()
                if yellow then
                    Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color3,
                        (level + 7) * activationTimer[shipManager.iShipId])
                end
                Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color2,
                    (level + 5) * activationTimer[shipManager.iShipId])
                Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color2,
                    (level + 3) * activationTimer[shipManager.iShipId])
                Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color1,
                    (level + 1) * activationTimer[shipManager.iShipId])
                Graphics.CSurface.GL_PopMatrix()
            end

            local bonusrooms = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms
            if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0) then
                for id, coord in pairs(bonusrooms) do
                    local roomdata = rooms[id]
                    local rect = roomdata.rect
                    local color1 = Graphics.GL_Color(68 / 255, math.min(1, (25 * math.floor(level / 2) + 154) / 255),
                    136 / 255,
                    activationTimer[shipManager.iShipId])
                    local color2 = Graphics.GL_Color(68 / 255, math.min(1, (25 * math.floor(level / 2) + 154) / 255),
                    136 / 255,
                        0.4 * activationTimer[shipManager.iShipId])
                    local color3 = Graphics.GL_Color((25 * math.floor(level / 2) + 154) / 255,
                    math.min(1, (25 * math.floor(level / 2) + 154) / 255),
                        40 / 255,
                        0.4 * activationTimer[shipManager.iShipId])

                    Graphics.CSurface.GL_PushMatrix()
                    if yellow then
                        Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color3,
                            (level / 2 + 7) * activationTimer[shipManager.iShipId])
                    end
                    Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color2,
                        (math.floor(level / 2) + 5) * activationTimer[shipManager.iShipId])
                    Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color2,
                        (math.floor(level / 2) + 3) * activationTimer[shipManager.iShipId])
                    Graphics.CSurface.GL_DrawRectOutline(rect.x, rect.y, rect.w, rect.h, color1,
                        (math.floor(level / 2) + 1) * activationTimer[shipManager.iShipId])
                    Graphics.CSurface.GL_PopMatrix()
                end
            end
        end
    end
end

script.on_render_event(Defines.RenderEvents.SHIP_FLOOR, function() end, render_shock_neutralizer_effects)




mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")] = mods.multiverse
    .register_system_icon("lily_shock_neutralizer")


script.on_internal_event(Defines.InternalEvents.SHIELD_COLLISION_PRE, function(ship, projectile, damage, collisionResponse)
        if ship:HasAugmentation("UPG_LILY_PLASMA_NEUTRALIZE") > 0 or ship:HasAugmentation("EX_LILY_PLASMA_NEUTRALIZE") > 0 then
            if damage and damage.iDamage <= 0 and damage.iSystemDamage > 0 and damage.iIonDamage > 0 then
                damage.iSystemDamage = 0
            end
        end
        return Defines.Chain.CONTINUE
    end)


script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(ship, projectile, location, damage, newTile, beamHit)
        if ship:HasAugmentation("UPG_LILY_PLASMA_NEUTRALIZE") > 0 or ship:HasAugmentation("EX_LILY_PLASMA_NEUTRALIZE") > 0 then
            if damage and damage.iDamage <= 0 and damage.iSystemDamage > 0 and damage.iIonDamage > 0 and math.random() < 0.5 then
                damage.iSystemDamage = 0
            end
        end
    return Defines.Chain.CONTINUE, beamHit
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA, function(ship, projectile, location, damage, forceHit, shipFriendlyFire)
        if ship:HasAugmentation("UPG_LILY_PLASMA_NEUTRALIZE") > 0 or ship:HasAugmentation("EX_LILY_PLASMA_NEUTRALIZE") > 0 then

            if damage and damage.iDamage <= 0 and damage.iSystemDamage > 0 and damage.iIonDamage > 0 and math.random() < 0.5 then
                damage.iSystemDamage = 0
            end
        end
    return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
end)









script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(ShipManager)
    if ShipManager:HasAugmentation("BOON_LILY_SHOCK_NEUTRALIZER") > 0 then
        local deionizationBoost = 0.1
        for sys in vter(ShipManager.vSystemList) do
            sys.lockTimer.currTime = sys.lockTimer.currTime + Hyperspace.FPS.SpeedFactor / 16 * deionizationBoost
        end
    end
end)


script.on_render_event(Defines.RenderEvents.SYSTEM_BOX,
    function(systemBox, ignoreStatus)
        return Defines.Chain.CONTINUE
    end, function(systemBox, ignoreStatus)
        local shipManager
        if systemBox and systemBox.pSystem and systemBox.pSystem._shipObj then
            shipManager = Hyperspace.ships(systemBox.pSystem._shipObj.iShipId)
        end

        if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer")) then
            local targetroom = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom
            local level = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer"))
            :GetEffectivePower()
            if level > 0 then
                local sys = targetroom and shipManager:GetSystemInRoom(targetroom)
                if sys and sys:GetId() == systemBox.pSystem:GetId() then
                    local rl = level * 2
                    if sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("cloaking") or sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("cloaking") then
                        rl = level
                    end

                    if not sys.bNeedsPower then
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(indicatorsSubsys[math.min(8, rl)],
                        activationTimer[shipManager.iShipId])
                    else
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(indicatorsSys[math.min(8, rl)],
                            activationTimer[shipManager.iShipId])
                    end

                end

                local bonusrooms = userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms
                if bonusrooms and (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0) then
                    local room = systemBox.pSystem.roomId
                    if bonusrooms[room] then
                        local sys = systemBox.pSystem
                        if not sys.bNeedsPower then
                            Graphics.CSurface.GL_RenderPrimitiveWithAlpha(indicatorsSubsys[math.min(8, level)],
                                activationTimer[shipManager.iShipId])
                        else
                            Graphics.CSurface.GL_RenderPrimitiveWithAlpha(indicatorsSys[math.min(8, level)],
                                activationTimer[shipManager.iShipId])
                        end
                    end
                end
            end
        end
    end)

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(system)
    if system and system:GetId() == Hyperspace.ShipSystem.NameToSystemId("lily_shock_neutralizer") then
        system:ForceDecreasePower(system.healthState.second)
        system.bNeedsPower = false
        system.bBoostable = false
    end
end)
