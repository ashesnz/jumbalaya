
local HitOrder = require("jumbalaya-engine.graphics.hit_order")
local shell = require("jumbalaya-engine.shell")
local game = shell.game
return function(Node)
	function Node:draw_boundingrect()
		self.under_overlay = game().under_overlay
		if not game().DEBUG then return end

		local transform = self.VT or self.T
		local px_w, px_h = transform.w * game().TILESIZE, transform.h * game().TILESIZE
		love.graphics.push()
		love.graphics.scale(game().TILESCALE, game().TILESCALE)
		love.graphics.translate(transform.x * game().TILESIZE + px_w * 0.5, transform.y * game().TILESIZE + px_h * 0.5)
		love.graphics.rotate(transform.r)
		love.graphics.translate(-px_w * 0.5, -px_h * 0.5)
		if self.DEBUG_VALUE then
			love.graphics.setColor(1, 1, 0, 1)
			love.graphics.print(self.DEBUG_VALUE, px_w, px_h, nil, 1 / game().TILESCALE)
		end
		love.graphics.setLineWidth(1 + (self.states.focus.is and 1 or 0))
		if self.states.collide.is then
			love.graphics.setColor(0, 1, 0, 0.3)
		else
			love.graphics.setColor(1, 0, 0, 0.3)
		end
		if self.states.focus.can then
			love.graphics.setColor(game().C.GOLD)
			love.graphics.setLineWidth(1)
		end
		if self.CALCING then
			love.graphics.setColor({ 0, 0, 1, 1 })
			love.graphics.setLineWidth(3)
		end
		love.graphics.rectangle("line", 0, 0, px_w, px_h, 3)
		love.graphics.pop()
	end

	function Node:draw()
		self:draw_boundingrect()
		if self.states.visible then
			HitOrder.track_hit_target(self)
			for _, child in pairs(self.children) do child:draw() end
		end
	end

	function Node:translate_container()
		if not (self.container and self.container ~= self) then return end
		local container, units = self.container, game().TILESCALE * game().TILESIZE
		love.graphics.translate(container.T.w * units * 0.5, container.T.h * units * 0.5)
		love.graphics.rotate(container.T.r)
		love.graphics.translate(
			-container.T.w * units * 0.5 + container.T.x * units,
			-container.T.h * units * 0.5 + container.T.y * units)
	end
end
