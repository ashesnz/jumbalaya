--[[ word_game/model/jumble/hand.lua - Jumble hand lifecycle (G glue over jumbalaya_core) ]]

return function(M)
local Timeline = require("word_game.model.run.timeline")
local modifier_effects = require("word_game.model.jumble_play.letter_modifier_effects")
local perk_effects = require("word_game.model.perks.effects")
local bonus_return = require("word_game.model.jumble.bonus_return")
local round_config = require("word_game.config.gameplay.round")
local jumble_rules = require("word_game.model.jumble_play.jumble_rules")
local Presentation = require("word_game.model.presentation")
local core_hand = require("jumbalaya_core.jumble.hand")
local game_access = require("word_game.model.game_access")
local store_sync = require("bridge.store_sync")
local runtime = require("bridge.runtime")

local function sync_store()
	local store = runtime.store()
	if store then
		store_sync.sync_to_g(store)
	end
end

local function puzzle_hooks()
	return {
		on_puzzle_start = function(j, wr)
			modifier_effects.reset_puzzle_state(j)
			perk_effects.on_puzzle_start(j, wr)
		end,
		on_puzzle_applied = function()
			Presentation.emit("puzzle_applied")
		end,
	}
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

function M.apply_puzzle(wr, puzzle)
	core_hand.apply_puzzle(wr, puzzle, puzzle_hooks())

	local j = wr.jumble
	local area = G.pattern_row and G.pattern_row.area
	if area and area.cards then
		for i = #area.cards, 1, -1 do
			local card = area.cards[i]
			if G.pattern_row then
				G.pattern_row:on_remove_card(card)
			end
			area:remove_card(card)
			if card.bonus_card then
				bonus_return.return_card(card)
			elseif card.area ~= G.dealt_letters and G.dealt_letters then
				G.dealt_letters:emplace(card)
			end
		end
		if area.config then
			area.config.card_limit = M.blank_count(j.slots, j.puzzle)
		end
		if G.pattern_row then
			G.pattern_row:relayout()
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
	end

	M.PlacementWord.clear()
end

function M.load_puzzle(wr, index)
	local set = wr and wr.set
	local hand = wr and wr.hand_index
	core_hand.load_puzzle(wr, index, M.puzzles(set, hand))
end

function M.start_hand(wr)
	modifier_effects.reset_stage_state(wr)
	core_hand.start_hand(wr, {
		on_stage_start = function()
			Presentation.emit("score_banner_jumble_hand_start")
		end,
		puzzle_list = M.puzzles(wr.set, wr.hand_index),
	})
end

function M.start_boss_word(wr)
	return M.reveal_boss_puzzle(wr)
end

function M.prepare_boss_word(wr)
	if not core_hand.prepare_boss_word(wr, M.boss_puzzle(wr.set, wr.hand_index)) then
		return false
	end
	if wr.jumble.slots then
		M.sync_placement_cards(wr.jumble.slots)
	end
	return true
end

function M.reveal_boss_puzzle(wr)
	local ok = core_hand.reveal_boss_puzzle(wr, puzzle_hooks())
	if ok then
		Presentation.emit("boss_puzzle_revealed")
	end
	return ok
end

function M.begin_boss_word(wr, on_complete)
	if not wr or not wr.jumble or wr.jumble.boss_word_active then return false end
	wr.jumble.boss_word_staging = true
	if Presentation.emit("boss_word_begin", wr, on_complete) then
		return true
	end
	if M.prepare_boss_word(wr) and WORD_GAME and WORD_GAME.Deck then
		local letters = M.boss_hand_letters(
			wr.jumble.pending_boss.boss_word,
			wr.jumble.pending_boss.pattern
		)
		WORD_GAME.Deck.deal_boss_hand(letters, on_complete)
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
	store_sync.adopt_current_g_game()
	local j = M.state()
	if not j then return 0, 0, 1.0, 1.0 end
	local wr = game_access.word_round()
	local used_cards = opts.used_cards
	local score_opts = jumble_rules.build_score_opts(j, word, used_cards, {
		wr = wr,
		apply_time_penalty = true,
		old_pts = j.puzzle_points or 0,
		old_multi = j.puzzle_multi or 1.0,
		word_count = #(j.puzzle_words or {}) + 1,
	})
	local old_pts, new_pts, old_multi, new_multi = core_hand.record_puzzle_word(j, word, score_opts)
	sync_store()
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

function M.advance_puzzle(wr)
	if not wr or not wr.jumble then return end
	core_hand.advance_puzzle(wr, M.puzzles(wr.set, wr.hand_index))
end
end
