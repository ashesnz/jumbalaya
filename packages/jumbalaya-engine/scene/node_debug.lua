
local HitOrder = require("jumbalaya-engine.graphics.hit_order")
local shell = require("jumbalaya-engine.shell")
local game = shell.game
return function(Node)
	function Node:draw_boundingrect()
		self.under_overlay = game().under_overlay
		if not game().DEBUG then return end

		local transform = self.drawn or self.VT or self.target or self.T
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
		love.graphics.setLineWidth(1 + (self.states.focused and 1 or 0))
		if self.states.colliding then
			love.graphics.setColor(0, 1, 0, 0.3)
		else
			love.graphics.setColor(1, 0, 0, 0.3)
		end
		if self.states.focusable then
			love.graphics.setColor(game().C.GOLD)
			love.graphics.setLineWidth(1)
		end
		if self.attach and self.attach.dirty then
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
		local root = (self.coord_root and self:coord_root()) or self.container
		if not (root and root ~= self) then return end
		local root_T = root.target or root.T
		local units = game().TILESCALE * game().TILESIZE
		love.graphics.translate(root_T.w * units * 0.5, root_T.h * units * 0.5)
		love.graphics.rotate(root_T.r or 0)
		love.graphics.translate(
			-root_T.w * units * 0.5 + root_T.x * units,
			-root_T.h * units * 0.5 + root_T.y * units)
	end
end
