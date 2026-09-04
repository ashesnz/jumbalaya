--[[ app/effects/easing.lua - Numeric and colour easing effects ]]

local Scheduler = require "app.effects.timeline_scheduler"

local Easing = {}

function Easing.value(options)
    local ref_table = options.ref_table
    local ref_value = options.ref_value
    local mod = options.mod or 0

    return Scheduler.tween{
        ref_table = ref_table,
        ref_value = ref_value,
        ease_to = ref_table[ref_value] + mod,
        timer = options.timer,
        delay = options.delay or 0.3,
        blockable = options.not_blockable == false,
        blocking = false,
        shape = options.shape or options.ease or options.ease_type,
        func = function(value)
            if options.floored then return math.floor(value) end
            return value
        end,
    }
end

local function ease_rgb(colour, target, options)
    for index = 1, 3 do
        Easing.value{
            ref_table = colour,
            ref_value = index,
            mod = target[index] - colour[index],
            delay = options.delay,
            not_blockable = true,
        }
    end
end

function Easing.background_colour(options)
    if not options.new_colour then return end

    for key, colour in pairs(G.C.BACKGROUND) do
        if key == 'C' or key == 'L' or key == 'D' then
            if options.special_colour and options.tertiary_colour then
                local colour_key = key == 'L' and 'new_colour'
                    or key == 'C' and 'special_colour'
                    or 'tertiary_colour'
                ease_rgb(colour, options[colour_key], {delay = 0.6})
            else
                local brightness = key == 'L' and 1.3
                    or key == 'D' and (options.special_colour and 0.4 or 0.7)
                    or 0.9
                local target = key == 'C' and options.special_colour
                if not target then
                    target = {
                        options.new_colour[1] * brightness,
                        options.new_colour[2] * brightness,
                        options.new_colour[3] * brightness,
                    }
                end
                ease_rgb(colour, target, {delay = 0.6})
            end
        end
    end

    if options.contrast then
        Easing.value{
            ref_table = G.C.BACKGROUND,
            ref_value = 'contrast',
            mod = options.contrast - G.C.BACKGROUND.contrast,
            delay = 0.6,
            not_blockable = true,
        }
    end
end

function Easing.colour(options)
    for index = 1, 4 do
        Easing.value{
            ref_table = options.old_colour,
            ref_value = index,
            mod = options.new_colour[index] - options.old_colour[index],
            timer = 'REAL',
            delay = options.delay,
        }
    end
end

return Easing