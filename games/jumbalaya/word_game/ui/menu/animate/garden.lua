--[[ word_game/ui/menu/animate/garden.lua - Title garden backdrop pan ]]

local GameRT = require("word_game.ui.util.game_runtime")

local M = {}

local TITLE_GARDEN_EXTRA_W = 60
local TITLE_GARDEN_EXTRA_H = 22
local TITLE_GARDEN_PAN = {
	amp_x = 10,
	amp_y = 4.5,
	period_x = 48,
	period_y = 64,
}

local function runtime()
	return GameRT.game()
end

function M.title_garden_sprite_dims(room)
	room = room or (runtime().ROOM and runtime().ROOM.T) or { w = 20, h = 11 }
	return (room.w or 20) + TITLE_GARDEN_EXTRA_W, (room.h or 11) + TITLE_GARDEN_EXTRA_H
end

function M.title_garden_pan_offset(time)
	time = time or 0
	local pan = TITLE_GARDEN_PAN
	local x = math.sin(time * 2 * math.pi / pan.period_x) * pan.amp_x
	local y = math.sin(time * 2 * math.pi / pan.period_y) * pan.amp_y
	return x, y
end

function M.update_title_garden_pan(dt)
	local sprite = runtime().SPLASH_BACK
	local pan = sprite and sprite.title_garden_pan
	if type(pan) ~= "table" then return end
	local off = sprite.alignment and sprite.alignment.offset
	if not off then return end
	dt = dt or (runtime() and runtime().real_dt) or 0
	pan.t = (pan.t or 0) + dt
	off.x, off.y = M.title_garden_pan_offset(pan.t)
end

function M.setup_title_garden_background()
	if runtime().SPLASH_BACK then
		runtime().SPLASH_BACK:remove()
		runtime().SPLASH_BACK = nil
	end

	local atlas = runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES.title_garden
	if not atlas or not atlas.image then return end

	local w, h = M.title_garden_sprite_dims()
	runtime().SPLASH_BACK = Sprite(-30, -13, w, h, atlas, {x = 0, y = 0})
	runtime().SPLASH_BACK:set_alignment({
		major = runtime().ROOM_ATTACH,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})
	runtime().SPLASH_BACK.title_garden_pan = { t = 0 }
	if runtime().SPLASH_BACK.align_to_major then
		runtime().SPLASH_BACK:align_to_major()
	end
	if runtime().SPLASH_BACK.snap_VT then
		runtime().SPLASH_BACK:snap_VT()
	end
end

return M
