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




local vter = mods.multiverse.vter


--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_fiber_liner(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner") then
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_system_disabled")
            end
            return string.format(Hyperspace.Text:GetText("tooltip_lily_fiber_liner_level"), tostring(level * 15))
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_fiber_liner_level"), tostring(level * 15))
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_fiber_liner)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_fiber_liner(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_fiber_liner" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_fiber_liner_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_fiber_liner" and not systemBox.bPlayerUI
end

local corners = {}
script.on_init(function()
    corners[1] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_fiberliner_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[2] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_fiberliner_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[3] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_fiberliner_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[4] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_fiberliner_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
end)



script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
        local lily_fiber_liner_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_fiber_liner"))

        --Remove ion if it has any
        if lily_fiber_liner_system.iLockCount > 0 then
            lily_fiber_liner_system.iLockCount = 0
            lily_fiber_liner_system.lockTimer.currTime = lily_fiber_liner_system.lockTimer.currGoal
        end

        lily_fiber_liner_system.bExploded = false

        local level = lily_fiber_liner_system.healthState.second
        lily_fiber_liner_system.bNeedsPower = false
        lily_fiber_liner_system.bBoostable = false

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_fiber_liner = level
        end

        if shipManager:HasAugmentation("UPG_LILY_BUNKER_FIBER") == 0 then
            shipManager:AddAugmentation("HIDDEN UPG_LILY_BUNKER_FIBER")
        end

        if shipManager:HasAugmentation("UPG_LILY_FIBER_REGEN") > 0 or shipManager:HasAugmentation("EX_LILY_FIBER_REGEN") > 0 then
            lily_fiber_liner_system:PartialRepair(4, true)
            if lily_fiber_liner_system:Functioning() then
                for sys in vter(shipManager.vSystemList) do
                    ---@type Hyperspace.ShipSystem
                    sys = sys
                    if sys then
                        sys:PartialRepair(0.20 * lily_fiber_liner_system.healthState.first, true)
                    end
                end
            end
        end
    end
end)


