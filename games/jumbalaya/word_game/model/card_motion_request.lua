--[[
	word_game/model/card_motion_request.lua - Model→UI card pile animation intent.

	Core: none
	Store: none
	Presentation: card_motion_move → ui/presentation/install.lua (CardMotion.move)
]]

local Presentation = require("word_game.model.presentation")

local M = {}

--- Queue animated card movement between piles. Presentation handler runs CardMotion;
--- headless tests without a handler fall back to an instant pile transfer.
---@param opts table CardMotion.move options (from, to, card, direction, …)
function M.move(opts)
	if Presentation.emit("card_motion_move", opts) then
		return
	end
	local card = opts.card
	if card and opts.from and opts.from.remove_card then
		card = opts.from:remove_card(card)
	end
	if card and opts.to and opts.to.emplace then
		opts.to:emplace(card, nil, opts.stay_flipped or false)
	end
end

return M
