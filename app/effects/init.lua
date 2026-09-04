--[[ app/effects/init.lua - Jumbalaya runtime effects package ]]

return {
    easing = require "app.effects.easing",
    card_motion = require "app.effects.card_motion",
    menu = require "app.effects.menu",
    runtime = require "app.effects.runtime",
    scheduler = require "app.effects.timeline_scheduler",
    status_text = require "app.effects.status_text",
}