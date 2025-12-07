local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment

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

local extraAnimations = {}
local rechargeTimer = {}
rechargeTimer[0] = 0
rechargeTimer[1] = 0
local loadComplete = {}
loadComplete[0] = false
loadComplete[1] = false

local def0XCREWSLOT = Hyperspace.StatBoostDefinition()
def0XCREWSLOT.stat = Hyperspace.CrewStat.CREW_SLOTS
def0XCREWSLOT.value = true
def0XCREWSLOT.amount = 0.0
def0XCREWSLOT.boostType = Hyperspace.StatBoostDefinition.BoostType.MULT
def0XCREWSLOT.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
def0XCREWSLOT.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
def0XCREWSLOT.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
def0XCREWSLOT.duration = 99
def0XCREWSLOT.priority = 999999
def0XCREWSLOT.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(def0XCREWSLOT)

local defNOCLONE = Hyperspace.StatBoostDefinition()
defNOCLONE.stat = Hyperspace.CrewStat.NO_CLONE
defNOCLONE.value = true
defNOCLONE.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOCLONE.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOCLONE.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOCLONE.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOCLONE.duration = 99
defNOCLONE.priority = 9999
defNOCLONE.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOCLONE)

local defNOSLOT = Hyperspace.StatBoostDefinition()
defNOSLOT.stat = Hyperspace.CrewStat.NO_SLOT
defNOSLOT.value = true
defNOSLOT.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOSLOT.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOSLOT.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOSLOT.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOSLOT.duration = 99
defNOSLOT.priority = 9999
defNOSLOT.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOSLOT)

local defNOWARNING = Hyperspace.StatBoostDefinition()
defNOWARNING.stat = Hyperspace.CrewStat.NO_WARNING
defNOWARNING.value = true
defNOWARNING.boostType = Hyperspace.StatBoostDefinition.BoostType.SET
defNOWARNING.boostSource = Hyperspace.StatBoostDefinition.BoostSource.AUGMENT
defNOWARNING.shipTarget = Hyperspace.StatBoostDefinition.ShipTarget.ALL
defNOWARNING.crewTarget = Hyperspace.StatBoostDefinition.CrewTarget.ALL
defNOWARNING.duration = 99
defNOWARNING.priority = 9999
defNOWARNING.realBoostId = Hyperspace.StatBoostDefinition.statBoostDefs:size()
Hyperspace.StatBoostDefinition.statBoostDefs:push_back(defNOWARNING)


