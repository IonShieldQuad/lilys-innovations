local vter = mods.multiverse.vter
local string_starts = mods.multiverse.string_starts
local screen_fade = mods.multiverse.screen_fade
local screen_shake = mods.multiverse.screen_shake
local on_load_game = mods.multiverse.on_load_game
local INT_MAX = 2147483647


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
                    txt = string.gsub(txt, "Medbay", "Infusion Bay")
                    txt = string.gsub(txt, "medbay", "infusion bay")
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
end)

