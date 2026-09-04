--[[ word_game/model/play/jumble_rules.lua - Pure jumble play logic (no UI) ]]

local InputLock = require("word_game.model.input_lock")
local RunMode = require("word_game.model.run_mode")
local state = require("word_game.model.state")

local M = {}

local round = require("word_game.model.round")
local modifier_effects = require("word_game.model.play.letter_modifier_effects")

function M.placed_count(slots)
	local count = 0
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card then
			count = count + 1
		elseif slot.kind == "span" and slot.cards then
			count = count + #slot.cards
		end
	end
	return count
end

function M.collect_used_cards(slots)
	local used = {}
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card then
			used[#used + 1] = slot.card
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				used[#used + 1] = card
			end
		end
	end
	return used
end

function M.round_target()
	return (G.GAME and G.GAME.word_round and G.GAME.word_round.target) or 20
end

function M.score_remaining(total_score, target)
	return math.max(0, target - total_score)
end

function M.puzzle_total(j)
	local pts = j.puzzle_points or 0
	local multi = j.puzzle_multi or 1.0
	return math.floor(pts * multi)
end

function M.preview_puzzle_total_after_word(j, word, used_cards)
	if not j or not word then return M.puzzle_total(j) end
	local bonus_stack = require("word_game.ui.boss_word_stack")
	local wr = G.GAME and G.GAME.word_round
	local old_pts = j.puzzle_points or 0
	local effects = modifier_effects.apply_word_effects(word, used_cards, j, wr)
	local word_pts = #word + (effects.bonus_points or 0)
	word_pts = word_pts + bonus_stack.bonus_points_for(used_cards)
	local committed = M.committed_earned(j)
	word_pts = M.scale_post_target_points(j, word_pts, committed)
	local new_pts = old_pts + word_pts
	local count = #(j.puzzle_words or {}) + 1
	local new_multi = 1.0
	if count >= 2 then
		new_multi = 1.0 + (count - 1) * 0.2
		new_multi = math.floor(new_multi * 10 + 0.5) / 10
	end
	new_multi = modifier_effects.apply_next_word_floor(new_multi, j)
	new_multi = modifier_effects.apply_combo_bonus(new_multi, effects.combo_bonus)
	new_multi = math.floor((new_multi + (effects.bonus_multi or 0)) * 10 + 0.5) / 10
	return math.floor(new_pts * new_multi)
end

local function placement_preview_word(j)
	if not j or not j.slots then return nil end
	if M.placed_count(j.slots) <= 0 then return nil end
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not jumble or not jumble.build_placement_preview_word then return nil end
	local word = jumble.build_placement_preview_word(j.slots)
	if not word or word == "" then return nil end
	local used_cards = M.collect_used_cards(j.slots)
	word = modifier_effects.adjust_word_for_q(word, used_cards)
	if word == "" then return nil end
	for _, played in ipairs(j.puzzle_words or {}) do
		if played == word then return nil end
	end
	return word, used_cards
end

function M.projected_stage_score(j)
	if not j then return 0 end
	return M.committed_earned(j) + M.placement_preview_got(j)
end

function M.remaining_to_target(j, target)
	target = target or M.round_target()
	return M.score_remaining(M.projected_stage_score(j), target)
end

function M.committed_earned(j)
	if not j then return 0 end
	return (j.total_score or 0) + M.puzzle_total(j)
end

function M.committed_before_word(j, old_pts, old_multi)
	if not j then return 0 end
	return (j.total_score or 0) + math.floor((old_pts or 0) * (old_multi or 1.0))
end

--- Classic mode: once the stage target is met, further scoring is doubled.
function M.post_target_active(j, committed)
	if not RunMode.is_classic() or not j then return false end
	committed = committed or M.committed_earned(j)
	return committed >= M.round_target()
end

function M.post_target_multiplier(j, committed)
	return M.post_target_active(j, committed) and 2 or 1
end

function M.scale_post_target_points(j, points, committed)
	return points * M.post_target_multiplier(j, committed)
end

function M.placement_preview_got(j)
	if not j then return 0 end
	local word, used_cards = placement_preview_word(j)
	if not word then return 0 end
	local committed_puzzle = M.puzzle_total(j)
	local preview = M.preview_puzzle_total_after_word(j, word, used_cards)
	return math.max(0, preview - committed_puzzle)
end

function M.score_breakdown(j, target)
	target = target or M.round_target()
	local earned = M.committed_earned(j)
	local got = M.placement_preview_got(j)
	local remaining = M.score_remaining(earned + got, target)
	return {
		earned = earned,
		got = got,
		remaining = remaining,
	}
end

function M.total_with_puzzle(j, pts, multi)
	return (j.total_score or 0) + math.floor(pts * multi)
end

function M.word_points(pts, multi)
	return math.floor(pts * multi)
end

function M.play_blocked(j)
	if not j then return true end
	if InputLock.is_table_busy() then return true end
	return false
end

local function puzzle_label(j)
	if j and type(j.pattern) == "string" and j.pattern ~= "" then
		return j.pattern
	end
	local puzzle = j and j.puzzle
	if type(puzzle) ~= "table" then
		return "Puzzle"
	end
	if type(puzzle.display) == "string" and puzzle.display ~= "" then
		return puzzle.display
	end
	if type(puzzle.pattern) == "string" and puzzle.pattern ~= "" then
		return puzzle.pattern
	end
	return "Puzzle"
end

function M.can_jumble_next(jumble)
	if not jumble or not jumble.is_active() then return false end
	local wr = G.GAME and G.GAME.word_round
	local j = jumble.state()
	if not wr or not j or not j.solved then return false end
	if InputLock.is_table_busy() then return false end
	return true
end

function M.evaluate_play(jumble, j)
	if M.play_blocked(j) then return nil end

	local placed = M.placed_count(j.slots)

	if placed == 0 and j.solved then
		local target = M.round_target()
		local bank_bonus = modifier_effects.bank_bonus_points(j)
		if bank_bonus > 0 then
			j.puzzle_points = (j.puzzle_points or 0) + bank_bonus
		end
		local raw_puzzle_total = M.puzzle_total(j)
		local puzzle_total = raw_puzzle_total
		local old_total = j.total_score or 0
		local post_target = M.post_target_active(j, old_total)
		if post_target then
			puzzle_total = puzzle_total * 2
		end
		local new_total = old_total + puzzle_total
		j.total_score = new_total
		local old_rem = M.score_remaining(old_total, target)
		local new_rem = M.score_remaining(new_total, target)
		local label = puzzle_label(j)
		state.record_puzzle_score(label, puzzle_total)
		return {
			kind = "bank_puzzle",
			puzzle_total = puzzle_total,
			old_total = old_total,
			new_total = new_total,
			old_rem = old_rem,
			new_rem = new_rem,
			cleared = new_rem <= 0,
			puzzle_label = label,
			post_target_doubled = post_target and raw_puzzle_total > 0,
		}
	end

	local word, err = jumble.validate_current()
	if not word then
		return { kind = "invalid", err = err }
	end

	local used_cards = M.collect_used_cards(j.slots)
	local pre_pts = j.puzzle_points or 0
	local pre_multi = j.puzzle_multi or 1.0
	local committed = M.committed_before_word(j, pre_pts, pre_multi)
	local post_target = M.post_target_active(j, committed)
	local old_pts, new_pts, old_multi, new_multi = jumble.record_puzzle_word(word, { used_cards = used_cards })
	round.record_word_play(word)
	j.bonus_available = false
	j.bonus_card_id = nil

	local target = M.round_target()
	local old_score = M.total_with_puzzle(j, old_pts, old_multi)
	local new_score = M.total_with_puzzle(j, new_pts, new_multi)
	local v_bonus = modifier_effects.target_hit_bonus(word, used_cards, old_score, new_score, target)
	if v_bonus > 0 then
		j.puzzle_points = new_pts + v_bonus
		new_pts = j.puzzle_points
		new_score = M.total_with_puzzle(j, new_pts, new_multi)
	end
	local old_rem = M.score_remaining(old_score, target)
	local new_rem = M.score_remaining(new_score, target)
	local word_pts = M.word_points(new_pts, new_multi)
	state.record_word_played()
	state.record_puzzle_score(puzzle_label(j), M.puzzle_total(j))

	return {
		kind = "word_play",
		word = word,
		old_pts = old_pts,
		new_pts = new_pts,
		old_multi = old_multi,
		new_multi = new_multi,
		old_score = old_score,
		new_score = new_score,
		old_rem = old_rem,
		new_rem = new_rem,
		word_pts = word_pts,
		cleared = new_rem <= 0,
		used_cards = used_cards,
		post_target_doubled = post_target and new_pts > pre_pts,
	}
end

return M