--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_infusion_bay(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay") then
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_infusion_bay_disabled")
            end
            return string.format(Hyperspace.Text:GetText("tooltip_lily_infusion_bay_level"), tostring(level * 2), tostring(13 - level * 3))
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_infusion_bay_level"), tostring(level * 2),
        tostring(13 - level * 3))
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_infusion_bay)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_infusion_bay(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_infusion_bay" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_infusion_bay_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_infusion_bay" and not systemBox.bPlayerUI
end

---@param shipManager Hyperspace.ShipManager
---@param crewFilter? boolean
---@return number
local function get_taken_infusions_count(shipManager, crewFilter)
    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
    local count = 0
    for crew in vter(shipManager.vCrewList) do
        ---@type Hyperspace.CrewMember
        crew = crew
        if crew.iShipId == shipManager.iShipId and userdata_table(crew, "mods.lilyinno.infusionbay") and userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion and (not crewFilter or crew.selectionState > 0.1) then
            count = count + 1
        end
    end
    if otherShipManager then
        for crew in vter(otherShipManager.vCrewList) do
            ---@type Hyperspace.CrewMember
            crew = crew
            if crew.iShipId == shipManager.iShipId and userdata_table(crew, "mods.lilyinno.infusionbay") and userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion and (not crewFilter or crew.selectionState > 0.1) then
                count = count + 1
            end
        end
    end
    return count
end

---@param crew Hyperspace.CrewMember
---@param amount integer 1 - small healing, 2 - medium healing, 3 - large healing
local function healCrewmember(crew, amount)
    amount = math.max(amount, 0)

    local healing = math.max(amount * 15, crew:GetMaxHealth() * 0.15 * amount)
    crew:DirectModifyHealth(healing)
end

local function get_activate_text(infusionName)
    return Hyperspace.Text:GetText("tooltip_lily_infusion_bay_activate_" .. infusionName)
    
end

local function get_effect_text(infusionName)
    return Hyperspace.Text:GetText("tooltip_lily_infusion_bay_effect_" .. infusionName)
end

-- -13, 64
local lily_infusion_bayBaseOffset_x = 37    --35
local lily_infusion_bayBaseOffset_y = -86   ---40
local lily_infusion_bayButtonOffset_x = 45 --35
local lily_infusion_bayButtonOffset_y = -4 ---40
local lily_infusion_bayButtonOffset_x_2 = 0  --35
local lily_infusion_bayButtonOffset_y_2 = -25 ---40
local buttons = {}
local buttonOffsets = {}
local functions = {}
local tooltips = {}

--Handles initialization of custom system box
local function lily_infusion_bay_construct_system_box(systemBox)
    if is_lily_infusion_bay(systemBox) then
        systemBox.extend.xOffset = 66
        local activateButtonReconstitution = Hyperspace.Button()
        activateButtonReconstitution:OnInit("systemUI/button_infusion_reconstitution",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x, lily_infusion_bayButtonOffset_y))
        activateButtonReconstitution.hitbox.x = 1
        activateButtonReconstitution.hitbox.y = 1
        activateButtonReconstitution.hitbox.w = 20
        activateButtonReconstitution.hitbox.h = 19
        systemBox.table.activateButtonReconstitution = activateButtonReconstitution
        
        local activateButtonCombatstimulant = Hyperspace.Button()
        activateButtonCombatstimulant:OnInit("systemUI/button_infusion_combatstimulant",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 1,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 1))
        activateButtonCombatstimulant.hitbox.x = 1
        activateButtonCombatstimulant.hitbox.y = 1
        activateButtonCombatstimulant.hitbox.w = 20
        activateButtonCombatstimulant.hitbox.h = 19
        systemBox.table.activateButtonCombatstimulant = activateButtonCombatstimulant

        local activateButtonGaseous = Hyperspace.Button()
        activateButtonGaseous:OnInit("systemUI/button_infusion_gaseous",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 2,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 2))
        activateButtonGaseous.hitbox.x = 1
        activateButtonGaseous.hitbox.y = 1
        activateButtonGaseous.hitbox.w = 20
        activateButtonGaseous.hitbox.h = 19
        systemBox.table.activateButtonGaseous = activateButtonGaseous

        local activateButtonLocked = Hyperspace.Button()
        activateButtonLocked:OnInit("systemUI/button_infusion_locked",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonLocked.hitbox.x = 1
        activateButtonLocked.hitbox.y = 1
        activateButtonLocked.hitbox.w = 20
        activateButtonLocked.hitbox.h = 19
        systemBox.table.activateButtonLocked = activateButtonLocked

        local activateButtonOverloaded = Hyperspace.Button()
        activateButtonOverloaded:OnInit("systemUI/button_infusion_overloaded",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonOverloaded.hitbox.x = 1
        activateButtonOverloaded.hitbox.y = 1
        activateButtonOverloaded.hitbox.w = 20
        activateButtonOverloaded.hitbox.h = 19
        systemBox.table.activateButtonOverloaded = activateButtonOverloaded

        local activateButtonChaotic = Hyperspace.Button()
        activateButtonChaotic:OnInit("systemUI/button_infusion_chaotic",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonChaotic.hitbox.x = 1
        activateButtonChaotic.hitbox.y = 1
        activateButtonChaotic.hitbox.w = 20
        activateButtonChaotic.hitbox.h = 19
        systemBox.table.activateButtonChaotic = activateButtonChaotic

        local activateButtonFireborne = Hyperspace.Button()
        activateButtonFireborne:OnInit("systemUI/button_infusion_fireborne",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonFireborne.hitbox.x = 1
        activateButtonFireborne.hitbox.y = 1
        activateButtonFireborne.hitbox.w = 20
        activateButtonFireborne.hitbox.h = 19
        systemBox.table.activateButtonFireborne = activateButtonFireborne

        local activateButtonExplosive = Hyperspace.Button()
        activateButtonExplosive:OnInit("systemUI/button_infusion_explosive",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonExplosive.hitbox.x = 1
        activateButtonExplosive.hitbox.y = 1
        activateButtonExplosive.hitbox.w = 20
        activateButtonExplosive.hitbox.h = 19
        systemBox.table.activateButtonExplosive = activateButtonExplosive

        local activateButtonPhoenix = Hyperspace.Button()
        activateButtonPhoenix:OnInit("systemUI/button_infusion_phoenix",
            Hyperspace.Point(lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
                lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3))
        activateButtonPhoenix.hitbox.x = 1
        activateButtonPhoenix.hitbox.y = 1
        activateButtonPhoenix.hitbox.w = 20
        activateButtonPhoenix.hitbox.h = 19
        systemBox.table.activateButtonPhoenix = activateButtonPhoenix

        buttons["reconstitution"] = activateButtonReconstitution
        buttons["combatstimulant"] = activateButtonCombatstimulant
        buttons["gaseous"] = activateButtonGaseous
        buttons["locked"] = activateButtonLocked
        buttons["overloaded"] = activateButtonOverloaded
        buttons["chaotic"] = activateButtonChaotic
        buttons["fireborne"] = activateButtonFireborne
        buttons["explosive"] = activateButtonExplosive
        buttons["phoenix"] = activateButtonPhoenix
        buttonOffsets["reconstitution"] = Hyperspace.Point(lily_infusion_bayButtonOffset_x,
        lily_infusion_bayButtonOffset_y)
        buttonOffsets["combatstimulant"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 1,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 1)
        buttonOffsets["gaseous"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 2,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 2)
        buttonOffsets["locked"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        buttonOffsets["overloaded"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        buttonOffsets["chaotic"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        buttonOffsets["fireborne"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        buttonOffsets["explosive"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        buttonOffsets["phoenix"] = Hyperspace.Point(
            lily_infusion_bayButtonOffset_x + lily_infusion_bayButtonOffset_x_2 * 3,
            lily_infusion_bayButtonOffset_y + lily_infusion_bayButtonOffset_y_2 * 3)
        
        tooltips["reconstitution"] = "Grants 0.85x combat damage resistance, 1.5hp/s health regeneration, 0.5x movement speed for the duration. 45 HP/% heal, 14 second sickness."
        tooltips["combatstimulant"] = "Grants 1.5x combat damage, door damage and movement speed, which diminishes over the course of the effect (1.25x after 5 seconds, 1.1x after 10 seconds). 15 HP/% heal, 21 second sickness."
        tooltips["gaseous"] = "Grants Suffocation/fire/mind control immunity, same-ship teleporation, but combat damage is reduced to 0.5x. 30 HP/% heal, 7 second sickness."
        tooltips["locked"] = "None."
        tooltips["overloaded"] = "Stuns self and all nearby crew for 5s and deals 2 ion damage to system. Systems on your ship have 1 ion removed instead. 30 HP/% heal, 21 second sickness."
        tooltips["chaotic"] = "Applies an effect of a random other infusion. Hopefully there isn't any adverse effects on your crew. 15 - 75 HP/% heal, 7 second sickness."
        tooltips["fireborne"] = "Starts a fire in current room. Grants ability to heal from fires for the duration, but also makes your crew suffocate at rapid speed, even if they are normally immune. 15 HP/% heal, 21 second sickness."
        tooltips["explosive"] = "Explodes, damaging all enemies in the room by 15 HP. System on enemy ships take 1 damage, while on your ship are repaired by 1 bar instead. 15 HP/% heal, 14 second sickness." --Grants lingering 3 HP/s regeneration for the duration. 
        tooltips["phoenix"] = "Crew cannot die during the duration. If they take damage that would normally kill them, they are instead healed to full health and teleported to the Infusion Bay. When this effect triggers, allies in the same room get healed by 30 HP/%, and the Infusion Bay takes 1 unresistable ion damage with double lockout duration. Won't save your boarders if enemy ship explodes. 15 HP/% heal, 14 second sickness."
    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, lily_infusion_bay_construct_system_box)

--Handles mouse movement
local function lily_infusion_bay_mouse_move(systemBox, x, y)
    if is_lily_infusion_bay(systemBox) then
        for name, activateButton in pairs(buttons) do
            activateButton:MouseMove(x - buttonOffsets[name].x, y - buttonOffsets[name].y,
                false)
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_MOVE, lily_infusion_bay_mouse_move)

local function lily_infusion_bay_click(systemBox, shift)
    if is_lily_infusion_bay(systemBox) then
        for name, activateButton in pairs(buttons) do
            ---@type Hyperspace.Button
            activateButton = activateButton
            local shipManager = Hyperspace.ships.player
            local crewControl = Hyperspace.App.gui.crewControl

            local crewFilter = Hyperspace.App.gui.crewControl.selectedCrew:size() > 0
            
            --[[for cmem in vter(crewControl.selectedCrew) do
                ---@type Hyperspace.CrewMember
                cmem = cmem
                if not crewFilter then
                    crewFilter = {}
                end
                crewFilter[cmem] = true
            end--]]

            --print("Filter", crewFilter == nil and "nil" or "ok")
            --[[if crewFilter then
                for index, value in pairs(crewFilter) do
                    ---@type Hyperspace.CrewMember
                    index = index
                    print(index, index:GetName())
                end
            end--]]
            if activateButton.bHover and activateButton.bActive and get_taken_infusions_count(shipManager, crewFilter) > 0 then
                local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                    "lily_infusion_bay"))
                if name ~= "locked" then
                    Hyperspace.Sounds:PlaySoundMix("lily_infusion_activation_1", -1, false)
                    for crew in vter(shipManager.vCrewList) do
                        ---@type Hyperspace.CrewMember
                        crew = crew
                        --print("A: ", crew, crew.selectionState, crew:GetName(), crewFilter and "true" or "false", crewFilter[crew])
                        if crew.iShipId == shipManager.iShipId and userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion and (not crewFilter or crew.selectionState > 0.1) then
                            userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion = false
                            if userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop then
                                userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = false
                            end
                            local animation = Hyperspace.Animations:GetAnimation("lily_infusion_activated_effect")
                            animation:Start(false)
                            animation.tracker:SetLoop(false, 0)
                            userdata_table(crew, "mods.lilyinno.infusionbay").animation = animation
                            functions[name](crew)
                        end
                    end
                    local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
                    if otherShipManager then
                        for crew in vter(otherShipManager.vCrewList) do
                            ---@type Hyperspace.CrewMember
                            crew = crew
                            if crew.iShipId == shipManager.iShipId and userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion and (not crewFilter or crew.selectionState > 0.1) then
                                userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion = false
                                if userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop then
                                    userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = false
                                end
                                local animation = Hyperspace.Animations:GetAnimation("lily_infusion_activated_effect")
                                animation:Start(false)
                                animation.tracker:SetLoop(false, 0)
                                userdata_table(crew, "mods.lilyinno.infusionbay").animation = animation
                                functions[name](crew)
                            end
                        end
                    end
                    --print(name .. " activated")
                end
            end
        end
    end
    return Defines.Chain.CONTINUE
end
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_MOUSE_CLICK, lily_infusion_bay_click)


--Utility function to see if the system is ready for use
local function lily_infusion_bay_ready(shipSystem)
    return shipSystem:Functioning() and shipSystem.iHackEffect <= 1
end

local buttonBase = {}
local syringes = {}
script.on_init(function()
    buttonBase[1] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_infusion_bay_base_1.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    buttonBase[2] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_infusion_bay_base_2.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    buttonBase[3] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_infusion_bay_base_3.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    syringes["empty"] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/infusion_empty.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    syringes["full"] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/infusion_full.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    syringes["taken"] = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/infusion_taken.png",
        lily_infusion_bayBaseOffset_x, lily_infusion_bayBaseOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    
    for i = 0, 1, 1 do
        loadComplete[i] = false
        --print("Loaded:", "mods_lilyinno_infusionbay_" .. i,
        --    Hyperspace.metaVariables["mods_lilyinno_infusionbay_" .. i])
    end
end)


---@param shipManager Hyperspace.ShipManager
---@return string
local function get_fourth_button_name(shipManager)
    local name = "locked"
    
    if shipManager and Hyperspace.playerVariables then
        local var = Hyperspace.playerVariables.lily_infusion_bay_fourthtype_select
        
        if var and var == 1 then
            name = "overloaded"
        elseif var and var == 2 then
            name = "chaotic"
        elseif var and var == 3 then
            name = "fireborne"
        elseif var and var == 4 then
            name = "explosive"
        elseif var and var == 5 then
            name = "phoenix"
        end
        
    end

    return name
end

--[[
---@param shipManager Hyperspace.ShipManager
---@return string
local function get_fourth_button_name(shipManager)
    local name = "locked"

    if shipManager:HasAugmentation("UPG_LILY_INFUSION_OVERLOADED_UNLOCK") > 0 then
        name = "overloaded"
    elseif shipManager:HasAugmentation("UPG_LILY_INFUSION_CHAOTIC_UNLOCK") > 0 then
        name = "chaotic"
    elseif shipManager:HasAugmentation("UPG_LILY_INFUSION_FIREBORNE_UNLOCK") > 0 then
        name = "fireborne"
    elseif shipManager:HasAugmentation("UPG_LILY_INFUSION_EXPLOSIVE_UNLOCK") > 0 then
        name = "explosive"
    elseif shipManager:HasAugmentation("UPG_LILY_INFUSION_PHOENIX_UNLOCK") > 0 then
        name = "phoenix"
    end


    return name
end
--]]

script.on_render_event(Defines.RenderEvents.SHIP, function() end, function(ship)
    local commandGui = Hyperspace.App.gui
    --Graphics.CSurface.GL_PushMatrix()
    --Graphics.CSurface.GL_RenderPrimitive(syringes["taken"])
    --Graphics.CSurface.GL_PopMatrix()
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


--Handles custom rendering
---@param systemBox Hyperspace.SystemBox
---@param ignoreStatus boolean
local function lily_infusion_bay_render(systemBox, ignoreStatus)
    if is_lily_infusion_bay(systemBox) then
        local shipManager = Hyperspace.ships.player
        local activateButtons = {}
        activateButtons[1] = buttons["reconstitution"]
        activateButtons[2] = buttons["combatstimulant"]
        activateButtons[3] = buttons["gaseous"]
        activateButtons[4] = buttons[get_fourth_button_name(shipManager)]
        local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
        "lily_infusion_bay"))

        local level = lily_infusion_bay_system.healthState.second
        Graphics.CSurface.GL_RenderPrimitive(buttonBase[math.max(math.min(level, 3), 1)])

        --local ttpre = "Activate the carried "
        --local ttpost = " infusions. Effects: "

        for name, button in pairs(buttons) do
            ---@type Hyperspace.Button
            button = button
            button.bActive = false
        end

        for _, button in ipairs(activateButtons) do
            ---@type Hyperspace.Button
            button = button
            button.bActive = lily_infusion_bay_ready(lily_infusion_bay_system) and
                (userdata_table(shipManager, "mods.lilyinno.infusionbay").dormantInfusions and userdata_table(shipManager, "mods.lilyinno.infusionbay").dormantInfusions > 0)
        


            if button.bHover then
                if _ == 1 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_activate_text("reconstitution") .. get_effect_text("reconstitution")
                elseif _== 2 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_activate_text("combatstimulant") .. get_effect_text("combatstimulant")
                elseif _== 3 then
                    Hyperspace.Mouse.bForceTooltip = true
                    Hyperspace.Mouse.tooltip = get_activate_text("gaseous") .. get_effect_text("gaseous")
                else
                    if get_fourth_button_name(shipManager) == "locked" then
                        Hyperspace.Mouse.bForceTooltip = true
                        Hyperspace.Mouse.tooltip = Hyperspace.Text:GetText("tooltip_lily_infusion_bay_locked")
                    else
                        Hyperspace.Mouse.bForceTooltip = true
                        Hyperspace.Mouse.tooltip = get_activate_text(get_fourth_button_name(shipManager)) ..
                            get_effect_text(get_fourth_button_name(shipManager))
                    end
                end
            end

            button:OnRender()
        end


        Graphics.CSurface.GL_Translate(32, 81, 0)
        local tCount = userdata_table(shipManager, "mods.lilyinno.infusionbay").dormantInfusions or 0
        local fCount = userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions or 0
        local num = 1
        local sum = {x = 0, y = 0}

        for i = 1, tCount, 1 do
            Graphics.CSurface.GL_RenderPrimitive(syringes["taken"])
            Graphics.CSurface.GL_Translate(0, num % 2 > 0 and -9 or -21, 0)
            sum.y = sum.y + ((num % 2 > 0) and -9 or -21)
            num = num + 1
        end
        for i = 1, fCount, 1 do
            Graphics.CSurface.GL_RenderPrimitive(syringes["full"])
            Graphics.CSurface.GL_Translate(0, num % 2 > 0 and -9 or -21, 0)
            sum.y = sum.y + ((num % 2 > 0) and -9 or -21)
            num = num + 1
        end

        if rechargeTimer[0] < 1 then
            local height = math.ceil(rechargeTimer[0] * 10)
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_SET, 1, 1)
            Graphics.CSurface.GL_DrawRect(lily_infusion_bayBaseOffset_x + 1, lily_infusion_bayBaseOffset_y + 11 - height,
                10,
                height,
                Graphics.GL_Color(1, 1, 1, 1))
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_USE, 1, 1)
            if systemBox.pSystem.iHackEffect > 1 then
                Graphics.CSurface.GL_RenderPrimitiveWithColor(syringes["full"], Graphics.GL_Color(0.75, 0.15, 1, 1))
            else
                Graphics.CSurface.GL_RenderPrimitiveWithColor(syringes["full"], Graphics.GL_Color(0.6, 0.8, 1, 0.8))
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            Graphics.CSurface.GL_SetStencilMode(Graphics.STENCIL_IGNORE, 1, 1)
            Graphics.CSurface.GL_Translate(-32, -81, 0)
            Graphics.CSurface.GL_Translate(-sum.x, -sum.y, 0)
        end
    end
end
script.on_render_event(Defines.RenderEvents.SYSTEM_BOX,
    function(systemBox, ignoreStatus)
        return Defines.Chain.CONTINUE
    end, lily_infusion_bay_render)


script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(shipManager)
if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay")) then
        local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_infusion_bay"))


        if not userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions then
            userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = 0
        end
        local storedInfusions = userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions


        local level = lily_infusion_bay_system.healthState.second
        local level2 = lily_infusion_bay_system.healthState.first
        local efflevel = lily_infusion_bay_system:GetEffectivePower()

        local maxTotalInfusions = level2 * 2

        local dormantInfusions = get_taken_infusions_count(shipManager)
        userdata_table(shipManager, "mods.lilyinno.infusionbay").dormantInfusions = dormantInfusions

        local maxStoredInfusions = maxTotalInfusions - dormantInfusions

        storedInfusions = math.max(0, maxStoredInfusions)
        userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = storedInfusions
    end
end)

--[[
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
            userdata_table(shipManager, "mods.lilyinno.shockneutralizer").targetroom = roomAtMouse
            userdata_table(shipManager, "mods.lilyinno.shockneutralizer").selectmode = false
            rechargeTimer[shipManager.iShipId] = 0
            Hyperspace.Sounds:PlaySoundMix("lily_infusion_bay_select_1", -1, false)
            --if shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") > 0 or shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE") > 0 then
            local adjRooms
            if (shipManager:HasAugmentation("UPG_LILY_WIDE_NEUTRALIZE") + shipManager:HasAugmentation("EX_LILY_WIDE_NEUTRALIZE")) >= 2 then
                adjRooms = get_adjacent_rooms(shipManager.iShipId, roomAtMouse, true)
            else
                adjRooms = get_adjacent_rooms(shipManager.iShipId, roomAtMouse, false)
            end
            userdata_table(shipManager, "mods.lilyinno.shockneutralizer").bonusrooms = adjRooms
            --print("count: " .. #adjRooms)
            --for id, point in pairs(adjRooms) do
            --    print(id)
            --end
            --end
            --print(roomAtMouse)
        end
    end
    return Defines.Chain.CONTINUE
end)
--]]

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay")) then
        local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_infusion_bay"))


        if lily_infusion_bay_system:CompletelyDestroyed() then
            rechargeTimer[shipManager.iShipId] = 0
        end

        if not userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions then
            userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = 0
        end
        local storedInfusions = userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions


        lily_infusion_bay_system.bBoostable = false
        local level = lily_infusion_bay_system.healthState.second
        local level2 = lily_infusion_bay_system.healthState.first
        local efflevel = lily_infusion_bay_system:GetEffectivePower()
        local multiplier = 1 / (13 - efflevel * 3)
        if lily_infusion_bay_system.iHackEffect > 1 then
            multiplier = -0.5
        end
        if efflevel == 0 then
            multiplier = 0
        end

        local maxTotalInfusions = level2 * 2

        local dormantInfusions = get_taken_infusions_count(shipManager)
        userdata_table(shipManager, "mods.lilyinno.infusionbay").dormantInfusions = dormantInfusions

        local maxStoredInfusions = maxTotalInfusions - dormantInfusions

        if mods.lilyinno.checkVarsOK() and not loadComplete[shipManager.iShipId] then
            local v = Hyperspace.playerVariables
            ["mods_lilyinno_infusionbay_" .. (shipManager.iShipId > 0.5 and "1" or "0")]
            if v > 0 then
                storedInfusions = v - 1
            end
            loadComplete[shipManager.iShipId] = true
        end

        storedInfusions = math.max(0, math.min(maxStoredInfusions, storedInfusions))
        if maxStoredInfusions == storedInfusions then
            multiplier = 0
            rechargeTimer[shipManager.iShipId] = 0
        end

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_infusion_bay = level
            local cApp = Hyperspace.App
            local gui = cApp.gui

            -- If player is not in danger
            local inSafeEnviroment = gui.upgradeButton.bActive
                and not gui.event_pause
                and cApp.world.space.projectiles:empty()
                and not shipManager.bJumping
            if inSafeEnviroment then
                multiplier = multiplier * 4
            end
        end

        if not mods.lilyinno.checkVarsOK() then
            multiplier = 0
        end
        if storedInfusions > 0 and lily_infusion_bay_system.iHackEffect > 1 then
            if rechargeTimer[shipManager.iShipId] == 0 then
                rechargeTimer[shipManager.iShipId] = 0.99
                storedInfusions = storedInfusions - 1
            end
        end

        if storedInfusions < maxStoredInfusions then
            rechargeTimer[shipManager.iShipId] = math.max(0,
            math.min(1, rechargeTimer[shipManager.iShipId] + multiplier * Hyperspace.FPS.SpeedFactor / 16))
            if rechargeTimer[shipManager.iShipId] >= 1 then
                
                storedInfusions = storedInfusions + 1
                userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = storedInfusions
                rechargeTimer[shipManager.iShipId] = 0
                Hyperspace.Sounds:PlaySoundMix("lily_infusion_recharge_1", -1, false)
            end
        else
            rechargeTimer[shipManager.iShipId] = 0
        end

        userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = storedInfusions
        local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
        if otherShipManager and (otherShipManager.bDestroyed or otherShipManager.ship.hullIntegrity == 0) then
            for crew in vter(otherShipManager.vCrewList) do
                ---@type Hyperspace.CrewMember
                crew = crew
                local type = userdata_table(crew, "mods.lilyinno.infusionbay").infusionType
                if crew.iShipId == shipManager.iShipId and type and (type == "phoenix" or type == "chaoticphoenix") then
                    --crew.health.first = 1
                    --print("!!!")
                    crew:SetCurrentShip(shipManager.iShipId)
                    crew:SetRoom(lily_infusion_bay_system.roomId)
                    --[[crew.currentShipId = shipManager.iShipId
                    local slot = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId):GetClosestSlot(
                    Hyperspace.Point(shipManager:GetRoomCenter(lily_infusion_bay_system.roomId).x,
                        shipManager:GetRoomCenter(lily_infusion_bay_system.roomId).y), shipManager.iShipId, false)
                    crew.currentSlot = slot]]--
                end
            end
        end
        if mods.lilyinno.checkVarsOK() and loadComplete[shipManager.iShipId] then
            Hyperspace.playerVariables["mods_lilyinno_infusionbay_" .. (shipManager.iShipId > 0.5 and "1" or "0")] =
            math.floor(storedInfusions + dormantInfusions) + 1
        end
    end
