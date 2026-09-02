-- Jumbalaya placement controls.

local InputLock = require("word_game.model.input_lock")

G.FUNCS.play_placement_word = function()
  if InputLock.is_table_busy() then return end
  if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.consume_click() then return end
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.play_word()
	end
end