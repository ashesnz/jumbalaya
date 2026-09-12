--[[
	word_game/ui/table/deck/ - Draw pile as a pack sitting on the table.

	2.5D table view: cards lie flat, camera looks slightly down from the front.
]]


local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")
local felt = require("word_game.ui.layout.felt")
local geometry = require("word_game.ui.table.deck.geometry")
local draw_pass = require("word_game.ui.table.deck.draw_pass")
local tokens = require("word_game.ui.table.deck.tokens")

local function runtime() return GameRT.game() end

local function deck_mod()
	return facade.deck()
end

local M = {
	SIZE = 0.68,
	MAX_STACK = 0.40,
	LABEL_H = 0.16,
	TOKEN_STACK_H = 0.62,
	TOKEN_DECK_GAP_PX = 14,
	DECK_SLOT_Y_ALIGN = 0.72,
}

tokens.attach(M)

function M.reset()
	tokens.reset(M)
	if WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.reset then
		WORD_GAME_UI.TokenReward.reset()
	end
	if WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.reset then
		WORD_GAME_UI.HandClearFocus.reset()
	end
end

function M.start_token_roll(from, to)
	tokens.start_token_roll(M, from, to)
end

function M.bump_token_display()
	tokens.bump_token_display(M)
end

function M.spend_tokens_display(amount)
	tokens.spend_tokens_display(M, amount)
end

function M.is_token_highlighted()
	return tokens.is_token_highlighted(M)
end

function M.token_count()
	return tokens.token_count(M)
end

function M.update_tokens(dt)
	tokens.update_tokens(M, dt)
end

function M.update(dt, area)
	dt = dt or (runtime() and runtime().real_dt) or 0.016
	M.update_tokens(dt)
end

function M.uses_table_draw()
	if runtime().STATE ~= runtime().STATES.TABLE_BOARD then return false end
	if felt.is_boss_sequence() then return false end
	return true
end

function M.footprint(card_w, card_h)
	return geometry.footprint(card_w, card_h, M)
end

function M.pack_stack_height(card_count)
	return geometry.pack_stack_height(M, card_count)
end

function M.token_center_px(area)
	return draw_pass.token_center_px(M, area)
end

function M.draw(area)
	draw_pass.draw(M, area)
end

function M.show_info()
	if not M.uses_table_draw() or not runtime().draw_pile then return end
	spawn_attention({
		scale = 0.58,
		text = "Cards left: " .. tostring(deck_mod().cards_left()),
		hold = 2.0,
		align = "cm",
		major = runtime().draw_pile,
		offset = { x = 0, y = -0.35 },
		colour = runtime().C.WHITE,
	})
	play_sfx("generic1", 0.88, 0.62)
end

return M