end)

local phoenixBlacklist = {}
phoenixBlacklist["eldritch_thing"] = true
phoenixBlacklist["eldritch_thing_weak"] = true
phoenixBlacklist["eldritch_cat"] = true

script.on_internal_event(Defines.InternalEvents.CREW_LOOP, function(crew)
    local shipManager = Hyperspace.ships(crew.iShipId)
    if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay")) then
        local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_infusion_bay"))
        if userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion == nil then
            userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion = false
        end


        --phoenix infusion LILY_FORCE_RECALL
        if userdata_table(crew, "mods.lilyinno.infusionbay").infusionType then
            local type = userdata_table(crew, "mods.lilyinno.infusionbay").infusionType
            if type == "phoenix" or type == "chaoticphoenix" and (not phoenixBlacklist[crew.species]) then
                --local otherShipManager = Hyperspace.ships(1 - crew.iShipId)
                ---@type Hyperspace.TimerHelper
                local timer = userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer
                local force = false
                if timer.currTime + time_increment() >= timer.currGoal and type == "phoenix" then
                    force = true
                end
                if crew.health.first < 4 or crew.bDead or force then
                    local currentShipManager = Hyperspace.ships(crew.currentShipId)
                    for cr in vter(currentShipManager.vCrewList) do
                        ---@type Hyperspace.CrewMember
                        cr = cr
                        if cr.iRoomId == crew.iRoomId and cr.iShipId == crew.iShipId then
                            healCrewmember(cr, 2)
                        end
                    end
                    crew.bDead = false
                    crew.bOutOfGame = false
                    crew.bFrozen = false
                    --crew.currentShipId = crew.iShipId
                    --crew.iRoomId = lily_infusion_bay_system.roomId
                    if crew.extend.deathTimer then
                        crew.extend.deathTimer.currTime = 0
                        crew.extend.deathTimer:Stop()
                        crew.extend.deathTimer = nil
                    end
                    crew.health.first = crew.health.second
                    crew:DirectModifyHealth(crew:GetMaxHealth())
                    crew.extend:InitiateTeleport(crew.iShipId, lily_infusion_bay_system.roomId)
                    if lily_infusion_bay_system:GetLocked() then
                        lily_infusion_bay_system:AddLock(2)
                    else
                        lily_infusion_bay_system:LockSystem(2)
                    end
                    lily_infusion_bay_system:ForceDecreasePower(1)
                    if timer then
                        timer.currTime = timer.currGoal
                    end
                end
            end
        end


        if crew:IsCrew() and (not crew.bOutOfGame) then
            if userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer then
                userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer:Update()
                if userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer:Done() then
                    userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = false
                    if userdata_table(crew, "mods.lilyinno.infusionbay").infusionType and userdata_table(crew, "mods.lilyinno.infusionbay").infusionType ~= "sickness" then
                        Hyperspace.Sounds:PlaySoundMix("lily_infusion_wearoff_1", -1, false)
                        if userdata_table(crew, "mods.lilyinno.infusionbay").sicknessAmount then
                            local timer = Hyperspace.TimerHelper(false)
                            timer:Start_Float(7 * userdata_table(crew, "mods.lilyinno.infusionbay").sicknessAmount)
                            local animationLoop = Hyperspace.Animations:GetAnimation(
                                "lily_infusion_sickness_debuff")
                            animationLoop.tracker:SetLoop(true, 0)
                            animationLoop:Start(false)
                            userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = animationLoop
                            userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer = timer
                            userdata_table(crew, "mods.lilyinno.infusionbay").infusionType = "sickness"
                            userdata_table(crew, "mods.lilyinno.infusionbay").sicknessAmount = false
                        end
                    elseif userdata_table(crew, "mods.lilyinno.infusionbay").infusionType and userdata_table(crew, "mods.lilyinno.infusionbay").infusionType == "sickness" then
                        userdata_table(crew, "mods.lilyinno.infusionbay").infusionType = false
                        userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer = false
                    end
                end
            end
        end
        local cApp = Hyperspace.App
        local gui = cApp.gui
        -- If player is not in danger
        local inSafeEnviroment = gui.upgradeButton.bActive
            and not gui.event_pause
            and cApp.world.space.projectiles:empty()
            and not shipManager.bJumping
        if inSafeEnviroment then
            local type = userdata_table(crew, "mods.lilyinno.infusionbay").infusionType
            ---@type Hyperspace.TimerHelper
            local timer = userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer
            if type and type == "sickness" then
                if timer then
                    timer.currTime = timer.currGoal
                end
            end
        end

        

        if shipManager:HasAugmentation("UPG_LILY_SICKNESS_RECOVERY") > 0 or shipManager:HasAugmentation("EX_LILY_SICKNESS_RECOVERY") > 0 then
            if userdata_table(crew, "mods.lilyinno.infusionbay").infusionType then
                local mult = 0
                if lily_infusion_bay_system:GetEffectivePower() > 0 then
                    mult = mult + 1
                    mult = mult + 0.75 * lily_infusion_bay_system:GetEffectivePower()
                end
                local type = userdata_table(crew, "mods.lilyinno.infusionbay").infusionType
                if crew.iRoomId == lily_infusion_bay_system.roomId and crew.currentShipId == shipManager.iShipId and type == "sickness" then
                    ---@type Hyperspace.TimerHelper
                    local timer = userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer
                    if timer then
                        timer.currTime = timer.currTime + (Hyperspace.FPS.SpeedFactor / 16) * mult
                    end
                end
            end
        end


        if crew:IsCrew() and (not crew.bOutOfGame) and userdata_table(crew, "mods.lilyinno.infusionbay").animation then
            if userdata_table(crew, "mods.lilyinno.infusionbay").animation:Done() then
                userdata_table(crew, "mods.lilyinno.infusionbay").animation = false
            else
                ---@type Hyperspace.Animation
                local animation = userdata_table(crew, "mods.lilyinno.infusionbay").animation
                --animation.position = Hyperspace.Pointf(crew.x, crew.y)
                animation:Update()
            end
        end
        if crew:IsCrew() and (not crew.bOutOfGame) and userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop then
            ---@type Hyperspace.Animation
            local animationLoop = userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop
            --animationLoop.position = Hyperspace.Pointf(crew.x, crew.y)
            animationLoop:Update()
        end

        if crew:IsCrew() and (not crew.bOutOfGame) and crew.iRoomId == lily_infusion_bay_system.roomId and 
            crew.currentShipId == crew.iShipId and
            (shipManager.ship:GetSelectedRoomId(crew:GetFinalGoal().x, crew:GetFinalGoal().y, true) < 0 or 
            shipManager.ship:GetSelectedRoomId(crew:GetFinalGoal().x, crew:GetFinalGoal().y, true) == lily_infusion_bay_system.roomId) and
            (not userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion) and
            (not userdata_table(crew, "mods.lilyinno.infusionbay").infusionType) then

            if not userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer then
                local timer = Hyperspace.TimerHelper(false)
                timer:Start_Float(1.0)
                userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer = timer
            end
            if userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer then
                userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer:Update()
            end
            if userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer and userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer:Done() then
                local stored = userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions or 0
                if stored > 0 then
                    stored = stored - 1
                    userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion = true
                    userdata_table(shipManager, "mods.lilyinno.infusionbay").storedInfusions = stored
                    Hyperspace.Sounds:PlaySoundMix("lily_infusion_pickup_1", -1, false)
                    local animation = Hyperspace.Animations:GetAnimation("lily_infusion_acquired_effect")
                    --animation.position = Hyperspace.Pointf(crew.x, crew.y)
                    animation:Start(false)
                    animation.tracker:SetLoop(false, 0)
                    userdata_table(crew, "mods.lilyinno.infusionbay").animation = animation
                    local animationLoop = Hyperspace.Animations:GetAnimation(
                        "lily_infusion_dormant_buff")
                    --animationLoop.position = Hyperspace.Pointf(crew.x, crew.y)
                    animationLoop.tracker:SetLoop(true, 0)
                    animationLoop:Start(false)
                    userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = animationLoop
                    userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer = false
                else
                    ---@type Hyperspace.TimerHelper
                    local timer = userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer
                    timer.currTime = 0
                    timer:Start_Float(0.1)
                end

            end
        else
            if userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer then
                userdata_table(crew, "mods.lilyinno.infusionbay").takeTimer = false
            end
        end


    end


end)


