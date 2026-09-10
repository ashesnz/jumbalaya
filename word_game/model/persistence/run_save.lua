--[[ word_game/model/persistence/run_save.lua - Run snapshot restore and letter inventory ]]

local TableAreas = require("word_game.model.table_areas")

local M = {}

local function inventory_areas()
	return {
		TableAreas.draw_pile(),
		TableAreas.dealt_letters(),
		TableAreas.recycle_stash(),
		TableAreas.pattern_row_area(),
	}
end

function M.rebuild_card_inventory()
	G.letter_inventory = {}
	local seen = {}
	local max_id = 0
	for _, area in ipairs(inventory_areas()) do
		if area and area.cards then
			for _, card in ipairs(area.cards) do
				local id = card.playing_card
				if id and not seen[id] then
					seen[id] = true
					G.letter_inventory[#G.letter_inventory + 1] = card
					if id > max_id then max_id = id end
				end
			end
		end
	end
	G.letter_card_id = max_id
	local draw_pile = TableAreas.draw_pile()
	if draw_pile and draw_pile.config and #G.letter_inventory > 0 then
		draw_pile.config.card_limit = math.max(draw_pile.config.card_limit or 52, #G.letter_inventory)
	end
	if G.GAME then
		G.GAME.starting_deck_size = #G.letter_inventory
	end
end

function M.restore_card_areas(save_table)
	if not save_table or not save_table.cardAreas then return end
	for name, data in pairs(save_table.cardAreas) do
		local key = TableAreas.resolve_save_key(name)
		if key == "pattern_row" then
			local row = TableAreas.pattern_row()
			if row and row.area then
				row.area:load(data)
			end
		else
			local area = G[key]
			if area and area.load then
				area:load(data)
			end
		end
	end
	M.rebuild_card_inventory()
end

function M.append_pattern_row_snapshot(snapshot)
	local row = TableAreas.pattern_row()
	if not row or not row.area then return end
	local serialized = row.area:save()
	if serialized then
		snapshot.cardAreas.pattern_row = serialized
	end
end

return M
