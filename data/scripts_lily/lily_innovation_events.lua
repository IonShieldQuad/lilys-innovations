local vter = mods.multiverse.vter
local string_starts = mods.multiverse.string_starts
local screen_fade = mods.multiverse.screen_fade
local screen_shake = mods.multiverse.screen_shake
local on_load_game = mods.multiverse.on_load_game
local INT_MAX = 2147483647


script.on_internal_event(Defines.InternalEvents.HAS_EQUIPMENT, function (shipManager, equipment, value)

    if equipment == "LILY_ECM_ASB_SCRAMBLER_ACTIVATE" then
        value = 0
        --local haseq = shipManager:HasAugmentation("LILY_ASB_SCRAMBLER") or
        --    shipManager:HasAugmentation("AUG_LILY_ULTRA_ECM") or shipManager:HasAugmentation("EX_LILY_ECM_ASB_SCRAMBLER") or
        --shipManager:HasAugmentation("UPG_LILY_ECM_ASB_SCRAMBLER")
        if shipManager:HasSystem(Hyperspace.ShipSystem.NameToSystemId("lily_ecm_suite")) and shipManager:HasEquipment("LILY_ECM_ASB_SCRAMBLER") > 0 then
            if Hyperspace.App.world.space and (Hyperspace.App.world.space.bPDS or (Hyperspace.playerVariables and Hyperspace.playerVariables["mods_lilyinno_ecmsuite_asb_disabled"] > 0)) then
                value = 1
            end
        end
    end

    return Defines.Chain.CONTINUE, value
end)

script.on_internal_event(Defines.InternalEvents.PRE_CREATE_CHOICEBOX, function(event)
    local shipManager = Hyperspace.ships.player
    if event.eventName ~= "THE_JUDGES_ENGI_REAL" then
        local Choices = event:GetChoices()
        for choice in vter(Choices) do
            ---@type Hyperspace.Choice
            choice = choice
            if choice.requirement.object == "medbay" then
                if choice.requirement.min_level == 2 or choice.requirement.min_level == 3 then
                    local txt = choice.text:GetText()
                    txt = string.gsub(txt, Hyperspace.Text:GetText("lily_eventtext_medbay1"),
                        Hyperspace.Text:GetText("lily_eventtext_infusion_bay1"))
                    txt = string.gsub(txt, Hyperspace.Text:GetText("lily_eventtext_medbay2"),
                        Hyperspace.Text:GetText("lily_eventtext_infusion_bay2"))
                    local ev = choice.event
                    local req = Hyperspace.ChoiceReq()
                    req.blue = true
                    req.object = "lily_infusion_bay"
                    req.min_level = choice.requirement.min_level
                    req.max_level = choice.requirement.max_level
                    event:AddChoice(ev, txt, req, true)
                end
            end
        end
    end
    if event.eventName ~= "" then
        local Choices = event:GetChoices()
        for choice in vter(Choices) do
            ---@type Hyperspace.Choice
            choice = choice
            if choice.requirement.object == "PDS_DISABLE" then
                local txt = choice.text:GetText()
                txt = string.gsub(txt, Hyperspace.Text:GetText("lily_eventtext_pds_disable1"),
                    Hyperspace.Text:GetText("lily_eventtext_ecm_suite1"))
                local ev = choice.event
                local req = Hyperspace.ChoiceReq()
                req.blue = true
                req.object = "lily_ecm_suite"
                req.min_level = choice.requirement.min_level
                req.max_level = choice.requirement.max_level
                event:AddChoice(ev, txt, req, choice.hiddenReward)
            end
            if choice.requirement.object == "MAGNET_ARM" and shipManager:HasEquipment("MAGNET_ARM") < 1 then
                --print("arm")
                --local spaceManager = Hyperspace.App.world.space
                --print("pds", spaceManager.bPDS and "true" or "false")
                if (choice.event.reward or choice.event.stuff) then
                    local txt = Hyperspace.Text:GetText("lily_eventtext_ecm_asb_salvage_choice")
                    local ev = choice.event
                    --local map = Hyperspace.App.world.starMap
                    --local worldLevel = map and map.worldLevel or 1
                    --ev = Hyperspace.Event:CreateEvent(ev.eventName, worldLevel, true)
                    
                    ---@type Hyperspace.LocationEvent
                    ev = mods.lilyinno.deepCopy(ev)
                    if ev.text then
                        ev.text.data = "lily_eventtext_ecm_asb_salvage"
                        ev.text.isLiteral = false
                    end
                    local req = Hyperspace.ChoiceReq()
                    req.blue = true
                    req.object = "LILY_ECM_ASB_SCRAMBLER_ACTIVATE"
                    req.min_level = 1
                    req.max_level = INT_MAX
                    event:AddChoice(ev, txt, req, choice.hiddenReward)
                end
                --[[if spaceManager and (spaceManager.bPDS or Hyperspace.playerVariables["mods_lilyinno_ecmsuite_asb_disabled"] > 0) and (choice.event.reward or choice.event.stuff) then
                    local txt = Hyperspace.Text:GetText("lily_eventtext_ecm_asb_salvage_choice")
                    local ev = choice.event
                    --local map = Hyperspace.App.world.starMap
                    --local worldLevel = map and map.worldLevel or 1
                    --ev = Hyperspace.Event:CreateEvent(ev.eventName, worldLevel, true)

                    ---@type Hyperspace.LocationEvent
                    ev = mods.lilyinno.deepCopy(ev)
                    if ev.text then
                        ev.text.data = "lily_eventtext_ecm_asb_salvage"
                        ev.text.isLiteral = false
                    end
                    local req = Hyperspace.ChoiceReq()
                    req.blue = true
                    req.object = "LILY_ECM_ASB_SCRAMBLER_ACTIVATE"
                    req.min_level = 1
                    req.max_level = INT_MAX
                    event:AddChoice(ev, txt, req, choice.hiddenReward)
                end--]]
            end
        end
    end
    --[[if event.eventName == "COMBAT_CHECK_REAL" then
        print("check")
        local spaceManager = Hyperspace.App.world.space
        print("pds", spaceManager.bPDS and "true" or "false")
        print(shipManager:HasEquipment("LILY_ECM_ASB_SCRAMBLER") and "true" or "false")
        if spaceManager and spaceManager.bPDS then
            local txt = Hyperspace.Text:GetText("lily_eventtext_ecm_asb_retarget")
            local ev = Hyperspace.Event:CreateEvent("COMBAT_CHECK_LILY_ECM_ASB_RETARGET", 1, true)
            local req = Hyperspace.ChoiceReq()
            req.blue = true
            req.object = "LILY_ECM_ASB_SCRAMBLER"
            --req.object = "pilot"
            --req.min_level = 1
            event:AddChoice(ev, txt, req, true)
        end
    end--]]
end)


