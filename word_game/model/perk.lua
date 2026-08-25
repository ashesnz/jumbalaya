--[[ word_game/model/perk.lua - Perk marketplace offers and selection ]]

local cfg = require("word_game.config.perks")
local state = require("word_game.model.state")

local M = {}

local function rand_float(key)
	if type(advance_seed) == "function" and G and G.GAME and G.GAME.seed_streams then
		return advance_seed(key)
	end
	return math.random()
end

local function rand_int(key, min, max)
	if max <= min then return min end
	local n = max - min + 1
	local idx = min + math.floor(rand_float(key) * n)
	if idx > max then idx = max end
	return idx
end

local function copy_perk(entry)
	return {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
		token_cost = entry.token_cost,
	}
end

function M.roll_offer(count)
	count = count or cfg.DEFAULT_OFFER_COUNT
	local pool = cfg.POOL
	if #pool == 0 then return {} end
	local bag = {}
	for i, entry in ipairs(pool) do
		bag[i] = entry
	end
	local picks = {}
	for i = 1, math.min(count, #bag) do
		local idx = rand_int(cfg.RANDOM_SEED_PREFIX .. i, 1, #bag)
		local picked = copy_perk(bag[idx])
		picked.token_cost = picked.token_cost or cfg.DEFAULT_TOKEN_COST
		picks[#picks + 1] = picked
		table.remove(bag, idx)
	end
	return picks
end

function M.can_afford(perk)
	if not perk then return false end
	return state.tokens() >= (perk.token_cost or 0)
end

function M.purchase(perk)
	if not perk or not perk.id then return false, "Invalid perk" end
	local cost = math.floor(perk.token_cost or 0)
	if cost > 0 and not state.spend_tokens(cost) then
		return false, "Not enough tokens"
	end
	if not M.apply_choice(perk) then
		if cost > 0 then
			state.add_tokens(cost)
		end
		return false, "Could not choose perk"
	end
	return true
end

function M.selected()
	return G.GAME and G.GAME.selected_perk
end

function M.apply_choice(perk)
	if not perk or not perk.id then return false end
	local entry = cfg.by_id(perk.id)
	if not entry then return false end
	local stored = copy_perk(entry)
	if G.GAME then
		G.GAME.selected_perk = stored
	end
	return true
end

function M.apply_showdown_bonus(perk)
	local wr = G.GAME and G.GAME.word_round
	if not wr or not perk then return end
	local bonus = cfg.SHOWDOWN_BONUSES[perk.id]
	if bonus == "plays" then
		wr.plays_left = (wr.plays_left or 0) + 1
		wr.words_left = wr.plays_left
	elseif bonus == "redraws" then
		wr.redraws_left = (wr.redraws_left or 0) + 1
	end
end

function M.pool_candidate(center, used_perks, shop_cards)

	if not center or center.set ~= "Perk" then return false end
	if used_perks and used_perks[center.key] then return false end
	for _, used_key in pairs(center.requires or {}) do
		if not (used_perks and used_perks[used_key]) then return false end
	end
	for _, card in ipairs(shop_cards or {}) do
		if card.config and card.config.center and card.config.center.key == center.key then
			return false
		end
	end
	return true
end

function M.unlock_count(unlock_condition, used_perks)
	if not unlock_condition or not used_perks then return false end
	local count = 0
	for _ in pairs(used_perks) do count = count + 1 end
	return count >= (unlock_condition.extra or math.huge)
end

function M.description_vars(center, profile)
	local condition = center and center.unlock_condition or {}
	local stats = profile and profile.career_stats or {}
	local variables = cfg.DESCRIPTION_VARIABLES[center and center.name]
	if variables then
		local result = { condition.extra }
		for _, key in ipairs(variables) do
			if key == "v_blank" then
				local usage = profile and profile.bonus_usage and profile.bonus_usage[key]
				result[#result + 1] = usage and usage.count or 0
			else
				result[#result + 1] = stats[key]
			end
		end
		return result
	end
	return nil
end

return M
