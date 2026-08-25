-- Jumbalaya placement controls.

G.FUNCS.play_placement_word = function()
  if G.GAME and G.GAME.word_score_animating then return end
  if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.consume_click() then return end
  if G.GAME and G.GAME.hand_redraw_animating then return end
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.play_word()
	end
end