--[[
	devtools/debug_button.lua - Temporary on-screen toggle for the debug panel.
]]

local Layout = require("word_game.ui.layout")

local M = {
	state = {
		len3 = "",
		len4 = "",
		len5 = "",
		len6 = "",
		len7 = "",
	},
	_last_counts_key = nil,
}

local HINT_SCALE = 0.26
local HINT_LABEL_SCALE = 0.24
local HINT_ROW_WIDTH = 8.4

local function hint_offset_y()
	return Layout.hud_bottom_y()
end

local function held_cards()
	local out = {}
	if G.hand and G.hand.cards then
		for _, card in ipairs(G.hand.cards) do
			out[#out + 1] = card
		end
	end
	local area = G.placement_table and G.placement_table.area
	if area and area.cards then
		for _, card in ipairs(area.cards) do
			out[#out + 1] = card
		end
	end
	return out
end

local function active_jumble_puzzle()
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not jumble or not jumble.is_active() then return nil end
	local j = jumble.state()
	return j and j.puzzle or nil
end

local function counts_key(counts, puzzle)
	local parts = {}
	for letter, n in pairs(counts or {}) do
		parts[#parts + 1] = letter .. tostring(n)
	end
	table.sort(parts)
	local key = table.concat(parts, ",")
	if puzzle then
		local jumble = WORD_GAME and WORD_GAME.Jumble
		key = key .. "|" .. (jumble and jumble.display_pattern(puzzle) or "")
	end
	return key
end

local function min_hand_letters(puzzle)
	if not puzzle then return 3 end
	if puzzle.kind == "span" then
		local pre = puzzle.prefix or ""
		local suf = puzzle.suffix or ""
		local center = puzzle.center or ""
		return math.max(1, puzzle.min - #pre - #suf - #center)
	end
	local blanks = 0
	for i = 1, #puzzle.pattern do
		if puzzle.pattern:sub(i, i) == "_" then
			blanks = blanks + 1
		end
	end
	return blanks
end

local function find_playable_words(counts, puzzle)
	if puzzle and WORD_GAME and WORD_GAME.Jumble then
		return WORD_GAME.Jumble.find_playable_words(counts, puzzle)
	end
	return Dictionary.find_playable(counts)
end

local function format_hint(counts, puzzle)
	for len = 3, 7 do
		M.state["len" .. len] = ""
	end

	if not Dictionary then return end
	Dictionary.load()

	local total = 0
	for _, n in pairs(counts or {}) do
		total = total + n
	end
	if total < min_hand_letters(puzzle) then return end

	local words = find_playable_words(counts, puzzle)
	if #words == 0 then
		M.state.len3 = "(none)"
		return
	end

	local by_len = {}
	for len = 3, 7 do
		by_len[len] = {}
	end
	for _, word in ipairs(words) do
		local len = #word
		if len >= 3 and len <= 7 then
			local bucket = by_len[len]
			bucket[#bucket + 1] = word
		end
	end

	for len = 3, 7 do
		local bucket = by_len[len]
		if #bucket > 0 then
			M.state["len" .. len] = table.concat(bucket, ", ")
		end
	end
end

local function hint_row(len)
	local key = "len" .. len
	return { n = G.UI.ROW, config = { align = "cl", padding = 0.015, minw = HINT_ROW_WIDTH, maxw = HINT_ROW_WIDTH }, nodes = {
		{ n = G.UI.TEXT, config = {
			text = len .. ": ",
			scale = HINT_LABEL_SCALE,
			colour = G.C.GOLD,
			shadow = true,
		}},
		{ n = G.UI.TEXT, config = {
			ref_table = M.state,
			ref_value = key,
			scale = HINT_SCALE,
			colour = G.C.WHITE,
			shadow = true,
		}},
	}}
end

function M.refresh_hint()
	if not G.debug_toggle_button or G.debug_toggle_button.REMOVED then return end

	if G.debug_toggle_button.config and G.debug_toggle_button.config.offset then
		G.debug_toggle_button.config.offset.y = hint_offset_y()
	end

	local puzzle = active_jumble_puzzle()
	local counts = Dictionary and Dictionary.counts_from_cards(held_cards()) or {}
	local key = counts_key(counts, puzzle)
	if key == M._last_counts_key then return end
	M._last_counts_key = key
	format_hint(counts, puzzle)
	G.debug_toggle_button:recalculate()
end

function M.visible()
	return false
end

function M.ensure()
	M.destroy()
end

function M.destroy()
	if G.debug_toggle_button then
		G.debug_toggle_button:remove()
		G.debug_toggle_button = nil
	end
	M._last_counts_key = nil
	for len = 3, 7 do
		M.state["len" .. len] = ""
	end
end

function M.sync()
	if M.visible() then
		M.ensure()
		M.refresh_hint()
	else
		M.destroy()
	end
end

return M
