--[[
	word_game/ui/layout/placement.lua - Board placement, portraits, and screen positions.
]]

local felt = require("word_game.ui.layout.felt")
local sidebar_layout = require("word_game.ui.sidebar.layout")
local dealt_hand = require("word_game.ui.dealt_hand")
local hand_size_cfg = require("word_game.config.hand_size")

local M = {}

local function snap_moveable(moveable)
	if not moveable then return end
	if moveable.snap_VT then moveable:snap_VT() end
	if moveable.velocity then
		moveable.velocity.x = 0
		moveable.velocity.y = 0
		moveable.velocity.r = 0
		moveable.velocity.scale = 0
	end
end

function M.card_area_width()
	if G.placement_table and G.placement_table.area and G.placement_table.area.T and (G.placement_table.area.T.w or 0) > 0 then
		return G.placement_table.area.T.w
	end
	local placement_area = G.placement_table and G.placement_table.area
	if placement_area and placement_area.T and (placement_area.T.w or 0) > 0 then
		return placement_area.T.w
	end
	local ok, playout = pcall(require, "word_game.board.layout")
	if ok and playout and playout.area_width then
		local pctx = {
			card_w = function() return G.CARD_W or 1.0 end,
			card_h = function() return G.CARD_H or 1.4 end,
			card_limit = function() return hand_size_cfg.get() end,
		}
		local w = playout.area_width(pctx)
		if w and w > 0 then return w end
	end
	return 6.0
end

function M.timeline_rect()
	local col = felt.play_column()
	local slot_h = felt.portrait_h()
	local w = M.card_area_width()
	local h = math.max(0.70, math.min(0.92, slot_h * 0.52))
	return {
		x = col.x + (col.w - w) * 0.5,
		y = felt.hud_top() + (slot_h - h) * 0.45,
		w = w,
		h = h,
		slant = h * 0.88,
	}
end

function M.hud_portrait_rect()
	return M.timeline_rect()
end

function M.portrait_rect()
	return M.hud_portrait_rect()
end

function M.banner_rect()
	local col = felt.play_column()
	local slot_h = felt.togo_h()
	local w = col.w * 0.62
	local h = slot_h * 0.72
	return {
		x = col.x + (col.w - w) * 0.5,
		y = felt.hud_top() + felt.portrait_h() + (slot_h - h) * 0.5,
		w = w,
		h = h,
		slant = math.min(w * 0.12, h * 0.55),
	}
end

function M.hud_bottom_y()
	local banner = M.banner_rect()
	return banner.y + banner.h + G.TILE_H * 0.02
end

function M.update_play_attach()
	if not G.PLAY_ATTACH then return end
	local rect = felt.felt_rect()
	G.PLAY_ATTACH.T.x = rect.x
	G.PLAY_ATTACH.T.y = rect.y
	G.PLAY_ATTACH.T.w = rect.w
	G.PLAY_ATTACH.T.h = rect.h
	G.PLAY_ATTACH:hard_set_T(rect.x, rect.y, rect.w, rect.h)
end

function M.update_all()
	sidebar_layout.update_sidebar_attach()
	sidebar_layout.update_panel_attach()
	M.update_play_attach()
end

function M.set_screen_positions(opts)
	opts = opts or {}
	if G.STAGE == G.STAGES.RUN and G.hand then
		if WORD_GAME and WORD_GAME.Layout then
			WORD_GAME.Layout.update_all()
		end
		local rect = get_table_felt_rect()
		local pad_x = rect.w * 0.04
		local pad_y = rect.h * 0.06
		if G.STATE == G.STATES.TABLE_BOARD
			and WORD_GAME and WORD_GAME.Layout and WORD_GAME.Layout.deck_rect then
			local deck = WORD_GAME.Layout.deck_rect()
			if G.deck and G.deck.T then
			G.deck.T.x = deck.x
			G.deck.T.y = deck.y
			G.deck.T.w = deck.w
			G.deck.T.h = deck.h
			if G.deck.hard_set_T then G.deck:hard_set_T(deck.x, deck.y, deck.w, deck.h) end
			end
			-- Invisible recycle pile; voucher discard dissolves on the perk imprint.
			if G.discard and G.discard.T then
				G.discard.T.x = -20
				G.discard.T.y = -20
				if G.discard.hard_set_T then
					G.discard:hard_set_T(-20, -20, G.discard.T.w, G.discard.T.h)
				end
			end
		else
			if G.deck and G.deck.T then
				G.deck.T.x = rect.x + pad_x
				G.deck.T.y = rect.y + rect.h - G.deck.T.h - pad_y
			end
		end

		dealt_hand.apply_screen_position()

		if G.discard and G.discard.T
			and not (WORD_GAME.VoucherDiscard and WORD_GAME.VoucherDiscard.uses_table_draw
				and WORD_GAME.VoucherDiscard.uses_table_draw()) then
			G.discard.T.x = rect.x + rect.w * 0.5
			G.discard.T.y = rect.y + rect.h * 0.5
		end

		if G.hand.snap_VT then G.hand:snap_VT() end
		snap_moveable(G.hand)
		snap_moveable(G.deck)
		snap_moveable(G.discard)
		if G.deck and G.deck.cards and G.deck.cards[1] then
			if G.deck.relayout then G.deck:relayout() end
			if G.deck.hard_set_cards then G.deck:hard_set_cards() end
		end

		if WORD_GAME and WORD_GAME.HandShuffle and not opts.skip_hand_shuffle then
			WORD_GAME.HandShuffle.try_sync()
		end
		local placement = G.placement_table and G.placement_table.area
		if G.placement_table and G.placement_table.apply_screen_position then
			G.placement_table:apply_screen_position()
			placement = G.placement_table.area
		end

		if placement then
			placement:snap_VT()
			placement:hard_set_cards()
		end

		if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.mark_layout_settle then
			WORD_GAME.HandShuffle.mark_layout_settle(4)
		end
	end
	if G.STAGE == G.STAGES.MAIN_MENU and layout_main_menu then
		layout_main_menu()
	end
end

function M.refresh_placement_layout()
	if G.STAGE ~= G.STAGES.RUN or not G.placement_table then return end
	if G.placement_table.apply_screen_position then
		G.placement_table:apply_screen_position()
	end
	local placement = G.placement_table.area
	if placement then
		placement:snap_VT()
		if placement.velocity then
			placement.velocity.x = 0
			placement.velocity.y = 0
			placement.velocity.r = 0
			placement.velocity.scale = 0
		end
		placement:hard_set_cards()
	end
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.mark_layout_settle then
		WORD_GAME.HandShuffle.mark_layout_settle(4)
	end
end

return M
