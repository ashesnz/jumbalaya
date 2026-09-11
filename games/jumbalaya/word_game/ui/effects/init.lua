--[[ app/effects/init.lua - Jumbalaya runtime effects package ]]

return {
    easing = require "word_game.ui.effects.easing",
    card_motion = require "word_game.ui.effects.card_motion",
    menu = require "word_game.ui.effects.menu",
    runtime = require "word_game.ui.effects.runtime",
    scheduler = require "word_game.ui.effects.timeline_scheduler",
    status_text = require "word_game.ui.effects.status_text",
}