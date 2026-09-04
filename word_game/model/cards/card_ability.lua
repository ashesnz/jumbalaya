-- Card identity, visual editions, seals, and deck membership.

---@class (partial) Card : EaseNode

local Scheduler = require "app.effects.timeline_scheduler"

function Card:apply_center(center, initial, delay_sprites)
    local old_center = self.config.center
    self.config.center = center
    for key, prototype in pairs(G.P_CENTERS) do
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
    if self.ability.set == "Companion" or self.ability.set == "Finish" then
        self.label = self.ability.name
    end
    if self.playing_card and not initial then
    end
end

function Card:set_edition(edition, immediate, silent)
    self.edition = nil
    if not edition then return end

    if edition.holo then
        self.edition = {holo = true, type = "holo", mult = G.P_CENTERS.finish_holo.config.extra}
    elseif edition.foil then
        self.edition = {foil = true, type = "foil", points = G.P_CENTERS.finish_foil.config.extra}
    elseif edition.polychrome then
        self.edition = {polychrome = true, type = "polychrome", x_mult = G.P_CENTERS.finish_polychrome.config.extra}
    elseif edition.negative then
        self.edition = {negative = true, type = "negative"}
    end

    local prototype = self.edition and G.P_CENTERS["e_" .. self.edition.type]
    if prototype and not prototype.discovered then discover_card(prototype) end
    if not self.edition or silent then return end

    G.INPUT.locks.edition = true
    -- One pitched sting per edition flavour; array keeps the play order stable.
    local edition_stings = {
        {flag = "foil",       sound = "foil1",       pitch = 1.05, volume = 0.5},
        {flag = "holo",       sound = "holo1",       pitch = 1.7,  volume = 0.35},
        {flag = "polychrome", sound = "polychrome1", pitch = 1.0,  volume = 0.65},
        {flag = "negative",   sound = "negative",    pitch = 1.3,  volume = 0.45},
    }
    Scheduler.add{
        mode = "delayed",
        delay = immediate and 0 or 0.2,
        blockable = not immediate,
        func = function()
            self:pulse(1, 0.5)
            for _, sting in ipairs(edition_stings) do
                if self.edition[sting.flag] then
                    play_sfx(sting.sound, sting.pitch, sting.volume)
                end
            end
            return true
        end
    }
    Scheduler.add{
        mode = "delayed",
        delay = 0.1,
        func = function()
            G.INPUT.locks.edition = false
            return true
        end
    }
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
