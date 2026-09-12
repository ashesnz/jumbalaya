--[[
	word_game/model/jumble/bonus_return.lua - Return displaced bonus card to the left gutter

	Core: none
	Store: none
	Presentation: bonus_card_return
]]

local BonusGutter = require("word_game.board.bonus.gutter")
local Presentation = require("word_game.model.presentation")

local M = {}

--- @param card Card|nil
--- @return boolean
function M.return_card(card)
	if not card or not card.bonus_card then
		return false
	end
	local handled = Presentation.emit("bonus_card_return", card)
	if handled then
		return true
	end
	local gutter = BonusGutter
	if gutter and gutter.return_card then
		return gutter.return_card(card)
	end
	return false
end

return M
