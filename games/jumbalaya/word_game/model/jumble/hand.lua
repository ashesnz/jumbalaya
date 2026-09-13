--[[
	word_game/model/jumble/hand.lua - Jumble hand lifecycle (start, clear, advance).

	Core: jumbalaya_core.jumble.hand
	Store: word_round.jumble via JUMBLE_* dispatches
	Presentation: hand_cleared, jumble_hand_started, boss_word_reveal
]]

local Deck = require("word_game.model.cards.deck")
local live_game = require("word_game.model.live_game")

return function(M)
local Timeline = require("word_game.model.run.timeline")
local modifier_effects = require("word_game.model.jumble_play.letter_modifier_effects")
local perk_effects = require("word_game.model.perks.effects")
local bonus_return = require("word_game.model.jumble.bonus_return")
local jumble_rules = require("word_game.model.jumble_play.jumble_rules")
local Presentation = require("word_game.model.presentation")
local core_hand = require("jumbalaya_core.jumble.hand")
local immutable = require("jumbalaya_core.store.immutable")
local game_access = require("word_game.model.game_access")

local function puzzle_start_hooks()
	return {
		on_puzzle_start = function(j, wr)
			modifier_effects.reset_puzzle_state(j)
			perk_effects.on_puzzle_start(j, wr)
		end,
	}
end

local function puzzle_list_for(wr)
	return M.puzzles(wr.set, wr.hand_index)
end

local function clear_pattern_row_cards(j)
	local area = live_game().pattern_row and live_game().pattern_row.area
	if area and area.cards then
		for i = #area.cards, 1, -1 do
			local card = area.cards[i]
			if live_game().pattern_row then
				live_game().pattern_row:on_remove_card(card)
			end
			area:remove_card(card)
			if card.bonus_card then
				bonus_return.return_card(card)
			elseif card.area ~= live_game().dealt_letters and live_game().dealt_letters then
				live_game().dealt_letters:emplace(card)
			end
		end
		if area.config then
			area.config.card_limit = M.blank_count(j.slots, j.puzzle)
		end
		if live_game().pattern_row then
			live_game().pattern_row:relayout()
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
	end
	M.PlacementWord.clear()
end

function M.is_active_hand(set, hand_index)
	return core_hand.is_active_hand(set, hand_index)
end

function M.is_active()
	return core_hand.is_active(game_access.word_round())
end

function M.state()
	return core_hand.state(game_access.word_round())
end

function M.apply_puzzle(_wr, puzzle)
	local wr = game_access.word_round()
	if not wr then return end
	local wr_copy = immutable.copy_word_round(wr)
	core_hand.apply_puzzle(wr_copy, puzzle, puzzle_start_hooks())
	game_access.dispatch({ type = "JUMBLE_APPLY_PUZZLE", word_round = wr_copy })
	Presentation.emit("puzzle_applied")
	local j = core_hand.state(game_access.word_round())
	if j then
		clear_pattern_row_cards(j)
	end
end

function M.load_puzzle(_wr, index)
	local wr = game_access.word_round()
	if not wr then return end
	game_access.dispatch({
		type = "JUMBLE_LOAD_PUZZLE",
		index = index,
		puzzle_list = puzzle_list_for(wr),
	})
end

function M.start_hand(_wr)
	local wr = game_access.word_round()
	if not wr then return end
	game_access.dispatch({
		type = "JUMBLE_START_HAND",
		puzzle_list = puzzle_list_for(wr),
	})
	Presentation.emit("score_banner_jumble_hand_start")
end

function M.start_boss_word(wr)
	return M.reveal_boss_puzzle(wr)
end

function M.prepare_boss_word(_wr)
	local wr = game_access.word_round()
	if not wr then return false end
	game_access.dispatch({
		type = "JUMBLE_PREPARE_BOSS_WORD",
		boss = M.boss_puzzle(wr.set, wr.hand_index),
	})
	local next_wr = game_access.word_round()
	if not next_wr or not next_wr.jumble or not next_wr.jumble.pending_boss then
		return false
	end
	if next_wr.jumble.slots then
		M.sync_placement_cards(next_wr.jumble.slots)
	end
	return true
end

function M.reveal_boss_puzzle(_wr)
	local wr = game_access.word_round()
	if not wr then return false end
	local wr_copy = immutable.copy_word_round(wr)
	local ok = core_hand.reveal_boss_puzzle(wr_copy, puzzle_start_hooks()) or false
	if ok then
		game_access.dispatch({ type = "JUMBLE_REVEAL_BOSS_PUZZLE", word_round = wr_copy })
		Presentation.emit("boss_puzzle_revealed")
	end
	return ok
end

function M.begin_boss_word(_wr, on_complete)
	local wr = game_access.word_round()
	if not wr or not wr.jumble or wr.jumble.boss_word_active then return false end

	game_access.dispatch({ type = "JUMBLE_SET_BOSS_STAGING" })
	wr = game_access.word_round()
	if Presentation.emit("boss_word_begin", wr, on_complete) then
		return true
	end

	if M.prepare_boss_word(wr) then
		wr = game_access.word_round()
		local letters = M.boss_hand_letters(
			wr.jumble.pending_boss.boss_word,
			wr.jumble.pending_boss.pattern
		)
		Deck.deal_boss_hand(letters, on_complete)
		return true
	end
	return false
end

function M.current_puzzle_points()
	local j = M.state()
	return j and j.puzzle_points or 0
end

function M.current_puzzle_multi()
	local j = M.state()
	return j and j.puzzle_multi or 1.0
end

function M.record_puzzle_word(word, opts)
	opts = opts or {}
	local wr = game_access.word_round()
	local j = core_hand.state(wr)
	if not j or not word then return 0, 0, 1.0, 1.0 end

	local wr_copy = immutable.copy_word_round(wr)
	local j_copy = core_hand.state(wr_copy)
	local used_cards = opts.used_cards
	local score_opts = jumble_rules.build_score_opts(j_copy, word, used_cards, {
		wr = wr_copy,
		apply_time_penalty = true,
		old_pts = j_copy.puzzle_points or 0,
		old_multi = j_copy.puzzle_multi or 1.0,
		word_count = #(j_copy.puzzle_words or {}) + 1,
	})
	local old_pts, new_pts, old_multi, new_multi = core_hand.record_puzzle_word(j_copy, word, score_opts)
	game_access.dispatch({
		type = "JUMBLE_RECORD_WORD",
		jumble = {
			puzzle_words = j_copy.puzzle_words,
			puzzle_points = j_copy.puzzle_points,
			puzzle_multi = j_copy.puzzle_multi,
			solved = j_copy.solved,
			next_word_multi_bonus = j_copy.next_word_multi_bonus,
		},
	})
	return old_pts, new_pts, old_multi, new_multi
end

function M.time_left()
	return Timeline.seconds_remaining()
end

function M.update_timer()
	local remaining = Timeline.seconds_remaining()
	if remaining == math.huge then return false end
	return remaining <= 0
end

function M.refresh_hud()
	if not M.is_active() then return end
	Presentation.emit("jumble_hud_refresh")
end

function M.advance_puzzle(_wr)
	local wr = game_access.word_round()
	if not wr or not wr.jumble then return end
	game_access.dispatch({
		type = "JUMBLE_ADVANCE_PUZZLE",
		puzzle_list = puzzle_list_for(wr),
	})
end
end
