--[[
	word_game/ui/effects/runtime.lua — Canvas bounce/juice and repeating table motion hooks.
	Inputs: Game shell CANVAS, TIMELINE, real_dt.
	Outputs: Runtime.update_canvas_juice(dt); registered from runtime_boot early_frame updater.
]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end

local Runtime = {}

function Runtime.update_canvas_juice(dt)
    if not g().ROOM or not g().ROOM_ORIG or not g().POINTER or not g().POINTER.T or not g().WINDOW_TRANSFORM then return end
    g().JIGGLE_VIBRATION = g().ROOM.jiggle or 0
    if not g().SETTINGS.screenshake or type(g().SETTINGS.screenshake) ~= 'number' then
        g().SETTINGS.screenshake = 50
    end
    local shake_amt = math.max(0, g().SETTINGS.screenshake - 30) / 100
    g().ARGS.eased_cursor_pos = g().ARGS.eased_cursor_pos or {
        x = g().POINTER.T.x,
        y = g().POINTER.T.y,
        sx = g().INPUT.cursor_position.x,
        sy = g().INPUT.cursor_position.y,
    }
    g().ARGS.eased_cursor_pos.x = g().ARGS.eased_cursor_pos.x * (1 - 3 * dt)
        + 3 * dt * (shake_amt * g().POINTER.T.x + (1 - shake_amt) * g().ROOM.T.w / 2)
    g().ARGS.eased_cursor_pos.y = g().ARGS.eased_cursor_pos.y * (1 - 3 * dt)
        + 3 * dt * (shake_amt * g().POINTER.T.y + (1 - shake_amt) * g().ROOM.T.h / 2)
    g().ARGS.eased_cursor_pos.sx = g().ARGS.eased_cursor_pos.sx * (1 - 3 * dt)
        + 3 * dt * (shake_amt * g().INPUT.cursor_position.x + (1 - shake_amt) * g().WINDOW_TRANSFORM.real_window_w / 2)
    g().ARGS.eased_cursor_pos.sy = g().ARGS.eased_cursor_pos.sy * (1 - 3 * dt)
        + 3 * dt * (shake_amt * g().INPUT.cursor_position.y + (1 - shake_amt) * g().WINDOW_TRANSFORM.real_window_h / 2)

    shake_amt = g().SETTINGS.screenshake / 100 * 3
    if shake_amt < 0.05 then shake_amt = 0 end

    g().ROOM.jiggle = (g().ROOM.jiggle or 0) * (1 - 5 * dt) * (shake_amt > 0.05 and 1 or 0)
    g().ROOM.T.r = (0.001 * math.sin(0.3 * g().TIMERS.REAL) + 0.002 * g().ROOM.jiggle * math.sin(39.913 * g().TIMERS.REAL)) * shake_amt
    g().ROOM.T.x = g().ROOM_ORIG.x + shake_amt * (0.015 * math.sin(0.913 * g().TIMERS.REAL)
        + 0.01 * (g().ROOM.jiggle * shake_amt) * math.sin(19.913 * g().TIMERS.REAL)
        + (g().ARGS.eased_cursor_pos.x - 0.5 * (g().ROOM.T.w + g().ROOM_ORIG.x)) * 0.01)
    g().ROOM.T.y = g().ROOM_ORIG.y + shake_amt * (0.015 * math.sin(0.952 * g().TIMERS.REAL)
        + 0.01 * (g().ROOM.jiggle * shake_amt) * math.sin(21.913 * g().TIMERS.REAL)
        + (g().ARGS.eased_cursor_pos.y - 0.5 * (g().ROOM.T.h + g().ROOM_ORIG.y)) * 0.01)

    g().JIGGLE_VIBRATION = g().JIGGLE_VIBRATION * (1 - 5 * dt)
    g().CURR_VIBRATION = g().CURR_VIBRATION or 0
    g().CURR_VIBRATION = math.min(1, g().CURR_VIBRATION + g().VIBRATION + g().JIGGLE_VIBRATION * 0.2)
    g().VIBRATION = 0
    g().CURR_VIBRATION = (1 - 15 * dt) * g().CURR_VIBRATION
    if not g().SETTINGS.rumble then g().CURR_VIBRATION = 0 end
    if g().INPUT.GAMEPAD.object and g().F_RUMBLE then
        g().INPUT.GAMEPAD.object:setVibration(g().CURR_VIBRATION * 0.4 * g().F_RUMBLE, g().CURR_VIBRATION * 0.4 * g().F_RUMBLE)
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