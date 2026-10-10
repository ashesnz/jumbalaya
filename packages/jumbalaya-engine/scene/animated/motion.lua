--[[
	jumbalaya-engine/scene/animated/motion.lua - Spatial:tick

	bind → copy host drawn rect
	follow → target from host + offset, then spring (or lock drawn xy)
	independent → spring drawn toward target
]]

local shell = require("jumbalaya-engine.shell")
local game = shell.game

local follow_offset = { x = 0, y = 0 }

return function(Spatial)
	local function mark_settled(self, settled)
		self.settled = settled
		self.STATIONARY = settled
	end

	local function tick_host(node, host, dt)
		if not host or host == node then return end
		if host.tick then
			host:tick(dt)
		elseif host.move then
			host:move(dt)
		end
	end

	local function rects(node)
		return node.target or node.T, node.drawn or node.VT
	end

	local function apply_bind(self, host)
		local T, VT = rects(self)
		local host_T, host_VT = rects(host)
		T.x, T.y, T.w, T.h = host_T.x, host_T.y, host_T.w, host_T.h
		T.r, T.scale = host_T.r, host_T.scale
		local host_w = host_T.w ~= 0 and host_T.w or 1
		VT.x = host_VT.x + (0.5 * (1 - host_VT.w / host_w) * T.w)
		VT.y = host_VT.y
		VT.w, VT.h = host_VT.w, host_VT.h
		VT.r, VT.scale = host_VT.r, host_VT.scale
		self.pinch = host.pinch
		self.shadow_parallax = host.shadow_parallax
		mark_settled(self, host.settled)
	end

	local function apply_follow(self, host, dt)
		tick_host(self, host, dt)
		local off = self.attach.offset or follow_offset
		local T = self.target or self.T
		local host_T = host.target or host.T
		T.x = host_T.x + (off.x or 0)
		T.y = host_T.y + (off.y or 0)

		self:advance_bounce(dt)

		if self.attach.lock_drawn then
			local VT = self.drawn or self.VT
			local host_VT = host.drawn or host.VT
			VT.x = host_VT.x + (off.x or 0)
			VT.y = host_VT.y + (off.y or 0)
		else
			self:move_xy(dt)
		end
		self:move_r(dt, self.velocity)
		self:move_scale(dt)
		self:move_wh(dt)
	end

	--- Layout snap for panel trees (dt = 0): copy follow target without springs.
	function Spatial:snap_to_attach()
		local attach = self.attach
		if not attach or attach.mode == "independent" or not attach.host then
			self:snap_drawn()
			return
		end
		if attach.mode == "bind" then
			apply_bind(self, attach.host)
			return
		end
		local host = attach.host
		local off = attach.offset or follow_offset
		local T, VT = rects(self)
		local host_T, host_VT = rects(host)
		T.x = host_T.x + (off.x or 0)
		T.y = host_T.y + (off.y or 0)
		if attach.lock_drawn then
			VT.x = host_VT.x + (off.x or 0)
			VT.y = host_VT.y + (off.y or 0)
		end
		VT.w, VT.h = T.w, T.h
	end

	function Spatial:tick(dt)
		if self.FRAME.TRANSFORM >= game().FRAMES.TRANSFORM then return end
		self.FRAME.TRANSFORM = game().FRAMES.TRANSFORM
		if not self.moves_while_paused and game().SETTINGS.paused then return end

		self:apply_alignment()

		local attach = self.attach or { mode = "independent" }
		if attach.mode == "bind" and attach.host then
			apply_bind(self, attach.host)
		elseif attach.mode == "follow" and attach.host then
			mark_settled(self, true)
			apply_follow(self, attach.host, dt)
		else
			mark_settled(self, true)
			self:advance_bounce(dt)
			self:move_xy(dt)
			self:move_r(dt, self.velocity)
			self:move_scale(dt)
			self:move_wh(dt)
		end
		if attach then attach.dirty = false end
	end

	Spatial.move = Spatial.tick
end
