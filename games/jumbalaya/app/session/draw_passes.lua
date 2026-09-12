--[[ app/session/draw_passes.lua - Jumbalaya draw passes registered on the engine loop ]]

local DrawPasses = require("jumbalaya-engine.session.draw_passes")

local M = {}

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

function M.install()
	DrawPasses.register('board', 'table_hud', function(game)
		local show_background = (not game.OVERLAY_MENU) or (not game.F_HIDE_BG)
		if not show_background then return end

		perf_checkpoint('primitives', 'draw')
		perf_checkpoint('panels', 'draw')

		if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableBoard then
			WORD_GAME_UI.TableBoard.draw_hud()
			if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.draw then
				WORD_GAME_UI.Sidebar.draw()
			end
			WORD_GAME_UI.TableBoard.draw_board(game)
		end

		if WORD_GAME_UI.TableBoard then
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

		if game.STAGE == game.STAGES.MAIN_MENU then
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
			if WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.backdrop_pass then
				WORD_GAME_UI.TradeUI.backdrop_pass()
			end
			draw_with_container(game.OVERLAY_MENU)
		end
		if (show_background or game.OVERLAY_MENU)
			and WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.draw_pass then
			WORD_GAME_UI.TradeUI.draw_pass()
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

		if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableBoard then
			WORD_GAME_UI.TableBoard.draw_card_interaction(game)
		end

		for _, popup in pairs(game.LIVE.POPUP) do draw_with_container(popup) end

		if game.screenwipe then draw_with_container(game.screenwipe) end

		love.graphics.push()
		game.POINTER:translate_container()
		love.graphics.translate(
			-game.POINTER.T.w * game.TILESCALE * game.TILESIZE * 0.5,
			-game.POINTER.T.h * game.TILESCALE * game.TILESIZE * 0.5)
		game.POINTER:draw()
		love.graphics.pop()

		if WORD_GAME_UI.PlayHoldRedraw then
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
