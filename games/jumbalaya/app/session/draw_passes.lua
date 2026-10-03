--[[ app/session/draw_passes.lua - Jumbalaya draw passes registered on the engine loop ]]

local DrawPasses = require("jumbalaya-engine.session.draw_passes")
local perf_checkpoint = require("jumbalaya-engine.adapters.love2d.display").perf_checkpoint

local M = {}

local function trade_marketplace_open()
	return WORD_GAME_UI
		and WORD_GAME_UI.TradeUI
		and WORD_GAME_UI.TradeUI.is_open
		and WORD_GAME_UI.TradeUI.is_open()
end

local function draw_with_container(node)
	love.graphics.push()
	node:translate_container()
	node:draw()
	love.graphics.pop()
end

local function draw_spotlight_overlay(game, overlay)
	if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableBoard then
		WORD_GAME_UI.TableBoard.draw_spotlight_overlay(game, overlay)
	end
end

local function draw_live_uibox(game)
	local live = game.LIVE and game.LIVE.UIBOX
	if not live then return end
	for _, panel in pairs(live) do
		if panel.REMOVED then goto continue end
		-- SIDEBAR_HUD draws in WORD_GAME_UI.Sidebar:draw (room transform + deck art).
		if panel == game.SIDEBAR_HUD then goto continue end
		-- Play/shuffle bars draw in TableBoard.draw_table_controls.
		if panel.config and panel.config.instance_type == "table_control_bar" then goto continue end
		local is_special = panel.flop_overlay or panel.spawn_attention or panel.parent
			or panel == game.OVERLAY_MENU or panel == game.screenwipe
			or panel == game.FIRST_PLAY_TUTORIAL_OVERLAY
			or panel == game.debug_tools
		if not is_special then
			draw_with_container(panel)
		end
		::continue::
	end
end

function M.install()
	DrawPasses.register('board', 'table_hud', function(game)
		local show_background = (not game.OVERLAY_MENU) or (not game.F_HIDE_BG)
		if not show_background then return end

		perf_checkpoint('primitives', 'draw')
		draw_live_uibox(game)
		perf_checkpoint('panels', 'draw')

		if not trade_marketplace_open()
			and game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableBoard then
			WORD_GAME_UI.TableBoard.draw_hud()
			if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.draw then
				WORD_GAME_UI.Sidebar:draw()
			end
			WORD_GAME_UI.TableBoard.draw_board(game)
		end

		if WORD_GAME_UI.TableBoard and not trade_marketplace_open() then
			WORD_GAME_UI.TableBoard.draw_reward_passes()
			WORD_GAME_UI.TableBoard.draw_attention_passes(game)
		end

		if game.SPLASH_FRONT then draw_with_container(game.SPLASH_FRONT) end

		game.under_overlay = false
		if game.HAND_CLEAR_OVERLAY then
			game.under_overlay = true
			draw_spotlight_overlay(game, game.HAND_CLEAR_OVERLAY)
		end
	end)

	DrawPasses.register('menu', 'overlays', function(game)
		local show_background = (not game.OVERLAY_MENU) or (not game.F_HIDE_BG)

		if game.STAGE == game.STAGES.MAIN_MENU and not game.OVERLAY_MENU then
			if game.MAIN_MENU_UI and not game.MAIN_MENU_UI.REMOVED then
				draw_with_container(game.MAIN_MENU_UI)
			end
			if game.PROFILE_BUTTON and not game.PROFILE_BUTTON.REMOVED then
				draw_with_container(game.PROFILE_BUTTON)
			end
			if game.MAIN_MENU_VERSION_UI and not game.MAIN_MENU_VERSION_UI.REMOVED then
				draw_with_container(game.MAIN_MENU_VERSION_UI)
			end
		end

		if game.OVERLAY_MENU and game.OVERLAY_MENU ~= game.INPUT.dragging.target then
			draw_with_container(game.OVERLAY_MENU)
		end

		if game.debug_tools and game.debug_tools ~= game.INPUT.dragging.target then
			draw_with_container(game.debug_tools)
		end
	end)

	DrawPasses.register('chrome', 'interaction', function(game)
		game.ALERT_ON_SCREEN = nil
		for _, alert in pairs(game.LIVE.ALERT) do
			draw_with_container(alert)
			game.ALERT_ON_SCREEN = true
		end

		if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableBoard
			and not game.OVERLAY_MENU then
			WORD_GAME_UI.TableBoard.draw_card_interaction(game)
		end

		for _, popup in pairs(game.LIVE.POPUP) do draw_with_container(popup) end

		if game.screenwipe then draw_with_container(game.screenwipe) end

		if trade_marketplace_open() and WORD_GAME_UI.TradeUI.draw_modal_on_top then
			WORD_GAME_UI.TradeUI.draw_modal_on_top()
		end
		if trade_marketplace_open() and WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.draw then
			WORD_GAME_UI.Sidebar:draw()
		end

		love.graphics.push()
		game.POINTER:translate_container()
		love.graphics.translate(
			-game.POINTER.T.w * game.TILESCALE * game.TILESIZE * 0.5,
			-game.POINTER.T.h * game.TILESCALE * game.TILESIZE * 0.5)
		game.POINTER:draw()
		love.graphics.pop()

		if WORD_GAME_UI.PlayHoldRedraw and not trade_marketplace_open() then
			WORD_GAME_UI.PlayHoldRedraw.draw()
		end

		if game.FIRST_PLAY_TUTORIAL_OVERLAY then
			game.under_overlay = true
			draw_spotlight_overlay(game, game.FIRST_PLAY_TUTORIAL_OVERLAY)
		end
	end)

	local atlas_diagnostics = require("app.startup.atlas_diagnostics")
	DrawPasses.register('present', 'atlas_diagnostics', function(_game)
		atlas_diagnostics.draw_overlay()
	end)
end

return M
