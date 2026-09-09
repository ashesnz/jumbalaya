--[[
	word_game/ui/hand_clear_focus.lua - Stage 1-1 hand-clear spotlight.

	Dims the table when the target score is reached so only the timeline,
	score banner, token pile, and celebration effects stay prominent.
]]

local M = {}
local Easing = require "app.effects.easing"

local active = false
local overlay_colour = { 0.06, 0.08, 0.12, 0 }

function M.is_eligible()
	local token = WORD_GAME and WORD_GAME.TokenReward
	return token and token.is_eligible and token.is_eligible()
end

function M.is_active()
	return active and G.HAND_CLEAR_OVERLAY ~= nil
end

local function refresh_input()
	if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
	if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
		G.placement_table.area:set_ranks()
	end
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.try_sync()
	end
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_action_buttons then
		WORD_GAME.Sidebar.sync_action_buttons()
	end
end

local function stop_drag()
	local controller = G.INPUT
	if not controller or not controller.dragging or not controller.dragging.target then return end
	local target = controller.dragging.target
	if target.stop_drag then
		target:stop_drag()
	elseif controller.release then
		controller:release(target)
	end
end

function M.begin()
	if not M.is_eligible() or active then return end
	if not G.ROOM_ATTACH then return end

	active = true
	if G.GAME then
		G.GAME.word_score_animating = true
	end
	G.under_overlay = true
	stop_drag()

	overlay_colour[4] = 0
	Easing.value{ref_table = overlay_colour, ref_value = 4, mod = 0.72, timer = "REAL", not_blockable = true, delay = 0.4}

	G.HAND_CLEAR_OVERLAY = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = {
				align = "cm",
				padding = 32.05,
				r = 0.1,
				colour = overlay_colour,
				emboss = 0.05,
			},
			nodes = {
				{ n = G.UI.ROW, config = { align = "cm", minh = G.ROOM.T.h, minw = G.ROOM.T.w }, nodes = {} },
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 3.2 },
			major = G.ROOM_ATTACH,
			bond = "Weak",
		},
	}
	G.HAND_CLEAR_OVERLAY.redraw_portrait = true
	G.HAND_CLEAR_OVERLAY.redraw_banner = true
	G.HAND_CLEAR_OVERLAY.redraw_tokens = true
	G.HAND_CLEAR_OVERLAY.redraw_confetti = true
	G.HAND_CLEAR_OVERLAY.redraw_token_reward = true
	G.HAND_CLEAR_OVERLAY.redraw_attention = true
	G.HAND_CLEAR_OVERLAY.selections = {}

	refresh_input()
end

function M.end_focus()
	if not active and not G.HAND_CLEAR_OVERLAY then return end
	active = false
	if G.HAND_CLEAR_OVERLAY then
		G.HAND_CLEAR_OVERLAY:remove()
		G.HAND_CLEAR_OVERLAY = nil
	end
	refresh_input()
end

function M.reset()
	M.end_focus()
end

return M