script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM,
    function(ship, projectile, location, damage, newTile, beamHit)

        --[[local cdamage = projectile and projectile.extend.customDamage.def or nil
        if cdamage then
            print("erosionChance", cdamage.erosionChance)
            print("statBoostChance", cdamage.statBoostChance)
            print("roomStatBoostChance", cdamage.roomStatBoostChance)
        end--]]

        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
            local lily_fiber_liner_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_fiber_liner"))
            local currentLayers = lily_fiber_liner_system.healthState.first or 0
            if currentLayers == nil or currentLayers == 0 then
                return Defines.Chain.CONTINUE, beamHit
            end

            if ship.ship:GetSelectedRoomId(location.x, location.y, true) == -1 then
                return Defines.Chain.CONTINUE, beamHit
            end

            if ship:HasAugmentation("UPG_LILY_FIBER_PRIORITY") > 0 or ship:HasAugmentation("EX_LILY_FIBER_PRIORITY") > 0 then
                local crewCount = ship:CountCrewShipId(ship.ship:GetSelectedRoomId(location.x, location.y, true), ship.iShipId)
                if crewCount <= 0 then
                    return Defines.Chain.CONTINUE, beamHit
                end
            end

            local maxAbsorb = currentLayers

            if ship:HasAugmentation("UPG_LILY_FIBER_STRONG") > 0 or ship:HasAugmentation("EX_LILY_FIBER_STRONG") > 0 then
                maxAbsorb = maxAbsorb * 2
            end

            local cdamage = projectile and projectile.extend.customDamage.def or nil



            if cdamage == nil then
                cdamage = Hyperspace.CustomDamageDefinition()
            end

            if ship:HasAugmentation("UPG_LILY_FIBER_HAZARD") > 0 or ship:HasAugmentation("EX_LILY_FIBER_HAZARD") > 0 then
                damage.fireChance = math.max(0, damage.fireChance - maxAbsorb)
                damage.breachChance = math.max(0, damage.breachChance - maxAbsorb)
                damage.stunChance = math.max(0, damage.stunChance - maxAbsorb)
                damage.iStun = math.max(0, damage.iStun - maxAbsorb * 2)
                --[[if cdamage then
                    cdamage.erosionChance = math.max(0, cdamage.erosionChance - maxAbsorb)
                    cdamage.statBoostChance = math.max(0, cdamage.statBoostChance - maxAbsorb)
                    cdamage.roomStatBoostChance = math.max(0, cdamage.roomStatBoostChance - maxAbsorb)
                end--]]
            end

            local hitDamage = damage.iPersDamage
            if not (cdamage and cdamage.noPersDamage) then
                hitDamage = hitDamage + damage.iDamage
            end

            local absorbedDamage = math.max(math.min(hitDamage, maxAbsorb), 0)

            damage.iPersDamage = damage.iPersDamage - absorbedDamage

            if beamHit == Defines.BeamHit.NEW_ROOM then

                local chance = absorbedDamage * 0.15

                local takenDmg = math.floor(chance)
                chance = chance - math.floor(chance)
                if math.random() < chance then
                    takenDmg = takenDmg + 1
                end

                Hyperspace.Sounds:PlaySoundMix("lily_fiber_liner_hit_1", -1, false)

                lily_fiber_liner_system.healthState.first = math.max(0, lily_fiber_liner_system.healthState.first - takenDmg)
            end

        end
        return Defines.Chain.CONTINUE, beamHit
    end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA,
    function(ship, projectile, location, damage, forceHit, shipFriendlyFire)
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
            local lily_fiber_liner_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner"))

            local currentLayers = lily_fiber_liner_system.healthState.first or 0
            if currentLayers == nil or currentLayers == 0 then
                return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
            end

            if ship.ship:GetSelectedRoomId(location.x, location.y, true) == -1 then
                return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
            end
            if damage.ownerId == ship.iShipId and damage.bFriendlyFire then
                return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
            end

            if ship:HasAugmentation("UPG_LILY_FIBER_PRIORITY") > 0 or ship:HasAugmentation("EX_LILY_FIBER_PRIORITY") > 0 then
                local crewCount = ship:CountCrewShipId(ship.ship:GetSelectedRoomId(location.x, location.y, true), ship.iShipId)
                if crewCount <= 0 then
                    return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
                end
            end

            local maxAbsorb = currentLayers

            if ship:HasAugmentation("UPG_LILY_FIBER_STRONG") > 0 or ship:HasAugmentation("EX_LILY_FIBER_STRONG") > 0 then
                maxAbsorb = maxAbsorb * 2
            end

            local cdamage = projectile and projectile.extend.customDamage.def or nil
            if cdamage == nil then
                cdamage = Hyperspace.CustomDamageDefinition()
            end

            if ship:HasAugmentation("UPG_LILY_FIBER_HAZARD") > 0 or ship:HasAugmentation("EX_LILY_FIBER_HAZARD") > 0 then
                damage.fireChance = math.max(0, damage.fireChance - maxAbsorb)
                damage.breachChance = math.max(0, damage.breachChance - maxAbsorb)
                damage.stunChance = math.max(0, damage.stunChance - maxAbsorb)
                damage.iStun = math.max(0, damage.iStun - maxAbsorb * 2)
                --[[if cdamage then
                    cdamage.erosionChance = math.max(0, cdamage.erosionChance - maxAbsorb)
                    cdamage.statBoostChance = math.max(0, cdamage.statBoostChance - maxAbsorb)
                    cdamage.roomStatBoostChance = math.max(0, cdamage.roomStatBoostChance - maxAbsorb)
                end--]]
            end

            local hitDamage = damage.iPersDamage
            if not (cdamage and cdamage.noPersDamage) then
                hitDamage = hitDamage + damage.iDamage
            end

            local absorbedDamage = math.max(math.min(hitDamage, maxAbsorb), 0)

            damage.iPersDamage = damage.iPersDamage - absorbedDamage

            if projectile then
                userdata_table(projectile, "mods.lilyinno.fiberliner").absorbed = absorbedDamage
            end
            --[[
            local chance = absorbedDamage * 0.25

            local takenDmg = math.floor(chance)
            chance = chance - math.floor(chance)
            if math.random() < chance then
                takenDmg = takenDmg + 1
            end

            lily_fiber_liner_system.healthState.first = math.max(0, lily_fiber_liner_system.healthState.first - takenDmg)
            --]]

        end
        return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
    end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT,
    function(ship, projectile, location, damage, shipFriendlyFire)

        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
            local lily_fiber_liner_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_fiber_liner"))
            local absorbedDamage = nil
            if projectile then
                absorbedDamage = projectile and userdata_table(projectile, "mods.lilyinno.fiberliner").absorbed
            end




            if absorbedDamage ~= nil and not (damage.bFriendlyFire and damage.ownerId == ship.iShipId) then
                local currentLayers = lily_fiber_liner_system.healthState.first or 0
                if currentLayers > 0 then
                    Hyperspace.Sounds:PlaySoundMix("lily_fiber_liner_hit_1", -1, false)
                    if absorbedDamage and absorbedDamage > 0 then
                        local chance = absorbedDamage * 0.20
                        
                        local takenDmg = math.floor(chance)
                        chance = chance - math.floor(chance)
                        if math.random() < chance then
                            takenDmg = takenDmg + 1
                        end
                        
                        Hyperspace.Sounds:PlaySoundMix("lily_fiber_liner_hit_1", -1, false)
                        
                        lily_fiber_liner_system.healthState.first = math.max(0, lily_fiber_liner_system.healthState.first - takenDmg)
                    end
                end
            end

        end
        return Defines.Chain.CONTINUE
    end)


