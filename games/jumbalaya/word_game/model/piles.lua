--[[
	word_game/model/piles.lua - Store-authoritative pile sync for CardPile hosts.

	Authoritative table layout lives in `store.piles` as plain PileCard records
	(id / pile_id / slot_index / ability). CardPile hosts (`dealt_letters`,
	`draw_pile`, `pattern_row.area`) are presentation/interaction targets;
	mutate hosts during animation, then `sync_hosts_to_store` or `move_card`.

	Run deck membership (`shell.game().letter_inventory`) is separate: it tracks every live
	letter Card instance in the run; pile placement is always `store.piles`.

	Core: jumbalaya_core.store.reducers.piles + selectors.piles + cards.pile_record
	Store: patches piles; hydrates hosts from store snapshots
	Presentation: none — CardPile relayout triggered by callers
]]

local BonusStack = require("word_game.model.jumble.bonus_stack")
local shell = require("jumbalaya-engine.shell")
local store_ops = require("word_game.model.store_ops")
local pile_record = require("jumbalaya_core.cards.pile_record")
local live_game = require("word_game.model.live_game")

local M = {}

local PILE_HOST = {
	hand = "dealt_letters",
	draw = "draw_pile",
	discard = "recycle_stash",
	pattern = "pattern_row",
}

local function card_id(card)
	return pile_record.id(card)
end

local function snapshot_card(card, pile_id, index)
	if not card or card.REMOVED then return nil end
	local id = card_id(card)
	if id then
		card.id = id
	elseif card.id == nil then
		-- Headless stub cards may omit ids; use pile-local index for store records.
		id = index
		card.id = id
	end
	local slot_index = pile_id == "pattern" and (card.slot_index or index) or index
	return pile_record.from_live_card(card, pile_id, slot_index)
end

local function snapshot_area(area, pile_id)
	local out = {}
	if not area or not area.cards then return out end
	for index, card in ipairs(area.cards) do
		local record = snapshot_card(card, pile_id, index)
		if record then
			if pile_id == "pattern" and record.slot_index then
				out[record.slot_index] = record
			else
				out[#out + 1] = record
			end
		end
	end
	return out
end

local function snapshot_bonus()
	local out = {}
	local bonus = BonusStack
	if bonus and bonus.cards then
		for index, card in ipairs(bonus.cards() or {}) do
			local record = snapshot_card(card, "bonus", index)
			if record then
				out[#out + 1] = record
			end
		end
	end
	return out
end

local function host_for_pile(pile_id)
	local game = shell.game()
	if not game then return nil end
	if pile_id == "pattern" then
		return game.pattern_row and game.pattern_row.area
	end
	return game[PILE_HOST[pile_id]]
end

local function interaction_cards()
	local out = {}
	local game = shell.game()
	if not game or not game.INPUT then return out end
	if game.INPUT.dragging and game.INPUT.dragging.target then
		out[game.INPUT.dragging.target] = true
	end
	if game.INPUT.focused and game.INPUT.focused.target then
		out[game.INPUT.focused.target] = true
	end
	return out
end

local function resolve_live_card(record)
	if not record then return nil end
	if not pile_record.is_record(record) then
		return record
	end
	local want = pile_record.id(record)
	local shell = live_game()
	if not shell or not want then return record end
	for _, card in ipairs(shell.letter_inventory or {}) do
		if card_id(card) == want and not card.REMOVED then
			card.pile_id = record.pile_id or card.pile_id
			card.slot_index = record.slot_index
			return card
		end
	end
	return record
end

--- Dispatch a core MOVE_CARD action and mirror pile_id on a live Card (presentation).
--- Gameplay ownership changes must go through the store reducer, not card.area alone.
function M.move_card(opts)
	if type(opts) ~= "table" then return end
	local id = opts.card_id or card_id(opts.card)
	local store = opts.store or store_ops.store()
	if store and id and opts.to_pile then
		store_ops.dispatch(store, {
			type = "MOVE_CARD",
			card_id = id,
			from_pile = opts.from_pile,
			to_pile = opts.to_pile,
			slot_index = opts.slot_index,
		})
	end
	if opts.card and opts.to_pile then
		opts.card.pile_id = opts.to_pile
		opts.card.slot_index = opts.slot_index
	end
end

function M.collect_piles()
	local game = shell.game()
	if not game then return nil end
	local pattern_host = game.pattern_row and game.pattern_row.area
	return {
		hand = snapshot_area(game.dealt_letters, "hand"),
		draw = snapshot_area(game.draw_pile, "draw"),
		discard = snapshot_area(game.recycle_stash, "discard"),
		pattern = snapshot_area(pattern_host, "pattern"),
		bonus = snapshot_bonus(),
	}
end

local function dispatch_piles(store, piles)
	store_ops.dispatch(store, { type = "SYNC_PILES", piles = piles })
end

---@param store table|nil
---@param pile_ids string[]|nil When set, only these piles are overwritten from host snapshots.
function M.sync_hosts_to_store(store, pile_ids)
	store = store or store_ops.store()
	if not store then return end
	local snapshot = M.collect_piles()
	if not snapshot then return end
	local state = store:get() or {}
	local piles = state.piles or {}
	if pile_ids then
		for _, pile_id in ipairs(pile_ids) do
			piles[pile_id] = snapshot[pile_id] or {}
		end
	else
		piles = snapshot
	end
	dispatch_piles(store, piles)
end

--- Copy resting store cards into empty pile hosts so deal/shuffle can mutate hosts.
---@param pile_ids string[]|nil
function M.hydrate_hosts_from_store(pile_ids)
	local store = store_ops.store()
	if not store then return end
	local state = store:get()
	if not state or not state.piles then return end
	pile_ids = pile_ids or { "hand", "draw", "discard", "pattern" }
	for _, pile_id in ipairs(pile_ids) do
		local host = host_for_pile(pile_id)
		local store_pile = state.piles[pile_id]
		if host and host.emplace and store_pile and pile_record.count(store_pile) > 0 and #(host.cards or {}) == 0 then
			if pile_id == "pattern" then
				for slot_index, record in pairs(store_pile) do
					if type(slot_index) == "number" and record then
						local card = resolve_live_card(record)
						if card then host:emplace(card) end
					end
				end
			else
				for _, record in ipairs(store_pile) do
					local card = resolve_live_card(record)
					if card then host:emplace(card) end
				end
			end
			if host.set_ranks then host:set_ranks() end
		end
	end
end

--- Snapshot hosts to store, then drop resting cards (keep drag/focus in hosts).
---@param store table|nil
---@param pile_ids string[]|nil
function M.release_static_chrome(store, pile_ids)
	store = store or store_ops.store()
	if not store then return end
	pile_ids = pile_ids or { "hand", "draw", "pattern" }
	M.sync_hosts_to_store(store, pile_ids)
	local keep = interaction_cards()
	for _, pile_id in ipairs(pile_ids) do
		local host = host_for_pile(pile_id)
		if host and host.cards then
			local retained = {}
			for _, card in ipairs(host.cards) do
				if keep[card] then
					retained[#retained + 1] = card
				elseif card and card.remove_from_area then
					card:remove_from_area()
				end
			end
			host.cards = retained
			if host.set_ranks then host:set_ranks() end
		end
	end
end

M.resolve_live_card = resolve_live_card

return M
