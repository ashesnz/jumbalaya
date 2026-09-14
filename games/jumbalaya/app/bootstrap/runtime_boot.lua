--[[
	app/bootstrap/runtime_boot.lua - Domain shell, card classes, and session hooks.
]]


local Timeline = require("word_game.model.run.timeline")
require("app.bootstrap.kind_globals").install_game()
require "word_game.model.game.globals"
Game()
require "jumbalaya-engine.adapters.love2d.display"
require "word_game.ui.util.colour"
require "word_game.ui.util.localize"
require "word_game.model.persistence.progress"
require "app.startup"
require "app.persistence.save"
require "jumbalaya-engine.session.loop"

require "word_game.ui.widgets"
require "word_game.ui.cards.popups"
local word_feedback = require "word_game.ui.feedback.word_feedback"
require "word_game.ui.overlays"

require "word_game.ui.effects"
require("word_game.ui.effects.easing").install_globals()
require "word_game.ui.cards.tooltip"

local InputActions = require "app.input.actions"

local game = require("app.runtime").game
InputController._input_actions = InputActions

require "word_game.model.cards"
require "app.callbacks.screen_wipe"
require "app.callbacks.profile"
require "app.callbacks.settings"
require("app.bootstrap.kind_globals").install_card_types()

Dictionary = require "dictionary"
WORD_GAME = require "word_game"
require("app.bootstrap.shell_bind").install()
require("app.bootstrap.kind_globals").install_ui_types()

local views_install = require("word_game.ui.views.install")

require "app.callbacks.registry"

DEVTOOLS = require "devtools"

require("app.session.draw_passes").install()

game().consume_board_click = function()
	if WORD_GAME_UI.FirstPlayTutorial.consume_click() then
		return true
	end
	if WORD_GAME_UI.PerkStamp.consume_click() then
		return true
	end
	if WORD_GAME_UI.SidebarStageButton.consume_click then
		local view = views_install.sidebar_view()
		if view and view.consume_click and view:consume_click() then
			return true
		end
	end
	return false
end

local Updaters = require "jumbalaya-engine.session.updaters"
local Runtime = require "word_game.ui.effects.runtime"

Updaters.register('early_frame', 'canvas_juice', function(_, dt)
	Runtime.update_canvas_juice(dt)
end)
Updaters.register('early_board', 'timeline_fuse', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD then
		Timeline.update(dt)
	end
end)
Updaters.register('early_board', 'sidebar_stage_button', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD then
		WORD_GAME_UI.SidebarStageButton.update(dt)
	end
end)
Updaters.register('early_board', 'table_board', function(game, dt)
	if game.STAGE == game.STAGES.RUN and game.STATE == game.STATES.TABLE_BOARD then
		WORD_GAME_UI.TableBoard.update(game, dt)
	end
end)
Updaters.register('early_board', 'title_garden_pan', function(game, dt)
	if update_title_garden_pan then
		update_title_garden_pan((game and game.real_dt) or dt)
	end
end)
Updaters.register('late_board', 'table_controls_stabilize', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD then
		WORD_GAME_UI.TableControls.stabilize_table_board()
	end
end)
Updaters.register('post_input', 'play_hold_redraw', function(game, dt)
	WORD_GAME_UI.PlayHoldRedraw.update(dt)
end)
Updaters.register('post_input', 'card_inspect', function(game, dt)
	WORD_GAME_UI.CardInspect.update(dt)
end)
Updaters.register('post_input', 'word_feedback_queue', function()
	if game().ARGS and game().ARGS.word_feedback_queue then
		word_feedback.flush_pending()
	end
end)
Updaters.register('post_input', 'trade_card_fly', function(_, dt)
	WORD_GAME_UI.TradeUI.step_card_fly(dt)
end)
Updaters.register('post_input', 'perk_stamp', function(_, dt)
	WORD_GAME_UI.PerkStamp.update(dt)
end)
