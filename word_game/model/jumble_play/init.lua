--[[
	word_game/model/jumble_play/init.lua - Jumble play-button orchestration.

	`play_jumble_word` / `play_word` evaluate rules and return a result table.
	UI calls `word_game.ui.play_resolution.resolve` to run presentation effects.
]]

local M = {}

require("word_game.model.jumble_play.hand")(M)
require("word_game.model.jumble_play.jumble")(M)

function M.play_word(opts)
	opts = opts or {}
	return M.play_jumble_word(opts)
end

function M.resolve_play(opts)
	return require("word_game.ui.play_resolution").resolve(M, opts)
end

return M
