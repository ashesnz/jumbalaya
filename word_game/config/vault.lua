--[[ word_game/config/vault.lua - Unique-word milestone bonuses ]]

local M = {
	MILESTONES = {
		{ words = 5,   kind = "boost", amount = 1,  label = "+1 Boost, all words" },
		{ words = 15,  kind = "ap",    amount = 5,  label = "+5 AP, all words" },
		{ words = 30,  kind = "boost", amount = 2,  label = "+2 Boost, all words" },
		{ words = 50,  kind = "ap",    amount = 8,  label = "+8 AP, all words" },
		{ words = 75,  kind = "ap",    amount = 10, label = "+10 AP, all words" },
		{ words = 100, kind = "perk",  amount = 1,  label = "Legendary Perk pick" },
	},
}

function M.passive_bonuses(word_count)
	local ap, boost = 0, 0
	local legendary_perk = false
	for _, row in ipairs(M.MILESTONES) do
		if word_count >= row.words then
			if row.kind == "ap" then
				ap = ap + row.amount
			elseif row.kind == "boost" then
				boost = boost + row.amount
			elseif row.kind == "perk" then
				legendary_perk = true
			end
		end
	end
	return {
		ap = ap,
		boost = boost,
		legendary_perk = legendary_perk,
	}
end

function M.next_milestone(word_count)
	for _, row in ipairs(M.MILESTONES) do
		if word_count < row.words then
			return row
		end
	end
	return nil
end

return M
