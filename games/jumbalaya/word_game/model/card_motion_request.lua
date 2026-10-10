--[[
	word_game/model/card_motion_request.lua - Model→UI card pile animation intent.

	Core: none
	Store: none
	Presentation: card_motion_move → ui/presentation/install.lua (CardMotion.move)
]]

local Presentation = require("word_game.model.presentation")
local piles = require("word_game.model.piles")

local TYPE_TO_PILE = {
	hand = "hand",
	draw = "draw",
	deck = "draw",
	discard = "discard",
	pattern = "pattern",
	placement = "pattern",
	bonus = "bonus",
}

local function pile_id_for(host)
	if not host or not host.config then return nil end
	return TYPE_TO_PILE[host.config.type]
end

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
	if card and opts.to and opts.to.add_card then
		opts.to:add_card(card, nil, opts.stay_flipped or false)
	end
	local to_pile = opts.to_pile or pile_id_for(opts.to)
	if card and to_pile then
		piles.move_card({
			card = card,
			from_pile = opts.from_pile or pile_id_for(opts.from),
			to_pile = to_pile,
			slot_index = opts.slot_index or card.slot_index,
		})
	end
end

return M
