--[[ app/effects/runtime.lua - Canvas motion and repeating card effects ]]

local Scheduler = require "app.effects.timeline_scheduler"

local Runtime = {}

function Runtime.update_canvas_juice(dt)
    if not G.ROOM or not G.ROOM_ORIG or not G.POINTER or not G.POINTER.T or not G.WINDOW_TRANSFORM then return end
    G.JIGGLE_VIBRATION = G.ROOM.jiggle or 0
    if not G.SETTINGS.screenshake or type(G.SETTINGS.screenshake) ~= 'number' then
        G.SETTINGS.screenshake = 50
    end
    local shake_amt = math.max(0, G.SETTINGS.screenshake - 30) / 100
    G.ARGS.eased_cursor_pos = G.ARGS.eased_cursor_pos or {
        x = G.POINTER.T.x,
        y = G.POINTER.T.y,
        sx = G.INPUT.cursor_position.x,
        sy = G.INPUT.cursor_position.y,
    }
    G.ARGS.eased_cursor_pos.x = G.ARGS.eased_cursor_pos.x * (1 - 3 * dt)
        + 3 * dt * (shake_amt * G.POINTER.T.x + (1 - shake_amt) * G.ROOM.T.w / 2)
    G.ARGS.eased_cursor_pos.y = G.ARGS.eased_cursor_pos.y * (1 - 3 * dt)
        + 3 * dt * (shake_amt * G.POINTER.T.y + (1 - shake_amt) * G.ROOM.T.h / 2)
    G.ARGS.eased_cursor_pos.sx = G.ARGS.eased_cursor_pos.sx * (1 - 3 * dt)
        + 3 * dt * (shake_amt * G.INPUT.cursor_position.x + (1 - shake_amt) * G.WINDOW_TRANSFORM.real_window_w / 2)
    G.ARGS.eased_cursor_pos.sy = G.ARGS.eased_cursor_pos.sy * (1 - 3 * dt)
        + 3 * dt * (shake_amt * G.INPUT.cursor_position.y + (1 - shake_amt) * G.WINDOW_TRANSFORM.real_window_h / 2)

    shake_amt = G.SETTINGS.screenshake / 100 * 3
    if shake_amt < 0.05 then shake_amt = 0 end

    G.ROOM.jiggle = (G.ROOM.jiggle or 0) * (1 - 5 * dt) * (shake_amt > 0.05 and 1 or 0)
    G.ROOM.T.r = (0.001 * math.sin(0.3 * G.TIMERS.REAL) + 0.002 * G.ROOM.jiggle * math.sin(39.913 * G.TIMERS.REAL)) * shake_amt
    G.ROOM.T.x = G.ROOM_ORIG.x + shake_amt * (0.015 * math.sin(0.913 * G.TIMERS.REAL)
        + 0.01 * (G.ROOM.jiggle * shake_amt) * math.sin(19.913 * G.TIMERS.REAL)
        + (G.ARGS.eased_cursor_pos.x - 0.5 * (G.ROOM.T.w + G.ROOM_ORIG.x)) * 0.01)
    G.ROOM.T.y = G.ROOM_ORIG.y + shake_amt * (0.015 * math.sin(0.952 * G.TIMERS.REAL)
        + 0.01 * (G.ROOM.jiggle * shake_amt) * math.sin(21.913 * G.TIMERS.REAL)
        + (G.ARGS.eased_cursor_pos.y - 0.5 * (G.ROOM.T.h + G.ROOM_ORIG.y)) * 0.01)

    G.JIGGLE_VIBRATION = G.JIGGLE_VIBRATION * (1 - 5 * dt)
    G.CURR_VIBRATION = G.CURR_VIBRATION or 0
    G.CURR_VIBRATION = math.min(1, G.CURR_VIBRATION + G.VIBRATION + G.JIGGLE_VIBRATION * 0.2)
    G.VIBRATION = 0
    G.CURR_VIBRATION = (1 - 15 * dt) * G.CURR_VIBRATION
    if not G.SETTINGS.rumble then G.CURR_VIBRATION = 0 end
    if G.INPUT.GAMEPAD.object and G.F_RUMBLE then
        G.INPUT.GAMEPAD.object:setVibration(G.CURR_VIBRATION * 0.4 * G.F_RUMBLE, G.CURR_VIBRATION * 0.4 * G.F_RUMBLE)
    end
end

function Runtime.pulse_card(options)
    return Scheduler.instant{
        func = function()
            options.card:pulse(options.amount or 0.7)
            return true
        end,
    }
end

function Runtime.pulse_card_until(options)
    return Scheduler.delayed{
        delay = options.delay or 0.1,
        blocking = false,
        blockable = false,
        timer = 'REAL',
        func = function()
            if options.eval_func(options.card) then
                if not options.first or options.first then options.card:pulse(0.1, 0.1) end
                Runtime.pulse_card_until{
                    card = options.card,
                    eval_func = options.eval_func,
                    delay = 0.8,
                }
            end
            return true
        end,
    }
end

return Runtime