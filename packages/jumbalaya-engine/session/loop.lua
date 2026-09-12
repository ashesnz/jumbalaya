--[[ jumbalaya-engine/session/loop.lua - Engine frame loop and state dispatch ]]

local save_queue = require("jumbalaya-engine.persistence.save_queue")
local debug_overlay = require("jumbalaya-engine.debug.overlay")
local Updaters = require("jumbalaya-engine.session.updaters")
local DrawPasses = require("jumbalaya-engine.session.draw_passes")

local function draw_with_container(node)
	love.graphics.push()
	node:translate_container()
	node:draw()
	love.graphics.pop()
end

function Game:update(dt)
	self.FRAMES.TRANSFORM = self.FRAMES.TRANSFORM + 1
	perf_checkpoint('start->discovery', 'update')
	mix_audio(dt)
	perf_checkpoint('sounds', 'update')
	Updaters.run('early_frame', self, dt)
	perf_checkpoint('canvas and bounce', 'update')
	self.TIMERS.REAL = self.TIMERS.REAL + dt
	self.TIMERS.UPTIME = self.TIMERS.UPTIME + dt
	self.SETTINGS.DEMO.total_uptime = (self.SETTINGS.DEMO.total_uptime or 0) + dt
	self.TIMERS.BACKGROUND = self.TIMERS.BACKGROUND + dt*(self.ARGS.spin and self.ARGS.spin.amount or 0)
	self.real_dt = dt

	if self.F_VERBOSE and self.real_dt > 0.05 then
		print('LONG DT @ '..math.floor(self.TIMERS.REAL)..': '..self.real_dt)
	end
	if not self.fbf or self.new_frame then
		self.new_frame = false

		if self.SETTINGS.paused then dt = 0 end

		self.TIME_SCALE = (self.STAGE == self.STAGES.RUN and not self.SETTINGS.paused and not self.screenwipe) and self.SETTINGS.GAMESPEED or 1

		self.TIMERS.TOTAL = self.TIMERS.TOTAL + dt*(self.TIME_SCALE)

		self.C.DARK_FINISH[1] = 0.6+0.2*math.sin(self.TIMERS.REAL*1.3)
		self.C.DARK_FINISH[3] = 0.6+0.2*(1- math.sin(self.TIMERS.REAL*1.3))
		self.C.DARK_FINISH[2] = math.min(self.C.DARK_FINISH[3], self.C.DARK_FINISH[1])

		self.C.FINISH[1] = 0.7+0.2*(1+math.sin(self.TIMERS.REAL*1.5 + 0))
		self.C.FINISH[3] = 0.7+0.2*(1+math.sin(self.TIMERS.REAL*1.5 + 3))
		self.C.FINISH[2] = 0.7+0.2*(1+math.sin(self.TIMERS.REAL*1.5 + 6))

		self.TIMELINE:advance(self.real_dt)
		perf_checkpoint('timeline', 'update')

		Updaters.run('early_board', self, dt)

		if self.STATE == self.STATES.GAME_OVER then
			self:update_match_end(dt)
		end
		perf_checkpoint('states', 'update')

		compact_array(self.ANIMATIONS)

		for k, v in pairs(self.ANIMATIONS) do
			v:animate(self.real_dt*self.TIME_SCALE)
		end
		perf_checkpoint('animate', 'update')

		self.smoothing.xy = math.exp(-38*self.real_dt)
		self.smoothing.scale = math.exp(-52*self.real_dt)
		self.smoothing.r = math.exp(-150*self.real_dt)

		local move_dt = math.min(1/20, self.real_dt)

		self.smoothing.max_vel = 58*move_dt

		for k, v in ipairs(self.TRANSFORMS) do
			if v and v.move and v.FRAME and v.FRAME.TRANSFORM and v.FRAME.TRANSFORM < self.FRAMES.TRANSFORM then v:move(move_dt) end
		end
		perf_checkpoint('move', 'update')

		Updaters.run('late_board', self, dt)

		for k, v in pairs(self.TRANSFORMS) do
			if v and v.update then
				v:update(dt*self.TIME_SCALE)
				if v.states and v.states.collide then
					v.states.collide.is = false
				end
			end
		end
		perf_checkpoint('update', 'update')
	end

	self.INPUT:update(self.real_dt)
	Updaters.run('post_input', self, self.real_dt)

	if self.STEAM and self.STEAM.send_control.update_queued and (
		self.STEAM.send_control.force or
		self.STEAM.send_control.last_sent_stage ~= self.STAGE or
		self.STEAM.send_control.last_sent_time < self.TIMERS.UPTIME - 120) then
		if self.STEAM.userStats.storeStats() then
			self.STEAM.send_control.force = false
			self.STEAM.send_control.last_sent_stage = self.STAGE
			self.STEAM.send_control.last_sent_time = self.TIMERS.UPTIME
			self.STEAM.send_control.update_queued = false
		else
			self.DEBUG_VALUE = 'UNABLE TO STORE STEAM STATS'
		end
	end

	save_queue.update()
end

function Game:render_scene_pass()
	for _, node in pairs(self.LIVE.NODE) do
		if not node.parent then draw_with_container(node) end
	end
	for _, node in pairs(self.LIVE.TRANSFORM) do
		if not node.parent then draw_with_container(node) end
	end
	if self.SPLASH_LOGO then draw_with_container(self.SPLASH_LOGO) end
end

function Game:present_frame()
	if love.graphics and love.graphics.pop then love.graphics.pop() end
	if love.graphics and love.graphics.setCanvas then love.graphics.setCanvas() end
	if love.graphics and love.graphics.push then love.graphics.push() end
	if love.graphics and love.graphics.scale then love.graphics.scale(1 / self.CANVAS_SCALE) end
	if love.graphics and love.graphics.setColor then love.graphics.setColor(self.C.WHITE) end

	if self.CANVAS then
		love.graphics.draw(self.CANVAS, 0, 0)
	end
	love.graphics.pop()

	love.graphics.setShader()
	perf_checkpoint('canvas', 'draw')

	debug_overlay.draw(self)
	DrawPasses.run('present', self)
	perf_checkpoint('debug', 'draw')
end

function Game:draw()
	self.FRAMES.RENDER = self.FRAMES.RENDER + 1
	reset_hit_order()
	if (self.HAND_CLEAR_OVERLAY or self.FIRST_PLAY_TUTORIAL_OVERLAY) and not self.OVERLAY_MENU then
		self.under_overlay = true
	end
	perf_checkpoint('start->canvas', 'draw')

	if love.graphics and love.graphics.setCanvas and self.CANVAS then love.graphics.setCanvas{self.CANVAS} end
	if love.graphics and love.graphics.push then love.graphics.push() end
	if love.graphics and love.graphics.scale then love.graphics.scale(self.CANVAS_SCALE) end
	if love.graphics and love.graphics.setShader then love.graphics.setShader() end
	if love.graphics and love.graphics.clear then love.graphics.clear(0, 0, 0, 1) end

	if self.SPLASH_BACK then
		if self.debug_background_toggle then
			love.graphics.clear({0, 1, 0, 1})
		else
			draw_with_container(self.SPLASH_BACK)
		end
	end

	if not self.debug_UI_toggle then
		perf_checkpoint('scene', 'draw')
		self:render_scene_pass()
		DrawPasses.run('board', self)
	end

	DrawPasses.run('menu', self)
	DrawPasses.run('chrome', self)
	perf_checkpoint('rest', 'draw')
	self:present_frame()
end

function Game:state_col(_state)
	return debug_overlay.state_col(_state)
end
