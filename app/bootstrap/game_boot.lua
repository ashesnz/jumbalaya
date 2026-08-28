--[[
	app/bootstrap/game_boot.lua - Game class extensions, shell, and domain facade.
]]

require "word_game.model.game"
require "word_game.model.cards"
require "word_game.model.globals"
require "app.startup"
require "app.core.persistence.save"
require "app.core.session.loop"

require "word_game.ui.widgets"
require "word_game.ui.card_popups"
require "word_game.ui.fx"
require "word_game.ui.overlays"
require "word_game.ui.stats"
require "word_game.ui.collection"

require "app.effects"
require "word_game.ui.card_tooltip"

local InputActions = require "app.input_actions"
InputController._input_actions = InputActions

require "app.screen_wipe"
require "app.profile_callbacks"
require "app.callbacks.settings"
require "word_game.ui.placement_controls"

require "word_game.model.cards.card"
require "word_game.ui.cardarea"

Dictionary = require "dictionary"
WORD_GAME = require "word_game"

require "app.callbacks.registry"

DEVTOOLS = require "devtools"

-- Per-frame hook registration (keeps Game:update free of hard-coded calls).
local Updaters = require "app.core.session.updaters"
Updaters.register('early_board', 'table_board', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME and WORD_GAME.TableBoard then
		WORD_GAME.TableBoard.update(game, dt)
	end
end)
Updaters.register('late_board', 'hand_shuffle_stabilize', function(game, dt)
	if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.stabilize_table_board()
	end
end)
Updaters.register('post_input', 'play_hold_redraw', function(game, dt)
	if WORD_GAME and WORD_GAME.PlayHoldRedraw then
		WORD_GAME.PlayHoldRedraw.update(dt)
	end
end)
Updaters.register('post_input', 'card_inspect', function(game, dt)
	if WORD_GAME and WORD_GAME.CardInspect then
		WORD_GAME.CardInspect.update(dt)
	end
end)
Updaters.register('post_input', 'trade_card_fly', function(_, dt)
	if WORD_GAME and WORD_GAME.TradeUI and WORD_GAME.TradeUI.step_card_fly then
		WORD_GAME.TradeUI.step_card_fly(dt)
	end
end)
Updaters.register('post_input', 'perk_stamp', function(_, dt)
	if WORD_GAME and WORD_GAME.PerkStamp and WORD_GAME.PerkStamp.update then
		WORD_GAME.PerkStamp.update(dt)
	end
end)
