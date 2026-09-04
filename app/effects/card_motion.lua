--[[ app/effects/card_motion.lua - Queued card movement and selection effects ]]

local Scheduler = require "app.effects.timeline_scheduler"

local CardMotion = {}

function CardMotion.move(options)
    local percent = options.percent or 50
    if options.direction == 'down' then
        percent = 1 - percent
    end

    local drawn = false
    Scheduler.window{
        delay = options.delay or 0.1,
        func = function()
            local card = options.card
            if card then
                if options.from then card = options.from:remove_card(card) end
                if card then drawn = true end
                local stay_flipped = options.stay_flipped or false
                options.to:emplace(card, nil, stay_flipped)
            elseif options.to:draw_card_from(options.from, options.stay_flipped, options.discarded_only) then
                drawn = true
            end

            if not options.mute and drawn then
                if options.from == G.deck or options.from == G.hand
                    or options.from == G.discard then
                    G.VIBRATION = G.VIBRATION + 0.6
                end
                play_sfx('card_slide1', 0.85 + percent * 0.2 / 100, 0.6 * (options.volume or 1))
            end
            if options.sort then options.to:sort() end
            return true
        end,
    }
end

function CardMotion.set_selected(options)
    local percent = options.percent or 0.5
    local set_selected = true
    if options.direction == 'down' then
        percent = 1 - percent
        set_selected = false
    end

    -- Jumbalaya 3–7 letter ladder: 0.90, then a fifth by the 7th card.
    local t = math.max(0, math.min(percent, 1))
    local pitch = 0.90 * (2 ^ (t * 7 / 12))

    return Scheduler.window{
        delay = 0.1,
        func = function()
            options.card:set_selected(set_selected)
            play_sfx('card_slide1', pitch)
            return true
        end,
    }
end

return CardMotion