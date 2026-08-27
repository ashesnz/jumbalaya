--[[ word_game/model/jumble/puzzle_spec.lua - Pattern parsing and puzzle definitions ]]

return function(M)
local puzzles_cfg = require("word_game.config.jumble_puzzles")

local stage_validated_puzzles = {}

local function pattern_matches(pattern, word)
	if not pattern or not word or #pattern ~= #word then return false end
	for i = 1, #pattern do
		local p = pattern:sub(i, i)
		if p ~= "_" and p ~= word:sub(i, i) then
			return false
		end
	end
	return true
end

local function count_revealed(pattern)
	local n = 0
	for i = 1, #pattern do
		if pattern:sub(i, i) ~= "_" then
			n = n + 1
		end
	end
	return n
end

local function finalize_span(prefix, suffix, min_len, max_len, display, opts)
	opts = opts or {}
	prefix = prefix ~= "" and prefix or nil
	suffix = suffix ~= "" and suffix or nil
	local center = opts.center
	local pin_index = opts.pin_index
	if not prefix and not suffix and not center then return nil end
	min_len = min_len or 3
	max_len = max_len or 7
	if not display then
		if center and prefix and suffix then
			display = prefix .. "…" .. center .. "…" .. suffix
		elseif center and suffix then
			display = "…" .. center .. "…" .. suffix
		elseif center and prefix then
			display = prefix .. "…" .. center .. "…"
		elseif center then
			display = "…" .. center .. "…"
		elseif prefix and suffix then
			display = prefix .. "…" .. suffix
		elseif prefix then
			display = prefix .. "…"
		else
			display = "…" .. suffix
		end
	end
	return {
		kind = "span",
		prefix = prefix,
		suffix = suffix,
		center = center,
		pin_index = pin_index,
		min = min_len,
		max = max_len,
		display = display,
	}
end

