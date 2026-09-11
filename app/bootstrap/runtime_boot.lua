--[[
	app/bootstrap/runtime_boot.lua - Domain shell, card classes, and session hooks.
]]

require "word_game.model.game"
require "word_game.model.cards"
require "word_game.model.game.globals"
require "word_game.ui.util.colour"
require "word_game.ui.util.localize"
require "word_game.model.persistence.progress"
require "app.startup"
require "app.core.persistence.save"
require "app.core.session.loop"

require "word_game.ui.widgets"
require "word_game.ui.cards.popups"
require "word_game.ui.feedback.word_feedback"
require "word_game.ui.overlays"

require "app.effects"
require "word_game.ui.cards.tooltip"

local InputActions = require "app.input_actions"
InputController._input_actions = InputActions

require "app.screen_wipe"
require "app.profile_callbacks"
require "app.callbacks.settings"
require "word_game.model.cards.card"
require("word_game.ui.cards.bind").install()
require "word_game.ui.cardarea.init"

Dictionary = require "dictionary"
WORD_GAME = require "word_game"
require("app.services.app_events")

require "app.callbacks.registry"

DEVTOOLS = require "devtools"

G.consume_board_click = function()
	local ui = WORD_GAME_UI
	if ui and ui.FirstPlayTutorial and ui.FirstPlayTutorial.consume_click() then
		return true
	end
	if ui and ui.PerkStamp and ui.PerkStamp.consume_click() then
		return true
	end
	if ui and ui.SidebarStageButton and ui.SidebarStageButton.consume_click then
		local views_install = require("word_game.ui.views.install")
		local view = views_install.sidebar_view()
		if view and view.consume_click and view:consume_click() then
			return true
		end
	end
	return false
end

local Updaters = require "app.core.session.updaters"
Updaters.register('early_board', 'timeline_fuse', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME.Timeline then
		WORD_GAME.Timeline.update(dt)
	end
end)
Updaters.register('early_board', 'sidebar_stage_button', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.SidebarStageButton then
		WORD_GAME_UI.SidebarStageButton.update(dt)
	end
end)
Updaters.register('early_board', 'table_board', function(game, dt)
	if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI and WORD_GAME_UI.TableBoard then
		WORD_GAME_UI.TableBoard.update(game, dt)
	end
end)
Updaters.register('early_board', 'title_garden_pan', function(game, dt)
	if update_title_garden_pan then
		update_title_garden_pan((game and game.real_dt) or dt)
	end
end)
Updaters.register('late_board', 'table_controls_stabilize', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.stabilize_table_board()
	end
end)
Updaters.register('post_input', 'play_hold_redraw', function(game, dt)
	if WORD_GAME_UI.PlayHoldRedraw then
		WORD_GAME_UI.PlayHoldRedraw.update(dt)
	end
end)
Updaters.register('post_input', 'card_inspect', function(game, dt)
	if WORD_GAME_UI.CardInspect then
		WORD_GAME_UI.CardInspect.update(dt)
	end
end)
Updaters.register('post_input', 'word_feedback_queue', function()
	if G.ARGS and G.ARGS.word_feedback_queue then
		require("word_game.ui.feedback.word_feedback").flush_pending()
	end
end)
Updaters.register('post_input', 'trade_card_fly', function(_, dt)
	if WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.step_card_fly then
		WORD_GAME_UI.TradeUI.step_card_fly(dt)
	end
end)
Updaters.register('post_input', 'perk_stamp', function(_, dt)
	if WORD_GAME_UI.PerkStamp and WORD_GAME_UI.PerkStamp.update then
		WORD_GAME_UI.PerkStamp.update(dt)
	end
end)
