--[[
	word_game/ui/layout/placement.lua - Board placement, portraits, and screen positions.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local felt = require("word_game.ui.layout.felt")
local sidebar_layout = require("word_game.ui.sidebar.layout")
local dealt_hand = require("word_game.ui.table.dealt_hand")
local facade = require("word_game.ui.facade")

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
	if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.T and (runtime().pattern_row.area.T.w or 0) > 0 then
		return runtime().pattern_row.area.T.w
	end
	local placement_area = runtime().pattern_row and runtime().pattern_row.area
	if placement_area and placement_area.T and (placement_area.T.w or 0) > 0 then
		return placement_area.T.w
	end
	local ok, playout = pcall(require, "word_game.board.placement.layout")
	if ok and playout and playout.area_width then
		local pctx = {
			card_w = function() return runtime().CARD_W or 1.0 end,
			card_h = function() return runtime().CARD_H or 1.4 end,
			card_limit = function() return facade.hand_size().get() end,
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
	local rect = {
		x = col.x + (col.w - w) * 0.5,
		y = felt.hud_top() + (slot_h - h) * 0.45,
		w = w,
		h = h,
		slant = h * 0.88,
	}
	runtime().ARGS = runtime().ARGS or {}
	runtime().ARGS.timeline_rect = rect
	return rect
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
	return banner.y + banner.h + runtime().TILE_H * 0.02
end

function M.update_play_attach()
	if not runtime().PLAY_ATTACH then return end
	local rect = felt.felt_rect()
	runtime().PLAY_ATTACH.T.x = rect.x
	runtime().PLAY_ATTACH.T.y = rect.y
	runtime().PLAY_ATTACH.T.w = rect.w
	runtime().PLAY_ATTACH.T.h = rect.h
	runtime().PLAY_ATTACH:hard_set_T(rect.x, rect.y, rect.w, rect.h)
end

function M.update_all()
	sidebar_layout.update_sidebar_attach()
	sidebar_layout.update_panel_attach()
	M.update_play_attach()
end

function M.set_screen_positions(opts)
	opts = opts or {}
	if runtime().STAGE == runtime().STAGES.RUN and runtime().dealt_letters then
		if WORD_GAME_UI.Layout then
			WORD_GAME_UI.Layout.update_all()
		end
		local rect = get_table_felt_rect()
		local pad_x = rect.w * 0.04
		local pad_y = rect.h * 0.06
		if runtime().STATE == runtime().STATES.TABLE_BOARD
			and WORD_GAME_UI.Layout and WORD_GAME_UI.Layout.deck_rect then
			local deck = WORD_GAME_UI.Layout.deck_rect()
			if runtime().draw_pile and runtime().draw_pile.T then
			runtime().draw_pile.T.x = deck.x
			runtime().draw_pile.T.y = deck.y
			runtime().draw_pile.T.w = deck.w
			runtime().draw_pile.T.h = deck.h
			if runtime().draw_pile.hard_set_T then runtime().draw_pile:hard_set_T(deck.x, deck.y, deck.w, deck.h) end
			end
			-- Invisible recycle pile; voucher discard dissolves on the perk imprint.
			if runtime().recycle_stash and runtime().recycle_stash.T then
				runtime().recycle_stash.T.x = -20
				runtime().recycle_stash.T.y = -20
				if runtime().recycle_stash.hard_set_T then
					runtime().recycle_stash:hard_set_T(-20, -20, runtime().recycle_stash.T.w, runtime().recycle_stash.T.h)
				end
			end
		else
			if runtime().draw_pile and runtime().draw_pile.T then
				runtime().draw_pile.T.x = rect.x + pad_x
				runtime().draw_pile.T.y = rect.y + rect.h - runtime().draw_pile.T.h - pad_y
			end
		end

		dealt_hand.apply_screen_position()

		if runtime().recycle_stash and runtime().recycle_stash.T
			and not (WORD_GAME_UI.VoucherDiscard and WORD_GAME_UI.VoucherDiscard.uses_table_draw
				and WORD_GAME_UI.VoucherDiscard.uses_table_draw()) then
			runtime().recycle_stash.T.x = rect.x + rect.w * 0.5
			runtime().recycle_stash.T.y = rect.y + rect.h * 0.5
		end

		if runtime().dealt_letters.snap_VT then runtime().dealt_letters:snap_VT() end
		snap_moveable(runtime().dealt_letters)
		snap_moveable(runtime().draw_pile)
		snap_moveable(runtime().recycle_stash)
		if runtime().draw_pile and runtime().draw_pile.cards and runtime().draw_pile.cards[1] then
			if runtime().draw_pile.relayout then runtime().draw_pile:relayout() end
			if runtime().draw_pile.hard_set_cards then runtime().draw_pile:hard_set_cards() end
		end

		if WORD_GAME_UI.TableControls and not opts.skip_hand_shuffle then
			WORD_GAME_UI.TableControls.sync()
		end
		local placement = runtime().pattern_row and runtime().pattern_row.area
		if runtime().pattern_row and runtime().pattern_row.apply_screen_position then
			runtime().pattern_row:apply_screen_position()
			placement = runtime().pattern_row.area
		end

		if placement then
			placement:snap_VT()
			placement:hard_set_cards()
		end

		if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.mark_layout_settle then
			WORD_GAME_UI.TableControls.mark_layout_settle(4)
		end
	end
	if runtime().STAGE == runtime().STAGES.MAIN_MENU and layout_main_menu then
		layout_main_menu()
	end
end

function M.refresh_placement_layout()
	if runtime().STAGE ~= runtime().STAGES.RUN or not runtime().pattern_row then return end
	if runtime().pattern_row.apply_screen_position then
		runtime().pattern_row:apply_screen_position()
	end
	local placement = runtime().pattern_row.area
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
	if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.mark_layout_settle then
		WORD_GAME_UI.TableControls.mark_layout_settle(4)
	end
end

return M
