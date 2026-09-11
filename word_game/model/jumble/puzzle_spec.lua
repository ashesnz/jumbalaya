--[[ word_game/model/jumble/puzzle_spec.lua - Puzzle definitions (G glue over jumbalaya_core) ]]

return function(M)
local puzzles_cfg = require("word_game.config.jumble")
local round_config = require("word_game.config.gameplay.round")
local core = require("jumbalaya_core.jumble.puzzle_spec")

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
	if not words or #words == 0 then return nil end
	local word = words[math.random(#words)]
	local revealed = {}
	local revealed_count = 0
	while revealed_count < 2 do
		local index = math.random(#word)
		if not revealed[index] then
			revealed[index] = true
			revealed_count = revealed_count + 1
		end
	end
	local pattern = {}
	for index = 1, #word do
		pattern[index] = revealed[index] and word:sub(index, index) or "_"
	end
	return { kind = "rigid", pattern = table.concat(pattern), boss_word = word, display = table.concat(pattern) }
end

local function build_validated_puzzles(set, hand_index)
	set = set or (G.GAME and G.GAME.word_round and G.GAME.word_round.set) or 1
	hand_index = hand_index or (G.GAME and G.GAME.word_round and G.GAME.word_round.hand_index) or 1
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
	set = set or (G.GAME and G.GAME.word_round and G.GAME.word_round.set) or 1
	hand_index = hand_index or (G.GAME and G.GAME.word_round and G.GAME.word_round.hand_index) or 1
	if not round_config.is_boss_word_hand(set, hand_index) then return nil end
	local stage_cfg = puzzles_cfg.get_stage(set, hand_index)
	return random_boss_puzzle(stage_cfg and stage_cfg.BOSS_WORDS)
end

end
