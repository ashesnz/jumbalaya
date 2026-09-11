--[[ word_game/ui/sidebar/init.lua - Right-hand match HUD panel ]]

local facade = require("word_game.ui.facade")
local Layout = require("word_game.ui.layout")
local felt = require("word_game.ui.layout.felt")
local hud_definition = require("word_game.ui.sidebar.hud_definition")
local StageLabel = require("word_game.ui.score_banner.stage_label")
local sidebar_callbacks = require("word_game.ui.sidebar.callbacks")
local table_discard = require("word_game.ui.perks.discard_bin")
local views_install = require("word_game.ui.views.install")
local game_access = require("word_game.model.game_access")

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

local REQUIRED_SIDEBAR_ROWS = {
	"row_sidebar_spacer",
	"row_stamp_slot",
	"row_deck",
	"row_deck_count",
	"row_end_run",
}

function WordSidebar:ensure()
	if WordSidebar.is_hidden() then
		self:destroy()
		return nil
	end
	if G.STAGE ~= G.STAGES.RUN then return end
	local runtime = require("bridge.runtime")
	local engine = runtime.engine()
	if engine then
		views_install.install_sidebar(engine)
	end
	if not G.ROOM_ATTACH then return end
	if G.SIDEBAR_HUD then
		for _, row_id in ipairs(REQUIRED_SIDEBAR_ROWS) do
			if not G.SIDEBAR_HUD:find_node_by_id(row_id) then
				self:destroy()
				break
			end
		end
	end
	if G.SIDEBAR_HUD then
		deck_mod().sync_deck_count_display()
		sync_hand_controls()
		hud_definition.sync_end_run_row()
		table_discard.sync_voucher_counter(true)
		return G.SIDEBAR_HUD
	end

	Layout.update_sidebar_attach()
	G.SIDEBAR_HUD = LayoutView({
		definition = WordSidebar.hud_definition(),
		config = {
			align = "tri",
			offset = { x = 0, y = 0 },
			major = G.SIDEBAR_ATTACH or G.ROOM_ATTACH,
			wh_bond = "Weak",
		},
	})
	G.SIDEBAR_HUD:recalculate()
	hud_definition.sync_end_run_row()
	table_discard.sync_voucher_counter(true)
	sync_hand_controls()
	Layout.set_screen_positions()
	return G.SIDEBAR_HUD
end

function WordSidebar:destroy()
	if G.SIDEBAR_HUD then
		G.SIDEBAR_HUD:remove()
		G.SIDEBAR_HUD = nil
	end
end

function WordSidebar:refresh()
	if WordSidebar.is_hidden() then
		self:destroy()
		return
	end
	if not G.SIDEBAR_HUD then
		if G.STATE == G.STATES.TABLE_BOARD then
			self:ensure()
		end
		return
	end
	hud_definition.relayout()
end

function WordSidebar:clear_hand()
	game_access.mutate(function(g)
		if g.word_round then
			g.word_round.played_words = {}
		end
	end)
end

--- UIBox registration target (`ensure_table_board_sidebar`).
function WordSidebar.ensure_table_board()
	WordSidebar:ensure()
end

--- Relayout or recreate the sidebar HUD (display resize, etc.).
function WordSidebar.rebuild()
	if G.SIDEBAR_HUD then
		hud_definition.relayout()
	else
		WordSidebar:ensure()
	end
end

--- End Run / Next sidebar button press.
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

--- Classic stage Next after target is met.
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
