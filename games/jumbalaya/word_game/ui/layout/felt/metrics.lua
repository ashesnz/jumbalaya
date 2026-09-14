--[[ word_game/ui/layout/felt/metrics.lua - Derived HUD and panel metrics ]]

local sidebar = require("word_game.ui.layout.felt.sidebar")
local hud = require("word_game.ui.layout.felt.hud")
local rects = require("word_game.ui.layout.felt.rects")

local M = {}

function M.metrics()
	local felt = rects.felt_rect()
	local panel = rects.panel_rect()
	local col = rects.play_column()
	local sw = panel.w
	local inner_w = sw * 0.86
	local panel_pad = sw * 0.07
	local base = math.min(sw, felt.h) * 0.11
	local hud_w = col.w
	local hud_scale = math.max(0.26, math.min(0.42, hud_w * 0.024))
	local togo_h = hud.togo_h()
	local portrait_h = hud.portrait_h()

	return {
		felt = felt,
		panel = panel,
		sidebar_w = sw,
		inner_w = inner_w,
		panel_pad = panel_pad,
		panel_h = panel.h,
		header_scale = math.max(0.32, math.min(0.48, base)),
		word_scale = math.max(0.28, math.min(0.42, base * 0.9)),
		score_scale = math.max(0.26, math.min(0.36, base * 0.85)),
		hint_scale = math.max(0.24, math.min(0.32, base * 0.75)),
		row_pad = math.max(0.04, panel_pad * 0.55),
		entry_pad = math.max(0.05, panel_pad * 0.65),
		list_h = math.max(2, panel.h - sw * 0.52),
		hud_w = hud_w,
		hud_scale = hud_scale,
		hud_col_w = hud_w / 3,
		portrait_h = portrait_h,
		togo_h = togo_h,
		togo_scale = math.max(0.4, math.min(0.7, hud_w * 0.038)),
	}
end

function M.inner_width()
	return M.metrics().inner_w
end

return M
