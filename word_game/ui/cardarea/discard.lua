--[[
	word_game/ui/cardarea/discard.lua - Invisible recycle-pile CardArea behaviour.

	G.discard holds played/discarded cards for deck recycling. Voucher discard
	uses dissolve-on-voucher; this pile is never shown as a bin sprite.
]]

local voucher_discard = require("word_game.ui.perks.discard_bin")

local M = {}

function M.update(self, dt)
	if self ~= G.discard then return end
	voucher_discard.sync_discard_pile_area()
	for _, card in ipairs(self.cards or {}) do
		if card.area == self then
			card.states.drag.can = false
			card.states.collide.can = false
			card.states.hover.can = false
			card.states.click.can = false
		end
	end
end

function M.draw_layer(self, v, draw_card_layer)
	if self.config.type ~= "discard" then return end
	for i = 1, #(self.cards or {}) do
		local card = self.cards[i]
		if card.played_pool or (card.states and card.states.visible == false) then
			-- Hidden played-pool cards never render in the sidebar.
		elseif card ~= G.INPUT.focused.target and math.abs(card.VT.x - self.T.x) > 1 then
			draw_card_layer(card, v)
		end
	end
end

return M
