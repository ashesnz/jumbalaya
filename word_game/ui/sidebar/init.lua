--[[ word_game/ui/sidebar/init.lua - The Vault: right-hand match HUD panel ]]

local LetterTile = require("word_game.ui.letter_tile")
local Layout = require("word_game.ui.layout")
local hud_definition = require("word_game.ui.sidebar.hud_definition")
local hand_progress = require("word_game.ui.sidebar.hand_progress")
local sidebar_callbacks = require("word_game.ui.sidebar.callbacks")

local WordSidebar = {}

WordSidebar.roll_plays = hand_progress.roll_plays
WordSidebar.roll_to_next_hand = hand_progress.roll_to_next_hand
WordSidebar.hud_definition = hud_definition.hud_definition
WordSidebar.list_nodes = hud_definition.list_nodes
WordSidebar.list_definition = hud_definition.list_definition
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

function WordSidebar:refresh_list()
	if G.STATE ~= G.STATES.TABLE_BOARD then
		self:destroy()
		return
	end
	self:destroy()
	self:ensure()
end

function WordSidebar:ensure()
	if WordSidebar.is_hidden() then
		self:destroy()
		return nil
	end
	if G.STAGE ~= G.STAGES.RUN then return end
	if not G.ROOM_ATTACH then return end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("row_vault_spacer") then
		self:destroy()
	end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("row_stamp_slot") then
		self:destroy()
	end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("row_hand_progress") then
		self:destroy()
	end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("hand_progress_odometer") then
		self:destroy()
	end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("row_deck") then
		self:destroy()
	end
	if G.VAULT_HUD and not G.VAULT_HUD:find_node_by_id("row_deck_count") then
		self:destroy()
	end
	if G.VAULT_HUD then
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
	WordSidebar.sync_action_buttons()
	Layout.set_screen_positions()
	return G.VAULT_HUD
end

function WordSidebar:destroy()
	if G.VAULT_LIST then
		G.VAULT_LIST:remove()
		G.VAULT_LIST = nil
	end
	if G.VAULT_HUD then
		G.VAULT_HUD:remove()
		G.VAULT_HUD = nil
	end
	hand_progress.reset()
	G.word_sidebar_uibox = nil
end

function WordSidebar:add_play(word, score, cards, result)
	G.GAME.table_word_history = G.GAME.table_word_history or {}
	table.insert(G.GAME.table_word_history, {
		word = word,
		score = score,
		cards = LetterTile.snapshot_cards(cards),
		echo = result and result.echo or 0,
	})
	local round = require("word_game.model.round")
	round.record_word_play(word)
	self:refresh()
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
	self:refresh_list()
end

function WordSidebar:clear()
	G.GAME.table_word_history = {}
	if G.GAME and G.GAME.word_round then
		G.GAME.word_round.played_words = {}
	end
	self:refresh()
end

function WordSidebar:clear_hand()
	G.GAME.table_word_history = {}
	if G.GAME and G.GAME.word_round then
		G.GAME.word_round.played_words = {}
	end
	self:refresh()
end

function WordSidebar:install()
	sidebar_callbacks.install(self)
end

return function()
	return setmetatable({}, { __index = WordSidebar })
end
