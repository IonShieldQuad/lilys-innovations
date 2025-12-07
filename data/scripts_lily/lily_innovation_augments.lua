local userdata_table = mods.multiverse.userdata_table
local vter = mods.multiverse.vter

--[[
script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SPACEDRONE, function(drone)
    print("CONSTRUCTED")
    print(drone.blueprint.name)
    print("Deployed: " .. tostring(drone.deployed))
    print("ID: " .. tostring(drone.iShipId))
    print("Boarder: " .. (drone:GetBoardingDrone() and "true" or "false"))
    local importantSystemList = {}
    importantSystemList["weapons"] = true
    importantSystemList["shields"] = true
    importantSystemList["cloaking"] = true
    
    if drone:GetBoardingDrone() then
        local tspace = drone.destinationSpace
        local otherShipManager = Hyperspace.ships(tspace)
        print("Target: " .. (drone.destinationLocation and (drone.destinationLocation.x .. "/" .. drone.destinationLocation.y) or "nil"))
        print("DestRoom: " ..
            tostring(otherShipManager.ship:GetSelectedRoomId(drone.destinationLocation.x,
                drone.destinationLocation.y, false)))

        local targets = {}
        local targets2 = {}

        local systems = otherShipManager.vSystemList

        for system in vter(systems) do
            ---@type Hyperspace.ShipSystem
            system = system
            if importantSystemList[system.name] then
                targets[#targets + 1] = system:GetRoomId()
            else
                targets2[#targets2 + 1] = system:GetRoomId()
            end
        end

        local target = nil
        if #targets > 0 then
            target = targets[math.random(#targets)]
        elseif #targets2 > 0 then
            target = targets2[math.random(#targets2)]
        end


        if target then
            drone.destinationLocation = otherShipManager:GetRoomCenter(target)
        end

        print("NewTarget: " .. (drone.destinationLocation and (drone.destinationLocation.x .. "/" .. drone.destinationLocation.y) or "nil"))
        print("NewDestRoom: " ..
            tostring(otherShipManager.ship:GetSelectedRoomId(drone.destinationLocation.x,
                drone.destinationLocation.y, false)))
    end
end)
--]]

local sun = false

script.on_game_event("BLUE_GIANT", false, function() sun = true end)
script.on_game_event("BLUE_GIANT_FLARE", false, function() sun = true end)

script.on_internal_event(Defines.InternalEvents.JUMP_LEAVE, function() sun = false end)

script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)

    if shipManager.cloneSystem and shipManager.cloneSystem.healthState.second > 0 then
        if shipManager:HasAugmentation("UPG_LILY_CLONEBAY_REGEN") > 0 or shipManager:HasAugmentation("EX_LILY_CLONEBAY_REGEN") > 0 then
            shipManager.cloneSystem:PartialRepair(0.25, true)
        end
    end

    if shipManager:HasAugmentation("UPG_CREW_OXYGEN") > 0 or shipManager:HasAugmentation("CREW_OXYGEN") > 0 then
        local mult = 0.8 * (shipManager:HasAugmentation("UPG_CREW_OXYGEN") + shipManager:HasAugmentation("CREW_OXYGEN"))

        local rooms = shipManager.ship.vRoomList

        for room in vter(rooms) do
            ---@type Hyperspace.Room
            room = room
            local numFires = shipManager:GetFireCount(room.iRoomId)

            if numFires > 0 then
                local o2sys = shipManager.oxygenSystem
                local vals = { 0, 0.3, 0.9, 1.8, 2.7, 4, 4, 4, 4, 4, 4, 4, 4, 4}
                if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("oxygen")) and o2sys then
                    o2sys:ModifyRoomOxygen(room.iRoomId, -vals[o2sys:GetEffectivePower() + 1] * mult )
                end
            end
        end
    end
    if shipManager:HasAugmentation("UPG_LILY_OXYGEN_BACKUP") > 0 or shipManager:HasAugmentation("EX_LILY_OXYGEN_BACKUP") > 0 then
        if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("oxygen")) then
            local o2sys = shipManager.oxygenSystem
            if (o2sys:CompletelyDestroyed() or o2sys:GetEffectivePower() == 0) and shipManager:GetFireCount(o2sys.roomId) == 0 then
                o2sys:ModifyRoomOxygen(o2sys.roomId, 0.12)
            end
        end
    end

    if shipManager:HasAugmentation("UPG_LILY_DOORS_FAILSAFE") > 0 or shipManager:HasAugmentation("EX_LILY_DOORS_FAILSAFE") > 0 then
        if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("doors")) then
            ---@type Hyperspace.ShipSystem
            local doorSys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("doors"))
            if (not shipManager:DoorsFunction() or doorSys:CompletelyDestroyed())then
                local ship = shipManager.ship
                for door in vter(ship.vDoorList) do
                    ---@type Hyperspace.Door
                    door = door
                    door.bOpen = false
                end
                for door in vter(ship.vOuterAirlocks) do
                    ---@type Hyperspace.Door
                    door = door
                    door.bOpen = false
                end
            end
        end
    end

    if shipManager:HasAugmentation("UPG_LILY_INN_PILOT") > 0 or shipManager:HasAugmentation("EX_LILY_INN_PILOT") > 0 then
        local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("pilot"))
        if sys and not sys:CompletelyDestroyed() then
            sys.bManned = true
            sys.iActiveManned = math.max(sys.iActiveManned, 1)
        end

    end
    if shipManager:HasAugmentation("UPG_LILY_INN_SENSORS") > 0 or shipManager:HasAugmentation("EX_LILY_INN_SENSORS") > 0 then
        local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("sensors"))
        if sys then
            sys.bManned = true
            sys.iActiveManned = math.max(sys.iActiveManned, 1)
        end
    end
    if shipManager:HasAugmentation("UPG_LILY_INN_DOORS") > 0 or shipManager:HasAugmentation("EX_LILY_INN_DOORS") > 0 then
        local sys = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("doors"))
        if sys and sys:Functioning() then
            sys.bManned = true
            sys.iActiveManned = math.max(sys.iActiveManned, 1)
        end
    end
    
    if shipManager:HasAugmentation("UPG_LILY_BATTERY_SURGE_OVERDRIVE") > 0 or shipManager:HasAugmentation("EX_LILY_BATTERY_SURGE_OVERDRIVE") > 0 then
        local battery = shipManager.batterySystem
        if battery and battery.lockTimer then
            local deionizationBoost = -0.20
            battery.lockTimer.currTime = battery.lockTimer.currTime + Hyperspace.FPS.SpeedFactor / 16 * deionizationBoost
        end
    end
    if shipManager:HasAugmentation("UPG_LILY_BATTERY_SOLAR_POWER") > 0 or shipManager:HasAugmentation("EX_LILY_BATTERY_SOLAR_POWER") > 0 then
        local battery = shipManager.batterySystem
        local space = Hyperspace.App.world.space
        sun = sun or space.sunLevel
        if battery and sun then
            if battery.lockTimer then
                battery.lockTimer.currTime = battery.lockTimer.currGoal
            
            end

        end 
    end

    --]]
    --[[
            ---@type Hyperspace.Room
            local o2room = shipManager.ship.vRoomList(shipManager.oxygenSystem.roomId)
            local graph = Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId)
            if (shipManager:GetFireCount(shipManager.oxygenSystem.roomId) > 0) then
                for i = 1, o2room.rect.w, 1 do
                    for j = 1, o2room.rect.h, 1 do
                        shipManager.fire                    end
                end
            end
        end
    
--]]


    if shipManager:HasAugmentation("UPG_LILY_DRONE_BOARDING_SMART") > 0 or shipManager:HasAugmentation("EX_LILY_DRONE_BOARDING_SMART") > 0 then
        local spaceManager = Hyperspace.App.world.space
        local otherShipManager = Hyperspace.ships(1 - shipManager.iShipId)
        if spaceManager and otherShipManager then
            local spacedrones = spaceManager.drones
            if spacedrones then
                for drone in vter(spacedrones) do
                    ---@type Hyperspace.SpaceDrone
                    drone = drone
                    if drone.deployed then

                        --print(drone.blueprint.name)
                        --print("Deployed: " .. tostring(drone.deployed))
                        --print("ID: " .. tostring(drone.iShipId))
                        --print("Boarder: " .. (drone:GetBoardingDrone() and "true" or "false"))
                        --print("Target: " .. (drone.destinationLocation and (drone.destinationLocation.x .. "/" .. drone.destinationLocation.y) or "nil"))
                        if drone:GetBoardingDrone() then
                            local boarder = drone:GetBoardingDrone()
                            --print("Location: " .. drone.currentLocation.x .. "/" .. drone.currentLocation.y)
                            --local otherShipManager = Hyperspace.ships(drone.destinationSpace)
                            local room = otherShipManager and otherShipManager.ship:GetSelectedRoomId(drone.currentLocation.x,
                                drone.currentLocation.y, false) or -1
                            --print("Room: " .. tostring(room))
                            --print("DestRoom: " .. tostring(otherShipManager.ship:GetSelectedRoomId(drone.destinationLocation.x, drone.destinationLocation.y, false)))

                            --If target is not set yet
                            if room == -1 and (not userdata_table(drone, "mods.lilyinno.dronetarget").target) then
                                --First, prioritize important rooms
                                local importantSystemList = {}
                                importantSystemList["weapons"] = true
                                importantSystemList["shields"] = true
                                importantSystemList["cloaking"] = true


                                local targets = {}
                                local targets2 = {}

                                local systems = otherShipManager.vSystemList

                                for system in vter(systems) do
                                    ---@type Hyperspace.ShipSystem
                                    system = system
                                    if importantSystemList[system.name] and not system:CompletelyDestroyed() then
                                        targets[#targets + 1] = system:GetRoomId()
                                    else
                                        targets2[#targets2 + 1] = system:GetRoomId()
                                    end
                                end

                                --room id
                                local target = nil
                                if #targets > 0 then
                                    target = targets[math.random(#targets)]
                                elseif #targets2 > 0 then
                                    target = targets2[math.random(#targets2)]
                                end

                                --local sys = otherShipManager:GetSystemInRoom(target or -1)
                                --print("SYSTEM1: " .. (sys and sys.name or "nil"))

                                --Check if other drones in flight have targets too and sync with them
                                for odrone in vter(spacedrones) do
                                    ---@type Hyperspace.SpaceDrone
                                    odrone = odrone
                                    if odrone ~= drone and odrone.deployed and 
                                    odrone:GetBoardingDrone() and 
                                    otherShipManager.ship:GetSelectedRoomId(odrone.currentLocation.x, odrone.currentLocation.y, false) == -1 and 
                                    (userdata_table(odrone, "mods.lilyinno.dronetarget").target) then
                                        if userdata_table(odrone, "mods.lilyinno.dronetarget").target > -1 then
                                            target = userdata_table(odrone, "mods.lilyinno.dronetarget").target
                                        end

                                    end
                                end

                                --local sys = otherShipManager:GetSystemInRoom(target or -1)
                                --print("SYSTEM2: " .. (sys and sys.name or "nil"))

                                -- Sync with crew already on enemy ship
                                for crew in vter(otherShipManager.vCrewList) do
                                    ---@type Hyperspace.CrewMember
                                    crew = crew
                                    --print(crew.species, crew.iShipId, shipManager.iShipId)
                                    if crew.iShipId == shipManager.iShipId then
                                        if crew.iRoomId > -1 then
                                            for _, tgt in pairs(targets) do
                                                if tgt == crew.iRoomId then
                                                    target = crew.iRoomId
                                                end
                                            end
                                        end
                                    end
                                end
                                --]]

                                if target then
                                    drone.destinationLocation = otherShipManager:GetRoomCenter(target)
                                    local sys = otherShipManager:GetSystemInRoom(target)
                                    --print("SYSTEM: " .. (sys and sys.name or "nil"))
                                end

                                
                                ---@diagnostic disable-next-line: need-check-nil
                                userdata_table(drone, "mods.lilyinno.dronetarget").target = target

                                --print("NewTarget: " .. (drone.destinationLocation and (drone.destinationLocation.x .. "/" .. drone.destinationLocation.y) or "nil"))
                                --print("NewDestRoom: " .. tostring(otherShipManager.ship:GetSelectedRoomId(drone.destinationLocation.x, drone.destinationLocation.y, false)))

                            end
                            if room == -1 and userdata_table(drone, "mods.lilyinno.dronetarget").target then
                                local target = userdata_table(drone, "mods.lilyinno.dronetarget").target
                                if target then
                                    drone.destinationLocation = otherShipManager:GetRoomCenter(target)
                                    drone.targetLocation = drone.destinationLocation
                                    drone.pointTarget = drone.destinationLocation
                                    if drone.currentSpace == drone.destinationSpace then
                                        local velocity = drone.speedVector
                                        local speed = math.sqrt(velocity.x * velocity.x + velocity.y + velocity.y)
                                        local pos = drone.currentLocation
                                        local tgt = drone.destinationLocation
                                        ---@type Hyperspace.Pointf
                                        local aim = tgt - pos
                                        aim = aim:Normalize()
                                        aim.x = aim.x * speed
                                        aim.y = aim.y * speed
                                        drone.speedVector = aim
                                    end
                                end
                                --print("NewTarget: " .. (drone.destinationLocation and (drone.destinationLocation.x .. "/" .. drone.destinationLocation.y) or "nil"))
                                --print("NewDestRoom: " .. tostring(otherShipManager.ship:GetSelectedRoomId(drone.destinationLocation.x, drone.destinationLocation.y, false)))
                            end
                        end
                    else
                        if drone:GetBoardingDrone() then
                            userdata_table(drone, "mods.lilyinno.dronetarget").target = nil
                        end
                    end

                end
            end
        end
    end
end)



script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(shipManager, augment, value)
    if shipManager and (shipManager:HasAugmentation("UPG_LILY_BATTERY_SURGE_OVERDRIVE") > 0 or shipManager:HasAugmentation("EX_LILY_BATTERY_SURGE_OVERDRIVE") > 0) then
        local battery = shipManager.batterySystem

        if battery and battery.bTurnedOn then
            local level = battery.healthState.first
            if augment == "AUTO_COOLDOWN" then
                value = value + level * 0.075
            end
            if augment == "SHIELD_RECHARGE" then
                value = value + level * 0.15
            end
        end
        

    end
    return Defines.Chain.CONTINUE, value
end)


script.on_internal_event(Defines.InternalEvents.GET_DODGE_FACTOR, function(shipManager, value)
    if value == 0 then
        return Defines.Chain.CONTINUE, value
    end
    if shipManager and (shipManager:HasAugmentation("UPG_LILY_BATTERY_SURGE_OVERDRIVE") > 0 or shipManager:HasAugmentation("EX_LILY_BATTERY_SURGE_OVERDRIVE") > 0) then
        local battery = shipManager.batterySystem

        if battery and battery.bTurnedOn then
            local level = battery.healthState.first
            
            if value > 0 then
                value = value + level * 5
            end
            
        end
    end
    return Defines.Chain.CONTINUE, value
end)
