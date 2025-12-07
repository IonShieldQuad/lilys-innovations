
local userdata_table = mods.multiverse.userdata_table
local time_increment = mods.multiverse.time_increment
local create_damage_message = mods.multiverse.create_damage_message
local damageMessages = mods.multiverse.damageMessages
local INT_MAX = 2147483647

local function dot(a, b)
    return a.X * b.X + a.Y * b.Y;
end
local function magnitude(vec)
    return math.sqrt(vec.X * vec.X + vec.Y * vec.Y);
end
local function angleBetween(b, c)
    return math.acos(dot(b, c) / (magnitude(b) * magnitude(c)));
end
local function addVec(a, b)
    return {X = a.X + b.X, Y = a.Y + b.Y}
end
local function subVec(a, b)
    return { X = a.X + b.X, Y = a.Y + b.Y }
end
local function mulVec(a, k)
    return { X = a.X * k, Y = a.Y * k }
end
--[[
local function find_collision_point(target_pos, target_vel, interceptor_pos, interceptor_speed)

    local k = magnitude(target_vel) / interceptor_speed;
    local distance_to_target = magnitude(subVec(interceptor_pos, target_pos));

    local b_hat = target_vel;
    local c_hat = subVec(interceptor_pos, target_pos);

    local CAB = angleBetween(b_hat, c_hat);
    local ABC = math.asin(math.sin(CAB) * k);
    local ACB = (math.pi) - (CAB + ABC);

    local j = distance_to_target / math.sin(ACB);
    local a = j * math.sin(CAB);
    local b = j * math.sin(ABC);


    local time_to_collision = b / magnitude(target_vel);
    local collision_pos = addVec(target_pos, (mulVec(target_vel, time_to_collision)));

    return collision_pos;
end
--]]


local function find_collision_point(target_pos, target_vel, interceptor_pos, interceptor_speed)

    local k = magnitude(target_vel) / interceptor_speed;
    local distance_to_target = magnitude(subVec(interceptor_pos, target_pos));

    local BA_vel = target_vel
    local CB = subVec(target_pos, interceptor_pos)

    local alpha = angleBetween(BA_vel, CB)
    local gamma = math.asin(k * math.sin(alpha))
    local beta = math.pi - alpha - gamma

    local ratio = distance_to_target / math.sin(beta)

    local kx = ratio * math.sin(gamma)
    local tti = kx / magnitude(target_vel)
    --local BA = mulVec(mulVec(target_vel, 1.0 / magnitude(target_vel))) * kx

    local intercept = addVec(target_pos, mulVec(target_vel, tti))

    return intercept;
end

local function toPointF(vec)
    return Hyperspace.Pointf(vec.X, vec.Y)
end

local function toVec(point)
    return {X = point.x, Y = point.y}
end

local function setup_damage_message(path)
    local messageTex = Hyperspace.Resources:GetImageId(path)
    return Hyperspace.Resources:CreateImagePrimitive(messageTex, -messageTex.width / 2, -messageTex.height / 2, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
end
local ABLATED = setup_damage_message("numbers/lily_text_ablate.png")
local ABLATED_ORANGE = setup_damage_message("numbers/lily_text_ablate_orange.png")

local function global_pos_to_player_pos(mousePosition)
    local cApp = Hyperspace.Global.GetInstance():GetCApp()
    local combatControl = cApp.gui.combatControl
    local playerPosition = combatControl.playerShipPosition
    return Hyperspace.Point(mousePosition.x - playerPosition.x, mousePosition.y - playerPosition.y)
end

local function get_room_at_location(shipManager, location, includeWalls)
    return Hyperspace.ShipGraph.GetShipInfo(shipManager.iShipId):GetSelectedRoom(location.x, location.y, includeWalls)
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


local armorTimer = {}
armorTimer[0] = 0
armorTimer[1] = 0
local loadComplete = {}
--loadComplete[0] = false
--loadComplete[1] = false

--Handles tooltips and mousever descriptions per level
local function get_level_description_lily_ablative_armor(systemId, level, tooltip)
    --print(systemId .. "/" .. Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
    if systemId == Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor") then
        --print(tostring(level * 2) .. "/" .. tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25) .. "/" .. tostring(10 * math.max(0, (level - 3))) .. "%")
        --return (tostring(level * 2) .. "/" .. tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25) .. "/" .. tostring(10 * math.max(0, (level - 3))) .. "%")
        if tooltip then
            if level == 0 then
                return Hyperspace.Text:GetText("tooltip_lily_ablative_armor_disabled") ..
                    "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_ablative_armor_manning")
            end

            if Hyperspace.ships.player and Hyperspace.ships.player:HasSystem(systemId) then
                local maxlvl = Hyperspace.ships.player:GetSystem(systemId).healthState.second

                if level > 3 then
                    return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level2_ion"),
                        tostring(maxlvl * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25),
                        tostring(10 * math.max(0, (level - 3)))) ..
                    "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_ablative_armor_manning")
                else
                    return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level2"),
                            tostring(maxlvl * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25)) ..
                        "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_ablative_armor_manning")
                end
            end
            if level > 3 then
                return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level2_ion"),
                        tostring(level * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25),
                        tostring(10 * math.max(0, (level - 3)))) ..
                    "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_ablative_armor_manning")
            else
                return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level2"),
                        tostring(level * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25)) ..
                    "\n\n" .. Hyperspace.Text:GetText("tooltip_lily_ablative_armor_manning")
            end
        end
        if level > 3 then
            return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level_ion"),
                    tostring(level * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25),
                    tostring(10 * math.max(0, (level - 3))))
        else
            return string.format(Hyperspace.Text:GetText("tooltip_lily_ablative_armor_level"),
                    tostring(level * 2), tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25))
        end
        --return string.format("Layers: %i / Regen: s%x, / Ion Res.: s%", level * 2, tostring(0.75 + ((level > 1) and 0.25 or 0) + level * 0.25 ), tostring(10 * math.max(0, (level - 3))) .. "%")
    end
