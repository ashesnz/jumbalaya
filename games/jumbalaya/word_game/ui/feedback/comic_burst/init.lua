--[[
	word_game/ui/feedback/comic_burst/init.lua — Comic starburst geometry behind score popups.
	Inputs: burst centre, elapsed time, scale.
	Outputs: ComicBurst.make/advance/paint; shared by cards and score banner.
]]

local Tables = require("jumbalaya-engine.util.tables")
local NodeTransform = require("jumbalaya-engine.graphics.node_transform")
local HitOrder = require("jumbalaya-engine.graphics.hit_order")
local SceneRoots = require("jumbalaya-engine.scene.roots")
local burst = require("word_game.ui.feedback.comic_burst.burst")

local ComicBurst = EaseNode:derive("ComicBurst")

ComicBurst.make = burst.make
ComicBurst.advance = burst.advance
ComicBurst.paint = burst.paint

function ComicBurst:construct(X, Y, W, H, config)
	config = config or {}
	EaseNode.construct(self, X, Y, W, H)

	local data = ComicBurst.make(config.radius or 0.62)
	self.alpha = data.alpha
	self.age = data.age
	self.pop = data.pop
	self.radius = data.radius
	self.star = data.star
	self.outline = data.outline
	self.shadow = data.shadow
	self.shards = data.shards
	self.dots = data.dots

	if config.attach then
		self:set_alignment({
			major = config.attach,
			type = "cm",
			bond = "Strong",
		})
		table.insert(self.role.major.children, self)
		SceneRoots.set_parent(self, self.role.major)
	end

	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self.states.release_on.can = false
end

function ComicBurst:update(dt)
	ComicBurst.advance(self, dt)
end

function ComicBurst:draw()
	if self.alpha <= 0 then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.setShader()
	NodeTransform.push_node_transform(self, 1)
	love.graphics.translate(self.VT.w / 2, self.VT.h / 2)
	ComicBurst.paint(self)
	love.graphics.pop()

	if prev_shader then
		love.graphics.setShader(prev_shader)
	end
	love.graphics.setColor(cr, cg, cb, ca)

	HitOrder.track_hit_target(self)
	self:draw_boundingrect()
end

function ComicBurst:remove()
	if self.role.major then
		for k, v in pairs(self.role.major.children) do
			if v == self and type(k) == "number" then
				table.remove(self.role.major.children, k)
			end
		end
	end
	Tables.teardown_tree(self.children)
	EaseNode.remove(self)
end

return ComicBurst
