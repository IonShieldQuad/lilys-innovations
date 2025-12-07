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
local function get_level_description_lily_system_bracers(systemId, level, tooltip)
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers") then
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_system_disabled")
            end
            return string.format(Hyperspace.Text:GetText("tooltip_lily_system_bracers_level"), tostring(level))
        end
        return string.format(Hyperspace.Text:GetText("tooltip_lily_system_bracers_level"), tostring(level))
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_system_bracers)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_system_bracers(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_system_bracers" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_system_bracers_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_system_bracers" and not systemBox.bPlayerUI
end

local corners = {}
local cornersBroken = {}
local cornersShielded = {}
local cornersAether = {}
script.on_init(function()

    corners[1] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[2] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[3] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    corners[4] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

    cornersBroken[1] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_broken_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersBroken[2] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_broken_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersBroken[3] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_broken_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersBroken[4] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_broken_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

    cornersShielded[1] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_shielded_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersShielded[2] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_shielded_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersShielded[3] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_shielded_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersShielded[4] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_shielded_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

    cornersAether[1] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_aether_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersAether[2] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_aether_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersAether[3] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_aether_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    cornersAether[4] = Hyperspace.Resources:CreateImagePrimitiveString(
        "misc/lily_systembrace_aether_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    
end)



script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
        local lily_system_bracers_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
            "lily_system_bracers"))

        --Remove ion if it has any
        if lily_system_bracers_system.iLockCount > 0 then
            lily_system_bracers_system.iLockCount = 0
            lily_system_bracers_system.lockTimer.currTime = lily_system_bracers_system.lockTimer.currGoal
        end

        lily_system_bracers_system.bExploded = false

        local level = lily_system_bracers_system.healthState.second
        lily_system_bracers_system.bNeedsPower = false
        lily_system_bracers_system.bBoostable = false

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_system_bracers = level
        end

        local absorbedDamage = 0
        if not userdata_table(shipManager, "mods.lilyinno.systembracers").absorbedDamage then
            userdata_table(shipManager, "mods.lilyinno.systembracers").absorbedDamage = 0
            userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves = {}
        end
        if not userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves then
            userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves = {}
        end
        --absorbedDamage = userdata_table(shipManager, "mods.lilyinno.systembracers").absorbedDamage

        

        if lily_system_bracers_system.healthState.first > 0 then
            local fixed = false
            for _, data in pairs(userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves) do
                local sys = shipManager:GetSystem(data.id)
                if sys and data.id ~= Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers") then
                    local needed = data.hp - sys.healthState.first
                    if needed > 0 then
                        local repairAmount = math.min(lily_system_bracers_system.healthState.first, needed)
                        sys.healthState.first = sys.healthState.first + repairAmount
                        lily_system_bracers_system.healthState.first = math.max(0, lily_system_bracers_system.healthState.first - repairAmount)
                        absorbedDamage = absorbedDamage + repairAmount
                        fixed = true
                        if repairAmount > 0 then
                            sys.bExploded = false
                        end
                    end
                end
            end
            if fixed then
                Hyperspace.Sounds:PlaySoundMix("lily_bracers_hit_1", -1, false)
            end
        end

        --[[if shipManager.weaponSystem then
            if userdata_table(shipManager, "mods.lilyinno.systembracers").weaponRepower then
                userdata_table(shipManager, "mods.lilyinno.systembracers").weaponRepower = false
                if userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons then
                    local num = 0
                    for weapon in vter(shipManager.weaponSystem.weapons) do
                        ---@type Hyperspace.ProjectileFactory
                        weapon = weapon
                        weapon.powered = userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons[num] and true or false
                        num = num + 1
                    end
                    userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons = {}
                end
            end
        end--]]

        if absorbedDamage > 0 then
            --print(absorbedDamage)

            --lily_system_bracers_system.healthState.first = math.max(lily_system_bracers_system.healthState.first - absorbedDamage, 0)
        end

        if shipManager:HasAugmentation("UPG_LILY_BRACERS_REGEN") > 0 or shipManager:HasAugmentation("EX_LILY_BRACERS_REGEN") > 0 then
            lily_system_bracers_system:PartialRepair(0.75, true)
        end
        
        userdata_table(shipManager, "mods.lilyinno.systembracers").absorbedDamage = 0
        userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves = {}

        if shipManager:HasAugmentation("UPG_LILY_BRACERS_COVERAGE") > 0 or shipManager:HasAugmentation("EX_LILY_BRACERS_COVERAGE") > 0 then
            for sys in vter(shipManager.vSystemList) do
                ---@type Hyperspace.ShipSystem
                sys = sys
                table.insert(userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves,
                    { id = sys:GetId(), hp = math.min(sys.healthState.first, sys.healthState.second) })
            end
        end

    end
end)


