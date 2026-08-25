--[[ word_game/model/vault.lua - Unique-word bank and Echo tracking ]]

local vault_cfg = require("word_game.config.vault")
local state = require("word_game.model.state")

local M = {}

function M.count()
	local alpha = state.get()
	if not alpha then return 0 end
	return #alpha.vault.order
end

function M.bank(word)
	local alpha = state.get()
	if not alpha or not word or word == "" then
		return { new = false, count = 0, echo = 0, milestone = nil }
	end

	local vault = alpha.vault
	local prior = vault.play_counts[word] or 0
	local is_new = vault.words[word] ~= true

	if is_new then
		vault.words[word] = true
		vault.order[#vault.order + 1] = word
	end
	vault.play_counts[word] = prior + 1

	local milestone = nil
	if is_new then
		local n = #vault.order
		for _, row in ipairs(vault_cfg.MILESTONES) do
			if n == row.words then
				milestone = row
				break
			end
		end
	end

	return {
		new = is_new,
		count = #vault.order,
		echo = prior,
		milestone = milestone,
	}
end

function M.passive()
	return vault_cfg.passive_bonuses(M.count())
end

function M.recent(limit)
	local alpha = state.get()
	if not alpha then return {} end
	limit = limit or 10
	local order = alpha.vault.order
	local out = {}
	local start = math.max(1, #order - limit + 1)
	for i = #order, start, -1 do
		local word = order[i]
		out[#out + 1] = {
			word = word,
			plays = alpha.vault.play_counts[word] or 1,
		}
	end
	return out
end

return M
