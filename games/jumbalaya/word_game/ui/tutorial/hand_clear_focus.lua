--[[
	word_game/ui/hand_clear_focus.lua - Stage 1-1 hand-clear spotlight.

	Dims the table when the target score is reached so only the timeline,
	score banner, token pile, and celebration effects stay prominent.
]]


local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local game = require("word_game.ui.util.game_runtime").game

local M = {}
local Easing = require "word_game.ui.effects.easing"
local UIViewHost = require("jumbalaya-engine.panels.view_host")

local active = false
local overlay_colour = { 0.06, 0.08, 0.12, 0 }

function M.is_eligible()
	local token = WORD_GAME_UI.TokenReward
	return token and token.is_eligible and token.is_eligible()
end

function M.is_active()
	return active and game().HAND_CLEAR_OVERLAY ~= nil
end

local function refresh_input()
	if game().dealt_letters and game().dealt_letters.set_ranks then game().dealt_letters:set_ranks() end
	if game().pattern_row and game().pattern_row.area and game().pattern_row.area.set_ranks then
		game().pattern_row.area:set_ranks()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

local function stop_drag()
	local controller = game().INPUT
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
	if not game().ROOM_ATTACH then return end

	active = true
	if game_access.get() then
		game_access.patch({ word_score_animating = true })
	end
	game().under_overlay = true
	stop_drag()

	overlay_colour[4] = 0
	Easing.value{ref_table = overlay_colour, ref_value = 4, mod = 0.72, timer = "REAL", not_blockable = true, delay = 0.4}

	game().HAND_CLEAR_OVERLAY = UIViewHost.create{
		definition = {
			n = game().UI.ROOT,
			config = {
				align = "cm",
				padding = 32.05,
				r = 0.1,
				colour = overlay_colour,
				emboss = 0.05,
			},
			nodes = {
				{ n = game().UI.ROW, config = { align = "cm", minh = game().ROOM.T.h, minw = game().ROOM.T.w }, nodes = {} },
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 3.2 },
			major = game().ROOM_ATTACH,
			bond = "Weak",
		},
	}
	game().HAND_CLEAR_OVERLAY.redraw_portrait = true
	game().HAND_CLEAR_OVERLAY.redraw_banner = true
	game().HAND_CLEAR_OVERLAY.redraw_tokens = true
	game().HAND_CLEAR_OVERLAY.redraw_confetti = true
	game().HAND_CLEAR_OVERLAY.redraw_token_reward = true
	game().HAND_CLEAR_OVERLAY.redraw_attention = true
	game().HAND_CLEAR_OVERLAY.selections = {}

	refresh_input()
end

function M.end_focus()
	if not active and not game().HAND_CLEAR_OVERLAY then return end
	active = false
	if game().HAND_CLEAR_OVERLAY then
		game().HAND_CLEAR_OVERLAY:remove()
		game().HAND_CLEAR_OVERLAY = nil
	end
	refresh_input()
end

function M.reset()
	M.end_focus()
end

return M
