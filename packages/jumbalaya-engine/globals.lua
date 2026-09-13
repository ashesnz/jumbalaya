--[[
	jumbalaya-engine/globals.lua - Engine class exports + optional _G install for Love2D boot.
]]

local Kind = require("jumbalaya-engine.object")
local Node = require("jumbalaya-engine.scene.node")
local AnimNode = require("jumbalaya-engine.scene.animated.init")
local GfxSprite = require("jumbalaya-engine.graphics.sprite")
local TweenMod = require("jumbalaya-engine.util.tween")
local InputRouter = require("jumbalaya-engine.interaction.router")

local M = {
	Kind = Kind,
	Node = Node,
	AnimNode = AnimNode,
	EaseNode = AnimNode,
	SceneNode = Node,
	GfxSprite = GfxSprite,
	Sprite = GfxSprite,
	Tween = TweenMod.Tween,
	Scheduler = TweenMod.Scheduler,
	InputRouter = InputRouter,
}

--- Install legacy global aliases expected by Love2D boot and card class mixins.
function M.install()
	_G.Kind = M.Kind
	_G.Node = M.Node
	_G.AnimNode = M.AnimNode
	_G.EaseNode = M.EaseNode
	_G.SceneNode = M.SceneNode
	_G.GfxSprite = M.GfxSprite
	_G.Sprite = M.Sprite
	_G.Tween = M.Tween
	_G.Scheduler = M.Scheduler
	_G.InputRouter = M.InputRouter
end

return M
