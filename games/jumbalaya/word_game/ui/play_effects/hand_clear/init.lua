--[[
	word_game/ui/play_effects/hand_clear/init.lua — Stage-clear celebration and marketplace handoff.
	Inputs: Play module hooks, facade deck/jumble, TIMELINE, Funcs dispatch strings.
	Outputs: install(Play) wires on_hand_cleared; discard anim, token fly, TradeUI open.
]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local play_effects = require("word_game.ui.play_effects")
local Funcs = require("app.callbacks.funcs")
local discard = require("word_game.ui.play_effects.hand_clear.discard")
local celebrate = require("word_game.ui.play_effects.hand_clear.celebrate")
local after_clear = require("word_game.ui.play_effects.hand_clear.after_clear")

local feedback = facade.feedback()
local game_access = facade.game_access()

local M = {}


local function set_score_animating(active)
	play_effects.set_word_score_animating(active)
end

function M.install(play_module)
	function play_module.on_hand_cleared(opts)
		opts = opts or {}
		play_module.prepare_hand_clear(opts)
		if game_access.get() then
			set_score_animating(true)
		end

		if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.roll_to_next_hand then
			WORD_GAME_UI.Sidebar.roll_to_next_hand()
		end
		if WORD_GAME_UI.Confetti and not opts.boss_cleared then
			WORD_GAME_UI.Confetti.burst()
		end
		discard.discard_remaining_hand()

		local function play_clear_sequence()
			local outcome = play_module.resolve_after_clear(opts)
			if game().TIMELINE and game().TIMELINE.enqueue then
				Scheduler.add{
					mode = "instant",
					func = function()
						if opts.boss_cleared then
							celebrate.play_boss_clear()
						else
							celebrate.play_hand_clear()
						end
						Scheduler.add{
							mode = "delayed",
							delay = 1.7,
							func = function()
								after_clear.handle_after_clear(play_module, opts, outcome, set_score_animating)
								return true
							end,
						}
						return true
					end,
				}
			else
				if opts.boss_cleared then
					celebrate.play_boss_clear()
				else
					celebrate.play_hand_clear()
				end
				after_clear.handle_after_clear(play_module, opts, outcome, set_score_animating)
			end
		end

		if not opts.boss_cleared
			and WORD_GAME_UI.TokenReward.try_award(play_clear_sequence) then
			return
		end
		play_clear_sequence()
	end

	function play_module.continue_after_dealer()
		if Funcs.get("close_overlay") then
			Funcs.dispatch("close_overlay")
		end
		if game().SETTINGS then
			game().SETTINGS.paused = false
		end
		set_score_animating(true)
		local function finish_deal()
			if WORD_GAME_UI.Sidebar then
				WORD_GAME_UI.Sidebar:refresh()
			end
			set_score_animating(false)
		end
		local function deal_next_stage()
			local outcome = play_module.advance_after_dealer()
			if outcome == "win" then
				play_module.end_match(true)
				return
			end
			finish_deal()
		end
		if game().TIMELINE and game().TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = 0.18,
				func = function()
					deal_next_stage()
					return true
				end,
			}
		else
			deal_next_stage()
		end
	end

	function play_module.end_match(won)
		play_module.finalize_match(won)
		if WORD_GAME_UI.EndMatch then
			WORD_GAME_UI.EndMatch.open(won)
		end
	end

	function play_module.jumble_next(opts)
		opts = opts or {}
		play_effects.present_jumble_next(
			facade.jumble(),
			game_access.word_round(),
			opts
		)
	end

	function play_module.end_jumble_hand()
		local score = play_module.end_jumble_hand_model()
		if score == nil then return end
		feedback.show("Time!  " .. score .. " points", game().C.GOLD, 2.2, 0.35)
		play_sfx("timpani", 0.9, 0.85)
		if WORD_GAME_UI.ScoreBanner then
			local hud = WORD_GAME_UI.ScoreBanner.state()
			hud.to_go_label = "TO CLEAR"
		end
		play_module.deal_after_jumble_timeout()
	end
end

return M
