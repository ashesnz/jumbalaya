--[[ devtools/sections/stage.lua - Jump to a match stage from the debug panel. ]]

local layout = require "devtools.layout"
local round_config = require "word_game.config.round_config"

local function jump_to_hand(ctx, set, hand_index)
	if not ctx:is_run_stage() then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if not (WORD_GAME and WORD_GAME.Round) then return end

	set = math.max(1, math.min(round_config.SETS_TO_WIN or 3, set))
	hand_index = math.max(1, math.min(3, hand_index or 1))
	if G.GAME then
		G.GAME.word_score_animating = false
	end
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
	if WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.dismiss_intro then
		WORD_GAME.PlayerHost.dismiss_intro()
	end
	if WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.end_stage3_cinematic then
		WORD_GAME.PlayerHost.end_stage3_cinematic()
	end
	local alpha = G.GAME and G.GAME.alpha
	if alpha then
		alpha.stage3_cinematic_seen = nil
		alpha.marco_cinematic_seen = nil
		alpha.cinematic_seen = nil
	end

	WORD_GAME.Round.start_hand(set, hand_index)
	if WORD_GAME.Deck and WORD_GAME.Deck.reset_table_deck then
		WORD_GAME.Deck.reset_table_deck()
	end
	if deal_table_opening_hand then
		deal_table_opening_hand()
	end
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar:refresh()
	end
	if WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.maybe_stage3_cinematic then
		WORD_GAME.PlayerHost.maybe_stage3_cinematic()
	end
	play_sfx("generic1", 0.9, 0.7)
end

local HANDS = {
	{ set = 1, hand = 1, label = "1-1" },
	{ set = 1, hand = 3, label = "1-3 (boss)" },
	{ set = 2, hand = 1, label = "2-1 (boss)" },
	{ set = 2, hand = 3, label = "2-3 (boss)" },
	{ set = 3, hand = 1, label = "3-1" },
	{ set = 3, hand = 3, label = "3-3 (boss)" },
}

return {
	id = "stage",
	order = 25,

	register = function(panel)
		for _, row in ipairs(HANDS) do
			local set, hand = row.set, row.hand
			panel:action("goto_hand_" .. set .. "_" .. hand, function(ctx)
				jump_to_hand(ctx, set, hand)
			end)
		end
	end,

	build = function(_panel)
		local buttons = {}
		for _, row in ipairs(HANDS) do
			buttons[#buttons + 1] = {
				label = row.label,
				action = "goto_hand_" .. row.set .. "_" .. row.hand,
			}
		end
		return layout.section("Stage", layout.button_columns(buttons, 3))
	end,
}