end

script.on_internal_event(Defines.InternalEvents.GET_LEVEL_DESCRIPTION, get_level_description_lily_ablative_armor)

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_ablative_armor(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_ablative_armor" and systemBox.bPlayerUI
end

--Utility function to check if the SystemBox instance is for our customs system
local function is_lily_ablative_armor_enemy(systemBox)
    local systemName = Hyperspace.ShipSystem.SystemIdToName(systemBox.pSystem.iSystemType)
    return systemName == "lily_ablative_armor" and not systemBox.bPlayerUI
end


local lily_ablative_armorButtonOffset_x = 35
local lily_ablative_armorButtonOffset_y = -40
--Handles initialization of custom system box
local function lily_ablative_armor_construct_system_box(systemBox)
    if is_lily_ablative_armor(systemBox) then
        --systemBox.extend.xOffset = 54
    end
end

script.on_internal_event(Defines.InternalEvents.CONSTRUCT_SYSTEM_BOX, lily_ablative_armor_construct_system_box)


local lastKeyDown = nil
script.on_internal_event(Defines.InternalEvents.SYSTEM_BOX_KEY_DOWN, function(systemBox, key, shift)
    if Hyperspace.metaVariables.lily_ablative_armor_hotkey_enabled == 0 and ((not lastKeyDown) or lastKeyDown ~= key) and is_lily_ablative_armor(systemBox) then
        lastKeyDown = key
        --print("press key:"..key.." shift:"..tostring(shift))
        local shipManager = Hyperspace.ships.player
        if not Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then return end
        if key == 97 and shift then
            local lily_ablative_armor_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_ablative_armor"))
            lily_ablative_armor_system:DecreasePower(true)
        elseif key == 97 then
            local lily_ablative_armor_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId(
                "lily_ablative_armor"))
            lily_ablative_armor_system:IncreasePower(1, false)
        end
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_KEY_UP, function(key)
    lastKeyDown = nil
end)

--Utility function to see if the system is ready for use
local function lily_ablative_armor_ready(shipSystem)
    return not shipSystem:GetLocked() and shipSystem:Functioning() and shipSystem.iHackEffect <= 1
end

--Initializes primitive for UI elements
local buttonBase
local armorTop
local armorCoverBar
local squareFull
local squareEmpty
local hulltile
local hulltileBroken
local hulltileCrack1
local hulltileCrack2

script.on_init(function()
    buttonBase = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("systemUI/button_artillery_1.png"), lily_ablative_armorButtonOffset_x,
        lily_ablative_armorButtonOffset_y, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    armorTop = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("statusUI/top_armor16.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    armorCoverBar = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("statusUI/top_armor_coverbar.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    squareFull = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("statusUI/top_armorsquare_2_full.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    squareEmpty = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("statusUI/top_armorsquare_2_empty.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    hulltile = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    hulltileBroken = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_broken.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    hulltileCrack1 = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_crack1.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)
    hulltileCrack2 = Hyperspace.Resources:CreateImagePrimitive(
        Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_crack2.png"), 0,
        0, 0,
        Graphics.GL_Color(1, 1, 1, 1), 1,
        false)


    --for i = 0, 1, 1 do
    --    loadComplete[i] = false
    --end

    --buttonBase = Hyperspace.Resources:CreateImagePrimitiveString("systemUI/button_artillery1.png",
    --    lily_ablative_armorButtonOffset_x, lily_ablative_armorButtonOffset_y, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)
end)

--LILY_POWER_BEAM_CURSOR = Hyperspace.Resources:CreateImagePrimitive(
--    Hyperspace.Resources:GetImageId("mouse/mouse_lily_beam.png"), 0, 0, 0, Graphics.GL_Color(1, 1, 1, 1), 1, false)

--Handles custom rendering
local function lily_ablative_armor_render(systemBox, ignoreStatus)
    if is_lily_ablative_armor(systemBox) then
        local shipManager = Hyperspace.ships.player
        local lily_ablative_armor_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))



        --Graphics.CSurface.GL_RenderPrimitive(LILY_POWER_BEAM_CURSOR)
        --[[
        Graphics.CSurface.GL_RenderPrimitive(buttonBase)
        local lily_ablative_armor_bar_x = 44
        local lily_ablative_armor_bar_y = 19
        local lily_ablative_armor_bar_width = 5
        local lily_ablative_armor_bar_height = 50

        Graphics.CSurface.GL_DrawRect(lily_ablative_armor_bar_x,
            lily_ablative_armor_bar_y - lily_ablative_armor_bar_height * (armorTimer[0] / (10)),
            lily_ablative_armor_bar_width, lily_ablative_armor_bar_height * (armorTimer[0] / (10)), Graphics.GL_Color(1, 1, 1, 1));
        --]]
    end
end
script.on_render_event(Defines.RenderEvents.SYSTEM_BOX,
    function(systemBox, ignoreStatus)
        return Defines.Chain.CONTINUE
    end, lily_ablative_armor_render)



--local shield_ui = Hyperspace.Resources:CreateImagePrimitiveString("statusUI/top_aea_aux_on.png", 25, 86, 0,
--   Graphics.GL_Color(1, 1, 1, 1), 1.0, false)
script.on_internal_event(Defines.InternalEvents.HAS_AUGMENTATION, function(ship, augment, value)
    if augment == "ION_ARMOR" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            return Defines.Chain.CONTINUE,
            value + math.min(1, math.max(0, lily_ablative_armor_system.healthState.second - 3))
        end
    end
    if augment == "ROCK_ARMOR" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            return Defines.Chain.CONTINUE, value + 1
        end
    end
    if augment == "SYSTEM_CASING" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            return Defines.Chain.CONTINUE, value + 1
        end
    end



    return Defines.Chain.CONTINUE, value
end)



