--[[ packages/jumbalaya_core/rules/jumble.lua - Pure jumble scoring rules (no G, no Love2D) ]]

local perk_math = require("jumbalaya_core.rules.perk_math")

local M = {}

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

function M.round_target(word_round, fallback)
	if word_round and word_round.target then
		return word_round.target
	end
	return fallback or 20
end

function M.score_remaining(total_score, target)
	return math.max(0, target - total_score)
end

function M.puzzle_total(j)
	local pts = j.puzzle_points or 0
	local multi = j.puzzle_multi or 1.0
	return math.floor(pts * multi)
end

function M.committed_before_word(j, old_pts, old_multi)
	if not j then return 0 end
	return (j.total_score or 0) + math.floor((old_pts or 0) * (old_multi or 1.0))
end

function M.committed_earned(j)
	if not j then return 0 end
	return (j.total_score or 0) + M.puzzle_total(j)
end

function M.total_with_puzzle(j, pts, multi)
	return (j.total_score or 0) + math.floor(pts * multi)
end

function M.word_points(pts, multi)
	return math.floor(pts * multi)
end

function M.post_target_active(run_mode, j, committed, target)
	if run_mode ~= "classic" or not j then return false end
	committed = committed or M.committed_earned(j)
	target = target or 20
	return committed >= target
end

function M.post_target_multiplier(run_mode, j, committed, target)
	return M.post_target_active(run_mode, j, committed, target) and 2 or 1
end

function M.scale_post_target_points(run_mode, j, points, committed, target)
	return points * M.post_target_multiplier(run_mode, j, committed, target)
end

---@class WordScoreEffects
---@field bonus_points number|nil
---@field bonus_multi number|nil
---@field point_multiplier number|nil
---@field combo_bonus number|nil

---@class WordScoreOpts
---@field wr table|nil
---@field old_pts number|nil
---@field old_multi number|nil
---@field word_count number|nil
---@field perks table|nil
---@field effects WordScoreEffects|nil
---@field bonus_points_for fun(used_cards: table[]): number|nil
---@field apply_time_penalty boolean|nil
---@field on_time_penalty fun(j: table)|nil
---@field apply_point_multiplier fun(word_pts: number, effects: WordScoreEffects): number|nil
---@field apply_next_word_floor fun(multi: number, j: table): number|nil
---@field apply_combo_bonus fun(multi: number, effects: WordScoreEffects): number|nil

function M.compute_word_score(j, word, used_cards, opts)
	opts = opts or {}
	if not j or not word then return nil end

	if opts.apply_time_penalty and opts.on_time_penalty then
		opts.on_time_penalty(j)
	end

	local effects = opts.effects or {}
	local old_pts = opts.old_pts or j.puzzle_points or 0
	local old_multi = opts.old_multi or j.puzzle_multi or 1.0
	local word_count = opts.word_count or (#(j.puzzle_words or {}) + 1)
	local perks = opts.perks or {}

	local word_pts = #word + (effects.bonus_points or 0)
	if opts.bonus_points_for then
		word_pts = word_pts + (opts.bonus_points_for(used_cards) or 0)
	end

	local committed = M.committed_before_word(j, old_pts, old_multi)
	local run_mode = opts.run_mode or (opts.wr and opts.wr.run_mode)
	word_pts = M.scale_post_target_points(run_mode, j, word_pts, committed, M.round_target(opts.wr))

	if opts.apply_point_multiplier then
		word_pts = opts.apply_point_multiplier(word_pts, effects)
	elseif effects.point_multiplier then
		word_pts = math.floor(word_pts * effects.point_multiplier)
	end

	local new_pts = old_pts + word_pts
	local new_multi = perk_math.puzzle_multi_for_word_count(word_count, perks)

	if opts.apply_next_word_floor then
		new_multi = opts.apply_next_word_floor(new_multi, j)
	end
	if opts.apply_combo_bonus then
		new_multi = opts.apply_combo_bonus(new_multi, effects)
	end
	new_multi = math.floor((new_multi + (effects.bonus_multi or 0)) * 10 + 0.5) / 10

	return {
		effects = effects,
		old_pts = old_pts,
		new_pts = new_pts,
		old_multi = old_multi,
		new_multi = new_multi,
	}
end

function M.preview_puzzle_total_after_word(j, word, used_cards, opts)
	if not j or not word then return M.puzzle_total(j) end
	local score = M.compute_word_score(j, word, used_cards, opts)
	if not score then return M.puzzle_total(j) end
	return math.floor(score.new_pts * score.new_multi)
end

function M.remaining_to_target(j, target, preview_got)
	target = target or 20
	preview_got = preview_got or 0
	return M.score_remaining(M.committed_earned(j) + preview_got, target)
end

function M.score_breakdown(j, target, preview_got)
	target = target or 20
	preview_got = preview_got or 0
	local earned = M.committed_earned(j)
	return {
		earned = earned,
		got = preview_got,
		remaining = M.score_remaining(earned + preview_got, target),
	}
end

--- Apply a scored word to jumble state (pure; no globals).
function M.apply_puzzle_word(j, word, opts)
	opts = opts or {}
	if not j or not word then return 0, 0, 1.0, 1.0 end

	local used_cards = opts.used_cards
	local old_pts = j.puzzle_points or 0
	local old_multi = j.puzzle_multi or 1.0
	j.puzzle_words = j.puzzle_words or {}
	table.insert(j.puzzle_words, word)
	opts.word_count = #(j.puzzle_words)

	local score = M.compute_word_score(j, word, used_cards, opts)
	if not score then return old_pts, old_pts, old_multi, old_multi end

	j.puzzle_points = score.new_pts
	j.puzzle_multi = score.new_multi
	j.solved = true
	return old_pts, score.new_pts, old_multi, score.new_multi
end

return M
