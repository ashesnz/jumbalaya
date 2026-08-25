local Layout = require("word_game.ui.layout")
local CharacterSpeech = require("word_game.ui.character_speech")
local characters = {
	intro_step_keys = function() return nil end,
	intro_uses_play_button = function() return true end,
	intro_is_free_play = function() return true end,
	intro_locks_cards = function() return false end,
	intro_spotlight = function() return nil end,
	intro_required_word = function() return nil end,
	intro_nudge_key = function() return nil end,
	skip_intro = function() return true end,
	current = function() return nil end,
	intro_hand_letters = function() return nil end,
}
local state = require("word_game.model.state")

local M = {}

function M.new(PlayerHost)
	return {
		PlayerHost = PlayerHost,
		Layout = Layout,
		CharacterSpeech = CharacterSpeech,
		characters = characters,
		state = state,
		BUBBLE_ALIGN = "tm",
		TAIL_ALONG = 0.82,
		STAGE3_DIM_TIME = 0.4,
		STAGE3_SLIDE_TIME = 0.85,
		STAGE3_BOSS_DROP_TIME = 0.7,
		STAGE3_BOSS_BEAT = 0.35,
		STAGE3_ALLY_LINES = {
			"aleisha_stage3_intro",
			"aleisha_stage3_ability",
			"aleisha_stage3_red",
			"aleisha_stage3_go",
		},
		STAGE23_GUEST_LINES = {
			"marco_stage23_intro",
			"marco_stage23_go",
			"marco_stage23_ability",
		},
	}
end

return M
