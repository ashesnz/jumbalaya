--[[
	jumbalaya-engine/scene/animated/attach.lua - Spatial attach: follow / bind / rects.
]]

local SceneRoots = require("jumbalaya-engine.scene.roots")
local DropShadow = require("jumbalaya-engine.graphics.drop_shadow")

return function(Spatial)
	--- Drop-shadow offset is a global constant (no room parallax).
	function Spatial:calculate_parallax()
		self.shadow_parallax = self.shadow_parallax or { x = DropShadow.X, y = DropShadow.Y }
		self.shadow_parallax.x = DropShadow.X
		self.shadow_parallax.y = DropShadow.Y
	end

	function Spatial:set_rect(x, y, w, h)
		local rect = self.target or self.T
		if type(x) == "table" then
			rect.x = x.x or x[1] or rect.x
			rect.y = x.y or x[2] or rect.y
			rect.w = x.w or x[3] or rect.w
			rect.h = x.h or x[4] or rect.h
			if x.r ~= nil then rect.r = x.r end
			if x.scale ~= nil then rect.scale = x.scale end
			return
		end
		if x ~= nil then rect.x = x end
		if y ~= nil then rect.y = y end
		if w ~= nil then rect.w = w end
		if h ~= nil then rect.h = h end
	end

	function Spatial:get_rect()
		return self.target or self.T
	end

	function Spatial:drawn_rect()
		return self.drawn or self.VT
	end

	--- HUD / panel: this node's target origin tracks `host` plus `offset`.
	---@param host table|nil Spatial to follow
	---@param offset {x:number, y:number}|nil
	---@param opts {lock_drawn:boolean}|nil
	function Spatial:follow(host, offset, opts)
		opts = opts or {}
		self.attach = self.attach or {}
		self.attach.mode = host and "follow" or "independent"
		self.attach.host = host
		if offset and type(offset) == "table" and offset.x and offset.y then
			self.attach.offset = { x = offset.x, y = offset.y }
		elseif not self.attach.offset then
			self.attach.offset = { x = 0, y = 0 }
		end
		if opts.lock_drawn ~= nil then
			self.attach.lock_drawn = opts.lock_drawn and true or false
		end
		self.attach.draw_host = host
		self.attach.dirty = true
		SceneRoots.sync(self)
	end

	--- Letter faces: copy the host's drawn rect each tick (drawn by the host).
	function Spatial:bind_to(host)
		self.attach = self.attach or {}
		self.attach.mode = host and "bind" or "independent"
		self.attach.host = host
		self.attach.draw_host = host
		self.attach.offset = self.attach.offset or { x = 0, y = 0 }
		self.attach.lock_drawn = true
		SceneRoots.sync(self)
	end

	function Spatial:unfollow()
		self.attach = self.attach or {}
		self.attach.mode = "independent"
		self.attach.host = nil
		self.attach.draw_host = self
		self.attach.dirty = true
		SceneRoots.sync(self)
	end

	--- Shader / tilt source: bound host, else self.
	function Spatial:draw_host()
		local attach = self.attach
		if attach and attach.draw_host then return attach.draw_host end
		if attach and attach.host then return attach.host end
		return self
	end
end
