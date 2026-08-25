--[[
	word_game/ui/character_speech.lua - Typewriter speech bubbles for characters.

	Letters start hidden and appear at full size one-by-one, left to right,
	with a paper tick — like a typewriter on the white bubble.
]]
local Scheduler = require "app.effects.scheduler"


local M = {}

M.CHARS_PER_SEC = 18
M.LINE_GAP = 0.28

local function assemble_part(part, vars)
	local out = ""
	for _, subpart in ipairs(part.strings) do
		if type(subpart) == "string" then
			out = out .. subpart
		elseif vars then
			out = out .. (vars[tonumber(subpart[1])] or "")
		end
	end
	return out
end

local function part_colour(part, vars, default_col)
	if part.control.V and vars and vars.colours then
		return vars.colours[tonumber(part.control.V)]
	end
	return loc_colour(part.control.C, default_col or G.C.UI.TEXT_DARK)
end

local function hide_letters(dyna)
	local bundle = dyna.strings and dyna.strings[dyna.focused_string or 1]
	if not bundle then return end
	for _, letter in ipairs(bundle.letters) do
		letter.pop_in = 0
	end
end

local function type_letters(dyna, delay, cps)
	local bundle = dyna.strings and dyna.strings[dyna.focused_string or 1]
	if not bundle then return delay end

	local letters = bundle.letters
	local n = #letters
	if n == 0 then return delay end

	for i, letter in ipairs(letters) do
		local when = delay + (i - 1) / cps
		Scheduler.add{
			mode = "delayed",
			delay = when,
			blockable = false,
			blocking = false,
			func = function()
				if dyna.REMOVED then return true end
				letter.pop_in = 1
				if letter.char and letter.char ~= " " then
					play_sfx("hover_card", 0.45 + 0.05 * math.random() + (0.3 / math.max(n, 1)) * i)
				end
				return true
			end,
		}
	end

	return delay + n / cps
end

function M.duration(text_key, loc_vars)
	loc_vars = loc_vars or {}
	local loc_target = G.localization and G.localization.tutorial_parsed and G.localization.tutorial_parsed[text_key]
	if not loc_target then return 1.4 end
	local cps = loc_vars.chars_per_sec or M.CHARS_PER_SEC
	local delay = loc_vars.pop_in_start or 0.02
	for _, lines in ipairs(loc_target) do
		local n = 0
		for _, part in ipairs(lines) do
			local text = assemble_part(part, loc_vars.vars)
			n = n + #text
		end
		if n > 0 then
			delay = delay + n / cps + M.LINE_GAP
		end
	end
	return delay
end

function M.bubble_definition(text_key, loc_vars)
	loc_vars = loc_vars or {}
	local loc_target = G.localization.tutorial_parsed[text_key]
	if not loc_target then
		return G.DEFINITIONS.speech_bubble(text_key, loc_vars)
	end

	local desc_scale = G.LANG.font.DESCSCALE
	local scale = 0.32 * desc_scale
	local cps = loc_vars.chars_per_sec or M.CHARS_PER_SEC
	local row = {}
	local delay = loc_vars.pop_in_start or 0.02

	for _, lines in ipairs(loc_target) do
		local line_nodes = {}
		for _, part in ipairs(lines) do
			local text = assemble_part(part, loc_vars.vars)
			if text ~= "" then
				local dyna = FlowText({
					string = { text },
					colours = { part_colour(part, loc_vars.vars, loc_vars.default_col) },
					shadow = true,
					silent = true,
					scale = scale * (part.control.s and tonumber(part.control.s) or 1),
					maxw = loc_vars.maxw or 4.9,
				})
				hide_letters(dyna)
				delay = type_letters(dyna, delay, cps)
				line_nodes[#line_nodes + 1] = {
					n = G.UI.OBJECT,
					config = { object = dyna },
				}
			end
		end
		if #line_nodes > 0 then
			row[#row + 1] = { n = G.UI.ROW, config = { align = "cl" }, nodes = line_nodes }
			delay = delay + M.LINE_GAP
		end
	end

	return {
		n = G.UI.ROOT,
		config = {
			align = "cm",
			minw = 1.8,
			minh = 0.5,
			padding = 0.16,
			r = 0.22,
			colour = G.C.WHITE,
			shadow = true,
			outline = 1,
			outline_colour = G.C.BLACK,
			speech_tail = "mouth",
		},
		nodes = {
			{ n = G.UI.COLUMN, config = { align = "cl", colour = G.C.CLEAR }, nodes = row },
			{ n = G.UI.BOX, config = { h = 0.1, w = 0.01 } },
		},
	}
end

function M.pop_bubble(uibox)
	local target = uibox and (uibox.root_node or uibox)
	if target and target.speech_pop then
		target:speech_pop()
	end
end

return M
