--[[ packages/jumbalaya_core/jumble/hand.lua - Jumble hand lifecycle (no G, no Love2D) ]]

local round_config = require("jumbalaya_core.config.gameplay.round")
local default_state = require("jumbalaya_core.store.default_state")
local puzzle_spec = require("jumbalaya_core.jumble.puzzle_spec")
local slots = require("jumbalaya_core.jumble.slots")
local rules = require("jumbalaya_core.rules.jumble")

local M = {}

function M.is_active_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	return set >= 1 and set <= round_config.SETS_TO_WIN and hand_index >= 1
		and hand_index <= round_config.hands_in_set(set)
end

--- Drop jumble mode when the hand coordinate is outside the active jumble range.
--- Returns false when the hand is jumble-active (caller should start jumble).
function M.clear_if_inactive_hand(wr, set, hand_index)
	if M.is_active_hand(set, hand_index) then
		return false
	end
	if wr and wr.mode == "jumble" then
		wr.mode = nil
		wr.jumble = nil
	end
	return true
end

function M.is_active(wr)
	return wr and wr.mode == "jumble" and wr.jumble ~= nil
end

function M.state(wr)
	return wr and wr.jumble
end

--- Apply a resolved puzzle to jumble state (no CardArea / presentation side effects).
---@param hooks table|nil { on_puzzle_start: fun(j, wr), on_puzzle_applied: fun(j, wr) }
function M.apply_puzzle(wr, puzzle, hooks)
	local j = wr and wr.jumble
	if not j or not puzzle then return end
	puzzle = puzzle_spec.resolve_puzzle(puzzle)
	j.puzzle = puzzle
	j.pattern = puzzle_spec.display_pattern(puzzle)
	j.solved = false
	j.bonus_available = false
	j.bonus_card_id = nil
	j.puzzle_points = 0
	j.puzzle_words = {}
	j.slots = slots.parse_slots(puzzle)
	if hooks and hooks.on_puzzle_start then
		hooks.on_puzzle_start(j, wr)
	end
	if hooks and hooks.on_puzzle_applied then
		hooks.on_puzzle_applied(j, wr)
	end
end

function M.load_puzzle(wr, index, puzzle_list)
	puzzle_list = puzzle_list or {}
	if #puzzle_list == 0 then return end
	local j = wr.jumble
	j.puzzle_index = ((index - 1) % #puzzle_list) + 1
	M.apply_puzzle(wr, puzzle_list[j.puzzle_index], nil)
end

---@param hooks table|nil { on_stage_start: fun(wr), on_hand_start: fun(wr), puzzle_list: table[] }
function M.start_hand(wr, hooks)
	hooks = hooks or {}
	wr.mode = "jumble"
	wr.target = wr.target or 20
	wr.jumble = default_state.new_jumble_state({
		puzzle_multi = 1.0,
		boss_word_active = false,
	})
	if hooks.on_stage_start then
		hooks.on_stage_start(wr)
	end
	if hooks.on_hand_start then
		hooks.on_hand_start(wr)
	end
	M.load_puzzle(wr, 1, hooks.puzzle_list)
end

function M.prepare_boss_word(wr, boss)
	if not wr or not round_config.is_boss_word_hand(wr.set, wr.hand_index) or not wr.jumble then
		return false
	end
	if not boss then return false end
	wr.jumble.pending_boss = boss
	wr.jumble.boss_puzzle_hidden = true
	wr.jumble.boss_word_active = false
	if wr.jumble.slots then
		slots.clear_blank_cards(wr.jumble.slots)
	end
	wr.jumble.slots = nil
	wr.jumble.pattern = nil
	return true
end

function M.reveal_boss_puzzle(wr, hooks)
	if not wr or not round_config.is_boss_word_hand(wr.set, wr.hand_index) or not wr.jumble then
		return false
	end
	local boss = wr.jumble.pending_boss
	if not boss then return false end
	wr.jumble.pending_boss = nil
	wr.jumble.boss_puzzle_hidden = false
	wr.jumble.boss_word_active = true
	wr.jumble.puzzle_phase_complete = true
	wr.jumble.solved = false
	wr.jumble.puzzle_points = 0
	wr.jumble.puzzle_multi = 1.0
	wr.jumble.puzzle_words = {}
	M.apply_puzzle(wr, boss, hooks)
	return true
end

function M.record_puzzle_word(j, word, score_opts)
	return rules.apply_puzzle_word(j, word, score_opts)
end

function M.advance_puzzle(wr, puzzle_list)
	if not wr or not wr.jumble then return end
	M.load_puzzle(wr, wr.jumble.puzzle_index + 1, puzzle_list)
end

return M
