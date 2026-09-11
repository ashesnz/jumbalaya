--[[ word_game/ui/sidebar/init.lua - Right-hand match HUD panel ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

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
WordSidebar.relayout = hud_definition.relayout

local function sync_hand_controls()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

local function sidebar_view()
	return views_install.sidebar_view()
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

function WordSidebar:ensure()
	if WordSidebar.is_hidden() then
		self:destroy()
		return nil
	end
	if runtime().STAGE ~= runtime().STAGES.RUN then return end
	local BridgeRuntime = require("app.runtime")
	local engine = BridgeRuntime.engine()
	if engine then
		views_install.install_sidebar(engine)
	end
	if not runtime().ROOM_ATTACH then return end

	local view = sidebar_view()
	if not view then return nil end

	view:ensure_deck_count()
	view:relayout()
	runtime().SIDEBAR_HUD = view
	deck_mod().sync_deck_count_display()
	sync_hand_controls()
	hud_definition.sync_end_run_row()
	table_discard.sync_voucher_counter(true)
	Layout.set_screen_positions()
	return view
end

function WordSidebar:destroy()
	local view = sidebar_view()
	if view and view.remove then
		view:remove()
	end
	runtime().SIDEBAR_HUD = nil
end

function WordSidebar:refresh()
	if WordSidebar.is_hidden() then
		self:destroy()
		return
	end
	if not sidebar_view() then
		if runtime().STATE == runtime().STATES.TABLE_BOARD then
			self:ensure()
		end
		return
	end
	hud_definition.relayout()
end

function WordSidebar:draw()
	if WordSidebar.is_hidden() then return end
	if runtime().STAGE ~= runtime().STAGES.RUN then return end
	local view = sidebar_view()
	if not view then
		self:ensure()
		view = sidebar_view()
	end
	if not view or not view.draw then return end
	if not runtime().SIDEBAR_ATTACH then return end
	love.graphics.push()
	runtime().SIDEBAR_ATTACH:translate_container()
	view:draw()
	love.graphics.pop()
end

function WordSidebar:clear_hand()
	game_access.mutate(function(g)
		if g.word_round then
			g.word_round.played_words = {}
		end
	end)
end

function WordSidebar.ensure_table_board()
	WordSidebar:ensure()
end

function WordSidebar.rebuild()
	if sidebar_view() then
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
