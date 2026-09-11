--[[ packages/jumbalaya-engine/views/letter_card_view.lua - Letter card view component ]]

local LetterCardView = {}
LetterCardView.__index = LetterCardView

function LetterCardView.new(card, rect)
	return setmetatable({
		card = card,
		rect = rect or { x = 0, y = 0, w = 1, h = 1 },
	}, LetterCardView)
end

function LetterCardView:draw(renderer)
	if renderer and renderer.draw_card then
		renderer:draw_card(self, self.rect)
	end
end

return LetterCardView