local function render_fiber_liner_effects(ship, experimental)
    if not (corners and corners[1]) then
        corners[1] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_fiberliner_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[2] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_fiberliner_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[3] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_fiberliner_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[4] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_fiberliner_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    end

    local shipManager = Hyperspace.ships(ship.iShipId)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
        local rooms = ship.vRoomList


        local usedCorners = corners

        local working = not shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")):CompletelyDestroyed()


        if working and not (Hyperspace.metaVariables.lily_fiber_liner_rendering_disabled and Hyperspace.metaVariables.lily_fiber_liner_rendering_disabled > 0) then
            local color = Graphics.GL_Color(1, 1, 1, 1)
            Graphics.CSurface.GL_SetColorTint(color)
            for room in vter(rooms) do
                ---@type Hyperspace.Room
                room = room
                local sys = shipManager:GetSystemInRoom(room.iRoomId)

                local priorityok = true

                if ship:HasAugmentation("UPG_LILY_FIBER_PRIORITY") > 0 or ship:HasAugmentation("EX_LILY_FIBER_PRIORITY") > 0 then
                    local crewCount = shipManager:CountCrewShipId(room.iRoomId, ship.iShipId)
                    if crewCount <= 0 then
                        priorityok = false
                    end
                end


                if priorityok and not (sys and sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")) then
                    local rect = room.rect


                    Graphics.CSurface.GL_Translate(rect.x, rect.y)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(usedCorners[1], 0.5)
                    Graphics.CSurface.GL_Translate(rect.w, 0)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(usedCorners[2], 0.5)
                    Graphics.CSurface.GL_Translate(0, rect.h)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(usedCorners[3], 0.5)
                    Graphics.CSurface.GL_Translate(-rect.w, 0)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(usedCorners[4], 0.5)
                    Graphics.CSurface.GL_Translate(0, -rect.h)
                    Graphics.CSurface.GL_Translate(-rect.x, -rect.y)
                end
            end
            Graphics.CSurface.GL_RemoveColorTint()
        end
    end
end

script.on_render_event(Defines.RenderEvents.SHIP_SPARKS, render_fiber_liner_effects, function() end)

local lily_recursionguard = false

---@diagnostic disable-next-line: undefined-field
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, function(crew, stat, def, amount, value)
    if mods.lilyinno.checkStartOK() then
        ---@type Hyperspace.CrewMember
        crew = crew
        ---@type Hyperspace.CrewStat
        stat = stat
        if crew and (not crew.bOutOfGame) and (crew.currentShipId == 0 or crew.currentShipId == 1) then
            local currentShipManager = Hyperspace.ships(crew.currentShipId)
            local crewShipManager = Hyperspace.ships(crew.iShipId)

            if currentShipManager and crewShipManager and not lily_recursionguard then
                lily_recursionguard = true
                if (crewShipManager:HasAugmentation("UPG_LILY_FIBER_AETHER") > 0 or crewShipManager:HasAugmentation("EX_LILY_FIBER_AETHER") > 0) and crew.iShipId then
                    local power, unused = crew.extend:CalculateStat(Hyperspace.CrewStat.BONUS_POWER)
                    if power and power > 0.5 then
                        if stat == Hyperspace.CrewStat.DAMAGE_MULTIPLIER then
                            amount = amount * 1.3
                        end
                        if stat == Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER then
                            amount = amount * 1.3
                        end
                        if stat == Hyperspace.CrewStat.DAMAGE_ENEMIES_AMOUNT then
                            amount = amount * 1.3
                        end
                        if stat == Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER then
                            amount = amount * 1.3
                        end
                    end
                end
                lily_recursionguard = false
            end
        end
    end
    return Defines.Chain.CONTINUE, amount, value
end)


mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner")] = mods.multiverse
    .register_system_icon("lily_fiber_liner")


script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(system)
    if system and system:GetId() == Hyperspace.ShipSystem.NameToSystemId("lily_fiber_liner") then
        system:ForceDecreasePower(system.healthState.second)
        system.bNeedsPower = false
        system.bBoostable = false
    end
end)