script.on_render_event(Defines.RenderEvents.CREW_MEMBER_HEALTH, function(crew)
local shipManager = Hyperspace.ships(crew.iShipId)
    if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay")) then
        local lily_infusion_bay_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_infusion_bay"))
        if userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion == nil then
            userdata_table(crew, "mods.lilyinno.infusionbay").hasDormantInfusion = false
        end
        local position = crew:GetPosition()
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(position.x, position.y, 0)
        if crew:IsCrew() and (not crew.bOutOfGame) and userdata_table(crew, "mods.lilyinno.infusionbay").animation then
            if userdata_table(crew, "mods.lilyinno.infusionbay").animation:Done() then
                userdata_table(crew, "mods.lilyinno.infusionbay").animation = false
            else
                ---@type Hyperspace.Animation
                local animation = userdata_table(crew, "mods.lilyinno.infusionbay").animation
                Graphics.CSurface.GL_Translate(-animation.info.frameWidth / 2, -animation.info.frameHeight / 2, 0)
                --animation.position = Hyperspace.Pointf(crew.x, crew.y)
                animation:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
                Graphics.CSurface.GL_Translate(animation.info.frameWidth / 2, animation.info.frameHeight / 2, 0)
            end
        end

        if crew:IsCrew() and (not crew.bOutOfGame) and userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop then
            ---@type Hyperspace.Animation
            local animationLoop = userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop
            Graphics.CSurface.GL_Translate(-animationLoop.info.frameWidth / 2, -animationLoop.info.frameHeight / 2, 0)
            --animationLoop.position = Hyperspace.Pointf(crew.x, crew.y)
            animationLoop:OnRender(1, Graphics.GL_Color(1, 1, 1, 1), false)
            Graphics.CSurface.GL_Translate(-animationLoop.info.frameWidth / 2, -animationLoop.info.frameHeight / 2, 0)
        end
        Graphics.CSurface.GL_PopMatrix()
    end

end, function() end)



mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_infusion_bay")] = mods.multiverse
    .register_system_icon("lily_infusion_bay")






---@param crew Hyperspace.CrewMember
---@param name string Name of the infusion
---@param sickness integer 1 - 7s, 2 - 14s, 3 - 21s
---@param animationName string
local function setInfusionData(crew, name, sickness, animationName)
    userdata_table(crew, "mods.lilyinno.infusionbay").infusionType = name
    userdata_table(crew, "mods.lilyinno.infusionbay").sicknessAmount = math.max(sickness, 0)
    local timer = Hyperspace.TimerHelper(false)
    timer:Start_Float(15)
    userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer = timer
    local animationLoop = Hyperspace.Animations:GetAnimation(animationName)
    animationLoop.tracker:SetLoop(true, 0)
    animationLoop:Start(false)
    userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = animationLoop
end

---@param crew Hyperspace.CrewMember
---@param amount integer 1 - 7s, 2 - 14s, 3 - 21s
local function applySickness(crew, amount)
    userdata_table(crew, "mods.lilyinno.infusionbay").infusionType = "sickness"
    userdata_table(crew, "mods.lilyinno.infusionbay").sicknessAmount = math.max(amount, 0)
    local timer = Hyperspace.TimerHelper(false)
    timer:Start_Float(amount * 7)
    userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer = timer
    local animationLoop = Hyperspace.Animations:GetAnimation("lily_infusion_sickness_debuff")
    animationLoop.tracker:SetLoop(true, 0)
    animationLoop:Start(false)
    userdata_table(crew, "mods.lilyinno.infusionbay").animationLoop = animationLoop
