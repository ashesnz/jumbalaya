--[[ word_game/model/jumble/puzzle_spec.lua - Puzzle definitions (G glue over jumbalaya_core) ]]

return function(M)
local puzzles_cfg = require("word_game.config.jumble")
local round_config = require("word_game.config.gameplay.round")
local core = require("jumbalaya_core.jumble.puzzle_spec")
local game_access = require("word_game.model.game_access")

local stage_validated_puzzles = {}

local function dictionary_opts()
	return {
		is_valid_word = function(word)
			if not Dictionary then return false end
			Dictionary.load()
			return Dictionary.is_valid(word)
		end,
	}
end

for key, value in pairs(core) do
	if key ~= "word_fits_pattern" and key ~= "normalize_puzzle" then
		M[key] = value
	end
end

M.normalize_puzzle = core.normalize_puzzle
M.validate_puzzle = core.validate_puzzle

function M.word_fits_pattern(word, puzzle)
	return core.word_fits_pattern(word, puzzle, dictionary_opts())
end

local function random_boss_puzzle(words)
	return core.random_boss_puzzle(words, {
		pick_word = function(ws) return ws[math.random(#ws)] end,
		pick_index = function(max) return math.random(max) end,
	})
end

local function current_round_coords()
	local wr = game_access.word_round()
	return wr and wr.set or 1, wr and wr.hand_index or 1
end

local function build_validated_puzzles(set, hand_index)
	if not set or not hand_index then
		local default_set, default_hand = current_round_coords()
		set = set or default_set
		hand_index = hand_index or default_hand
	end
	local key = string.format("%d_%d", set, hand_index)
	if stage_validated_puzzles[key] then return stage_validated_puzzles[key] end

	local list
	local stage_cfg = puzzles_cfg.get_stage and puzzles_cfg.get_stage(set, hand_index)
	if stage_cfg and (stage_cfg.PATTERNS or stage_cfg.PUZZLES) then
		list = stage_cfg.PATTERNS or stage_cfg.PUZZLES
	else
		list = puzzles_cfg.PATTERNS or puzzles_cfg.PUZZLES or {}
	end

	local validated = {}
	for _, row in ipairs(list) do
		local puzzle = core.normalize_puzzle(row)
		if core.validate_puzzle(puzzle) then
			validated[#validated + 1] = puzzle
		end
	end
	stage_validated_puzzles[key] = validated
	return validated
end

function M.puzzles(set, hand_index)
	return build_validated_puzzles(set, hand_index)
end

function M.boss_puzzle(set, hand_index)
	if not set or not hand_index then
		local default_set, default_hand = current_round_coords()
		set = set or default_set
		hand_index = hand_index or default_hand
	end
	if not round_config.is_boss_word_hand(set, hand_index) then return nil end
	local stage_cfg = puzzles_cfg.get_stage(set, hand_index)
	return random_boss_puzzle(stage_cfg and stage_cfg.BOSS_WORDS)
end

end
