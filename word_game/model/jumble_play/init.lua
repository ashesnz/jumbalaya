--[[
	word_game/model/jumble_play/init.lua - Jumble play-button orchestration.

	Exported as WORD_GAME.Play. UI should call Play.play_word() rather than
	duplicating match rules.
]]

local M = {}

require("word_game.model.jumble_play.hand")(M)
require("word_game.model.jumble_play.jumble")(M)

function M.play_word(opts)
	opts = opts or {}
	return M.play_jumble_word(opts)
end

return M