end


---@diagnostic disable-next-line: undefined-field
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, function(crew, stat, def, amount, value)
    ---@type Hyperspace.CrewMember
    crew = crew
    ---@type Hyperspace.CrewStat
    stat = stat

    if userdata_table(crew, "mods.lilyinno.infusionbay").infusionType then
        local type = userdata_table(crew, "mods.lilyinno.infusionbay").infusionType
        if type == "sickness" then
            if stat == Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER then
                amount = amount * 0.85
            end
        elseif type == "reconstitution" then
            if stat == Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER then
                amount = amount * 0.5
            end
            if stat == Hyperspace.CrewStat.DAMAGE_TAKEN_MULTIPLIER then
                amount = amount * 0.85
            end
            if stat == Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT then
                amount = amount + 1.5
            end
        elseif type == "chaoticreconstitution" then
            if stat == Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER then
                amount = amount * 0.75
            end
            if stat == Hyperspace.CrewStat.DAMAGE_TAKEN_MULTIPLIER then
                amount = amount * 0.5
            end
            if stat == Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT then
                amount = amount + 1.5
            end
        elseif type == "combatstimulant" then
            ---@type Hyperspace.TimerHelper
            local timer = userdata_table(crew, "mods.lilyinno.infusionbay").infusionTimer
            local mult = 1.5
            if timer.currTime > 5 then
                mult = 1.25
            end
            if timer.currTime > 10 then
                mult = 1.1
            end

            if stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER then
                amount = amount * mult
            end
            if stat == Hyperspace.CrewStat.DOOR_DAMAGE_MULTIPLIER then
                amount = amount * mult
            end
            if stat == Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER then
                amount = amount * mult
            end
            if stat == Hyperspace.CrewStat.DAMAGE_ENEMIES_AMOUNT then
                amount = amount * mult
            end
        elseif type == "chaoticcombatstimulant" then
            if stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER then
                amount = amount * 1.5
            end
            if stat == Hyperspace.CrewStat.DOOR_DAMAGE_MULTIPLIER then
                amount = amount * 1.5
            end
            if stat == Hyperspace.CrewStat.MOVE_SPEED_MULTIPLIER then
                amount = amount * 1.5
            end
            if stat == Hyperspace.CrewStat.DAMAGE_ENEMIES_AMOUNT then
                amount = amount * 3
            end
        elseif type == "gaseous" then
            if stat == Hyperspace.CrewStat.CAN_SUFFOCATE then
                value = false
            end
            if stat == Hyperspace.CrewStat.CAN_BURN then
                value = false
            end
            if stat == Hyperspace.CrewStat.CAN_PHASE_THROUGH_DOORS then
                value = true
            end
            if stat == Hyperspace.CrewStat.TELEPORT_MOVE then
                value = true
            end
            if stat == Hyperspace.CrewStat.RESISTS_MIND_CONTROL then
                value = true
            end
            if stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER then
                amount = amount * 0.5
            end

        elseif type == "chaoticgaseous" then
            if stat == Hyperspace.CrewStat.CAN_SUFFOCATE then
                value = false
            end
            if stat == Hyperspace.CrewStat.CAN_BURN then
                value = false
            end
            if stat == Hyperspace.CrewStat.CAN_PHASE_THROUGH_DOORS then
                value = true
            end
            if stat == Hyperspace.CrewStat.TELEPORT_MOVE then
                value = true
            end
            if stat == Hyperspace.CrewStat.RESISTS_MIND_CONTROL then
                value = true
            end
            if stat == Hyperspace.CrewStat.CAN_FIGHT then
                value = false
            end
            if stat == Hyperspace.CrewStat.ALL_DAMAGE_TAKEN_MULTIPLIER then
                amount = amount * 0.25
            end
        elseif type == "fireborne" then
            if stat == Hyperspace.CrewStat.CAN_SUFFOCATE then
                value = true
            end
            if stat == Hyperspace.CrewStat.CAN_BURN then
                value = true
            end
            if stat == Hyperspace.CrewStat.SUFFOCATION_MODIFIER then
                amount = math.max(amount, 2)
            end
            if stat == Hyperspace.CrewStat.FIRE_DAMAGE_MULTIPLIER then
                amount = math.min(amount, -1)
            end
        elseif type == "chaoticfireborne" then
            if stat == Hyperspace.CrewStat.CAN_SUFFOCATE then
                value = true
            end
            if stat == Hyperspace.CrewStat.CAN_BURN then
                value = true
            end
            if stat == Hyperspace.CrewStat.FIRE_DAMAGE_MULTIPLIER then
                amount = math.min(amount, -1)
            end
            if stat == Hyperspace.CrewStat.SUFFOCATION_MODIFIER then
                amount = math.max(amount / 2, 0.5)
            end
            if stat == Hyperspace.CrewStat.FIRE_REPAIR_MULTIPLIER then
                amount = math.max(amount * 5, 5)
            end
        elseif type == "explosive" then
            if stat == Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT then
                amount = amount + 3
            end
        elseif type == "chaoticexplosive" then
            if stat == Hyperspace.CrewStat.DAMAGE_TAKEN_MULTIPLIER then
                amount = amount * 0.8
            end
            if stat == Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT then
                amount = amount + 3
            end
        elseif type == "phoenix" then
            if stat == Hyperspace.CrewStat.CAN_TELEPORT then
                value = true
            end
            if stat == Hyperspace.CrewStat.DEATH_EFFECT then
                value = false
                amount = 0
            end

        elseif type == "chaoticphoenix" then
            if stat == Hyperspace.CrewStat.ACTIVE_HEAL_AMOUNT then
                amount = amount + 3
            end
            if stat == Hyperspace.CrewStat.CAN_TELEPORT then
                value = true
            end
            if stat == Hyperspace.CrewStat.DEATH_EFFECT then
                value = false
                amount = 0
            end
        end

    end



    
    return Defines.Chain.CONTINUE, amount, value
