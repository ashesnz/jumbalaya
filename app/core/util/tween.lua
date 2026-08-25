--[[ app/core/util/tween.lua - timeline events + queue manager ]]

local Kind = require("app.core.object")

Tween = Kind:derive("Tween")
Scheduler = Kind:derive("Scheduler")

require("app.core.util.tween_event")(Tween)
require("app.core.util.scheduler")(Scheduler)

return { Tween = Tween, Scheduler = Scheduler }
