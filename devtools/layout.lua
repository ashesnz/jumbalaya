--[[
	devtools/layout.lua - LayoutView layout helpers for the debug panel.

	Used by devtools/sections/*.lua when building button grids and headings.
]]

local game_runtime = require "devtools.runtime"

local M = {}

local Components = require "word_game.ui.widgets.components"

local function shell()
	return game_runtime.game()
end

M.COLS = 2
M.BUTTON = { minw = 1.85, minh = 0.5, scale = 0.38, padding = 0.05 }

function M.text_row(text, scale)
	local game = shell()
	return {n = game.UI.ROW, config = {align = "cm", padding = 0.03}, nodes = {
		{n = game.UI.TEXT, config = {text = text, scale = scale or 0.24, colour = game.C.WHITE, shadow = true}},
	}}
end

function M.labeled_row(key, ref_table, scale)
	local game = shell()
	return {n = game.UI.ROW, config = {align = "cm", padding = 0.04}, nodes = {
		{n = game.UI.TEXT, config = {
			id = key,
			ref_table = ref_table,
			ref_value = key,
			scale = scale or 0.3,
			colour = game.C.WHITE,
			shadow = true,
		}},
	}}
end

function M.button(label, action)
	-- Default row button stacks vertically inside a UI.COLUMN column.
	return Components.button{
		label = {label},
		onClick = "DT_" .. action,
		width = M.BUTTON.minw,
		height = M.BUTTON.minh,
		textSize = M.BUTTON.scale,
		padding = M.BUTTON.padding,
	}
end

--- Two vertical columns of buttons (matches original debug panel layout).
function M.button_columns(defs, cols)
	cols = cols or M.COLS
	local columns = {}
	for c = 1, cols do columns[c] = {} end

	local col_idx = 1
	for _, def in ipairs(defs) do
		if def.type ~= "label" then
			columns[col_idx][#columns[col_idx] + 1] = M.button(def.label, def.action)
			col_idx = col_idx % cols + 1
		end
	end

	local row_nodes = {}
	for c = 1, cols do
		if #columns[c] > 0 then
			local game = shell()
			row_nodes[#row_nodes + 1] = {n = game.UI.COLUMN, config = {align = "cm", padding = 0.04}, nodes = columns[c]}
		end
	end

	local game = shell()
	return {{n = game.UI.ROW, config = {align = "cm", padding = 0.04}, nodes = row_nodes}}
end

--- Section block: title + child rows.
function M.section(title, child_rows)
	local game = shell()
	local nodes = {
		{n = game.UI.ROW, config = {align = "cm", padding = 0.06}, nodes = {
			{n = game.UI.TEXT, config = {text = title, scale = 0.32, colour = game.C.GOLD, shadow = true}},
		}},
	}
	for _, row in ipairs(child_rows) do
		nodes[#nodes + 1] = row
	end
	return {n = game.UI.ROW, config = {align = "cm", padding = 0.07}, nodes = nodes}
end

--- Panel chrome without UIBox_dyn_container's minh=30 (taller than the screen).
function M.panel_container(content)
	local game = shell()
	return {n = game.UI.ROW, config = {align = "cm", padding = 0.04, colour = game.C.UI.TRANSPARENT_DARK, r = 0.1}, nodes = {
		{n = game.UI.ROW, config = {align = "cm", padding = 0.06, colour = game.C.DYN_UI.MAIN, r = 0.1}, nodes = {
			{n = game.UI.ROW, config = {align = "tm", colour = game.C.DYN_UI.BOSS_DARK, r = 0.1, padding = 0.1}, nodes = content},
		}},
	}}
end

return M