end)



---@param crew Hyperspace.CrewMember
local function activateLocked(crew, name) end
functions["locked"] = activateLocked

---@param crew Hyperspace.CrewMember
local function activateReconstitution(crew)
    healCrewmember(crew, 3)
    setInfusionData(crew, "reconstitution", 2, "lily_reconstitution_buff")


    --local manager = Hyperspace.StatBoostManager.GetInstance().CreateTimedAugmentBoost

    --[[local defs = Hyperspace.StatBoostDefinition.savedStatBoostDefs--["RAD_MOVE"]

    local num = 1
    for str, def in pairs(defs) do
        ---@type Hyperspace.StatBoostDefinition
        def = def
        print(num)
        print(str .. ": " .. def.realBoostId)
        print(str .. ": " .. def.stat)
        print(str .. ": " .. def.duration)
        num = num + 1
    end]]--


    --manager:CreateTimedAugmentBoost(Hyperspace.StatBoost(def), crew)
end
functions["reconstitution"] = activateReconstitution

---@param crew Hyperspace.CrewMember
local function activateCombatstimulant(crew)
    healCrewmember(crew, 1)
    setInfusionData(crew, "combatstimulant", 3, "lily_combatstimulant_buff")

end
functions["combatstimulant"] = activateCombatstimulant

---@param crew Hyperspace.CrewMember
local function activateGaseous(crew)
    healCrewmember(crew, 2)
    setInfusionData(crew, "gaseous", 1, "lily_gaseous_buff")

end
functions["gaseous"] = activateGaseous

---@param crew Hyperspace.CrewMember
local function activateOverloaded(crew)
    healCrewmember(crew, 2)
    applySickness(crew, 3)
    local onEnemyShip = crew.iShipId ~= crew.currentShipId
    local room = crew.iRoomId
    local currentShipManager = Hyperspace.ships(crew.currentShipId)
    for cr in vter(currentShipManager.vCrewList) do
        ---@type Hyperspace.CrewMember
        cr = cr
        if cr.iRoomId == crew.iRoomId then
            cr.fStunTime = math.max(cr.fStunTime, 5)
        end
    end
    local dmg = Hyperspace.Damage()
    if onEnemyShip then
        dmg.iIonDamage = 2
        currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
    else
        local sys = currentShipManager:GetSystemInRoom(crew.iRoomId)
        if sys then
            if sys:GetEffectivePower() < sys.originalPower then
                sys:ForceIncreasePower(1)
            end
            if sys.iLockCount > 0 then
                sys.iLockCount = math.max(0, sys.iLockCount - 1)
            end
        end
    end
    Hyperspace.Sounds:PlaySoundMix("ionHit1", 4, false)
    local anim = Hyperspace.Animations:GetAnimation("explosion_big1_ion")
    anim.position = Hyperspace.Pointf(crew.x - anim.info.frameWidth / 2, crew.y - anim.info.frameHeight / 2)
    anim:Start(false)
    table.insert(extraAnimations, {anim = anim, id = crew.currentShipId})
    
