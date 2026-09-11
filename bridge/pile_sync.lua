--[[ bridge/pile_sync.lua - Phase 8: store-authoritative pile sync (areas ↔ store) ]]

local store_sync = require("bridge.store_sync")

local M = {}

--- True when TABLE_BOARD view is installed and store-backed pile draw is active.
function M.chrome_release_enabled()
	if not G or G.STATE ~= G.STATES.TABLE_BOARD then return false end
	local views_install = package.loaded["word_game.ui.views.install"]
	if not views_install or not views_install.table_board_view then return false end
	return views_install.table_board_view() ~= nil
end

local PILE_AREA = {
	hand = "dealt_letters",
	draw = "draw_pile",
	discard = "recycle_stash",
	pattern = "pattern_row",
}

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

local function area_for_pile(pile_id)
	if not G then return nil end
	if pile_id == "pattern" then
		return G.pattern_row and G.pattern_row.area
	end
	return G[PILE_AREA[pile_id]]
end

local function interaction_cards()
	local out = {}
	if not G or not G.INPUT then return out end
	if G.INPUT.dragging and G.INPUT.dragging.target then
		out[G.INPUT.dragging.target] = true
	end
	if G.INPUT.focused and G.INPUT.focused.target then
		out[G.INPUT.focused.target] = true
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
	local runtime = require("bridge.runtime")
	store = store or runtime.store()
	if not store then return end
	local piles = M.collect_piles()
	if not piles then return end
	store:patch({ piles = piles })
end

--- Drop static CardArea chrome after snapshotting to store (store renders resting cards).
---@param store table|nil
---@param pile_ids string[]|nil
function M.release_static_chrome(store, pile_ids)
	local runtime = require("bridge.runtime")
	store = store or runtime.store()
	if not store then return end
	M.sync_areas_to_store(store)
	pile_ids = pile_ids or { "hand", "draw", "pattern" }
	local keep = interaction_cards()
	for _, pile_id in ipairs(pile_ids) do
		local area = area_for_pile(pile_id)
		if area and area.cards then
			local retained = {}
			for _, card in ipairs(area.cards) do
				if keep[card] then
					retained[#retained + 1] = card
				elseif card and card.remove_from_area then
					card:remove_from_area()
				end
			end
			area.cards = retained
			if area.set_ranks then area:set_ranks() end
		end
	end
end

--- Rebuild a live CardArea from store pile entries (deal/shuffle follow store).
---@param store table
---@param pile_id string
function M.sync_store_pile_to_area(store, pile_id)
	if not store or not pile_id then return end
	local area = area_for_pile(pile_id)
	if not area or not area.cards then return end
	local state = store:get()
	local pile = state and state.piles and state.piles[pile_id]
	if not pile then return end

	local by_id = {}
	for _, card in ipairs(G.letter_inventory or {}) do
		local id = card_id(card)
		if id then by_id[id] = card end
	end
	for _, card in ipairs(area.cards) do
		local id = card_id(card)
		if id then by_id[id] = card end
	end

	local rebuilt = {}
	for index, entry in ipairs(pile) do
		local id = entry.id or entry.letter_card_id
		local card = (id and by_id[id]) or entry
		if card and not card.REMOVED then
			card.pile_id = pile_id
			card.slot_index = index
			rebuilt[#rebuilt + 1] = card
			if area.emplace and card.area ~= area then
				card:set_card_area(area)
			end
		end
	end
	area.cards = rebuilt
	if area.set_ranks then area:set_ranks() end
	if area.relayout then area:relayout() end
end

--- Mirror all store piles onto live CardAreas (after save restore or shuffle).
---@param store table|nil
function M.sync_store_to_areas(store)
	local runtime = require("bridge.runtime")
	store = store or runtime.store()
	if not store then return end
	for pile_id in pairs(PILE_AREA) do
		M.sync_store_pile_to_area(store, pile_id)
	end
end

return M
