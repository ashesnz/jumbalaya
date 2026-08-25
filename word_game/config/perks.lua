--[[ word_game/config/perks.lua - Perk pool for the showdown marketplace ]]

local M = {}

M.DEFAULT_OFFER_COUNT = 3
M.DEFAULT_TOKEN_COST = 10
M.RANDOM_SEED_PREFIX = "perk_pick_"

M.SHOWDOWN_BONUSES = {
	extra_play = "plays",
	extra_redraw = "redraws",
}

M.DESCRIPTION_VARIABLES = {
	["Overstock Plus"] = { "c_shop_dollars_spent" },
	["Liquidation"] = {},
	["Glow Up"] = {},
	["Petroglyph"] = {},
	["Retcon"] = {},
	["Palette"] = {},
	["Charm Tycoon"] = { "charms_bought" },
	["Orbit Tycoon"] = { "orbits_bought" },
	["Reroll Glut"] = { "c_shop_rerolls" },
	["Omen Globe"] = { "charm_reading_used" },
	["Observatory"] = { "orbit_wheel_used" },
	["Nacho Tong"] = { "c_cards_played" },
	["Recyclomancy"] = { "c_cards_discarded" },
	["Money Tree"] = { "c_round_interest_cap_streak" },
	["Antimatter"] = { "v_blank" },
	["Illusion"] = { "c_playing_cards_bought" },
}

-- Sprites from resources/textures/{scale}x/Perks.png (71×95 cells, 9×4 grid).
M.POOL = {
    {
        id = "wide_hand",
        name = "Wide Hand",
        desc = "Your hand size is increased to 8 cards.",
        token_cost = 10,
        pos = { x = 0, y = 0 },
    },
	{
        id = "combo_starter",
        name = "Hot Start",
        desc = "Each puzzle starts with a 1.2× multiplier.",
        token_cost = 10,
        pos = { x = 4, y = 0 },
    },
    {
        id = "combo_master",
        name = "Combo Master",
        desc = "Each additional word increases the multiplier by +0.3× instead of +0.2×.",
        token_cost = 10,
        pos = { x = 5, y = 0 },
    },
    {
        id = "combo_keeper",
        name = "Combo Keeper",
        desc = "Banking a puzzle preserves 0.2× of your current multiplier for the next puzzle.",
        token_cost = 10,
        pos = { x = 6, y = 0 },
    },
	{
		id = "letter_boost",
		name = "Letter Boost",
		desc = "High-tier letters score +2 AP.",
		token_cost = 10,
		pos = { x = 2, y = 0 },
	},
	{
		id = "red_rush",
		name = "Red Rush",
		desc = "Red letters score +1 AP.",
		token_cost = 10,
		pos = { x = 3, y = 0 },
	},
	{
		id = "vowel_veil",
		name = "Vowel Veil",
		desc = "Vowels score +2 AP.",
		token_cost = 10,
		pos = { x = 4, y = 0 },
	},
	{
		id = "long_word",
		name = "Long Word",
		desc = "Words of 6+ letters gain +15 AP.",
		token_cost = 10,
		pos = { x = 5, y = 0 },
	},
	{
		id = "extra_redraw",
		name = "Extra Redraw",
		desc = "+1 redraw this showdown.",
		token_cost = 10,
		pos = { x = 6, y = 0 },
	},
	{
		id = "time_bank",
		name = "Time Bank",
		desc = "Banking a solved puzzle restores 2 seconds. But lose 2 seconds for next word",
		token_cost = 10,
		pos = { x = 0, y = 1 },
	},
	{
		id = "speed_demon",
		name = "Speed Demon",
		desc = "Words played within 3 seconds gain +0.2× multiplier.",
		token_cost = 10,
		pos = { x = 1, y = 1 },
	},
	{
		id = "time_saver",
		name = "Time Saver",
		desc = "Every 5 seconds remaining when a stage is cleared grants +5 bonus points.",
		token_cost = 10,
		pos = { x = 2, y = 1 },
	},
	{
		id = "last_second",
		name = "Last Second",
		desc = "Words played with less than 10 seconds remaining gain +50% points.",
		token_cost = 10,
		pos = { x = 3, y = 1 },
	},
	{
    	id = "risky_business",
    	name = "Risky Business",
    	desc = "Words of 6+ letters gain +0.5× multiplier, but words of 3 letters gain -0.2×.",
		token_cost = 10,
    	pos = { x = 0, y = 2 },
    },
    {
    	id = "greedy",
    	name = "Greedy",
    	desc = "If you play 3 or more words on a puzzle, gain +20% points when banking it.",
		token_cost = 10,
    	pos = { x = 1, y = 2 },
    },
}


function M.by_id(id)
	for _, perk in ipairs(M.POOL) do
		if perk.id == id then return perk end
	end
	return nil
end

return M
