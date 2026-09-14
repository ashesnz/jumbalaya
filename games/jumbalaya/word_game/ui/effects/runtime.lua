--[[
	word_game/ui/effects/runtime.lua — Canvas bounce/juice and repeating table motion hooks.
	Inputs: Game shell CANVAS, TIMELINE, real_dt.
	Outputs: Runtime.update_canvas_juice(dt); registered from runtime_boot early_frame updater.
]]

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local game = require("word_game.ui.util.game_runtime").game

local Runtime = {}

function Runtime.update_canvas_juice(dt)
    if not game().ROOM or not game().ROOM_ORIG or not game().POINTER or not game().POINTER.T or not game().WINDOW_TRANSFORM then return end
    game().JIGGLE_VIBRATION = game().ROOM.jiggle or 0
    if not game().SETTINGS.screenshake or type(game().SETTINGS.screenshake) ~= 'number' then
        game().SETTINGS.screenshake = 50
    end
    local shake_amt = math.max(0, game().SETTINGS.screenshake - 30) / 100
    game().ARGS.eased_cursor_pos = game().ARGS.eased_cursor_pos or {
        x = game().POINTER.T.x,
        y = game().POINTER.T.y,
        sx = game().INPUT.cursor_position.x,
        sy = game().INPUT.cursor_position.y,
    }
    game().ARGS.eased_cursor_pos.x = game().ARGS.eased_cursor_pos.x * (1 - 3 * dt)
        + 3 * dt * (shake_amt * game().POINTER.T.x + (1 - shake_amt) * game().ROOM.T.w / 2)
    game().ARGS.eased_cursor_pos.y = game().ARGS.eased_cursor_pos.y * (1 - 3 * dt)
        + 3 * dt * (shake_amt * game().POINTER.T.y + (1 - shake_amt) * game().ROOM.T.h / 2)
    game().ARGS.eased_cursor_pos.sx = game().ARGS.eased_cursor_pos.sx * (1 - 3 * dt)
        + 3 * dt * (shake_amt * game().INPUT.cursor_position.x + (1 - shake_amt) * game().WINDOW_TRANSFORM.real_window_w / 2)
    game().ARGS.eased_cursor_pos.sy = game().ARGS.eased_cursor_pos.sy * (1 - 3 * dt)
        + 3 * dt * (shake_amt * game().INPUT.cursor_position.y + (1 - shake_amt) * game().WINDOW_TRANSFORM.real_window_h / 2)

    shake_amt = game().SETTINGS.screenshake / 100 * 3
    if shake_amt < 0.05 then shake_amt = 0 end

    game().ROOM.jiggle = (game().ROOM.jiggle or 0) * (1 - 5 * dt) * (shake_amt > 0.05 and 1 or 0)
    game().ROOM.T.r = (0.001 * math.sin(0.3 * game().TIMERS.REAL) + 0.002 * game().ROOM.jiggle * math.sin(39.913 * game().TIMERS.REAL)) * shake_amt
    game().ROOM.T.x = game().ROOM_ORIG.x + shake_amt * (0.015 * math.sin(0.913 * game().TIMERS.REAL)
        + 0.01 * (game().ROOM.jiggle * shake_amt) * math.sin(19.913 * game().TIMERS.REAL)
        + (game().ARGS.eased_cursor_pos.x - 0.5 * (game().ROOM.T.w + game().ROOM_ORIG.x)) * 0.01)
    game().ROOM.T.y = game().ROOM_ORIG.y + shake_amt * (0.015 * math.sin(0.952 * game().TIMERS.REAL)
        + 0.01 * (game().ROOM.jiggle * shake_amt) * math.sin(21.913 * game().TIMERS.REAL)
        + (game().ARGS.eased_cursor_pos.y - 0.5 * (game().ROOM.T.h + game().ROOM_ORIG.y)) * 0.01)

    game().JIGGLE_VIBRATION = game().JIGGLE_VIBRATION * (1 - 5 * dt)
    game().CURR_VIBRATION = game().CURR_VIBRATION or 0
    game().CURR_VIBRATION = math.min(1, game().CURR_VIBRATION + game().VIBRATION + game().JIGGLE_VIBRATION * 0.2)
    game().VIBRATION = 0
    game().CURR_VIBRATION = (1 - 15 * dt) * game().CURR_VIBRATION
    if not game().SETTINGS.rumble then game().CURR_VIBRATION = 0 end
    if game().INPUT.GAMEPAD.object and game().F_RUMBLE then
        game().INPUT.GAMEPAD.object:setVibration(game().CURR_VIBRATION * 0.4 * game().F_RUMBLE, game().CURR_VIBRATION * 0.4 * game().F_RUMBLE)
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