local function center_block_range(word, puzzle)
	local center = puzzle.center
	if not center or center == "" then return nil, nil end
	if puzzle.pin_index then
		return puzzle.pin_index, puzzle.pin_index + #center - 1
	end
	local start = math.floor((#word - #center) / 2) + 1
	return start, start + #center - 1
end

--- Convert simple rigid strings to span puzzles when possible.
local function convert_rigid_to_span(pattern)
	if not pattern or #pattern < 3 or #pattern > 8 then return nil end

	local single = pattern:match("^_(.)_$")
	if single then
		return finalize_span(nil, nil, 3, 7, nil, { center = single })
	end

	local pin, suf = pattern:match("^_(%a)_(%a)$")
	if pin and #pattern == 4 then
		return finalize_span(nil, suf, 4, 7, nil, { center = pin, pin_index = 2 })
	end

	local pinned, tail = pattern:match("^_(%a)(_+)$")
	if pinned and tail and #pattern >= 4 then
		return finalize_span(nil, nil, #pattern, 7, nil, { center = pinned, pin_index = 2 })
	end

	local block = pattern:match("^_+(%a+)_+$")
	if block then
		return finalize_span(nil, nil, #pattern, 7, nil, { center = block })
	end

	local pre, end_letter = pattern:match("^(%a)_+(%a)$")
	if pre and end_letter and pattern:sub(2, -2):find("[^_]") == nil then
		return finalize_span(pre, end_letter, 3, 7)
	end

	local prefix = pattern:match("^(%a+)_+$")
	if prefix then
		return finalize_span(prefix, nil, 3, 7)
	end

	local suffix = pattern:match("^_+(%a+)$")
	if suffix then
		return finalize_span(nil, suffix, 3, 7)
	end

	return nil
end

local function normalize_puzzle(row)
	if type(row) == "string" then
		if row:find("%*") or row:find("%.%.%.") then
			local pre = row:sub(1, 1)
			local suf = row:sub(-1, -1)
			return finalize_span(pre, suf, 3, 8)
		end
		return convert_rigid_to_span(row) or { kind = "rigid", pattern = row }
	end
	if type(row) == "table" and row.span and #row.span >= 2 then
		return finalize_span(row.span[1], row.span[2], row.min, row.max, row.display)
	end
	if type(row) == "table" and row.span and #row.span == 1 then
		return finalize_span(row.span[1], nil, row.min, row.max, row.display)
	end
	if type(row) == "table" and (row.prefix or row.suffix or row.center) then
		return finalize_span(row.prefix, row.suffix, row.min, row.max, row.display, {
			center = row.center,
			pin_index = row.pin_index,
		})
	end
	if type(row) == "table" and (row.dynamic or row.kind == "span") then
		local pre, suf
		if row.span and #row.span >= 2 then
			pre, suf = row.span[1], row.span[#row.span]
		elseif row.pattern then
			pre = row.pattern:sub(1, 1)
			suf = row.pattern:sub(-1, -1)
		elseif row[1] and row[2] then
			pre = row[1]
			suf = row[2]
		end
		return finalize_span(pre, suf, row.min, row.max, row.display)
	end
	if type(row) == "table" and row.pattern then
		return convert_rigid_to_span(row.pattern) or { kind = "rigid", pattern = row.pattern }
	end
	return nil
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

function M.boss_hand_letters(word, pattern)
	if not word or not pattern or #word ~= #pattern then return {} end
	local letters = {}
	for index = 1, #word do
		if pattern:sub(index, index) == "_" then
			letters[#letters + 1] = word:sub(index, index)
		end
	end
	for i = #letters, 2, -1 do
		local j = math.random(i)
		letters[i], letters[j] = letters[j], letters[i]
	end
	return letters
end

local function validate_puzzle(puzzle)
	if not puzzle then return false end
	if puzzle.kind == "rigid" then
		local pattern = puzzle.pattern
		return pattern
			and #pattern >= 3 and #pattern <= 9
			and count_revealed(pattern) >= 1
			and count_revealed(pattern) <= 3
			and count_revealed(pattern) < #pattern
	end
	if puzzle.kind == "span" then
		return puzzle.min >= 3
			and puzzle.max <= 8
			and puzzle.min <= puzzle.max
			and (puzzle.prefix or puzzle.suffix or puzzle.center)
	end
	return false
end

local stage_validated_puzzles = {}

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
		local puzzle = normalize_puzzle(row)
		if validate_puzzle(puzzle) then
			validated[#validated + 1] = puzzle
		end
	end
	stage_validated_puzzles[key] = validated
	return validated
end

function M.puzzle_kind(puzzle)
	return puzzle and puzzle.kind
end

function M.display_pattern(puzzle)
	if not puzzle then return "" end
	if puzzle.kind == "span" then
		if puzzle.display then return puzzle.display end
		if puzzle.center and puzzle.prefix and puzzle.suffix then
			return puzzle.prefix .. "…" .. puzzle.center .. "…" .. puzzle.suffix
		elseif puzzle.center and puzzle.suffix then
			return "…" .. puzzle.center .. "…" .. puzzle.suffix
		elseif puzzle.center and puzzle.prefix then
			return puzzle.prefix .. "…" .. puzzle.center .. "…"
		elseif puzzle.center then
			return "…" .. puzzle.center .. "…"
		elseif puzzle.prefix and puzzle.suffix then
			return puzzle.prefix .. "…" .. puzzle.suffix
		elseif puzzle.prefix then
			return puzzle.prefix .. "…"
		elseif puzzle.suffix then
			return "…" .. puzzle.suffix
		end
		return ""
	end
	return puzzle.pattern or ""
end

function M.layout_length(puzzle)
	if not puzzle then return 7 end
	if puzzle.kind == "span" then
		return puzzle.max
	end
	return #puzzle.pattern
end

function M.score_for_word(word)
	word = word or ""
	return #word
end

function M.word_fits_pattern(word, puzzle)
	if not word or not puzzle then return false end
	puzzle = M.resolve_puzzle(puzzle)
	if puzzle.kind == "span" then
		local pre = puzzle.prefix or ""
		local suf = puzzle.suffix or ""
		if #word < puzzle.min or #word > puzzle.max then return false end
		if pre ~= "" and word:sub(1, #pre) ~= pre then return false end
		if suf ~= "" and word:sub(-#suf) ~= suf then return false end
		if puzzle.center then
			local start, finish = center_block_range(word, puzzle)
			if not start or word:sub(start, finish) ~= puzzle.center then
				return false
			end
		end
		if Dictionary then Dictionary.load() end
		return Dictionary and Dictionary.is_valid(word)
	end
	if #word ~= #puzzle.pattern then return false end
	if not pattern_matches(puzzle.pattern, word) then return false end
	if puzzle.boss_word then
		return true
	end
	return Dictionary and Dictionary.is_valid(word)
end

function M.resolve_puzzle(puzzle)
	if not puzzle then return nil end
	if type(puzzle) == "string" then
		return { pattern = puzzle, min = #puzzle, max = #puzzle, kind = "rigid" }
	end
	if puzzle.kind == "span" then
		if puzzle.span and #puzzle.span >= 2 and not puzzle.prefix and not puzzle.suffix and not puzzle.center then
			return finalize_span(
				puzzle.span[1],
				puzzle.span[2],
				puzzle.min,
				puzzle.max,
				puzzle.display,
				{ center = puzzle.center, pin_index = puzzle.pin_index }
			)
		end
		return puzzle
	end
	if type(puzzle) == "table" and puzzle.span and #puzzle.span >= 2 then
		return finalize_span(
			puzzle.span[1],
			puzzle.span[2],
			puzzle.min,
			puzzle.max,
			puzzle.display,
			{ center = puzzle.center, pin_index = puzzle.pin_index }
		)
	end
	if type(puzzle) == "table" and (puzzle.prefix or puzzle.suffix or puzzle.center) then
		return finalize_span(puzzle.prefix, puzzle.suffix, puzzle.min, puzzle.max, puzzle.display, {
			center = puzzle.center,
			pin_index = puzzle.pin_index,
		})
	end
	return puzzle
end

function M.center_block_range(word, puzzle)
	return center_block_range(word, puzzle)
end

function M.puzzles(set, hand_index)
	return build_validated_puzzles(set, hand_index)
end

function M.boss_puzzle(set, hand_index)
	if set ~= 1 or hand_index ~= 3 then return nil end
	local stage_cfg = puzzles_cfg.get_stage(set, hand_index)
	return random_boss_puzzle(stage_cfg and stage_cfg.BOSS_WORDS)
end

end
