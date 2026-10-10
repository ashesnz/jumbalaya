--[[ word_game/ui/trade/definition.lua - Marketplace modal: art + 4×3 grid overlay ]]

local game = require("word_game.ui.util.game_runtime").game
local trade_layout = require("word_game.ui.trade.layout")
local grid_mod = require("word_game.ui.trade.columns")

local M = {}

local CLOSE_LAYER = 2

local Panel = require("jumbalaya-engine.panels.api")
local Press = require("word_game.ui.widgets.press")

local function marketplace_sprite(w, h)
	if not Sprite then
		return nil
	end
	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.marketplace_bg
	if not atlas or not atlas.image then
		return nil
	end
	local sprite = Sprite(0, 0, w, h, atlas, { x = 0, y = 0 })
	sprite.states.draggable = false
	sprite.states.hoverable = false
	sprite.states.collideable = false
	sprite.states.clickable = false
	return sprite
end

local function close_button_node()
	return Panel.column({
		id = "trade_marketplace_close",
		align = "cm",
		minw = 0.42,
		minh = 0.42,
		r = 0.12,
		padding = 0.04,
		hover = true,
		colour = game().C.RED,
		hover_colour = game().C.UI.BUTTON_HOVER,
		on_press = Press.named("trade_close"),
		shadow = false,
		emboss = false,
		no_jiggle = true,
	}, {
		Panel.label({
			text = "X",
			scale = 0.32,
			font = alpha_button_font(),
			colour = game().C.WHITE,
			shadow = false,
		}),
	})
end

function M.build_overlay_definition()
	local g = game()
	local frame = trade_layout.modal_frame()
	local sprite = marketplace_sprite(frame.w, frame.h)
	local room = g.ROOM and g.ROOM.T
	local dim_w = (room and room.w or 4) * 5
	local dim_h = (room and room.h or 2) * 5

	local stage_nodes = {}
	if sprite then
		stage_nodes[#stage_nodes + 1] = Panel.object({
			id = "trade_marketplace_art",
			object = sprite,
			w = frame.w,
			h = frame.h,
			colour = g.C.WHITE,
			outline_colour = g.C.CLEAR,
			shadow = false,
		})
	end
	stage_nodes[#stage_nodes + 1] = grid_mod.build_grid(frame)
	stage_nodes[#stage_nodes + 1] = Panel.row({
		id = "trade_marketplace_close_row",
		draw_layer = CLOSE_LAYER,
		align = "tr",
		minw = frame.w,
		minh = frame.h,
		padding = 0.08,
		colour = g.C.CLEAR,
		shadow = false,
	}, { close_button_node() })

	local marketplace_stage = Panel.column({
		id = "trade_marketplace_stage",
		align = "cm",
		minw = frame.w,
		minh = frame.h,
		padding = 0,
		colour = g.C.CLEAR,
		shadow = false,
	}, stage_nodes)

	return Panel.root({
			id = "trade_marketplace_frame",
			align = "cm",
			minw = dim_w,
			minh = dim_h,
			padding = 0.1,
			r = 0.1,
			colour = { 0, 0, 0, 0.55 },
			shadow = false,
		}, {
			Panel.column({
				align = "cm",
				padding = 0,
				colour = g.C.CLEAR,
				shadow = false,
			}, { marketplace_stage }),
		})
end

M.CLOSE_DRAW_LAYER = CLOSE_LAYER

return M