script.on_internal_event(Defines.InternalEvents.GET_AUGMENTATION_VALUE, function(ship, augment, value)

    if augment == "ION_ARMOR" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            if lily_ablative_armor_system.iHackEffect > 1 then
                return Defines.Chain.CONTINUE, value
            end
            return Defines.Chain.CONTINUE, value + 0.1 * math.max(0, lily_ablative_armor_system:GetEffectivePower() - 3)
        end
    end
    if augment == "ROCK_ARMOR" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            return Defines.Chain.CONTINUE, value + 0.1
        end
    end
    if augment == "SYSTEM_CASING" then
        if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
            local lily_ablative_armor_system = ship:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
            return Defines.Chain.CONTINUE, value + 0.1
        end
    end



    return Defines.Chain.CONTINUE, value
end)



script.on_internal_event(Defines.InternalEvents.SHIP_LOOP, function(shipManager)
    if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local lily_ablative_armor_system = shipManager:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))



        local manningCrew = nil
        for crew in vter(shipManager.vCrewList) do
            if crew.bActiveManning and crew.currentSystem == lily_ablative_armor_system then
                lily_ablative_armor_system.iActiveManned = crew:GetSkillLevel(4)
                manningCrew = crew
            end
        end
        local level = lily_ablative_armor_system.healthState.second
        local efflevel = lily_ablative_armor_system:GetEffectivePower()
        local maxLayers = level * 2
        local multiplier = 0.5 * ((efflevel > 0 and 0.75 or 0) + ((efflevel > 1) and 0.25 or 0) + efflevel * 0.25) *
            (1 + lily_ablative_armor_system.iActiveManned * 0.20)




        if lily_ablative_armor_system.iHackEffect > 1 then
            multiplier = -3
        end

        if shipManager.iShipId == 0 then
            Hyperspace.playerVariables.lily_ablative_armor = level
            local cApp = Hyperspace.App
            local gui = cApp.gui

            -- If player is not in danger
            local inSafeEnviroment = gui.upgradeButton.bActive
                and not gui.event_pause
                and cApp.world.space.projectiles:empty()
                and not shipManager.bJumping
                if inSafeEnviroment then
                    multiplier = multiplier * 10
                end
        end
        if userdata_table(shipManager, "mods.lilyinno.ablativearmor").second and maxLayers > userdata_table(shipManager, "mods.lilyinno.ablativearmor").second then
            userdata_table(shipManager, "mods.lilyinno.ablativearmor").first = maxLayers
        end
        userdata_table(shipManager, "mods.lilyinno.ablativearmor").second = maxLayers
        if not userdata_table(shipManager, "mods.lilyinno.ablativearmor").first then
                userdata_table(shipManager, "mods.lilyinno.ablativearmor").first = userdata_table(shipManager,"mods.lilyinno.ablativearmor").second
            --userdata_table(shipManager, "mods.lilyinno.ablativearmor").first = 0
        end

        --if shipManager.iShipId == 1 then multiplier = multiplier * 0.7 end
        local currentLayers = userdata_table(shipManager, "mods.lilyinno.ablativearmor").first or 0
            --print(currentLayers)
        if not mods.lilyinno.checkVarsOK() then
            loadComplete[shipManager.iShipId] = false
        end

        if mods.lilyinno.checkVarsOK() and not loadComplete[shipManager.iShipId] then
            local v = Hyperspace.playerVariables["mods_lilyinno_ablativearmor_" .. (shipManager.iShipId > 0.5 and "1" or "0")]
            if v > 0 then
                currentLayers = v - 1
            end
            userdata_table(shipManager, "mods_lilyinno_ablativearmor").first = currentLayers
            loadComplete[shipManager.iShipId] = true
        end

        if currentLayers == 0 then
            multiplier = multiplier * 0.25
        end


        if currentLayers < maxLayers then
            armorTimer[shipManager.iShipId] = math.max(0, math.min(10, armorTimer[shipManager.iShipId] + multiplier * Hyperspace.FPS.SpeedFactor / 16))
            if armorTimer[shipManager.iShipId] >= 10 then
                --if manningCrew and Hyperspace.ships.enemy and Hyperspace.ships.enemy._targetable.hostile then
                --    manningCrew:IncreaseSkill(4)
                --end

                if manningCrew and math.random(2) == 2 then
                    manningCrew:IncreaseSkill(4)
                end
                --if maxLayers > 5 then shipManager.shieldSystem.shields.power.super.second = maxLayers end
                --shipManager.shieldSystem:AddSuperShield(shipManager.shieldSystem.superUpLoc)
                currentLayers = currentLayers + 1
                userdata_table(shipManager, "mods.lilyinno.ablativearmor").first = currentLayers
                armorTimer[shipManager.iShipId] = 0
                Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_restore_1", -1, false)
                --shipManager.shieldSystem.shields.power.super.second = shipManager.shieldSystem.shields.power.super.first
            end
        else
            armorTimer[shipManager.iShipId] = 0
        end
        if mods.lilyinno.checkVarsOK() and loadComplete[shipManager.iShipId] then
            Hyperspace.playerVariables["mods_lilyinno_ablativearmor_" .. (shipManager.iShipId > 0.5 and "1" or "0")] = currentLayers + 1
        end
    end
end)

