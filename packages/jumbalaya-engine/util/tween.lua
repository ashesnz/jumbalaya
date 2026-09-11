--[[ app/core/util/tween.lua - timeline events + queue manager ]]

local Kind = require("jumbalaya-engine.object")

Tween = Kind:derive("Tween")
Scheduler = Kind:derive("Scheduler")

require("jumbalaya-engine.util.tween_event")(Tween)
require("jumbalaya-engine.util.scheduler")(Scheduler)

return { Tween = Tween, Scheduler = Scheduler }
