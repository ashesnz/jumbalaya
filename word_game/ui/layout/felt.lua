--[[
	word_game/ui/layout/felt.lua - Play column, felt, panel, and HUD metrics.
]]

local M = {}

M.HUD_TOP_FRAC = 0.015
M.PORTRAIT_H_FRAC = 0.18
M.TOGO_H_FRAC = 0.09
M.META_H_FRAC = 0
M.FELT_GAP_FRAC = 0.02
M.BOTTOM_PAD_FRAC = 0.10
M.PLAY_LEFT_FRAC = 0.02
M.VAULT_EDGE_FRAC = 0.025
M.VAULT_BOTTOM_FRAC = 0.055
M.SIDEBAR_WIDTH = 3.0

function M.sidebar_frac()
	return M.sidebar_width() / (G.TILE_W or 20)
end

function M.sidebar_width()
	return G.TABLE_BOARD_SIDEBAR_WIDTH or M.SIDEBAR_WIDTH
end

function M.sidebar_gap()
	return math.max(0.15, G.TILE_W * 0.01)
end

function M.right_margin()
	return 0
end

function M.window_width_tiles()
	local ts = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	if love and love.graphics and love.graphics.getWidth then
		return love.graphics.getWidth() / ts
	end
	return G.TILE_W or 20
end

function M.is_boss_sequence()
	local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
	if not j then return false end
	return j.boss_word_active or j.boss_word_staging or j.boss_puzzle_hidden
end

function M.hand_play_column()
	local pad_x = G.TILE_W * M.PLAY_LEFT_FRAC
	local gap = M.sidebar_gap()
	local vault_x = M.vault_right_x() - M.sidebar_width()
	return {
		x = pad_x,
		w = math.max(4, vault_x - pad_x - gap),
	}
end

function M.hand_felt_rect()
	if G.STAGE == G.STAGES.RUN or G.STATE == G.STATES.TABLE_BOARD then
		local col = M.hand_play_column()
		local y = M.hud_top() + M.hud_height() + G.TILE_H * M.FELT_GAP_FRAC
		local bottom = G.TILE_H * M.BOTTOM_PAD_FRAC
		return {
			x = col.x,
			y = y,
			w = col.w,
			h = math.max(3, G.TILE_H - y - bottom),
		}
	end
	return M.felt_rect()
end

function M.vault_right_x()
	local room_x = (G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0
	return M.window_width_tiles() - room_x
end

function M.hud_top()
	return G.TILE_H * M.HUD_TOP_FRAC
end

function M.portrait_h()
	return math.max(1.7, G.TILE_H * M.PORTRAIT_H_FRAC)
end

function M.togo_h()
	return math.max(0.8, G.TILE_H * M.TOGO_H_FRAC)
end

function M.meta_h()
	return 0
end

function M.hud_height()
	return M.portrait_h() + M.togo_h() + M.meta_h()
end

function M.play_column()
	local pad_x = G.TILE_W * M.PLAY_LEFT_FRAC
	if M.is_boss_sequence() then
		local room_x = (G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0
		local win_w = M.window_width_tiles() - room_x
		local margin = math.max(pad_x, G.TILE_W * 0.03)
		return {
			x = margin,
			w = math.max(4, win_w - 2 * margin),
		}
	end
	local gap = M.sidebar_gap()
	local vault_x = M.vault_right_x() - M.sidebar_width()
	return {
		x = pad_x,
		w = math.max(4, vault_x - pad_x - gap),
	}
end

function M.felt_rect()
	if (G.STAGE == G.STAGES.RUN or G.STATE == G.STATES.TABLE_BOARD) then
		local col = M.play_column()
		local y = M.hud_top() + M.hud_height() + G.TILE_H * M.FELT_GAP_FRAC
		local bottom = G.TILE_H * M.BOTTOM_PAD_FRAC
		return {
			x = col.x,
			y = y,
			w = col.w,
			h = math.max(3, G.TILE_H - y - bottom),
		}
	end
	return {
		x = 0.8,
		y = 2.0,
		w = G.TILE_W - 1.6,
		h = G.TILE_H - 3.5,
	}
end

function M.panel_rect()
	local felt = M.felt_rect()
	local sidebar_w = M.sidebar_width()
	return {
		x = M.vault_right_x() - sidebar_w,
		y = felt.y,
		w = sidebar_w,
		h = felt.h,
	}
end

function M.hud_offset()
	local col = M.play_column()
	return {
		x = col.x + col.w * 0.5 - G.TILE_W * 0.5,
		y = M.hud_top(),
	}
end

function M.portrait_name_h()
	return math.max(0.32, M.portrait_h() * 0.18)
end

function M.metrics()
	local felt = M.felt_rect()
	local panel = M.panel_rect()
	local col = M.play_column()
	local sw = panel.w
	local inner_w = sw * 0.86
	local panel_pad = sw * 0.07
	local base = math.min(sw, felt.h) * 0.11
	local hud_w = col.w
	local hud_scale = math.max(0.26, math.min(0.42, hud_w * 0.024))
	local togo_h = M.togo_h()
	local portrait_h = M.portrait_h()

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
