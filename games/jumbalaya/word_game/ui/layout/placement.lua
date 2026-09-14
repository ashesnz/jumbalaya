--[[
	word_game/ui/layout/placement.lua - Board placement, portraits, and screen positions.
]]


local game = require("word_game.ui.util.game_runtime").game

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
	if game().pattern_row and game().pattern_row.area and game().pattern_row.area.T and (game().pattern_row.area.T.w or 0) > 0 then
		return game().pattern_row.area.T.w
	end
	local placement_area = game().pattern_row and game().pattern_row.area
	if placement_area and placement_area.T and (placement_area.T.w or 0) > 0 then
		return placement_area.T.w
	end
	local ok, playout = pcall(require, "word_game.board.placement.layout")
	if ok and playout and playout.area_width then
		local pctx = {
			card_w = function() return game().CARD_W or 1.0 end,
			card_h = function() return game().CARD_H or 1.4 end,
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
	game().ARGS = game().ARGS or {}
	game().ARGS.timeline_rect = rect
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
	return banner.y + banner.h + game().TILE_H * 0.02
end

function M.update_play_attach()
	if not game().PLAY_ATTACH then return end
	local rect = felt.felt_rect()
	game().PLAY_ATTACH.T.x = rect.x
	game().PLAY_ATTACH.T.y = rect.y
	game().PLAY_ATTACH.T.w = rect.w
	game().PLAY_ATTACH.T.h = rect.h
	game().PLAY_ATTACH:hard_set_T(rect.x, rect.y, rect.w, rect.h)
end

function M.update_all()
	sidebar_layout.update_sidebar_attach()
	sidebar_layout.update_panel_attach()
	M.update_play_attach()
end

function M.set_screen_positions(opts)
	opts = opts or {}
	if game().STAGE == game().STAGES.RUN and game().dealt_letters then
		if WORD_GAME_UI.Layout then
			WORD_GAME_UI.Layout.update_all()
		end
		local rect = get_table_felt_rect()
		local pad_x = rect.w * 0.04
		local pad_y = rect.h * 0.06
		if game().STATE == game().STATES.TABLE_BOARD
			and WORD_GAME_UI.Layout and WORD_GAME_UI.Layout.deck_rect then
			local deck = WORD_GAME_UI.Layout.deck_rect()
			if game().draw_pile and game().draw_pile.T then
			game().draw_pile.T.x = deck.x
			game().draw_pile.T.y = deck.y
			game().draw_pile.T.w = deck.w
			game().draw_pile.T.h = deck.h
			if game().draw_pile.hard_set_T then game().draw_pile:hard_set_T(deck.x, deck.y, deck.w, deck.h) end
			end
			-- Invisible recycle pile; voucher discard dissolves on the perk imprint.
			if game().recycle_stash and game().recycle_stash.T then
				game().recycle_stash.T.x = -20
				game().recycle_stash.T.y = -20
				if game().recycle_stash.hard_set_T then
					game().recycle_stash:hard_set_T(-20, -20, game().recycle_stash.T.w, game().recycle_stash.T.h)
				end
			end
		else
			if game().draw_pile and game().draw_pile.T then
				game().draw_pile.T.x = rect.x + pad_x
				game().draw_pile.T.y = rect.y + rect.h - game().draw_pile.T.h - pad_y
			end
		end

		dealt_hand.apply_screen_position()

		if game().recycle_stash and game().recycle_stash.T
			and not (WORD_GAME_UI.VoucherDiscard and WORD_GAME_UI.VoucherDiscard.uses_table_draw
				and WORD_GAME_UI.VoucherDiscard.uses_table_draw()) then
			game().recycle_stash.T.x = rect.x + rect.w * 0.5
			game().recycle_stash.T.y = rect.y + rect.h * 0.5
		end

		if game().dealt_letters.snap_VT then game().dealt_letters:snap_VT() end
		snap_moveable(game().dealt_letters)
		snap_moveable(game().draw_pile)
		snap_moveable(game().recycle_stash)
		if game().draw_pile and game().draw_pile.cards and game().draw_pile.cards[1] then
			if game().draw_pile.relayout then game().draw_pile:relayout() end
			if game().draw_pile.hard_set_cards then game().draw_pile:hard_set_cards() end
		end

		if WORD_GAME_UI.TableControls and not opts.skip_hand_shuffle then
			WORD_GAME_UI.TableControls.sync()
		end
		local placement = game().pattern_row and game().pattern_row.area
		if game().pattern_row and game().pattern_row.apply_screen_position then
			game().pattern_row:apply_screen_position()
			placement = game().pattern_row.area
		end

		if placement then
			placement:snap_VT()
			placement:hard_set_cards()
		end

		if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.mark_layout_settle then
			WORD_GAME_UI.TableControls.mark_layout_settle(4)
		end
		if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
			WORD_GAME_UI.TableInput.refresh_card_input()
		end
	end
	if game().STAGE == game().STAGES.MAIN_MENU and layout_main_menu then
		layout_main_menu()
	end
end

function M.refresh_placement_layout()
	if game().STAGE ~= game().STAGES.RUN or not game().pattern_row then return end
	if game().pattern_row.apply_screen_position then
		game().pattern_row:apply_screen_position()
	end
	local placement = game().pattern_row.area
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
	if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	end
end

return M