script.on_render_event(Defines.RenderEvents.SHIP_SPARKS, function() end, function(ship)
    if not hulltile then
        armorTop = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("statusUI/top_armor16.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        armorCoverBar = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("statusUI/top_armor_coverbar.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        squareFull = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("statusUI/top_armorsquare_2_full.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        squareEmpty = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("statusUI/top_armorsquare_2_empty.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        hulltile = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        hulltileBroken = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_broken.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        hulltileCrack1 = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_crack1.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
        hulltileCrack2 = Hyperspace.Resources:CreateImagePrimitive(
            Hyperspace.Resources:GetImageId("misc/lily_armorsquare_tile_crack2.png"), 0,
            0, 0,
            Graphics.GL_Color(1, 1, 1, 1), 1,
            false)
    end
    local shipManager = Hyperspace.ships(ship.iShipId)
    local enabled = not (Hyperspace.metaVariables.lily_ablative_armor_rendering_disabled and Hyperspace.metaVariables.lily_ablative_armor_rendering_disabled > 0)
    if enabled and shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local currentLayers = userdata_table(shipManager, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(shipManager, "mods.lilyinno.ablativearmor").second or 0

        if maxLayers > 0 then
            local colors = {}
            colors[1] = Graphics.GL_Color(175 / 255.0, 150 / 255.0, 150 / 255.0, 1)
            colors[2] = Graphics.GL_Color(145 / 255.0, 160 / 255.0, 175 / 255.0, 1)
            colors[3] = Graphics.GL_Color(100 / 255.0, 200 / 255.0, 100 / 255.0, 1)
            local color = 1
            if shipManager:HasAugmentation("UPG_LILY_STRONG_ARMOR") > 0 or shipManager:HasAugmentation("EX_LILY_STRONG_ARMOR") > 0 then
                color = 2
            end
            if shipManager:HasAugmentation("UPG_LILY_AETHER_ARMOR") > 0 or shipManager:HasAugmentation("EX_LILY_AETHER_ARMOR") > 0 then
                color = 3
            end
            --print(color)
            local num = 1
            Graphics.CSurface.GL_SetColorTint(colors[color])
            for wall in vter(ship.vOuterWalls) do
                ---@type Hyperspace.OuterHull
                wall = wall

                if currentLayers > 0 then
                    Graphics.CSurface.GL_Translate(wall.pLoc.x, wall.pLoc.y, 0)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltile, 0.25)

                    if (num + 1) > 2 * currentLayers then
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltileCrack2, 0.3)
                    elseif (num + 1) > 2 * currentLayers - maxLayers then
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltileCrack1, 0.3)
                    end



                    --[[
                    if currentLayers < maxLayers then
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltileCrack1,
                        0.3 * math.sqrt(1 - (math.max(0, currentLayers - maxLayers / 2) / (maxLayers / 2))))
                    end

                    if currentLayers < (maxLayers / 2) then
                        Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltileCrack2,
                            0.5 * (1 - ((currentLayers - 1) / (maxLayers / 2))))
                    end
                    --]]
                    Graphics.CSurface.GL_Translate(-wall.pLoc.x, -wall.pLoc.y, 0)
                end
                --print(currentLayers)
                if currentLayers <= 0 then
                    --print("BROKEN")
                    Graphics.CSurface.GL_Translate(wall.pLoc.x, wall.pLoc.y, 0)
                    Graphics.CSurface.GL_RenderPrimitiveWithAlpha(hulltileBroken, 0.25)
                    Graphics.CSurface.GL_Translate(-wall.pLoc.x, -wall.pLoc.y, 0)
                end
                num = num + 1
                num = num % maxLayers
            end
            Graphics.CSurface.GL_RemoveColorTint()
        end
    end
end)



