--[[
	word_game/ui/feedback/modifier_feedback.lua — Floating letter-modifier hint above a placed card.
	Inputs: card T, modifier id from deck/perk rules.
	Outputs: show_above_card(card) during pattern-row placement.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")

local function deck_api()
	return facade.deck()
end

local M = {}

local DEFAULT_COLOUR = { 1, 0.85, 0.2, 1 }

function M.show_on_placed_card(card)
	if not card then return end
	if not deck_api().is_modified(card) then return end
	local text = deck_api().modifier_ui_text(deck_api().card_letter(card))
	if not text then return end
	local FloatUp = WORD_GAME_UI.FloatUpText
	if not FloatUp or not FloatUp.from_card_above then return end
	FloatUp.from_card_above(card, text, {
		colour = runtime().C and runtime().C.GOLD or DEFAULT_COLOUR,
		font_px = 26,
		life = 1.35,
		speed = 1.2,
	})
end

return M
