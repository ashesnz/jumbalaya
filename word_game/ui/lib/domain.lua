--[[
	word_game/ui/lib/domain.lua - Resolve WORD_GAME model/board exports at runtime.

	UI modules load during `word_game/init.lua` before the global WORD_GAME exists;
	use these helpers in function bodies (or lazy locals) instead of deep requires.
]]

local M = {}

function M.placement_word()
	if WORD_GAME and WORD_GAME.PlacementWord then
		return WORD_GAME.PlacementWord
	end
	return require("word_game.model.jumble.placement_word")
end

function M.jumble_rules()
	if WORD_GAME and WORD_GAME.JumbleRules then
		return WORD_GAME.JumbleRules
	end
	return require("word_game.model.jumble_play.jumble_rules")
end

function M.hand_size()
	if WORD_GAME and WORD_GAME.HandSize then
		return WORD_GAME.HandSize
	end
	return require("word_game.model.hand_size")
end

function M.board_snap()
	if WORD_GAME and WORD_GAME.Board and WORD_GAME.Board.Snap then
		return WORD_GAME.Board.Snap
	end
	return require("word_game.board.placement.snap")
end

function M.bonus_gutter()
	if WORD_GAME and WORD_GAME.Board and WORD_GAME.Board.BonusGutter then
		return WORD_GAME.Board.BonusGutter
	end
	return require("word_game.board.bonus.gutter")
end

return M
