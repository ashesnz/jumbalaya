--[[ word_game/ui/tutorial/first_play/layout.lua - Speech bubble placement per spotlight ]]

local GameRT = require("word_game.ui.util.game_runtime")
local CharacterSpeech = require("word_game.ui.tutorial.character_speech")
local dealt_hand = require("word_game.ui.table.dealt_hand")
local Layout = require("word_game.ui.layout")
local config = require("word_game.ui.tutorial.first_play.config")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.bubble_definition(text_key)
	local def = CharacterSpeech.bubble_definition(text_key)
	if def and def.config then
		def.config.speech_tail = nil
	end
	return def
end

local function room_centered_bubble(cx, center_y)
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end
	local room_cx = room.x + room.w * 0.5
	local room_cy = room.y + room.h * 0.5
	return {
		align = "cm",
		offset = { x = cx - room_cx, y = center_y - room_cy },
		major = runtime().ROOM_ATTACH,
	}
end

local function hand_bubble_config()
	dealt_hand.apply_screen_position()

	local hand = runtime().dealt_letters and runtime().dealt_letters.T
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not hand or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local hand_cx = hand.x + hand.w * 0.5
	local center_y = hand.y - config.HAND_BUBBLE_GAP - config.HAND_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + config.HAND_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(hand_cx, center_y)
end

local function placement_bubble_config()
	if runtime().pattern_row and runtime().pattern_row.apply_screen_position then
		runtime().pattern_row:apply_screen_position()
	end

	local area = runtime().pattern_row and runtime().pattern_row.area
	local placement = area and area.T
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not placement or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local placement_cx = placement.x + placement.w * 0.5
	local center_y = placement.y + placement.h + config.PLACEMENT_BUBBLE_GAP + config.PLACEMENT_BUBBLE_HEIGHT * 0.5
	local max_center_y = (runtime().TILE_H or (room.y + room.h)) - config.PLACEMENT_BUBBLE_HEIGHT * 0.5 - 0.08
	center_y = math.min(center_y, max_center_y)

	return room_centered_bubble(placement_cx, center_y)
end

local function play_bubble_config()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end

	local bar = runtime().hand_action_bar
	local btn = WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.play_button_uie()
	local target = (bar and not bar.REMOVED and bar.T) or (btn and btn.T)
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not target or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local cx = target.x + target.w * 0.5
	local center_y = target.y - config.PLAY_BUBBLE_GAP - config.PLAY_BUBBLE_HEIGHT * 0.5
	local min_center_y = room.y + config.PLAY_BUBBLE_HEIGHT * 0.5 + 0.08
	center_y = math.max(center_y, min_center_y)

	return room_centered_bubble(cx, center_y)
end

local function timeline_bubble_config()
	local rect = Layout.timeline_rect and Layout.timeline_rect() or Layout.portrait_rect()
	local room = runtime().ROOM_ATTACH and runtime().ROOM_ATTACH.T
	if not rect or not room then
		return { align = "cm", offset = { x = 0, y = 0 }, major = runtime().ROOM_ATTACH }
	end

	local timeline_cx = rect.x + rect.w * 0.5
	local center_y = rect.y + rect.h + config.TIMELINE_BUBBLE_GAP + config.TIMELINE_BUBBLE_HEIGHT * 0.5
	local max_center_y = (runtime().TILE_H or (room.y + room.h)) - config.TIMELINE_BUBBLE_HEIGHT * 0.5 - 0.08
	center_y = math.min(center_y, max_center_y)

	return room_centered_bubble(timeline_cx, center_y)
end

function M.resolve_bubble_config(step)
	if step.bubble.layout == "hand" then
		return hand_bubble_config()
	end
	if step.bubble.layout == "placement" then
		return placement_bubble_config()
	end
	if step.bubble.layout == "play" then
		return play_bubble_config()
	end
	if step.bubble.layout == "timeline" then
		return timeline_bubble_config()
	end
	return {
		align = step.bubble.align,
		offset = step.bubble.offset,
		major = runtime().ROOM_ATTACH,
	}
end

return M
