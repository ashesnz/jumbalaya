--[[ packages/jumbalaya_core/rules/play.lua - Jumble play evaluation (no G) ]]

local jumble_rules = require("jumbalaya_core.rules.jumble")
local ModifierEffects = require("jumbalaya_core.rules.letter_modifier_effects")
local PerkEffects = require("jumbalaya_core.rules.perk_effects")

local M = {}

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

function M.evaluate(j, wr, opts)
	opts = opts or {}
	if opts.play_blocked and opts.play_blocked(j) then return nil end

	local placed = opts.placed_count(j.slots)
	local target = opts.round_target(wr)
	local run_mode = opts.run_mode or "time_run"

	if placed == 0 and j.solved then
		if opts.on_puzzle_bank then
			opts.on_puzzle_bank(j, wr)
		end
		local bank_bonus = ModifierEffects.bank_bonus_points(j)
		if bank_bonus > 0 then
			j.puzzle_points = (j.puzzle_points or 0) + bank_bonus
		end
		local raw_puzzle_total = jumble_rules.puzzle_total(j)
		local puzzle_total = raw_puzzle_total * PerkEffects.bank_total_multiplier(j, opts.perk_flags)
		local old_total = j.total_score or 0
		local post_target = jumble_rules.post_target_active(run_mode, j, old_total, target)
		if post_target then
			puzzle_total = puzzle_total * 2
		end
		local new_total = old_total + puzzle_total
		j.total_score = new_total
		local old_rem = jumble_rules.score_remaining(old_total, target)
		local new_rem = jumble_rules.score_remaining(new_total, target)
		return {
			kind = "bank_puzzle",
			puzzle_total = puzzle_total,
			old_total = old_total,
			new_total = new_total,
			old_rem = old_rem,
			new_rem = new_rem,
			cleared = new_rem <= 0,
			puzzle_label = puzzle_label(j),
			post_target_doubled = post_target and raw_puzzle_total > 0,
		}
	end

	local word, err = opts.validate_current()
	if not word then
		return { kind = "invalid", err = err }
	end

	local used_cards = opts.collect_used_cards(j.slots)
	local pre_pts = j.puzzle_points or 0
	local pre_multi = j.puzzle_multi or 1.0
	local committed = jumble_rules.committed_before_word(j, pre_pts, pre_multi)
	local post_target = jumble_rules.post_target_active(run_mode, j, committed, target)
	local record = opts.record_puzzle_word
	if not record then
		return { kind = "invalid", err = "missing record_puzzle_word" }
	end
	local old_pts, new_pts, old_multi, new_multi = record(word, { used_cards = used_cards })
	if opts.on_word_recorded then
		opts.on_word_recorded(j)
	end

	local old_score = jumble_rules.total_with_puzzle(j, old_pts, old_multi)
	local new_score = jumble_rules.total_with_puzzle(j, new_pts, new_multi)
	local v_bonus = ModifierEffects.target_hit_bonus(word, used_cards, old_score, new_score, target)
	if v_bonus > 0 then
		j.puzzle_points = new_pts + v_bonus
		new_pts = j.puzzle_points
		new_score = jumble_rules.total_with_puzzle(j, new_pts, new_multi)
	end
	local old_rem = jumble_rules.score_remaining(old_score, target)
	local new_rem = jumble_rules.score_remaining(new_score, target)
	local word_pts = jumble_rules.word_points(new_pts, new_multi)

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
