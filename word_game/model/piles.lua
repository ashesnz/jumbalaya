--[[ word_game/model/piles.lua - Store-authoritative pile sync (Phase 10b) ]]

local BridgeRuntime = require("bridge.runtime")
local game_access = require("word_game.model.game_access")

local M = {}

--- Resting cards render from store piles; pile hosts keep drag/focus cards only.
function M.chrome_release_enabled()
	return true
end

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

function M.sync_hosts_to_store(store)
	store = store or BridgeRuntime.store()
	if not store then return end
	local piles = M.collect_piles()
	if not piles then return end
	store:patch({ piles = piles })
end

--- Snapshot hosts to store, then drop resting cards (keep drag/focus in hosts).
---@param store table|nil
---@param pile_ids string[]|nil
function M.release_static_chrome(store, pile_ids)
	store = store or BridgeRuntime.store()
	if not store then return end
	M.sync_hosts_to_store(store)
	pile_ids = pile_ids or { "hand", "draw", "pattern" }
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
