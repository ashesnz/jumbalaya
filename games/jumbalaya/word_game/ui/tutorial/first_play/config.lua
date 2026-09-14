--[[ word_game/ui/tutorial/first_play/config.lua - Tutorial step script and layout constants ]]

local M = {}

M.STEPS = {
	{
		key = "first_play_welcome",
		spotlight = nil,
		bubble = { align = "cm", offset = { x = 0, y = -0.35 }, major = "room" },
	},
	{
		key = "first_play_hand",
		spotlight = "hand",
		bubble = { layout = "hand" },
	},
	{
		key = "first_play_placement",
		spotlight = "placement",
		bubble = { layout = "placement" },
	},
	{
		key = "first_play_positions",
		spotlight = "placement",
		bubble = { layout = "placement" },
	},
	{
		key = "first_play_play_button",
		spotlight = "play",
		bubble = { layout = "play" },
	},
	{
		key = "first_play_goal",
		spotlight = "timeline",
		bubble = { layout = "timeline" },
	},
}

M.HAND_BUBBLE_GAP = 0.12
M.HAND_BUBBLE_HEIGHT = 0.9
M.PLACEMENT_BUBBLE_GAP = 0.14
M.PLACEMENT_BUBBLE_HEIGHT = 1.1
M.PLAY_BUBBLE_GAP = 0.12
M.PLAY_BUBBLE_HEIGHT = 1.15
M.TIMELINE_BUBBLE_GAP = 0.14
M.TIMELINE_BUBBLE_HEIGHT = 0.85

return M
