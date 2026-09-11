--[[
	word_game/ui/hand_clear_focus.lua - Stage 1-1 hand-clear spotlight.

	Dims the table when the target score is reached so only the timeline,
	score banner, token pile, and celebration effects stay prominent.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local M = {}
local Easing = require "word_game.ui.effects.easing"
local game_access = require("word_game.model.game_access")
local UIViewHost = require("jumbalaya-engine.panels.view_host")

local active = false
local overlay_colour = { 0.06, 0.08, 0.12, 0 }

function M.is_eligible()
	local token = WORD_GAME_UI.TokenReward
	return token and token.is_eligible and token.is_eligible()
end

function M.is_active()
	return active and runtime().HAND_CLEAR_OVERLAY ~= nil
end

local function refresh_input()
	if runtime().dealt_letters and runtime().dealt_letters.set_ranks then runtime().dealt_letters:set_ranks() end
	if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.set_ranks then
		runtime().pattern_row.area:set_ranks()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

local function stop_drag()
	local controller = runtime().INPUT
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
	if not runtime().ROOM_ATTACH then return end

	active = true
	if game_access.get() then
		game_access.patch({ word_score_animating = true })
	end
	runtime().under_overlay = true
	stop_drag()

	overlay_colour[4] = 0
	Easing.value{ref_table = overlay_colour, ref_value = 4, mod = 0.72, timer = "REAL", not_blockable = true, delay = 0.4}

	runtime().HAND_CLEAR_OVERLAY = UIViewHost.create{
		definition = {
			n = runtime().UI.ROOT,
			config = {
				align = "cm",
				padding = 32.05,
				r = 0.1,
				colour = overlay_colour,
				emboss = 0.05,
			},
			nodes = {
				{ n = runtime().UI.ROW, config = { align = "cm", minh = runtime().ROOM.T.h, minw = runtime().ROOM.T.w }, nodes = {} },
			},
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 3.2 },
			major = runtime().ROOM_ATTACH,
			bond = "Weak",
		},
	}
	runtime().HAND_CLEAR_OVERLAY.redraw_portrait = true
	runtime().HAND_CLEAR_OVERLAY.redraw_banner = true
	runtime().HAND_CLEAR_OVERLAY.redraw_tokens = true
	runtime().HAND_CLEAR_OVERLAY.redraw_confetti = true
	runtime().HAND_CLEAR_OVERLAY.redraw_token_reward = true
	runtime().HAND_CLEAR_OVERLAY.redraw_attention = true
	runtime().HAND_CLEAR_OVERLAY.selections = {}

	refresh_input()
end

function M.end_focus()
	if not active and not runtime().HAND_CLEAR_OVERLAY then return end
	active = false
	if runtime().HAND_CLEAR_OVERLAY then
		runtime().HAND_CLEAR_OVERLAY:remove()
		runtime().HAND_CLEAR_OVERLAY = nil
	end
	refresh_input()
end

function M.reset()
	M.end_focus()
end

return M