script.on_render_event(Defines.RenderEvents.SHIP_STATUS, function() end, function()
    if Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local lily_ablative_armor_system = Hyperspace.ships.player:GetSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor"))
        local shields = false
        if Hyperspace.ships.player:HasSystem(Hyperspace.ShipSystem.NameToSystemId("shields")) then
            shields = true
        end
        Graphics.CSurface.GL_PushMatrix()
        Graphics.CSurface.GL_Translate(16 - 12, 56 - 9, 5)

        if shields then
            Graphics.CSurface.GL_Translate(376, 0, 0)
        end

        Graphics.CSurface.GL_RenderPrimitive(armorTop)
        --Graphics.CSurface.GL_DrawRect(25 + 7, 87 + 2, (armorTimer[0] / (5)) * 94, 4, Graphics.GL_Color(1, 1, 1, 1));
        local shipManager = Hyperspace.ships.player
        local currentLayers = userdata_table(shipManager, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(shipManager, "mods.lilyinno.ablativearmor").second or 0
        local drawn = 0
        if currentLayers ~= nil and maxLayers ~= nil then
        Graphics.CSurface.GL_Translate(31, 7 + 10, 0)
            while (drawn < maxLayers) do

                if (drawn < currentLayers) then
                    Graphics.CSurface.GL_RenderPrimitive(squareFull)
                else
                    Graphics.CSurface.GL_RenderPrimitive(squareEmpty)
                end

                if drawn % 2 == 0 then
                    Graphics.CSurface.GL_Translate(0, -10, 0)
                else
                    Graphics.CSurface.GL_Translate(10, 10, 0)
                end

                drawn = drawn + 1

                if drawn % 4 == 0 then
                    Graphics.CSurface.GL_Translate(3, 0, 0)
                end

            end
        end
        Graphics.CSurface.GL_PopMatrix()

        local barHeight
        if (not shields) and shipManager:GetShieldPower().super.first > 0 then
            barHeight = 2
        else
            barHeight = 6
        end

        if currentLayers ~= nil and maxLayers ~= nil then
            Graphics.CSurface.GL_PushMatrix()
            if shields then
                Graphics.CSurface.GL_Translate(376, 0, 0)
            end
            Graphics.CSurface.GL_Translate(33, 79, 5)

            local color = Graphics.GL_Color(1, 1, 1, 1)

            if lily_ablative_armor_system.iHackEffect > 1 then
                color = Graphics.GL_Color(187 / 255.0, 37 / 255.0, 249 / 255.0, 1)
            end
            if shipManager:GetShieldPower().super.first > 0 then
                if shields then
                    --Graphics.CSurface.GL_DrawRect(0, 0, 92, 6, Graphics.GL_Color(22 / 255.0, 30 / 255.0, 37 / 255.0, 1));
                else
                    Graphics.CSurface.GL_RenderPrimitive(armorCoverBar)
                    --Graphics.CSurface.GL_DrawRect(0, 0, 92, 3, Graphics.GL_Color(22 / 255.0, 30 / 255.0, 37 / 255.0, 1));
                end
            end
            Graphics.CSurface.GL_DrawRect(0, 0, (armorTimer[0] / (10)) * 92, barHeight, color);
            Graphics.CSurface.GL_PopMatrix()
        end
    end
end)


mods.multiverse.systemIcons[Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")] = mods.multiverse
.register_system_icon("lily_ablative_armor")



local lily_ablating = false

script.on_internal_event(Defines.InternalEvents.DAMAGE_BEAM, function(ship, projectile, location, damage, newTile, beamHit)
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local currentLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").second or 0
        if currentLayers == nil or currentLayers == 0 or beamHit == Defines.BeamHit.SAME_TILE then
            return Defines.Chain.CONTINUE, beamHit
        end


        --print("1:" .. damage.iDamage)
        --[[
            if ship:GetAugmentationValue("ROCK_ARMOR") < math.random() then
                damage.iDamage = 0
            end
            if ship:GetAugmentationValue("SYSTEM_CASING") < math.random() then
                damage.iPersDamage = 0
            end
            --]]

        local cdamage = projectile and projectile.extend.customDamage.def or nil
        if cdamage == nil then
            cdamage = Hyperspace.CustomDamageDefinition()
        end

        local frac = (currentLayers * 100.0) / (maxLayers * 1.0)
        if damage.iDamage <= 0 and damage.iPersDamage <= 0 and damage.iSystemDamage <= 0 then
                local neg0
                if ship:HasAugmentation("UPG_LILY_STRONG_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_STRONG_ARMOR") > 0 then
                    neg0 = math.min(math.random() * 100, math.random() * 100) < frac
                else
                    neg0 = math.max(math.random() * 100, math.random() * 100) < frac
                end
                if neg0 then
                    damage.fireChance = math.max(0, math.min(damage.fireChance, math.max(damage.fireChance, 10) - currentLayers))
                end
            return Defines.Chain.CONTINUE, beamHit
        end

        local hullres = false
        local sysres = false
        if ship:HasAugmentation("UPG_LILY_AETHER_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_AETHER_ARMOR") > 0 then
            hullres = math.random() < math.min(ship:GetAugmentationValue("ROCK_ARMOR"), 0.9)
            sysres = math.random() < math.min(ship:GetAugmentationValue("SYSTEM_CASING"), 0.9)
        end

        --polished armor gives -1 to beam dmg
        if ship:HasAugmentation("UPG_LILY_POLISHED_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_POLISHED_ARMOR") > 0 then
            if damage.iDamage > 0 then
                damage.iDamage = damage.iDamage - 1
            end
            if damage.iSystemDamage > 0 then
                damage.iSystemDamage = damage.iSystemDamage - 1
            end
            if damage.iPersDamage > 0 then
                damage.iPersDamage = damage.iPersDamage - 1
            end
        end
        --print("2:" .. damage.iDamage)
        --baseline halves beam damage
        local neg1 = math.random() < 0.5
        --print("neg:" .. tostring(neg1))
        if damage.iDamage > 0 then
            if damage.iDamage == 1  then
                if not neg1 then
                    damage.iDamage = 0
                end
            else
                damage.iDamage = math.floor(damage.iDamage / 2.0)
            end
        end
        if damage.iSystemDamage > 0 then
            if damage.iSystemDamage == 1 then
                if not neg1 then
                    damage.iSystemDamage = 0
                end
            else
                damage.iSystemDamage = math.floor(damage.iSystemDamage / 2.0)
            end
        end
        if damage.iPersDamage > 0 then
            if damage.iPersDamage == 1 then
                if not neg1 then
                    damage.iPersDamage = 0
                end
            else
                damage.iPersDamage = math.floor(damage.iPersDamage / 2.0)
            end
        end

        --print("3:" .. damage.iDamage)

        if damage.iDamage == 0 and damage.iPersDamage == 0 and damage.iSystemDamage == 0 then
                if beamHit == Defines.BeamHit_NEW_ROOM and damageMessages then
                Hyperspace.Sounds:PlaySoundMix("zoltanResist", -1, false)
                create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
            end
            userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
            return Defines.Chain.CONTINUE, beamHit
        end


        local neg2
        if ship:HasAugmentation("UPG_LILY_STRONG_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_STRONG_ARMOR") > 0 then
            neg2 = math.min(math.random() * 100, math.random() * 100) < frac
        else
            neg2 = math.max(math.random() * 100, math.random() * 100) < frac
        end

        local roomId = ship.ship:GetSelectedRoomId(location.x, location.y, true)
        local sys = ship:GetSystemInRoom(roomId)

        local currentLayers2 = currentLayers
        local armorDamage = 0

        if sys == nil and damage.bHullBuster == true then
            if damage.iDamage * 2 < currentLayers then
                --if damage.iDamage > 0 then
                --    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                --end
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + damage.iDamage
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + damage.iDamage
                end
                if not hullres then
                    armorDamage = armorDamage + damage.iDamage * 2
                end
                damage.iDamage = 0
                currentLayers = currentLayers - damage.iDamage * 2
            else
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + math.ceil(currentLayers / 2)
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + math.ceil(currentLayers / 2)
                end
                if not hullres then
                    armorDamage = armorDamage + currentLayers
                end
                damage.iDamage = damage.iDamage - math.ceil(currentLayers / 2)
                currentLayers = 0
            end
        else
            if damage.iDamage < currentLayers then
                --if damage.iDamage > 0 then
                --    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                --end
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + damage.iDamage
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + damage.iDamage
                end
                if not hullres then
                    armorDamage = armorDamage + damage.iDamage
                end
                currentLayers = currentLayers - damage.iDamage
                damage.iDamage = 0
            else
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + currentLayers
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + currentLayers
                end
                damage.iDamage = damage.iDamage - currentLayers
                if not hullres then
                    armorDamage = armorDamage + currentLayers
                end
                currentLayers = 0
            end
        end


        if sys and neg2 then
            if damage.iSystemDamage < currentLayers then
                if not sysres  then
                    armorDamage = armorDamage + damage.iSystemDamage
                end
                currentLayers = currentLayers - damage.iSystemDamage
                damage.iSystemDamage = 0
            else
                damage.iSystemDamage = damage.iSystemDamage - currentLayers
                if not sysres then
                    armorDamage = armorDamage + currentLayers
                end
                currentLayers = 0
            end
        end

        if neg2 then
            damage.iPersDamage = math.max(0, damage.iPersDamage - currentLayers2)
            damage.fireChance = math.max(0, math.min(damage.fireChance, math.max(damage.fireChance, 10) - currentLayers2))
        end
        if beamHit == Defines.BeamHit_NEW_ROOM then
            if neg2 then
                    if armorDamage == 0 and damageMessages then
                    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                    Hyperspace.Sounds:PlaySoundMix("zoltanResist", -1, false)
                else
                    Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_1", -1, false)
                    create_damage_message(ship.iShipId, ABLATED, location.x, location.y)
                end
            else
                if armorDamage == 0 then
                    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                else
                    create_damage_message(ship.iShipId, ABLATED_ORANGE, location.x, location.y)
                end
                Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_breach_1", -1, false)
            end
        end

        if ship:HasAugmentation("UPG_LILY_VENGEANCE_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_VENGEANCE_ARMOR") > 0 then
            if armorDamage > 0 then
                local dmg = Hyperspace.Damage()
                dmg.bFriendlyFire = true
                dmg.iDamage = 1
                dmg.iPersDamage = -1
                dmg.iSystemDamage = -1
                dmg.selfId = ship.iShipId
                dmg.ownerId = ship.iShipId
                local hull = ship.ship.hullIntegrity.first
                ship:DamageArea(location, dmg, true)
                local restore = hull - ship.ship.hullIntegrity.first
                ship:DamageHull(-restore, true)
            end
        end

        --currentLayers = math.max(0, currentLayers - armorDamage)
            userdata_table(ship, "mods.lilyinno.ablativearmor").first = math.max(0, currentLayers2 - armorDamage)
        --userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
    end
    return Defines.Chain.CONTINUE, beamHit
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA, function(ship, projectile, location, damage, forceHit, shipFriendlyFire)
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local currentLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").second or 0

        if currentLayers > 0 then

                if projectile and projectile:GetType() == 2 then
                    if currentLayers > 0 then
                        damage.iDamage = 0
                        Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_bounce_1", -1, false)
                        return Defines.Chain.HALT, Defines.Evasion.MISS, shipFriendlyFire
                    end
                end

        end


    end

        return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
end, INT_MAX)


script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA, function(ship, projectile, location, damage, forceHit, shipFriendlyFire)
    --[[print("DAMAGE_AREA")
    print("Projectile: " .. (projectile and "true" or "false"))
    if projectile then
        print(projectile)
        print("ID:" .. projectile.ownerId)
        print("Type:" .. projectile:GetType())
    end--]]
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) and lily_ablating then
        damage.iSystemDamage = -damage.iDamage
        damage.iPersDamage = -damage.iDamage
    end
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) and not lily_ablating then
        local currentLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").second or 0

        --ASB
        if projectile and projectile.target and projectile:GetType() == 6 then
                local targetroom = ship.ship:GetSelectedRoomId(projectile.target.x, projectile.target.y, true)
                if targetroom < 0 then
                    return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
                end
        end

        --Asteroids
        if projectile and projectile:GetType() == 2 then
            if currentLayers > 0 then
                --currentLayers = currentLayers - 1
                damage.iDamage = 0
                --Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_1", -1, false)
                --userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
                --create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                return Defines.Chain.CONTINUE, Defines.Evasion.MISS, shipFriendlyFire
            end
        end

        if damage.ownerId == ship.iShipId and damage.bFriendlyFire then
            return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
        end

        if damage.iDamage <= 0 and damage.iPersDamage <= 0 and damage.iSystemDamage <= 0 then
            return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
        end

        if currentLayers == nil or currentLayers == 0 or forceHit == Defines.Evasion.MISS then
            return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
        end

        local cdamage = projectile and projectile.extend.customDamage.def or nil
        if cdamage == nil then
            cdamage = Hyperspace.CustomDamageDefinition()
        end
        --[[
        if ship:GetAugmentationValue("ROCK_ARMOR") < math.random() then
            damage.iDamage = 0
        end
        if ship:GetAugmentationValue("SYSTEM_CASING") < math.random() then
            damage.iSystemDamage = 0
        end
        --]]

        local frac = (currentLayers * 100.0) / (maxLayers * 1.0)

        --[[
        if damage.iDamage == 0 and damage.iPersDamage == 0 and damage.iSystemDamage == 0 and (projectile and not projectile.missed) and not Defines.Evasion.MISS then
            Hyperspace.Sounds:PlaySoundMix("zoltanResist", -1, false)
            create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
            userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
        end
        --]]

        local hullres = false
        local sysres = false
        if ship:HasAugmentation("UPG_LILY_AETHER_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_AETHER_ARMOR") > 0 then
            hullres = math.random() < math.min(ship:GetAugmentationValue("ROCK_ARMOR"), 0.9)
            sysres = math.random() < math.min(ship:GetAugmentationValue("SYSTEM_CASING"), 0.9)
        end

        local neg2
        if ship:HasAugmentation("UPG_LILY_STRONG_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_STRONG_ARMOR") > 0 then
            neg2 = math.min(math.random() * 100, math.random() * 100) < frac
        else
            neg2 = math.max(math.random() * 100, math.random() * 100) < frac
        end

        --print(frac .. "%; " .. tostring(neg2))

        local roomId = ship.ship:GetSelectedRoomId(location.x, location.y, true)
        local sys = ship:GetSystemInRoom(roomId)
        --print("7:" .. damage.iDamage)


        local currentLayers2 = currentLayers

        local armorDamage = 0

        if sys == nil and damage.bHullBuster == true then
            if damage.iDamage * 2 < currentLayers then
                --if damage.iDamage > 0 then
                --    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                --end
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + damage.iDamage
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + damage.iDamage
                end
                if not hullres then
                    armorDamage = armorDamage + damage.iDamage * 2
                end
                damage.iDamage = 0
                currentLayers = currentLayers - damage.iDamage * 2
            else
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + math.ceil(currentLayers / 2)
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + math.ceil(currentLayers / 2)
                end
                if not hullres then
                    armorDamage = armorDamage + currentLayers
                end
                damage.iDamage = damage.iDamage - math.ceil(currentLayers / 2)
                currentLayers = 0
            end
        else
            if damage.iDamage < currentLayers then
                --if damage.iDamage > 0 then
                --    create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                --end
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + damage.iDamage
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + damage.iDamage
                end
                if not hullres then
                    armorDamage = armorDamage + damage.iDamage
                end
                currentLayers = currentLayers - damage.iDamage
                damage.iDamage = 0
            else
                if not neg2 and not cdamage.noSysDamage then
                    damage.iSystemDamage = damage.iSystemDamage + currentLayers
                end
                if not neg2 and not cdamage.noPersDamage then
                    damage.iPersDamage = damage.iPersDamage + currentLayers
                end
                damage.iDamage = damage.iDamage - currentLayers
                if not hullres then
                    armorDamage = armorDamage + currentLayers
                end
                currentLayers = 0
            end
        end


        if sys and neg2 then
            if damage.iSystemDamage < currentLayers then
                if not sysres then
                    armorDamage = armorDamage + damage.iSystemDamage
                end
                currentLayers = currentLayers - damage.iSystemDamage
                damage.iSystemDamage = 0
            else
                damage.iSystemDamage = damage.iSystemDamage - currentLayers
                if not sysres then
                    armorDamage = armorDamage + currentLayers
                end
                currentLayers = 0
            end
        end

        if neg2 then
            damage.iPersDamage = math.max(0, damage.iPersDamage - currentLayers2)
            damage.fireChance = math.max(0, math.min(damage.fireChance, math.max(damage.fireChance, 10) - currentLayers2))
        end

        if projectile then
            userdata_table(projectile, "mods.lilyinno.ablativearmor").armorDamage = armorDamage
            userdata_table(projectile, "mods.lilyinno.ablativearmor").neg = neg2
        end
        --print("8:" .. damage.iDamage)
        --Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_1", -1, false)
        --userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
        --print("9:" .. damage.iDamage)
    end
    return Defines.Chain.CONTINUE, forceHit, shipFriendlyFire
