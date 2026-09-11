--[[ packages/jumbalaya-engine/views/pile_view.lua - Pile view component ]]

local LetterCardView = require("jumbalaya-engine.views.letter_card_view")

local PileView = {}
PileView.__index = PileView

function PileView.new(pile_id, cards, rect)
	return setmetatable({
		pile_id = pile_id,
		cards = cards or {},
		rect = rect or { x = 0, y = 0, w = 1, h = 1 },
	}, PileView)
end

function PileView:draw(renderer)
	for i, card in ipairs(self.cards) do
		local card_rect = {
			x = self.rect.x + (i - 1) * 1.1 * (self.rect.card_w or 1),
			y = self.rect.y,
			w = self.rect.card_w or 1,
			h = self.rect.card_h or 1,
		}
		local view = LetterCardView.new(card, card_rect)
		view:draw(renderer)
	end
end

return PileView
