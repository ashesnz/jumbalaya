-- Card identity and deck membership.
local live_game = require("word_game.model.live_game")


---@class (partial) Card : EaseNode

function Card:apply_center(center, initial, delay_sprites)
    local old_center = self.config.center
    self.config.center = center
    for key, prototype in pairs(live_game().LETTERS.centers) do
        if center == prototype then self.config.center_key = key end
    end

    if self.params.discover and not center.discovered then
        unlock_card(center)
        discover_card(center)
    end

    if delay_sprites then
        Scheduler.add{
            func = function()
                if not self.REMOVED then self:set_sprites(center) end
                return true
            end
        }
    else
        self:set_sprites(center)
    end

    local previous = self.ability
    self.ability = {
        name = center.name,
        effect = center.effect,
        set = center.set,
        bonus = center.config.bonus or 0,
        extra = deep_clone(center.config.extra),
        type = center.config.type or "",
        order = center.order,
        forced_selection = previous and previous.forced_selection or nil,
        perma_bonus = previous and previous.perma_bonus or 0,
    }
    if previous and old_center and old_center.config.bonus then
        self.ability.bonus = self.ability.bonus + (previous.bonus or 0) - old_center.config.bonus
    end

    self.label = center.label or self.config.card.label or self.ability.set
    if self.ability.set == "Companion" then
        self.label = self.ability.name
    end
    if self.letter_card_id and not initial then
    end
end

function Card:add_to_deck()
    if self.added_to_deck then return end
    self.added_to_deck = true
    if self.config.center and not self.config.center.discovered then
        discover_card(self.config.center)
    end
end

function Card:remove_from_deck()
    self.added_to_deck = false
end

return true