end)

script.on_internal_event(Defines.InternalEvents.DAMAGE_AREA_HIT, function(ship, projectile, location, damage, shipFriendlyFire)
    --[[print("DAMAGE_AREA_HIT")
    print("Projectile: " .. (projectile and "true" or "false"))
    if projectile then
        print(projectile)
        print("ID:" .. projectile.ownerId)
        print("Type:" .. projectile:GetType())
    end--]]
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) and not lily_ablating then
        local armorDamage = nil
        local neg = true
        if projectile then
            armorDamage = projectile and userdata_table(projectile, "mods.lilyinno.ablativearmor").armorDamage
            neg = projectile and userdata_table(projectile, "mods.lilyinno.ablativearmor").neg
        end
        local currentLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").second or 0

        --asteroid bandaid fix
        if projectile and projectile:GetType() == 2 then
            if currentLayers > 0 then
                if damage.iDamage > 0 then
                    ship:DamageHull(-damage.iDamage, true)
                end
                Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_breach_1", -1, false)
                return Defines.Chain.CONTINUE
            end
        end

        if neg == nil then
            neg = true
        end


        if armorDamage ~= nil and not (damage.bFriendlyFire and damage.ownerId == ship.iShipId) then
            currentLayers = math.max(0, currentLayers - armorDamage)
            if armorDamage == 0 and damageMessages then
                create_damage_message(ship.iShipId, damageMessages.NEGATED, location.x, location.y)
                if neg then
                    Hyperspace.Sounds:PlaySoundMix("zoltanResist", -1, false)
                else
                    Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_breach_1", -1, false)
                end
            else
                if neg then
                    Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_1", -1, false)
                    create_damage_message(ship.iShipId, ABLATED, location.x, location.y)
                else
                    Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_breach_1", -1, false)
                    create_damage_message(ship.iShipId, ABLATED_ORANGE, location.x, location.y)
                end

                if ship:HasAugmentation("UPG_LILY_VENGEANCE_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_VENGEANCE_ARMOR") > 0 then
                    --A hack for triggering crystal armor
                    local dmg = Hyperspace.Damage()
                    dmg.bFriendlyFire = true
                    dmg.iDamage = 1
                    dmg.iPersDamage = -1
                    dmg.iSystemDamage = -1
                    dmg.selfId = ship.iShipId
                    dmg.ownerId = ship.iShipId

                    lily_ablating = true
                    local hull = ship.ship.hullIntegrity.first
                    ship:DamageArea(location, dmg, true)
                    local restore = hull - ship.ship.hullIntegrity.first
                    ship:DamageHull(-restore, true)
                    lily_ablating = false

                end



                userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers

                --reactive armor shoots flak
                if ship:HasAugmentation("UPG_LILY_REACTIVE_ARMOR") > 0 or ship:HasAugmentation("EX_LILY_REACTIVE_ARMOR") > 0 then
                    local spaceManager = Hyperspace.App.world.space
                    local weapon = Hyperspace.Blueprints:GetWeaponBlueprint("LILY_REACTIVE_BLAST")
                    local targets = {}
                    if spaceManager.drones then
                        for drone in vter(spaceManager.drones) do
                            ---@type Hyperspace.SpaceDrone
                            drone = drone
                            if drone._collideable and drone._targetable and drone.currentSpace == ship.iShipId and drone.iShipId ~= ship.iShipId then
                                targets[#targets + 1] = { location = drone.currentLocation, velocity = drone.speedVector}
                            end
                        end
                    end
                    if spaceManager.projectiles then
                        for proj in vter(spaceManager.projectiles) do
                            if proj._targetable and proj.currentSpace == ship.iShipId and proj.ownerId ~= ship.iShipId and not proj.passedTarget then
                                targets[#targets + 1] = { location = proj.position, velocity = proj.speed }
                            end
                        end
                    end

                    for _, target in pairs(targets) do
                        if target and target.velocity then
                            target.velocity = Hyperspace.Pointf(target.velocity.x / (18.333 * time_increment(true)), target.velocity.y / (18.333 * time_increment(true)))
                        end
                    end
                    Hyperspace.Sounds:PlaySoundMix("smallExplosion", -1, false)
                    Hyperspace.Sounds:PlaySoundMix("smallExplosion", -1, false)
                        for i = 1, math.floor(maxLayers / 2), 1 do
                        if #targets > 0 then
                            local target = targets[math.random(#targets)]
                            local intercept = find_collision_point(toVec(target.location), toVec(target.velocity),
                            toVec(location), 400.0)
                            intercept = toPointF(intercept) --Hyperspace.Pointf(intercept.X, intercept.Y)
                            local randomvector = Hyperspace.Pointf((math.random() - 0.5) * 10, (math.random() - 0.5) * 10)
                            local point = (intercept - location):Normalize() * 200 + randomvector + location

                            local piece = spaceManager:CreateBurstProjectile(
                                weapon, "lily_reactive_armor_proj", false,
                                location,
                                ship.iShipId,
                                ship.iShipId,
                                intercept + randomvector,
                                ship.iShipId,
                                1
                            )
                            piece:ComputeHeading()
                        else
                            local theta = math.random() * math.pi * 2
                            local vector = Hyperspace.Pointf(location.x + 1000 * math.cos(theta),
                            location.y + 1000 * math.sin(theta))
                            local piece = spaceManager:CreateBurstProjectile(
                                weapon, "lily_reactive_armor_proj", false,
                                location,
                                ship.iShipId,
                                ship.iShipId,
                                vector,
                                ship.iShipId,
                                1
                            )
                            piece:ComputeHeading()
                        end
                    end
                    for i = 1, math.floor(maxLayers / 2), 1 do

                        local theta = math.random() * math.pi * 2
                        local vector = Hyperspace.Pointf(location.x + 1000 * math.cos(theta),
                            location.y + 1000 * math.sin(theta))
                        local piece = spaceManager:CreateBurstProjectile(
                            weapon, "lily_reactive_armor_proj", false,
                            location,
                            ship.iShipId,
                            ship.iShipId,
                            vector,
                            ship.iShipId,
                            math.random() * math.pi * 2
                        )
                        piece:ComputeHeading()

                    end
                end
            end
        end



        if damage.iDamage > 0 and currentLayers > 0 and not (damage.bFriendlyFire) then
            if damage.iDamage > currentLayers then
                ship:DamageHull(-currentLayers, true)

            else
                currentLayers = currentLayers - damage.iDamage
                ship:DamageHull(-damage.iDamage, true)
            end

            Hyperspace.Sounds:PlaySoundMix("lily_ablative_armor_hit_1", -1, false)
        end

        userdata_table(ship, "mods.lilyinno.ablativearmor").first = currentLayers
    end
    return Defines.Chain.CONTINUE
end)

script.on_internal_event(Defines.InternalEvents.SYSTEM_ADD_DAMAGE, function(sys, projectile, amount)
    local ship = Hyperspace.ships(sys._shipObj.iShipId)
    if ship and ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) then
        local currentLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").first or 0
        local maxLayers = userdata_table(ship, "mods.lilyinno.ablativearmor").second or 0

        if projectile and projectile:GetType() == 2 then
            if currentLayers > 0 then
                return Defines.Chain.CONTINUE, 0
            end
        end
    end
    return Defines.Chain.CONTINUE, amount
end)


script.on_internal_event(Defines.InternalEvents.JUMP_ARRIVE, function(ship) -- only player ships trigger JUMP_ARRIVE
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) and ship:HasAugmentation("UPG_LILY_REGEN_ARMOR") ~= 0 or ship:HasAugmentation("EX_LILY_REGEN_ARMOR") ~= 0 then -- ship has aug
        local regen = 2 * math.max(1, ship:GetAugmentationValue("UPG_LILY_REGEN_ARMOR"))
        ship:DamageHull(-regen, true)
    end
    if ship:HasAugmentation("BOON_LILY_ABLATIVE_ARMOR") ~= 0 then
        ship:DamageHull(-1, true)
    end
end)

script.on_internal_event(Defines.InternalEvents.ON_WAIT, function(ship) -- similar
    if ship:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ablative_armor")) and ship:HasAugmentation("UPG_LILY_REGEN_ARMOR") ~= 0 or ship:HasAugmentation("EX_LILY_REGEN_ARMOR") ~= 0 then
        local regen = 2 * math.max(1, ship:GetAugmentationValue("UPG_LILY_REGEN_ARMOR"))
        ship:DamageHull(-regen, true)
    end
    if ship:HasAugmentation("BOON_LILY_ABLATIVE_ARMOR") ~= 0 then
        ship:DamageHull(-1, true)
    end
end)