local function render_system_bracers_effects(ship, experimental)
    if not (corners and corners[1]) then
        corners[1] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[2] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[3] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        corners[4] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

        cornersBroken[1] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_broken_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersBroken[2] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_broken_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersBroken[3] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_broken_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersBroken[4] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_broken_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

        cornersShielded[1] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_shielded_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersShielded[2] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_shielded_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersShielded[3] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_shielded_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersShielded[4] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_shielded_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

        cornersAether[1] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_aether_1.png", 1, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersAether[2] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_aether_2.png", -36, 1, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersAether[3] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_aether_3.png", -36, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
        cornersAether[4] = Hyperspace.Resources:CreateImagePrimitiveString(
            "misc/lily_systembrace_aether_4.png", 1, -36, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
    end

    local shipManager = Hyperspace.ships(ship.iShipId)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
        local rooms = ship.vRoomList

        local working = not shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")):CompletelyDestroyed()

        local usedCorners = corners

        if shipManager:HasAugmentation("UPG_LILY_BRACERS_COVERAGE") > 0 or shipManager:HasAugmentation("EX_LILY_BRACERS_COVERAGE") > 0 then
            usedCorners = cornersShielded
        end
        if shipManager:HasAugmentation("UPG_LILY_BRACERS_AETHER") > 0 or shipManager:HasAugmentation("EX_LILY_BRACERS_AETHER") > 0 then
            usedCorners = cornersAether
        end

        if not working then
            usedCorners = cornersBroken
        end
        if not (Hyperspace.metaVariables.lily_system_bracers_rendering_disabled and Hyperspace.metaVariables.lily_system_bracers_rendering_disabled > 0) then
            local color = Graphics.GL_Color(1, 1, 1, 1)
            Graphics.CSurface.GL_SetColorTint(color)
            for room in vter(rooms) do
                ---@type Hyperspace.Room
                room = room
                local sys = shipManager:GetSystemInRoom(room.iRoomId)
                if sys and sys:GetId() ~= Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers") then
                    
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

script.on_render_event(Defines.RenderEvents.SHIP_SPARKS, render_system_bracers_effects, function() end)




mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")] = mods.multiverse
    .register_system_icon("lily_system_bracers")


script.on_internal_event(Defines.InternalEvents.SYSTEM_ADD_DAMAGE, function(sys, projectile, amount)
    --print(2, Hyperspace.ShipSystem.SystemIdToName(sys:GetId()))
    --print("pre", amount)
    if not sys then
        return Defines.Chain.CONTINUE, amount
    end
    local ship = Hyperspace.ships(sys._shipObj.iShipId)
    if ship and ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
        local lily_system_bracers = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers"))
        if lily_system_bracers:CompletelyDestroyed() then
            return Defines.Chain.CONTINUE, amount
        end
        if lily_system_bracers:GetRoomId() == sys:GetRoomId() then
            return Defines.Chain.CONTINUE, amount
        end
        
        local absorbedDamage = math.max(0, math.min(lily_system_bracers.healthState.first, sys.healthState.first, amount))

        amount = amount - absorbedDamage
        --print("abs", absorbedDamage)
        --lily_system_bracers.healthState.first = lily_system_bracers.healthState.first - absorbedDamage
        if not userdata_table(ship, "mods.lilyinno.systembracers").absorbedDamage then
            userdata_table(ship, "mods.lilyinno.systembracers").absorbedDamage = 0
        end
        if absorbedDamage > 0 then
            --userdata_table(ship, "mods.lilyinno.systembracers").absorbedDamage =
            --userdata_table(ship, "mods.lilyinno.systembracers").absorbedDamage + absorbedDamage
            local absorbed = false
            if ship:HasAugmentation("UPG_LILY_BRACERS_THERMAL") > 0 or ship:HasAugmentation("EX_LILY_BRACERS_THERMAL") > 0 then
                absorbed = math.random() < 0.5
            end
            
            Hyperspace.Sounds:PlaySoundMix("lily_bracers_hit_1", -1, false)
            if absorbed then
                ship:StartFire(lily_system_bracers.roomId)
            else
                lily_system_bracers.healthState.first = math.max(
                lily_system_bracers.healthState.first - absorbedDamage, 0)
            end
            local overflow = Hyperspace.Damage()
            overflow.ownerId = projectile and projectile.ownerId or ship.iShipId
            overflow.iSystemDamage = amount
            ship:DamageSystem(sys:GetRoomId(), overflow)
            --print("post", amount)
            return Defines.Chain.PREEMPT, 0
        end
    end
    return Defines.Chain.CONTINUE, amount
end, 2147483647)


script.on_internal_event(Defines.InternalEvents.DAMAGE_SYSTEM, function(shipManager, projectile, roomId, damage)
    if shipManager and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
        local lily_system_bracers = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers"))

        local sys = shipManager:GetSystemInRoom(roomId)
        --print(1, Hyperspace.ShipSystem.SystemIdToName(sys:GetId()))
        --print(1, sys.healthState.first)

        if not userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves then
            userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves = {}
        end
        if sys then
            table.insert(userdata_table(shipManager, "mods.lilyinno.systembracers").systemSaves,
                { id = sys:GetId(), hp = math.min(sys.healthState.first, sys.healthState.second) })
        end 

        if sys and shipManager.weaponSystem and sys:GetId() == Hyperspace.ShipSystem.NameToSystemId("weapons") then
            userdata_table(shipManager, "mods.lilyinno.systembracers").weaponRepower = true
            userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons = {}
            local num = 0
            for weapon in vter(shipManager.weaponSystem.weapons) do
                ---@type Hyperspace.ProjectileFactory                
                weapon = weapon
                if weapon.powered then
                    userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons[num] = true
                else
                    userdata_table(shipManager, "mods.lilyinno.systembracers").savedWeapons[num] = false
                end
                num = num + 1
            end
        end

        --[[if not sys then
            return Defines.Chain.CONTINUE
        end
        if lily_system_bracers:GetId() == sys:GetId() then
            return Defines.Chain.CONTINUE
        end

        local noSysDamage = false
        if projectile then
            if projectile.extend.customDamage.def.noSysDamage then
                noSysDamage = true
            end            
        end

        local amount = damage.iSystemDamage
        if not noSysDamage then
            amount = amount + damage.iDamage
        end

        local absorbedDamage = math.max(0, math.min(lily_system_bracers.healthState.first, amount))

        amount = amount - absorbedDamage
        lily_system_bracers.healthState.first = lily_system_bracers.healthState.first - absorbedDamage
        if absorbedDamage > 0 then
            Hyperspace.Sounds:PlaySoundMix("lily_bracers_hit_1", -1, false)
            local repair = Hyperspace.Damage()
            repair.bFriendlyFire = true
            repair.ownerId = shipManager.iShipId
            repair.iSystemDamage = -absorbedDamage
            shipManager:DamageSystem(sys:GetId(), repair)
        end--]]
        return Defines.Chain.CONTINUE
    end
    return Defines.Chain.CONTINUE
end)

---@diagnostic disable-next-line: undefined-field
script.on_internal_event(Defines.InternalEvents.CALCULATE_STAT_POST, function(crew, stat, def, amount, value)
    --print("vars", mods.lilyinno.checkVarsOK())
    --print("start", mods.lilyinno.checkStartOK())
    if mods.lilyinno.checkStartOK() then
        ---@type Hyperspace.CrewMember
        crew = crew
        ---@type Hyperspace.CrewStat
        stat = stat
        if crew and (not crew.bOutOfGame) and (crew.currentShipId == 0 or crew.currentShipId == 1) then
            local currentShipManager = Hyperspace.ships(crew.currentShipId)

            if currentShipManager and currentShipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
                local bracers = currentShipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers"))
                if crew.iRoomId >= 0 and crew.iRoomId == currentShipManager:GetSystemRoom(Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers")) then
                    if stat == Hyperspace.CrewStat.REPAIR_SPEED_MULTIPLIER and currentShipManager:HasAugmentation("BOON_LILY_SYSTEM_BRACERS") == 0 then
                        amount = amount * 0.5
                    end
                    if stat == Hyperspace.CrewStat.FIRE_REPAIR_MULTIPLIER and currentShipManager:HasAugmentation("BOON_LILY_SYSTEM_BRACERS") == 0 then
                        amount = amount * 2
                    end
                    if stat == Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER then
                        amount = amount * 0.5
                    end
                end
                if not bracers:CompletelyDestroyed() and (currentShipManager:HasAugmentation("UPG_LILY_BRACERS_AETHER") > 0 or currentShipManager:HasAugmentation("EX_LILY_BRACERS_AETHER") > 0) and crew.iShipId ~= currentShipManager.iShipId then
                    local crewRoom = crew.iRoomId
                    local sys = currentShipManager:GetSystemInRoom(crewRoom)
                    if sys then
                        if stat == Hyperspace.CrewStat.SABOTAGE_SPEED_MULTIPLIER then
                            amount = amount * 0.5
                        end
                        if stat == Hyperspace.CrewStat.TRUE_HEAL_AMOUNT then
                            amount = amount - 2
                        end
                    end
                end
            end
        end
    end
    return Defines.Chain.CONTINUE, amount, value
end)

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SHIP_SYSTEM, function(system)
    
    if system and system:GetId() == Hyperspace.ShipSystem.NameToSystemId("lily_system_bracers") then
        system:ForceDecreasePower(system.healthState.second)
        system.bNeedsPower = false
        system.bBoostable = false
    end
end)