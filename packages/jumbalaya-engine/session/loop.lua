--[[ jumbalaya-engine/session/loop.lua - Engine frame loop and state dispatch ]]

local debug_overlay = require("jumbalaya-engine.debug.overlay")
local Updaters = require("jumbalaya-engine.session.updaters")
local DrawPasses = require("jumbalaya-engine.session.draw_passes")
local Tables = require("jumbalaya-engine.util.tables")
local Node = require("jumbalaya-engine.scene.node")
local perf_checkpoint = require("jumbalaya-engine.adapters.love2d.display").perf_checkpoint

require("jumbalaya-engine.session.frame_updaters")

local default_node_update = Node.update

local function draw_with_container(node)
	love.graphics.push()
	node:translate_container()
	node:draw()
	love.graphics.pop()
end

function Game:update(dt)
	self.FRAMES.TRANSFORM = self.FRAMES.TRANSFORM + 1
	perf_checkpoint("start->discovery", "update")
	Updaters.run("early_frame", self, dt)
	perf_checkpoint("sounds", "update")

	if self.F_VERBOSE and self.real_dt > 0.05 then
		print("LONG DT @ " .. math.floor(self.TIMERS.REAL) .. ": " .. self.real_dt)
	end
	if not self.fbf or self.new_frame then
		self.new_frame = false

		if self.SETTINGS.paused then dt = 0 end

		self.TIME_SCALE = (self.STAGE == self.STAGES.RUN and not self.SETTINGS.paused and not self.screenwipe) and self.SETTINGS.GAMESPEED or 1

		self.TIMERS.TOTAL = self.TIMERS.TOTAL + dt * (self.TIME_SCALE)

		Updaters.run("simulation", self, dt)
		perf_checkpoint("timeline", "update")

		Updaters.run("early_board", self, dt)

		if self.STATE == self.STATES.GAME_OVER then
			self:update_match_end(dt)
		end
		perf_checkpoint("states", "update")

		self.ANIMATIONS = Tables.compact_array(self.ANIMATIONS)

		for _, v in ipairs(self.ANIMATIONS) do
			v:animate(self.real_dt * self.TIME_SCALE)
		end
		perf_checkpoint("animate", "update")

		self.smoothing.xy = math.exp(-38 * self.real_dt)
		self.smoothing.scale = math.exp(-52 * self.real_dt)
		self.smoothing.r = math.exp(-150 * self.real_dt)

		local move_dt = math.min(1 / 20, self.real_dt)

		self.smoothing.max_vel = 58 * move_dt

		self.TRANSFORMS = Tables.compact_array(self.TRANSFORMS)

		for _, v in ipairs(self.TRANSFORMS) do
			if v and v.move and v.FRAME and v.FRAME.TRANSFORM and v.FRAME.TRANSFORM < self.FRAMES.TRANSFORM then
				v:move(move_dt)
			end
		end
		perf_checkpoint("move", "update")

		Updaters.run("late_board", self, dt)

		for _, v in ipairs(self.TRANSFORMS) do
			if not v or not v.update then goto continue_update end
			if v.STATIONARY
				and v.FRAME
				and v.FRAME.TRANSFORM
				and v.FRAME.TRANSFORM >= self.FRAMES.TRANSFORM
				and v.update == default_node_update then
				goto continue_update
			end
			v:update(dt * self.TIME_SCALE)
			if v.states and v.states.collide then
				v.states.collide.is = false
			end
			::continue_update::
		end
		perf_checkpoint("update", "update")
	end

	self.INPUT:update(self.real_dt)
	Updaters.run("post_input", self, self.real_dt)
end

function Game:render_scene_pass()
	for _, node in ipairs(self.SCENE_ROOTS or {}) do
		if not node.REMOVED and not node.parent then
			draw_with_container(node)
		end
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
	perf_checkpoint("canvas", "draw")

	debug_overlay.draw(self)
	DrawPasses.run("present", self)
	perf_checkpoint("debug", "draw")
end

function Game:draw()
	self.FRAMES.RENDER = self.FRAMES.RENDER + 1
	reset_hit_order()
	if (self.HAND_CLEAR_OVERLAY or self.FIRST_PLAY_TUTORIAL_OVERLAY) and not self.OVERLAY_MENU then
		self.under_overlay = true
	end
	perf_checkpoint("start->canvas", "draw")

	if love.graphics and love.graphics.setCanvas and self.CANVAS then love.graphics.setCanvas{ self.CANVAS } end
	if love.graphics and love.graphics.push then love.graphics.push() end
	if love.graphics and love.graphics.scale then love.graphics.scale(self.CANVAS_SCALE) end
	if love.graphics and love.graphics.setShader then love.graphics.setShader() end
	if love.graphics and love.graphics.clear then love.graphics.clear(0, 0, 0, 1) end

	if self.SPLASH_BACK then
		if self.debug_background_toggle then
			love.graphics.clear({ 0, 1, 0, 1 })
		else
			draw_with_container(self.SPLASH_BACK)
		end
	end

	if not self.debug_UI_toggle then
		perf_checkpoint("scene", "draw")
		self:render_scene_pass()
		DrawPasses.run("board", self)
	end

	DrawPasses.run("menu", self)
	DrawPasses.run("chrome", self)
	perf_checkpoint("rest", "draw")
	self:present_frame()
end

function Game:state_col(_state)
	return debug_overlay.state_col(_state)
end
