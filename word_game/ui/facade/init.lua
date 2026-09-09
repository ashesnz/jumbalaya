--[[
	word_game/ui/facade/init.lua - Cross-package imports for UI (model, board, app).

	UI modules should require this facade instead of deep `word_game.model.*` paths.
	Modules are loaded lazily on first getter access to avoid bootstrap cycles
	(e.g. deck → layout → sidebar → discard_bin → facade).
]]

local M = {}

local cache = {}

local function load(path)
	if not cache[path] then
		cache[path] = require(path)
	end
	return cache[path]
end

function M.placement_word()
	return (WORD_GAME and WORD_GAME.PlacementWord) or load("word_game.model.jumble.placement_word")
end

function M.jumble_rules()
	return (WORD_GAME and WORD_GAME.JumbleRules) or load("word_game.model.jumble_play.jumble_rules")
end

function M.hand_size()
	return (WORD_GAME and WORD_GAME.HandSize) or load("word_game.model.hand_size")
end

function M.board_snap()
	return (WORD_GAME and WORD_GAME.Board and WORD_GAME.Board.Snap) or load("word_game.board.placement.snap")
end

function M.bonus_gutter()
	return (WORD_GAME and WORD_GAME.Board and WORD_GAME.Board.BonusGutter) or load("word_game.board.bonus.gutter")
end

function M.run_mode()
	return load("word_game.model.run.mode")
end

function M.input_lock()
	return (WORD_GAME and WORD_GAME.InputLock) or load("word_game.model.run.input_lock")
end

function M.run_state()
	return load("word_game.model.run.state")
end

function M.match()
	return (WORD_GAME and WORD_GAME.Match) or load("word_game.model.run.match")
end

function M.deck()
	return (WORD_GAME and WORD_GAME.Deck) or load("word_game.model.cards.deck")
end

function M.trade()
	return load("word_game.model.trade")
end

function M.perks_registry()
	return (WORD_GAME and WORD_GAME.Perks and WORD_GAME.Perks.Registry) or load("word_game.model.perks.registry")
end

function M.perks_effects()
	return (WORD_GAME and WORD_GAME.Perks and WORD_GAME.Perks.Effects) or load("word_game.model.perks.effects")
end

function M.feedback()
	return load("word_game.model.feedback")
end

function M.jumble_play()
	return (WORD_GAME and WORD_GAME.Play) or load("word_game.model.jumble_play")
end

function M.slot_topology()
	return load("word_game.model.jumble.slot_topology")
end

function M.bonus_stack()
	return (WORD_GAME and WORD_GAME.BonusStack) or load("word_game.model.jumble.bonus_stack")
end

function M.bonus_stack_ui()
	return WORD_GAME and WORD_GAME.BonusStackUI
end

function M.dissolve_fx()
	return load("app.effects.dissolve_fx")
end

function M.updaters()
	return load("app.core.session.updaters")
end

return M
