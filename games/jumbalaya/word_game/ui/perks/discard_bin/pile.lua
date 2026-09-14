--[[ word_game/ui/perks/discard_bin/pile.lua - Hidden recycle stash for voucher discards ]]

local shell = require("word_game.ui.facade").shell()

local M = {}

function M.sync_discard_pile_area()
	local stash = shell.recycle_stash()
	if not stash or not stash.states then return end
	stash.states.collide.can = false
	stash.states.hover.can = false
	stash.states.release_on.can = false
end

function M.stash_discarded_card(card)
	if not card or card.played_pool then return end
	card.discard_stash = true
	if card.states then
		card.states.visible = false
	end
end

function M.hide_discard_pile_cards()
	local stash = shell.recycle_stash()
	if not stash or not stash.cards then return end
	for _, card in ipairs(stash.cards) do
		M.stash_discarded_card(card)
	end
end

return M
