--[[ word_game/ui/play_effects/hand_clear.lua - Hand-clear presentation and flow wiring ]]

local facade = require("word_game.ui.facade")
local Scheduler = require("app.effects.timeline_scheduler")
local CardMotion = require("app.effects.card_motion")
local play_effects = require("word_game.ui.play_effects")

local feedback = facade.feedback()

local M = {}

local function set_score_animating(active)
	play_effects.set_word_score_animating(active)
end

local function discard_remaining_hand()
	if not G.hand then return 0 end
	local n = #(G.hand.cards or {})
	if G.TIMELINE and G.TIMELINE.enqueue then
		for i = 1, n do
			Scheduler.add{
				mode = "delayed",
				delay = 0.07,
				func = function()
					local card = G.hand and G.hand.cards and G.hand.cards[1]
					if card then
						CardMotion.move{
							from = G.hand,
							to = G.discard,
							percent = 50,
							direction = "down",
							stay_flipped = false,
							card = card,
							delay = 0.08,
						}
					end
					return true
				end,
			}
		end
	end
	return n
end

local function play_hand_clear()
	local major = (G.placement_table and G.placement_table.area)
		or G.PLAY_ATTACH
		or G.ROOM_ATTACH
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.burst()
	end
	feedback.show("Hand Cleared", G.C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
	play_sfx("card_tick", 0.6, 0.5)
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

local function play_boss_clear()
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.burst()
	end
	feedback.show("Boss Defeated!", G.C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
end

local function handle_after_clear(play_module, opts, outcome)
	if WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.end_focus then
		WORD_GAME_UI.HandClearFocus.end_focus()
	end
	set_score_animating(false)

	if outcome == "win" then
		play_module.end_match(true)
		return
	end
	if outcome == "boss_bonus_hand" then
		local wr = G.GAME.word_round
		local bonus_stack = WORD_GAME_UI.BonusStackUI
		if bonus_stack and bonus_stack.finalize_for_bonus_hand then
			bonus_stack.finalize_for_bonus_hand(wr)
		end
		if WORD_GAME_UI.PlayEffects and WORD_GAME_UI.PlayEffects.restore_boss_layout then
			WORD_GAME_UI.PlayEffects.restore_boss_layout({ keep_bonus_stack = true })
		end
		if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
			WORD_GAME_UI.ScoreBanner.set_banner_mode("normal")
		end
		play_module.begin_next_hand_after_boss()
		return
	end
	if outcome == "boss_hand_advanced" then
		if WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.destroy_boss_cards then
			WORD_GAME.Deck.destroy_boss_cards()
		end
		if WORD_GAME_UI.PlayEffects and WORD_GAME_UI.PlayEffects.restore_boss_layout then
			WORD_GAME_UI.PlayEffects.restore_boss_layout()
		end
		if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
			WORD_GAME_UI.ScoreBanner.set_banner_mode("normal")
		end
		play_module.begin_next_hand_after_boss()
		return
	end
	if outcome == "boss_next" then
		local wr = G.GAME.word_round
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.begin_boss_word then
			WORD_GAME.Jumble.begin_boss_word(wr, function()
				set_score_animating(false)
			end)
		end
		return
	end
	if outcome == "trade" then
		WORD_GAME_UI.TradeUI.open_then_dealer()
		return
	end
	if outcome == "dealer" then
		play_module.continue_after_dealer()
	end
end

function M.install(play_module)
	function play_module.on_hand_cleared(opts)
		opts = opts or {}
		play_module.prepare_hand_clear(opts)
		if G.GAME then
			set_score_animating(true)
		end

		if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.roll_to_next_hand then
			WORD_GAME_UI.Sidebar.roll_to_next_hand()
		end
		if WORD_GAME_UI.Confetti and not opts.boss_cleared then
			WORD_GAME_UI.Confetti.burst()
		end
		discard_remaining_hand()

		local function play_clear_sequence()
			local outcome = play_module.resolve_after_clear(opts)
			if G.TIMELINE and G.TIMELINE.enqueue then
				Scheduler.add{
					mode = "instant",
					func = function()
						if opts.boss_cleared then
							play_boss_clear()
						else
							play_hand_clear()
						end
						Scheduler.add{
							mode = "delayed",
							delay = 1.7,
							func = function()
								handle_after_clear(play_module, opts, outcome)
								return true
							end,
						}
						return true
					end,
				}
			else
				if opts.boss_cleared then
					play_boss_clear()
				else
					play_hand_clear()
				end
				handle_after_clear(play_module, opts, outcome)
			end
		end

		if not opts.boss_cleared
			and WORD_GAME
			and WORD_GAME_UI.TokenReward
			and WORD_GAME_UI.TokenReward.try_award(play_clear_sequence) then
			return
		end
		play_clear_sequence()
	end

	function play_module.continue_after_dealer()
		if G.FUNCS and G.FUNCS.close_overlay then
			G.FUNCS.close_overlay()
		end
		if G.SETTINGS then
			G.SETTINGS.paused = false
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
		if G.TIMELINE and G.TIMELINE.enqueue then
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
			WORD_GAME and WORD_GAME.Jumble,
			G.GAME and G.GAME.word_round,
			opts
		)
	end

	function play_module.end_jumble_hand()
		local score = play_module.end_jumble_hand_model()
		if score == nil then return end
		feedback.show("Time!  " .. score .. " points", G.C.GOLD, 2.2, 0.35)
		play_sfx("timpani", 0.9, 0.85)
		if WORD_GAME_UI.ScoreBanner then
			local hud = WORD_GAME_UI.ScoreBanner.state()
			hud.to_go_label = "TO CLEAR"
		end
		play_module.deal_after_jumble_timeout()
	end
end

return M
