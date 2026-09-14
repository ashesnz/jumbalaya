--[[ app/core/util/tween.lua - timeline events + queue manager ]]

local Kind = require("jumbalaya-engine.object")

local Tween = Kind:derive("Tween")
local Scheduler = Kind:derive("Scheduler")

require("jumbalaya-engine.util.tween_event")(Tween)
require("jumbalaya-engine.util.scheduler")(Scheduler)

return { Tween = Tween, Scheduler = Scheduler }
