--[[
	word_game/model/piles.lua - Store-authoritative pile sync for CardPile hosts.

	Authoritative table layout lives in `store.piles` (plain card records with
	id / pile_id / slot_index / ability). CardPile hosts (`dealt_letters`,
	`draw_pile`, `pattern_row.area`) are presentation/interaction targets;
	mutate hosts during animation, then `sync_hosts_to_store` or `move_card`.

	Run deck membership (`G.letter_inventory`) is separate: it tracks every live
	letter Card instance in the run; pile placement is always `store.piles`.

	Core: jumbalaya_core.store.reducers.piles + selectors.piles
	Store: patches piles; hydrates hosts from store snapshots
	Presentation: none — CardPile relayout triggered by callers
]]

local BonusStack = require("word_game.model.jumble.bonus_stack")
local BridgeRuntime = require("app.runtime")
local store_sync = require("app.bootstrap.store_sync")

local M = {}

local PILE_HOST = {
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
	local bonus = BonusStack
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

local function host_for_pile(pile_id)
	local shell = BridgeRuntime.game()
	if not shell then return nil end
	if pile_id == "pattern" then
		return shell.pattern_row and shell.pattern_row.area
	end
	return shell[PILE_HOST[pile_id]]
end

local function interaction_cards()
	local out = {}
	local shell = BridgeRuntime.game()
	if not shell or not shell.INPUT then return out end
	if shell.INPUT.dragging and shell.INPUT.dragging.target then
		out[shell.INPUT.dragging.target] = true
	end
	if shell.INPUT.focused and shell.INPUT.focused.target then
		out[shell.INPUT.focused.target] = true
	end
	return out
end

--- Dispatch a core MOVE_CARD action and mirror pile_id on a live Card (presentation).
--- Gameplay ownership changes must go through the store reducer, not card.area alone.
function M.move_card(opts)
	if type(opts) ~= "table" then return end
	local card_id = opts.card_id or (opts.card and (opts.card.id or opts.card.letter_card_id))
	local store = opts.store or BridgeRuntime.store()
	if store and card_id and opts.to_pile then
		store_sync.dispatch(store, {
			type = "MOVE_CARD",
			card_id = card_id,
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
	local shell = BridgeRuntime.game()
	if not shell then return nil end
	local pattern_host = shell.pattern_row and shell.pattern_row.area
	return {
		hand = snapshot_area(shell.dealt_letters, "hand"),
		draw = snapshot_area(shell.draw_pile, "draw"),
		discard = snapshot_area(shell.recycle_stash, "discard"),
		pattern = snapshot_area(pattern_host, "pattern"),
		bonus = snapshot_bonus(),
	}
end

---@param store table|nil
---@param pile_ids string[]|nil When set, only these piles are overwritten from host snapshots.
function M.sync_hosts_to_store(store, pile_ids)
	store = store or BridgeRuntime.store()
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
	store:patch({ piles = piles })
end

--- Copy resting store cards into empty pile hosts so deal/shuffle can mutate hosts.
---@param pile_ids string[]|nil
function M.hydrate_hosts_from_store(pile_ids)
	local store = BridgeRuntime.store()
	if not store then return end
	local state = store:get()
	if not state or not state.piles then return end
	pile_ids = pile_ids or { "hand", "draw", "discard", "pattern" }
	for _, pile_id in ipairs(pile_ids) do
		local host = host_for_pile(pile_id)
		local store_pile = state.piles[pile_id]
		if host and host.emplace and store_pile and #store_pile > 0 and #(host.cards or {}) == 0 then
			for _, card in ipairs(store_pile) do
				host:emplace(card)
			end
			if host.set_ranks then host:set_ranks() end
		end
	end
end

--- Snapshot hosts to store, then drop resting cards (keep drag/focus in hosts).
---@param store table|nil
---@param pile_ids string[]|nil
function M.release_static_chrome(store, pile_ids)
	store = store or BridgeRuntime.store()
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

return M
