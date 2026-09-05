--[[ word_game/ui/sidebar/init.lua - The Vault: right-hand match HUD panel ]]

local Layout = require("word_game.ui.layout")
local hud_definition = require("word_game.ui.sidebar.hud_definition")
local StageLabel = require("word_game.ui.stage_label")
local sidebar_callbacks = require("word_game.ui.sidebar.callbacks")
local deck = require("word_game.model.cards.deck")
local table_discard = require("word_game.ui.table_discard")

local WordSidebar = {}

WordSidebar.roll_to_next_hand = function()
	if WORD_GAME and WORD_GAME.StageLabel and WORD_GAME.StageLabel.roll_to_next_hand then
		WORD_GAME.StageLabel.roll_to_next_hand()
	elseif StageLabel.roll_to_next_hand then
		StageLabel.roll_to_next_hand()
	end
end
WordSidebar.hud_definition = hud_definition.hud_definition
WordSidebar.relayout_vault = hud_definition.relayout_vault
WordSidebar.sync_action_buttons = hud_definition.sync_action_buttons

function WordSidebar.is_hidden()
	local felt = require("word_game.ui.layout.felt")
	return felt.is_boss_sequence()
end

function WordSidebar.sync_visibility()
	if WordSidebar.is_hidden() then
		WordSidebar:destroy()
	else
		WordSidebar:ensure()
	end
end

local REQUIRED_VAULT_ROWS = {
	"row_vault_spacer",
	"row_stamp_slot",
	"row_deck",
	"row_deck_count",
	"row_discard",
}

function WordSidebar:ensure()
	if WordSidebar.is_hidden() then
		self:destroy()
		return nil
	end
	if G.STAGE ~= G.STAGES.RUN then return end
	if not G.ROOM_ATTACH then return end
	if G.VAULT_HUD then
		for _, row_id in ipairs(REQUIRED_VAULT_ROWS) do
			if not G.VAULT_HUD:find_node_by_id(row_id) then
				self:destroy()
				break
			end
		end
	end
	if G.VAULT_HUD then
		deck.sync_deck_count_display()
		WordSidebar.sync_action_buttons()
		hud_definition.sync_discard_row()
		table_discard.sync_discards_left_display(true)
		return G.VAULT_HUD
	end

	Layout.update_vault_attach()
	G.VAULT_HUD = LayoutView({
		definition = WordSidebar.hud_definition(),
		config = {
			align = "tri",
			offset = { x = 0, y = 0 },
			major = G.VAULT_ATTACH or G.ROOM_ATTACH,
			wh_bond = "Weak",
		},
	})
	G.VAULT_HUD:recalculate()
	G.word_sidebar_uibox = G.VAULT_HUD
	hud_definition.sync_discard_row()
	table_discard.sync_discards_left_display(true)
	WordSidebar.sync_action_buttons()
	Layout.set_screen_positions()
	return G.VAULT_HUD
end

function WordSidebar:destroy()
	if G.VAULT_HUD then
		G.VAULT_HUD:remove()
		G.VAULT_HUD = nil
	end
	G.word_sidebar_uibox = nil
end

function WordSidebar:refresh()
	if WordSidebar.is_hidden() then
		self:destroy()
		return
	end
	if not G.VAULT_HUD then
		if G.STATE == G.STATES.TABLE_BOARD then
			self:ensure()
		end
		return
	end
	hud_definition.relayout_vault()
end

function WordSidebar:clear_hand()
	if G.GAME and G.GAME.word_round then
		G.GAME.word_round.played_words = {}
	end
end

function WordSidebar:install()
	sidebar_callbacks.install(self)
end

return function()
	return setmetatable({}, { __index = WordSidebar })
end
