--[[
	jumbalaya-engine - Portable Love2D engine (scene, input, panels, services).
]]

local Panels = require("jumbalaya-engine.panels")

return {
	Boot = require("jumbalaya-engine.boot"),
	Shell = require("jumbalaya-engine.shell"),
	Kind = require("jumbalaya-engine.object"),
	Scene = {
		Node = require("jumbalaya-engine.scene.node"),
		AnimNode = require("jumbalaya-engine.scene.animated.init"),
	},
	Context = require("jumbalaya-engine.services.context"),
	Renderer = require("jumbalaya-engine.services.renderer"),
	InputService = require("jumbalaya-engine.services.input"),
	AudioService = require("jumbalaya-engine.services.audio"),
	Clock = require("jumbalaya-engine.services.clock"),
	EventBus = require("jumbalaya-engine.services.event_bus"),
	Adapters = require("jumbalaya-engine.adapters.love2d"),
	Views = {
		LetterCardView = require("jumbalaya-engine.views.letter_card_view"),
		PileView = require("jumbalaya-engine.views.pile_view"),
	},
	Panels = Panels,
	ViewHost = Panels.ViewHost,
}
