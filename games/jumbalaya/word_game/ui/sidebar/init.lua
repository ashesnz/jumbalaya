--[[ word_game/ui/sidebar/init.lua - Right-hand match HUD panel ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local Layout = require("word_game.ui.layout")
local felt = require("word_game.ui.layout.felt")
local hud_definition = require("word_game.ui.sidebar.hud_definition")
local StageLabel = require("word_game.ui.score_banner.stage_label")
local sidebar_callbacks = require("word_game.ui.sidebar.callbacks")
local table_discard = require("word_game.ui.perks.discard_bin")
local Panels = require("jumbalaya-engine.panels")
local TableDeck = require("word_game.ui.table.deck")

local function deck_mod()
	return facade.deck()
end

local WordSidebar = {}

WordSidebar.roll_to_next_hand = function()
	if WORD_GAME_UI.StageLabel and WORD_GAME_UI.StageLabel.roll_to_next_hand then
		WORD_GAME_UI.StageLabel.roll_to_next_hand()
	elseif StageLabel.roll_to_next_hand then
		StageLabel.roll_to_next_hand()
	end
end
WordSidebar.hud_definition = hud_definition.hud_definition
WordSidebar.relayout = hud_definition.relayout

local function sync_hand_controls()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

local function ensure_uibox_registry(hud)
	local live = game().LIVE
	if not live then return end
	live.UIBOX = live.UIBOX or {}
	for _, panel in pairs(live.UIBOX) do
		if panel == hud then return end
	end
	table.insert(live.UIBOX, hud)
end

local REQUIRED_SIDEBAR_ROWS = {
	"row_sidebar_spacer",
	"row_stamp_slot",
	"row_deck",
	"row_deck_count",
	"row_end_run",
}

function WordSidebar.is_hidden()
	return felt.is_boss_sequence()
end

function WordSidebar.sync_visibility()
	if WordSidebar.is_hidden() then
		WordSidebar:destroy()
	else
		WordSidebar:ensure()
	end
end

local function draw_sidebar_deck()
	if not TableDeck.uses_table_draw() or not game().draw_pile then return end
	local deck_rect = Layout.deck_rect()
	if not deck_rect then return end
	local pile = game().draw_pile
	pile.T.x = deck_rect.x
	pile.T.y = deck_rect.y
	pile.T.w = deck_rect.w
	pile.T.h = deck_rect.h
	if pile.hard_set_T then
		pile:hard_set_T(deck_rect.x, deck_rect.y, deck_rect.w, deck_rect.h)
	end
	TableDeck.draw(pile)
end

function WordSidebar:ensure()
	if WordSidebar.is_hidden() then
		self:destroy()
		return nil
	end
	if game().STAGE ~= game().STAGES.RUN then
		return
	end
	if not game().ROOM_ATTACH then
		return
	end

	if game().SIDEBAR_HUD then
		for _, row_id in ipairs(REQUIRED_SIDEBAR_ROWS) do
			if not game().SIDEBAR_HUD:find_node_by_id(row_id) then
				self:destroy()
				break
			end
		end
	end
	if game().SIDEBAR_HUD then
		deck_mod().sync_deck_count_display()
		sync_hand_controls()
		hud_definition.sync_end_run_row()
		table_discard.sync_voucher_counter(true)
		return game().SIDEBAR_HUD
	end

	Layout.update_sidebar_attach()
	local room = game().ROOM or game().ROOM_ATTACH
	local ok, panel = pcall(Panels.create, {
		definition = hud_definition.hud_definition(),
		config = {
			align = "tri",
			offset = { x = 0, y = 0 },
			major = game().SIDEBAR_ATTACH or game().ROOM_ATTACH,
			wh_bond = "Weak",
		},
	})
	if not ok then
		return nil
	end
	game().SIDEBAR_HUD = panel
	if room and game().SIDEBAR_HUD.set_container then
		game().SIDEBAR_HUD:set_container(room)
	end
	if game().SIDEBAR_HUD.align_to_major then
		game().SIDEBAR_HUD:align_to_major()
	end
	ensure_uibox_registry(game().SIDEBAR_HUD)
	game().SIDEBAR_HUD:recalculate()
	deck_mod().sync_deck_count_display()
	sync_hand_controls()
	hud_definition.sync_end_run_row()
	table_discard.sync_voucher_counter(true)
	Layout.set_screen_positions()
	return game().SIDEBAR_HUD
end

function WordSidebar:destroy()
	if game().SIDEBAR_HUD then
		game().SIDEBAR_HUD:remove()
		game().SIDEBAR_HUD = nil
	end
end

function WordSidebar:refresh()
	if WordSidebar.is_hidden() then
		self:destroy()
		return
	end
	if not game().SIDEBAR_HUD then
		if game().STATE == game().STATES.TABLE_BOARD then
			self:ensure()
		end
		return
	end
	hud_definition.relayout()
end

function WordSidebar:draw()
	if WordSidebar.is_hidden() then return end
	if game().STAGE ~= game().STAGES.RUN then return end
	if game().STATE ~= game().STATES.TABLE_BOARD then return end
	if not game().SIDEBAR_HUD then
		self:ensure()
	end
	local hud = game().SIDEBAR_HUD
	if hud and not hud.REMOVED then
		love.graphics.push()
		hud:translate_container()
		-- Sidebar is drawn through this dedicated path rather than draw_live_uibox,
		-- so the panel's per-frame render cache must be reset to ensure it draws.
		if hud.FRAME then hud.FRAME.RENDER = -1 end
		hud:draw()
		love.graphics.pop()
	end
	if not game().draw_pile then return end
	love.graphics.push()
	game().draw_pile:translate_container()
	draw_sidebar_deck()
	love.graphics.pop()
end

function WordSidebar:clear_hand()
	game_access.dispatch({ type = "ROUND_CLEAR_PLAYED_WORDS" })
end

function WordSidebar.ensure_table_board()
	WordSidebar:ensure()
end

function WordSidebar.rebuild()
	if game().SIDEBAR_HUD then
		hud_definition.relayout()
	else
		WordSidebar:ensure()
	end
end

function WordSidebar.end_run()
	local stage_btn = WORD_GAME_UI.SidebarStageButton
	if stage_btn and stage_btn.press then
		stage_btn.press()
		return
	end
	if WORD_GAME_UI.VoucherDiscard and WORD_GAME_UI.VoucherDiscard.end_run then
		WORD_GAME_UI.VoucherDiscard.end_run()
	end
end

function WordSidebar.classic_stage_next()
	local stage_btn = WORD_GAME_UI.SidebarStageButton
	if stage_btn and stage_btn.collect_and_advance then
		stage_btn.collect_and_advance()
	end
end

function WordSidebar:install()
	sidebar_callbacks.install(self)
end

return function()
	return setmetatable({}, { __index = WordSidebar })
end
