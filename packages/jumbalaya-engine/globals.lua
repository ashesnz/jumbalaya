--[[
	jumbalaya-engine/globals.lua - Engine Kind classes + single _G install at boot.

	Modules return class tables; do not assign Kind types to _G at require time.
]]

local Kind = require("jumbalaya-engine.object")
local Node = require("jumbalaya-engine.scene.node")
local AnimNode = require("jumbalaya-engine.scene.animated.init")
local GfxSprite = require("jumbalaya-engine.graphics.sprite")
local GfxAnimator = require("jumbalaya-engine.graphics.sprite_animator")
local TweenMod = require("jumbalaya-engine.util.tween")
local InputRouter = require("jumbalaya-engine.interaction.router")
local RetainedPanel = require("jumbalaya-engine.panels.panel")
local LayoutNode = require("jumbalaya-engine.panels.node")
local ParticleEmitter = require("jumbalaya-engine.graphics.particles")
local FlowText = require("jumbalaya-engine.graphics.flow_text")

local M = {
	Kind = Kind,
	Node = Node,
	AnimNode = AnimNode,
	EaseNode = AnimNode,
	SceneNode = Node,
	GfxSprite = GfxSprite,
	Sprite = GfxSprite,
	GfxAnimator = GfxAnimator,
	SpriteAnimator = GfxAnimator,
	Tween = TweenMod.Tween,
	Scheduler = TweenMod.Scheduler,
	InputRouter = InputRouter,
	InputController = InputRouter,
	RetainedPanel = RetainedPanel,
	LayoutNode = LayoutNode,
	ParticleEmitter = ParticleEmitter,
	Particles = ParticleEmitter,
	FlowText = FlowText,
}

--- Install legacy global aliases expected by Love2D boot, UIBox, and Kind graph checks.
function M.install()
	_G.Kind = M.Kind
	_G.Node = M.Node
	_G.AnimNode = M.AnimNode
	_G.EaseNode = M.EaseNode
	_G.SceneNode = M.SceneNode
	_G.GfxSprite = M.GfxSprite
	_G.Sprite = M.Sprite
	_G.GfxAnimator = M.GfxAnimator
	_G.SpriteAnimator = M.SpriteAnimator
	_G.Tween = M.Tween
	_G.Scheduler = M.Scheduler
	_G.InputRouter = M.InputRouter
	_G.InputController = M.InputController
	_G.RetainedPanel = M.RetainedPanel
	_G.LayoutNode = M.LayoutNode
	_G.ParticleEmitter = M.ParticleEmitter
	_G.Particles = M.Particles
	_G.FlowText = M.FlowText
end

return M
