--[[ bridge/pile_sync.lua - Phase 5 dual-write: live CardArea piles → store.piles ]]

local store_sync = require("bridge.store_sync")

local M = {}

local function card_id(card)
	return card and (card.letter_card_id or card.id)
end

local function snapshot_area(area, pile_id)
	local out = {}
	if not area or not area.cards then return out end
	for index, card in ipairs(area.cards) do
		if card and not card.REMOVED then
			local id = card_id(card)
			if id then
				card.id = id
			end
			card.pile_id = pile_id
			card.slot_index = index
			out[#out + 1] = card
		end
	end
	return out
end

local function snapshot_bonus()
	local out = {}
	local bonus = rawget(_G, "WORD_GAME") and WORD_GAME.BonusStack
	if bonus and bonus.cards then
		for index, card in ipairs(bonus.cards() or {}) do
			if card and not card.REMOVED then
				local id = card_id(card)
				if id then card.id = id end
				card.pile_id = "bonus"
				card.slot_index = index
				out[#out + 1] = card
			end
		end
	end
	return out
end

function M.collect_piles()
	if not G then return nil end
	local pattern_area = G.pattern_row and G.pattern_row.area
	return {
		hand = snapshot_area(G.dealt_letters, "hand"),
		draw = snapshot_area(G.draw_pile, "draw"),
		discard = snapshot_area(G.recycle_stash, "discard"),
		pattern = snapshot_area(pattern_area, "pattern"),
		bonus = snapshot_bonus(),
	}
end

function M.sync_areas_to_store(store)
	store = store or (G and G._store)
	if not store then return end
	local piles = M.collect_piles()
	if not piles then return end
	store:patch({ piles = piles })
	store_sync.sync_to_g(store)
end

return M