end
functions["overloaded"] = activateOverloaded

local chaoticlist = { 
    "chaoticreconstitution", 
    "chaoticcombatstimulant", 
    "chaoticgaseous", 
    "chaoticoverloaded", 
    "chaoticfireborne", 
    "chaoticexplosive", 
    "chaoticphoenix", 
    "chaoticreconstitution",
    "chaoticcombatstimulant",
    "chaoticgaseous",
    "chaoticoverloaded",
    "chaoticfireborne",
    "chaoticexplosive",
    "chaoticphoenix",
    "chaoticsiren"
}

---@param crew Hyperspace.CrewMember
local function activateChaotic(crew)
    healCrewmember(crew, math.random(1, 5))
    local currentShipManager = Hyperspace.ships(crew.currentShipId)
    local buff = chaoticlist[math.random(#chaoticlist)]

    if buff == "chaoticoverloaded" then 
        applySickness(crew, 1)
        local onEnemyShip = crew.iShipId ~= crew.currentShipId
        local room = crew.iRoomId
        for cr in vter(currentShipManager.vCrewList) do
            ---@type Hyperspace.CrewMember
            cr = cr
            if cr.iRoomId == crew.iRoomId then
                cr.fStunTime = math.max(cr.fStunTime, 5)
            end
        end
        local dmg = Hyperspace.Damage()
        if onEnemyShip then
            dmg.iIonDamage = 2
            currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
        else
            local sys = currentShipManager:GetSystemInRoom(crew.iRoomId)
            if sys then
                for i = 1, 2, 1 do
                    
                    if sys:GetEffectivePower() < sys.originalPower then
                        sys:ForceIncreasePower(1)
                    end
                    if sys.iLockCount > 0 then
                        sys.iLockCount = math.max(0, sys.iLockCount - 1)
                    end
                end
            end
        end
        Hyperspace.Sounds:PlaySoundMix("ionHit1", 4, false)
        local anim = Hyperspace.Animations:GetAnimation("explosion_big1_ion_chaos")
        anim.position = Hyperspace.Pointf(crew.x - anim.info.frameWidth / 2, crew.y - anim.info.frameHeight / 2)
        anim:Start(false)
        table.insert(extraAnimations, { anim = anim, id = crew.currentShipId })

    elseif buff == "chaoticexplosive" then
        applySickness(crew, 1)
        --setInfusionData(crew, buff, 1, "lily_invisible")
        local onEnemyShip = crew.iShipId ~= crew.currentShipId
        local room = crew.iRoomId
        for cr in vter(currentShipManager.vCrewList) do
            ---@type Hyperspace.CrewMember
            cr = cr
            if cr.iRoomId == crew.iRoomId and cr.iShipId ~= crew.iShipId then
                cr:ApplyDamage(-30)
            end
        end
        local dmg = Hyperspace.Damage()
        if onEnemyShip then
            dmg.iSystemDamage = 1
            currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
        else
            dmg.iSystemDamage = -1
            currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
        end
        local anim = Hyperspace.Animations:GetAnimation("explosion_big1_chaos")
        anim.position = Hyperspace.Pointf(crew.x - anim.info.frameWidth / 2, crew.y - anim.info.frameHeight / 2)
        anim:Start(false)
        table.insert(extraAnimations, { anim = anim, id = crew.currentShipId })
        Hyperspace.Sounds:PlaySoundMix("explosionShell", -1, false)
    elseif buff == "chaoticfireborne" then
        setInfusionData(crew, buff, 1, "lily_" .. buff .. "_buff")
        currentShipManager:StartFire(crew.iRoomId)
        currentShipManager:StartFire(crew.iRoomId)
        Hyperspace.Sounds:PlaySoundMix("fireBomb", -1, false)
    elseif buff == "chaoticsiren" then
        local siren1 = currentShipManager:AddCrewMemberFromString("Siren", "siren", crew.currentShipId ~= crew.iShipId, crew.iRoomId, true, false)
        local siren2 = currentShipManager:AddCrewMemberFromString("Siren", "siren", crew.currentShipId ~= crew.iShipId, crew.iRoomId, true, false)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(def0XCREWSLOT), siren1)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOCLONE), siren1)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOSLOT), siren1)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOWARNING), siren1)
        siren1.extend.deathTimer = Hyperspace.TimerHelper(false)
        siren1.extend.deathTimer:Start(60)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(def0XCREWSLOT), siren2)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOCLONE), siren2)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOSLOT), siren2)
        Hyperspace.StatBoostManager.GetInstance():CreateTimedAugmentBoost(Hyperspace.StatBoost(defNOWARNING), siren2)
        siren2.extend.deathTimer = Hyperspace.TimerHelper(false)
        siren2.extend.deathTimer:Start(60)
        Hyperspace.Sounds:PlaySoundMix("hc_spawn_1", -1, false)
    else
        
        setInfusionData(crew, buff, 1, "lily_" .. buff .. "_buff")
    end

end
functions["chaotic"] = activateChaotic

---@param crew Hyperspace.CrewMember
local function activateFireborne(crew)
    healCrewmember(crew, 1)
    setInfusionData(crew, "fireborne", 3, "lily_fireborne_buff")
    local currentShipManager = Hyperspace.ships(crew.currentShipId)
    currentShipManager:StartFire(crew.iRoomId)
    Hyperspace.Sounds:PlaySoundMix("fireBomb", -1, false)
end
functions["fireborne"] = activateFireborne

---@param crew Hyperspace.CrewMember
local function activateExplosive(crew)
    local currentShipManager = Hyperspace.ships(crew.currentShipId)
    healCrewmember(crew, 1)
    applySickness(crew, 2)
    --setInfusionData(crew, "explosive", 2, "lily_invisible")
    local onEnemyShip = crew.iShipId ~= crew.currentShipId
    local room = crew.iRoomId
    for cr in vter(currentShipManager.vCrewList) do
        ---@type Hyperspace.CrewMember
        cr = cr
        if cr.iRoomId == crew.iRoomId and cr.iShipId ~= crew.iShipId then
            cr:ApplyDamage(-15)
        end
    end
    local dmg = Hyperspace.Damage()
    if onEnemyShip then
        dmg.iSystemDamage = 1
        currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
    else
        dmg.iSystemDamage = -1
        currentShipManager:DamageArea(currentShipManager:GetRoomCenter(crew.iRoomId), dmg, true)
    end
    local anim = Hyperspace.Animations:GetAnimation("explosion_big1_green")
    anim.position = Hyperspace.Pointf(crew.x - anim.info.frameWidth / 2, crew.y - anim.info.frameHeight / 2)
    anim:Start(false)
    table.insert(extraAnimations, { anim = anim, id = crew.currentShipId })
    Hyperspace.Sounds:PlaySoundMix("explosionShell", -1, false)
end
functions["explosive"] = activateExplosive

---@param crew Hyperspace.CrewMember
local function activatePhoenix(crew)
    healCrewmember(crew, 1)
    setInfusionData(crew, "phoenix", 2, "lily_phoenix_buff")
end
functions["phoenix"] = activatePhoenix
