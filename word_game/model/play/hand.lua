--[[ word_game/model/play/hand.lua ]]
local Scheduler = require "app.effects.scheduler"


return function(M)
local round = require("word_game.model.round")
local round_config = require("word_game.config.round_config")
local state = require("word_game.model.state")
local word_feedback = require("word_game.ui.word_feedback")
local play_effects = require("word_game.ui.play_effects")
local CardMotion = require("app.effects.card_motion")

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
						CardMotion.move{from = G.hand, to = G.discard, percent = 50, direction = "down", stay_flipped = false, card = card, delay = 0.08}
					end
					return true
				end,
			}
		end
	end
	return n
end

local function open_after_hand(opts)
	opts = opts or {}
	if WORD_GAME and WORD_GAME.HandClearFocus and WORD_GAME.HandClearFocus.end_focus then
		WORD_GAME.HandClearFocus.end_focus()
	end
	set_score_animating(false)
	local host = G.player_host
	if host then
		host:remove_speech_bubble()
	end
	local wr = G.GAME.word_round
	local j = wr and wr.jumble
	if opts.boss_cleared or (j and j.boss_word_active) then
		local bonus_stack = WORD_GAME and WORD_GAME.BossWordStack
		local keep_bonus_cards = opts.boss_cleared
			and round_config.is_boss_word_hand(wr.set, wr.hand_index)
		if j then
			j.boss_word_active = false
			j.boss_word_staging = false
			j.boss_puzzle_hidden = false
			j.pending_boss = nil
			j.locked_hand_layout = nil
		end
		if keep_bonus_cards then
			if bonus_stack and bonus_stack.finalize_for_bonus_hand then
				bonus_stack.finalize_for_bonus_hand(wr)
			end
			if WORD_GAME and WORD_GAME.PlayEffects and WORD_GAME.PlayEffects.restore_boss_layout then
				WORD_GAME.PlayEffects.restore_boss_layout({ keep_bonus_stack = true })
			end
		else
			if WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.destroy_boss_cards then
				WORD_GAME.Deck.destroy_boss_cards()
			end
			if WORD_GAME and WORD_GAME.PlayEffects and WORD_GAME.PlayEffects.restore_boss_layout then
				WORD_GAME.PlayEffects.restore_boss_layout()
			end
		end
		if WORD_GAME and WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.set_banner_mode then
			WORD_GAME.ScoreBanner.set_banner_mode("normal")
		end
		if wr.set >= round_config.SETS_TO_WIN then
			M.end_match(true)
			return
		end
		round.start_hand(wr.set, wr.hand_index + 1)
		require("word_game.model.play.opening_deal").deal()
		return
	end
	if opts.boss_next then
		-- Stage 1-3 cleared: the celebration has played; now hide the sidebar
		-- and bring up the boss stage.
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.begin_boss_word then
			WORD_GAME.Jumble.begin_boss_word(wr, function()
				set_score_animating(false)
			end)
		end
		return
	end
	if round.is_final_hand() then
		M.end_match(true)
	elseif WORD_GAME.TradeUI then
		WORD_GAME.TradeUI.open_then_dealer()
	else
		M.continue_after_dealer()
	end
end

local function play_hand_clear()
	local major = (G.placement_table and G.placement_table.area)
		or G.PLAY_ATTACH
		or G.ROOM_ATTACH
	if WORD_GAME and WORD_GAME.Confetti then
		WORD_GAME.Confetti.burst()
	end
	word_feedback.show("Hand Cleared", G.C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
	play_sfx("card_tick", 0.6, 0.5)
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

local function play_boss_clear()
	if WORD_GAME and WORD_GAME.Confetti then
		WORD_GAME.Confetti.burst()
	end
	word_feedback.show("Boss Defeated!", G.C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
end

function M.on_hand_cleared(opts)
	opts = opts or {}
	local wr = G.GAME and G.GAME.word_round
	local j = wr and wr.jumble
	if not opts.boss_cleared
		and j and j.slots
		and WORD_GAME and WORD_GAME.Jumble
		and WORD_GAME.Jumble.clear_blank_cards then
		WORD_GAME.Jumble.clear_blank_cards(j.slots)
	end
	if not opts.boss_cleared
		and WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.is_jumble_deck
		and WORD_GAME.Deck.is_jumble_deck()
		and WORD_GAME.Deck.reset_table_deck then
		WORD_GAME.Deck.reset_table_deck()
	end
	if G.GAME then
		set_score_animating(true)
	end

	if wr and round_config.is_boss_word_hand(wr.set, wr.hand_index) and j
		and not j.boss_word_active and not opts.boss_cleared then
		-- Stage 1-3 celebrates like every other hand, then flows into the
		-- boss stage instead of the dealer (see open_after_hand).
		opts.boss_next = true
	end

	if WORD_GAME.Sidebar and WORD_GAME.Sidebar.roll_to_next_hand then
		WORD_GAME.Sidebar.roll_to_next_hand()
	end
	if WORD_GAME and WORD_GAME.Confetti and not opts.boss_cleared then
		WORD_GAME.Confetti.burst()
	end
	local leftover = discard_remaining_hand()

	local function play_clear_sequence()
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
							open_after_hand(opts)
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
			open_after_hand(opts)
		end
	end

	if not opts.boss_cleared and WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.try_award(play_clear_sequence) then
		return
	end
	play_clear_sequence()
end

function M.continue_after_dealer()
	if G.FUNCS and G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
	if G.SETTINGS then
		G.SETTINGS.paused = false
	end
	local wr = G.GAME and G.GAME.word_round
	if not wr then return end
	local result = round.advance_hand()
	if result == "win" then
		M.end_match(true)
		return
	end
	set_score_animating(true)
	local function deal_next_stage()
		if WORD_GAME and WORD_GAME.Deck then
			WORD_GAME.Deck.reset_table_deck()
		end
		require("word_game.model.play.opening_deal").deal()
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar:refresh()
		end
		set_score_animating(false)
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

function M.end_match(won)
	state.record_current_jumble_if_best()
	local alpha = state.get()
	if alpha then
		alpha.match_over = true
		alpha.match_won = won and true or false
	end
	if WORD_GAME.EndMatch then
		WORD_GAME.EndMatch.open(won)
	end
end

end
