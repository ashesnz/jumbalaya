--[[
	word_game/model/jumble_play/hand.lua - Hand-clear prep, boss/trade/dealer resolution, match finalize after stage clear

	Core: jumbalaya_core.config.gameplay.round
	Store: game_access.dispatch(RUN_MATCH_END)
	Presentation: none
]]

return function(M)
local round = require("word_game.model.round")
local round_config = require("jumbalaya_core.config.gameplay.round")
local opening_deal = require("word_game.model.jumble_play.opening_deal")
local perk_effects = require("word_game.model.perks.effects")
local state = require("word_game.model.run.state")
local trade = require("word_game.model.trade")
local game_access = require("word_game.model.game_access")

local function wr_jumble()
	local wr = game_access.word_round()
	return wr, wr and wr.jumble
end

function M.prepare_hand_clear(opts)
	opts = opts or {}
	local wr, j = wr_jumble()
	if j and (j.total_score or 0) >= (wr.target or 20) then
		perk_effects.try_award_stage_clear_bonus(j)
	end
	if not opts.boss_cleared
		and j and j.slots
		and WORD_GAME and WORD_GAME.Jumble
		and WORD_GAME.Jumble.clear_blank_cards then
		WORD_GAME.Jumble.clear_blank_cards(j.slots)
	end
	if not opts.boss_cleared
		and WORD_GAME and WORD_GAME.Deck
		and WORD_GAME.Deck.is_jumble_deck
		and WORD_GAME.Deck.is_jumble_deck()
		and WORD_GAME.Deck.reset_table_deck then
		WORD_GAME.Deck.reset_table_deck()
	end
	if wr and round_config.is_boss_word_hand(wr.set, wr.hand_index) and j
		and not j.boss_word_active and not opts.boss_cleared then
		opts.boss_next = true
	end
	return wr, j, opts
end

function M.clear_boss_state(j, wr)
	if not j then return end
	j.boss_word_active = false
	j.boss_word_staging = false
	j.boss_puzzle_hidden = false
	j.pending_boss = nil
	j.locked_hand_layout = nil
end

function M.resolve_after_clear(opts)
	opts = opts or {}
	local wr, j = wr_jumble()
	if not wr then return "none" end

	if opts.boss_cleared or (j and j.boss_word_active) then
		local keep_bonus_cards = opts.boss_cleared
			and round_config.is_boss_word_hand(wr.set, wr.hand_index)
		M.clear_boss_state(j, wr)
		if wr.set >= round_config.SETS_TO_WIN then
			return "win"
		end
		return keep_bonus_cards and "boss_bonus_hand" or "boss_hand_advanced"
	end

	if opts.boss_next then
		return "boss_next"
	end
	if round.is_final_hand() then
		return "win"
	end
	if trade.can_use() then
		return "trade"
	end
	return "dealer"
end

function M.begin_next_hand_after_boss()
	local wr = game_access.word_round()
	if not wr then return end
	round.start_hand(wr.set, wr.hand_index + 1)
	opening_deal.deal()
end

function M.advance_after_dealer()
	local wr = game_access.word_round()
	if not wr then return "none" end
	local result = round.advance_hand()
	if result == "win" then
		return "win"
	end
	if WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.reset_table_deck then
		WORD_GAME.Deck.reset_table_deck()
	end
	opening_deal.deal()
	return "next"
end

function M.finalize_match(won)
	state.record_current_jumble_if_best()
	game_access.dispatch({ type = "RUN_MATCH_END", won = won })
	return won
end

end
