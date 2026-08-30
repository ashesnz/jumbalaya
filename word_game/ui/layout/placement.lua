--[[
	word_game/ui/layout/placement.lua - Board placement, portraits, and screen positions.
]]

local felt = require("word_game.ui.layout.felt")
local vault = require("word_game.ui.layout.vault")
local dealt_hand = require("word_game.ui.dealt_hand")

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
			card_limit = function() return G.TABLE_HAND_SIZE or 8 end,
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

function M.cinematic_portrait_active()
	local alpha = G.GAME and G.GAME.alpha
	return alpha and alpha.stage3_cinematic and true or false
end

function M.cinematic_portrait_hidden()
	local alpha = G.GAME and G.GAME.alpha
	return alpha and alpha.stage3_cinematic and not alpha.stage3_portrait_visible
end

function M.cinematic_pose_rect(pose)
	local hud = M.hud_portrait_rect()
	if pose == "left" then
		return {
			x = math.max(0.35, G.TILE_W * 0.06),
			y = hud.y,
			w = hud.w,
			h = hud.h,
		}
	end
	return hud
end

function M.portrait_rect()
	local alpha = G.GAME and G.GAME.alpha
	if alpha and alpha.stage3_portrait_rect then
		return alpha.stage3_portrait_rect
	end
	local pose = alpha and alpha.stage3_portrait_pose
	if pose == "center" or pose == "left" then
		return M.cinematic_pose_rect(pose)
	end
	return M.hud_portrait_rect()
end

function M.cinematic_boss_rest_rect()
	local hud = M.hud_portrait_rect()
	local x = vault.vault_left() - felt.sidebar_gap() - hud.w
	local min_x = hud.w + math.max(0.4, G.TILE_W * 0.08)
	return {
		x = math.max(min_x, x),
		y = hud.y,
		w = hud.w,
		h = hud.h,
	}
end

function M.cinematic_ally_rest_rect()
	local milo = M.cinematic_pose_rect("left")
	local gap = math.max(0.12, milo.w * 0.1)
	return {
		x = milo.x + milo.w + gap,
		y = milo.y,
		w = milo.w,
		h = milo.h,
	}
end

function M.cinematic_guest_rest_rect()
	local ally = M.cinematic_ally_rest_rect()
	local gap = math.max(0.12, ally.w * 0.1)
	return {
		x = ally.x + ally.w + gap,
		y = ally.y,
		w = ally.w,
		h = ally.h,
	}
end

function M.ally_portrait_rect()
	local alpha = G.GAME and G.GAME.alpha
	if alpha and alpha.stage3_ally_portrait_rect then
		return alpha.stage3_ally_portrait_rect
	end
	return M.cinematic_ally_rest_rect()
end

function M.guest_portrait_rect()
	local alpha = G.GAME and G.GAME.alpha
	if alpha and alpha.stage3_guest_portrait_rect then
		return alpha.stage3_guest_portrait_rect
	end
	if alpha and alpha.stage3_guest_pose == "center" then
		return M.hud_portrait_rect()
	end
	return M.cinematic_guest_rest_rect()
end

function M.guest_portrait_name_rect()
	local photo = M.guest_portrait_rect()
	local h = felt.portrait_name_h()
	local w = math.max(photo.w * 1.35, 2.4)
	return {
		x = photo.x + (photo.w - w) * 0.5,
		y = photo.y - h * 0.92,
		w = w,
		h = h * 0.88,
	}
end

function M.ally_portrait_name_rect()
	local photo = M.ally_portrait_rect()
	local h = felt.portrait_name_h()
	local w = math.max(photo.w * 1.35, 2.4)
	return {
		x = photo.x + (photo.w - w) * 0.5,
		y = photo.y - h * 0.92,
		w = w,
		h = h * 0.88,
	}
end


function M.portrait_name_rect()
	local photo = M.portrait_rect()
	local h = felt.portrait_name_h()
	local w = math.max(photo.w * 1.35, 2.4)
	local y = M.cinematic_portrait_active()
		and (photo.y - h * 0.92)
		or (felt.hud_top() + (h - h * 0.88) * 0.35)
	return {
		x = photo.x + (photo.w - w) * 0.5,
		y = y,
		w = w,
		h = h * 0.88,
	}
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
	vault.update_vault_attach()
	vault.update_panel_attach()
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
			if G.discard and G.discard.T and WORD_GAME.Layout.discard_rect then
				local discard = WORD_GAME.Layout.discard_rect()
				G.discard.T.x = discard.x
				G.discard.T.y = discard.y
				G.discard.T.w = discard.w
				G.discard.T.h = discard.h
				if G.discard.hard_set_T then
					G.discard:hard_set_T(discard.x, discard.y, discard.w, discard.h)
				end
			end
		else
			if G.deck and G.deck.T then
				G.deck.T.x = rect.x + pad_x
				G.deck.T.y = rect.y + rect.h - G.deck.T.h - pad_y
			end
		end

		dealt_hand.apply_screen_position()

		local table_discard = WORD_GAME and WORD_GAME.TableDiscard
		if G.discard and G.discard.T
			and not (table_discard and table_discard.uses_table_draw and table_discard.uses_table_draw()) then
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

		if G.player_host and G.player_host.states.visible then
			G.player_host:apply_screen_position()
		end

		if WORD_GAME and WORD_GAME.HandShuffle and not opts.skip_hand_shuffle then
			WORD_GAME.HandShuffle.sync()
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
	if G.STAGE == G.STAGES.MAIN_MENU and G.title_top then
		G.title_top.T.x = G.TILE_W/2 - G.title_top.T.w/2
		G.title_top.T.y = G.TILE_H/2 - G.title_top.T.h/2 -(G.debug_splash_size_toggle and 2 or 1.2)

		G.title_top:snap_VT()
	end
end

function M.refresh_placement_layout()
	if G.STAGE ~= G.STAGES.RUN or not G.placement_table then return end
	G.placement_table:apply_screen_position()
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
