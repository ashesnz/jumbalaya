--[[ word_game/model/jumble_play/jumble_rules.lua - Jumble play logic (G glue over jumbalaya_core) ]]

local InputLock = require("word_game.model.run.input_lock")
local RunMode = require("word_game.model.run.mode")
local state = require("word_game.model.run.state")
local invariant = require("word_game.model.invariant")
local core = require("jumbalaya_core.rules.jumble")
local core_play = require("jumbalaya_core.rules.play")
local placement_preview = require("jumbalaya_core.jumble.placement_preview")
local store_sync = require("bridge.store_sync")
local game_access = require("word_game.model.game_access")

local M = {}

local round = require("word_game.model.round")
local bonus_stack = require("word_game.model.jumble.bonus_stack")
local modifier_effects = require("word_game.model.jumble_play.letter_modifier_effects")
local perk_effects = require("word_game.model.perks.effects")

local function run_mode_id()
	return RunMode.is_classic() and "classic" or "time_run"
end

local function perk_flags()
	return {
		combo_starter = perk_effects.has("combo_starter"),
		combo_master = perk_effects.has("combo_master"),
	}
end

local function word_round_ref(wr)
	return wr or game_access.word_round()
end

M.placed_count = core.placed_count
M.collect_used_cards = core.collect_used_cards
M.score_remaining = core.score_remaining
M.puzzle_total = core.puzzle_total
M.committed_before_word = core.committed_before_word
M.committed_earned = core.committed_earned
M.total_with_puzzle = core.total_with_puzzle
M.word_points = core.word_points

function M.round_target(wr)
	return core.round_target(word_round_ref(wr))
end

local function score_opts_for_word(j, word, used_cards, opts)
	opts = opts or {}
	local wr = word_round_ref(opts.wr)
	return {
		wr = wr,
		run_mode = run_mode_id(),
		used_cards = used_cards,
		effects = opts.effects or modifier_effects.apply_word_effects(word, used_cards, j, wr),
		bonus_points_for = bonus_stack.bonus_points_for,
		perks = opts.perks or perk_flags(),
		word_count = opts.word_count or (#(j.puzzle_words or {}) + 1),
		old_pts = opts.old_pts,
		old_multi = opts.old_multi,
		apply_time_penalty = opts.apply_time_penalty,
		on_time_penalty = perk_effects.apply_time_bank_penalty_on_word,
		apply_point_multiplier = function(pts, effects)
			return perk_effects.apply_point_multiplier(pts, effects and effects.point_multiplier)
		end,
		apply_next_word_floor = modifier_effects.apply_next_word_floor,
		apply_combo_bonus = function(multi, effects)
			return modifier_effects.apply_combo_bonus(multi, effects and effects.combo_bonus)
		end,
	}
end

function M.build_score_opts(j, word, used_cards, opts)
	return score_opts_for_word(j, word, used_cards, opts)
end

function M.compute_word_score(j, word, used_cards, opts)
	return core.compute_word_score(j, word, used_cards, score_opts_for_word(j, word, used_cards, opts))
end

function M.preview_puzzle_total_after_word(j, word, used_cards, opts)
	return core.preview_puzzle_total_after_word(j, word, used_cards, score_opts_for_word(j, word, used_cards, opts))
end

local function placement_preview_word(j)
	local jumble = WORD_GAME and WORD_GAME.Jumble
	return placement_preview.preview_word(j and j.slots, {
		placed_count = j and M.placed_count(j.slots) or 0,
		build_word = jumble and jumble.build_placement_preview_word,
		collect_used_cards = M.collect_used_cards,
		puzzle_words = j and j.puzzle_words,
	})
end

function M.projected_stage_score(j)
	if not j then return 0 end
	return M.committed_earned(j) + M.placement_preview_got(j)
end

function M.remaining_to_target(j, target)
	target = target or M.round_target()
	return core.remaining_to_target(j, target, M.placement_preview_got(j))
end

function M.post_target_active(j, committed)
	return core.post_target_active(run_mode_id(), j, committed, M.round_target())
end

function M.post_target_multiplier(j, committed)
	return core.post_target_multiplier(run_mode_id(), j, committed, M.round_target())
end

function M.scale_post_target_points(j, points, committed)
	return core.scale_post_target_points(run_mode_id(), j, points, committed, M.round_target())
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
	return core.score_breakdown(j, target, M.placement_preview_got(j))
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
	local wr = game_access.word_round()
	local j = jumble.state()
	if not wr or not j or not j.solved then return false end
	if InputLock.is_table_busy() then return false end
	return true
end

function M.evaluate_play(jumble, j)
	invariant.check(jumble ~= nil, "evaluate_play requires jumble module")
	invariant.check(j ~= nil, "evaluate_play requires jumble state")
	local wr = game_access.word_round()
	local result = core_play.evaluate(j, wr, {
		play_blocked = M.play_blocked,
		placed_count = M.placed_count,
		round_target = M.round_target,
		run_mode = run_mode_id(),
		perk_flags = perk_flags(),
		on_puzzle_bank = function(puzzle_j)
			perk_effects.on_puzzle_bank(puzzle_j)
		end,
		validate_current = function()
			return jumble.validate_current()
		end,
		collect_used_cards = M.collect_used_cards,
		record_puzzle_word = function(word, opts)
			return jumble.record_puzzle_word(word, opts)
		end,
		on_word_recorded = function(puzzle_j, word)
			round.record_word_play(word)
			puzzle_j.bonus_available = false
			puzzle_j.bonus_card_id = nil
			state.record_word_played()
			state.record_puzzle_score(puzzle_label(puzzle_j), M.puzzle_total(puzzle_j))
		end,
	})
	if not result then return nil end
	if result.kind == "bank_puzzle" then
		state.record_puzzle_score(result.puzzle_label, result.puzzle_total)
	end
	return result
end

return M
