--[[ app/effects/status_text.lua - Data-driven Jumbalaya status presentation ]]

local Scheduler = require "app.effects.scheduler"

local StatusText = {}

local STATUS_DEFINITIONS = {
    debuff = {
        sound = 'cancel',
        amount = 1,
        colour = function() return G.C.RED end,
        text = function() return localize('term_debuffed') end,
        config = {scale = 0.6},
    },
    points = {
        sound = 'card_tick',
        colour = function() return G.C.POINTS end,
        text = function(amount) return localize{type = 'variable', key = 'a_chips', vars = {amount}} end,
        delay = 0.6,
    },
    mult = {
        sound = 'multhit1',
        colour = function() return G.C.MULTIPLIER end,
        text = function(amount) return localize{type = 'variable', key = 'a_mult', vars = {amount}} end,
        config = {type = 'fade', scale = 0.7},
    },
    x_mult = {
        sound = 'multhit2',
        volume = 0.7,
        colour = function() return G.C.XMULT end,
        text = function(amount) return localize{type = 'variable', key = 'a_xmult', vars = {amount}} end,
        config = {type = 'fade', scale = 0.7},
    },
    h_mult = {
        sound = 'multhit1',
        colour = function() return G.C.MULTIPLIER end,
        text = function(amount) return localize{type = 'variable', key = 'a_mult', vars = {amount}} end,
        config = {type = 'fade', scale = 0.7},
    },
    dollars = {
        sound = 'coin3',
        colour = function() return G.C.MONEY end,
        text = function(amount) return localize("$") .. tostring(amount) end,
    },
    swap = {
        sound = 'generic1',
        colour = function() return G.C.PURPLE end,
        text = function() return localize('term_swapped_ex') end,
    },
}

STATUS_DEFINITIONS.h_x_mult = STATUS_DEFINITIONS.x_mult
StatusText.definitions = STATUS_DEFINITIONS

local function copy_config(config)
    local copy = {}
    for key, value in pairs(config or {}) do copy[key] = value end
    return copy
end

local function position_for(card)
    local position = {align = 'bm', y = 0.15 * G.CARD_H}
    if card.area == G.hand
        or (card.area and card.area.config.type == 'placement') or card.is_mascot then
        position.y = -0.05 * G.CARD_H
        position.align = 'tm'
    end
    return position
end

local function extra_definition(extra)
    local sound = extra.sound or extra.edition and 'foil2'
        or extra.mult_mod and 'multhit1' or extra.Xmult_mod and 'multhit2' or 'generic1'
    local config = {type = 'fall', scale = 0.7}
    local colour = extra.colour or G.C.FILTER
    if extra.edition then
        colour = G.C.DARK_FINISH
    elseif extra.mult_mod or extra.Xmult_mod then
        colour = G.C.MULTIPLIER
    end
    if extra.chip_mod then
        colour = G.C.POINTS
    elseif extra.comic_burst then
        config.scale = extra.scale or 0.85
    elseif extra.swap then
        colour = G.C.PURPLE
    end

    return {
        sound = sound,
        volume = extra.edition and 0.3 or sound == 'multhit2' and 0.7 or 1,
        delay = extra.delay or 0.75,
        amount = 1,
        text = extra.message or '',
        colour = colour,
        config = config,
    }
end

local function resolve_definition(eval_type, amount, extra)
    if eval_type == 'extra' or eval_type == 'companions' then
        return extra_definition(extra)
    end

    local definition = STATUS_DEFINITIONS[eval_type]
    if not definition then return nil end
    return {
        sound = definition.sound,
        volume = definition.volume or 1,
        delay = definition.delay or 0.65,
        amount = definition.amount or amount,
        text = definition.text(amount),
        colour = definition.colour(),
        config = copy_config(definition.config),
    }
end

function StatusText.show(options)
    local card = options.card
    local extra = options.extra or {}
    if extra.focus then card = extra.focus end

    local percent = options.percent or (0.9 + 0.2 * math.random())
    if options.direction == 'down' then percent = 1 - percent end

    local position = position_for(card)
    local definition = resolve_definition(options.eval_type, options.amount, extra)
    if not definition then return end

    local amount = definition.amount
    local delay = definition.delay * 1.25
    local config = definition.config
    local status = {
        text = definition.text,
        scale = config.scale or 1,
        hold = delay - 0.2,
        colour = extra.comic_burst and (extra.text_colour or {0.10, 0.07, 0.12, 1}) or nil,
        backdrop_colour = extra.comic_burst and nil or definition.colour,
        comic_burst = extra.comic_burst,
        align = position.align,
        major = card,
        offset = {x = 0, y = position.y},
    }

    local function present()
        if options.extra_func then options.extra_func() end
        spawn_attention(status)
        play_sfx(definition.sound, 0.8 + percent * 0.2, definition.volume)
        if not extra.no_bounce then
            card:pulse(0.6, 0.1)
            G.ROOM.jiggle = G.ROOM.jiggle + 0.7
        end
    end

    if amount > 0 then
        if extra.instant then
            present()
        else
            Scheduler.window{
                delay = delay,
                func = function()
                    present()
                    return true
                end,
            }
        end
    end
end


return StatusText