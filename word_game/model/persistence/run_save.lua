--[[ word_game/model/persistence/run_save.lua - Run snapshot store state and card inventory ]]

local live_game = require("word_game.model.live_game")

local TableAreas = require("word_game.model.table_areas")
local game_access = require("word_game.model.game_access")
local store_sync = require("bridge.store_sync")
local BridgeRuntime = require("bridge.runtime")

local M = {}

function M.rebuild_card_inventory()
	live_game().letter_inventory = {}
	local seen = {}
	local max_id = 0
	local piles = {
		TableAreas.hand_cards(),
		TableAreas.draw_cards(),
		TableAreas.recycle_cards(),
		TableAreas.pattern_cards(),
		TableAreas.bonus_cards(),
	}
	for _, cards in ipairs(piles) do
		if cards then
			for _, card in ipairs(cards) do
				local id = card.letter_card_id or card.id
				if id and not seen[id] then
					seen[id] = true
					live_game().letter_inventory[#live_game().letter_inventory + 1] = card
					if id > max_id then max_id = id end
				end
			end
		end
	end
	live_game().letter_card_id = max_id
	local draw_pile = TableAreas.draw_pile()
	if draw_pile and draw_pile.config and #live_game().letter_inventory > 0 then
		draw_pile.config.card_limit = math.max(draw_pile.config.card_limit or 52, #live_game().letter_inventory)
	end
	game_access.patch({ starting_deck_size = #live_game().letter_inventory })
end

function M.restore_card_areas(save_table)
	if not save_table then return end
	if save_table.store then
		local store = BridgeRuntime.store()
		if store then
			store_sync.restore_snapshot(store, save_table.store)
		end
	elseif save_table.cardAreas then
		local store_piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} }
		for name, data in pairs(save_table.cardAreas) do
			local key = TableAreas.resolve_save_key(name)
			local pile_name = "hand"
			if key == "draw_pile" or key == "deck" then pile_name = "draw"
			elseif key == "recycle_stash" or key == "discard" then pile_name = "discard"
			elseif key == "pattern_row" or key == "placement_table" then pile_name = "pattern"
			elseif key == "dealt_letters" or key == "hand" then pile_name = "hand"
			end
			if data and data.cards then
				for _, cdata in ipairs(data.cards) do
					local card = {
						id = cdata.state and cdata.state.letter_card_id or 0,
						letter = cdata.state and cdata.state.ability and cdata.state.ability.letter or "A",
						pile_id = pile_name,
						ability = cdata.state and cdata.state.ability or {},
						config = cdata.refs or {},
					}
					if cdata.state then
						for k, v in pairs(cdata.state) do card[k] = v end
					end
					table.insert(store_piles[pile_name], card)
				end
			end
			if key == "pattern_row" then
				local row = TableAreas.pattern_row()
				if row and row.area and row.area.load then
					row.area:load(data)
				end
			else
				local area = live_game()[key]
				if area and area.load then
					area:load(data)
				end
			end
		end
		local store = BridgeRuntime.store()
		if store then
			store:patch({ piles = store_piles })
		end
	end
	M.rebuild_card_inventory()
end

function M.append_pattern_row_snapshot(snapshot)
	local store = BridgeRuntime.store()
	if store then
		snapshot.store = store:get()
	else
		snapshot.store = {
			GAME = game_access.get(),
			piles = {
				hand = TableAreas.hand_cards(),
				draw = TableAreas.draw_cards(),
				discard = TableAreas.recycle_cards(),
				pattern = TableAreas.pattern_cards(),
				bonus = TableAreas.bonus_cards(),
			}
		}
	end
end

return M
