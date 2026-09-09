--[[
	word_game.model.jumble.bonus_return - Return a bonus card to the left gutter.

	Model code that displaces bonus cards from the puzzle row should call this
	instead of reaching into board geometry or the UI boss-word stack directly.
]]

local M = {}

--- @param card Card|nil
--- @return boolean
function M.return_card(card)
	if not card or not card.bonus_card then
		return false
	end
	local boss = WORD_GAME and WORD_GAME.BonusStackUI
	if boss and boss.return_card then
		return boss.return_card(card)
	end
	local gutter = WORD_GAME and WORD_GAME.Board and WORD_GAME.Board.BonusGutter
	if gutter and gutter.return_card then
		return gutter.return_card(card)
	end
	return false
end

return M
