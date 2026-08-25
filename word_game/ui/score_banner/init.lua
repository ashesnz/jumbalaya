--[[
	word_game/ui/score_banner/init.lua - Jumble score banner facade.

	Points × multiplier points and "Points to get" label under the portrait.
]]

local fonts = require("word_game.ui.score_banner.fonts")
local jumble = require("word_game.ui.score_banner.jumble")
local draw = require("word_game.ui.score_banner.draw")

local M = jumble

local LABEL_NEED = "TO CLEAR"

M.title_font = fonts.title_font
M.bubble_font = fonts.bubble_font

function M.state()
	if not G.GAME then
		return { remaining = 0, target = 0, to_go_label = LABEL_NEED }
	end
	G.GAME.word_hud = G.GAME.word_hud or {
		remaining = 0,
		target = 0,
		to_go_label = LABEL_NEED,
	}
	return G.GAME.word_hud
end

function M.actual_remaining()
	local wr = G.GAME and G.GAME.word_round
	local target = wr and wr.target or 0
	local scored = G.GAME and G.GAME.points or 0
	return math.max(0, target - scored)
end

function M.sync_label(hud)
	hud = hud or M.state()
	if hud.banner_mode == "boss_prep" or hud.banner_mode == "boss_word" then
		return
	end
	hud.to_go_label = LABEL_NEED
end

function M.set_banner_mode(mode, message)
	local hud = M.state()
	hud.banner_mode = mode or "normal"
	hud.banner_message = message
end

function M.reset(target)
	local hud = M.state()
	hud.target = target or 0
	hud.remaining = target or 0
	hud.banner_mode = "normal"
	hud.banner_message = nil
	M.sync_label(hud)
end

function M.snap_to_actual()
	local hud = M.state()
	hud.remaining = M.actual_remaining()
	hud.target = (G.GAME.word_round and G.GAME.word_round.target) or hud.target or 0
	M.sync_label(hud)
end

function M.draw()
	draw.draw(M)
end

return M
