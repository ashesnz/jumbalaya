--[[
	word_game/ui/effects/init.lua — Package entry for runtime FX (motion, dissolve, canvas juice).
	Inputs: none.
	Outputs: easing, card_motion, menu, runtime, scheduler, status_text module tables.
]]

return {
    easing = require "word_game.ui.effects.easing",
    card_motion = require "word_game.ui.effects.card_motion",
    menu = require "word_game.ui.effects.menu",
    runtime = require "word_game.ui.effects.runtime",
    scheduler = require "jumbalaya-engine.effects.timeline_scheduler",
    status_text = require "word_game.ui.effects.status_text",
}