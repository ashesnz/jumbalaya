--[[
	app/core/session/loop.lua - Engine frame loop and state dispatch.
]]

local save_queue = require "app.core.session.loop.save_queue"
local debug_overlay = require "app.core.session.loop.debug_overlay"
local Runtime = require "app.effects.runtime"
local Updaters = require "app.core.session.updaters"

function Game:update(dt)
	G.FRAMES.TRANSFORM = G.FRAMES.TRANSFORM + 1
	perf_checkpoint('start->discovery', 'update')
	mix_audio(dt)
	perf_checkpoint('sounds', 'update')
	Runtime.update_canvas_juice(dt)
	perf_checkpoint('canvas and bounce', 'update')
	self.TIMERS.REAL = self.TIMERS.REAL + dt
	self.TIMERS.UPTIME = self.TIMERS.UPTIME + dt
	self.SETTINGS.DEMO.total_uptime = (self.SETTINGS.DEMO.total_uptime or 0) + dt
	self.TIMERS.BACKGROUND = self.TIMERS.BACKGROUND + dt*(G.ARGS.spin and G.ARGS.spin.amount or 0)
	self.real_dt = dt

	if G.F_VERBOSE and self.real_dt > 0.05 then
		print('LONG DT @ '..math.floor(G.TIMERS.REAL)..': '..self.real_dt)
	end
	if not G.fbf or G.new_frame then
		G.new_frame = false

		if G.SETTINGS.paused then dt = 0 end

		self.TIME_SCALE = (G.STAGE == G.STAGES.RUN and not G.SETTINGS.paused and not G.screenwipe) and self.SETTINGS.GAMESPEED or 1

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

		G.smoothing.xy = math.exp(-38*self.real_dt)
		G.smoothing.scale = math.exp(-52*self.real_dt)
		G.smoothing.r = math.exp(-150*self.real_dt)

		local move_dt = math.min(1/20, self.real_dt)

		G.smoothing.max_vel = 58*move_dt

		for k, v in ipairs(self.TRANSFORMS) do
			if v and v.move and v.FRAME and v.FRAME.TRANSFORM and v.FRAME.TRANSFORM < G.FRAMES.TRANSFORM then v:move(move_dt) end
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

	if G.STEAM and G.STEAM.send_control.update_queued and (
		G.STEAM.send_control.force or
		G.STEAM.send_control.last_sent_stage ~= G.STAGE or
		G.STEAM.send_control.last_sent_time < G.TIMERS.UPTIME - 120) then
		if G.STEAM.userStats.storeStats() then
			G.STEAM.send_control.force = false
			G.STEAM.send_control.last_sent_stage = G.STAGE
			G.STEAM.send_control.last_sent_time = G.TIMERS.UPTIME
			G.STEAM.send_control.update_queued = false
		else
			G.DEBUG_VALUE = 'UNABLE TO STORE STEAM STATS'
		end
	end

	save_queue.update()
end

function Game:draw_spotlight_overlay(overlay)
	if WORD_GAME and WORD_GAME.TableBoard then
		WORD_GAME.TableBoard.draw_spotlight_overlay(self, overlay)
	end
end

-- Draws one node with its container transform applied.
local function draw_with_container(node)
	love.graphics.push()
	node:translate_container()
	node:draw()
	love.graphics.pop()
end

--- Scene pass: rootless scene nodes, transforms, and the splash logo.
function Game:render_scene_pass()
	for _, node in pairs(self.LIVE.NODE) do
		if not node.parent then draw_with_container(node) end
	end
	for _, node in pairs(self.LIVE.TRANSFORM) do
		if not node.parent then draw_with_container(node) end
	end
	if G.SPLASH_LOGO then draw_with_container(G.SPLASH_LOGO) end
end

--- Board pass: free panels, the table HUD/board, reward + attention layers,
--- the splash front, and any active spotlight overlays.
--  Skipped entirely when the debug UI toggle hides gameplay rendering.
function Game:render_board_pass()
	local show_background = (not self.OVERLAY_MENU) or (not self.F_HIDE_BG)
	if not show_background then return end

	perf_checkpoint('primitives', 'draw')
	for _, panel in pairs(self.LIVE.UIBOX) do
		local is_special = panel.flop_overlay or panel.spawn_attention or panel.parent
			or panel == self.OVERLAY_MENU or panel == self.screenwipe
			or panel == self.OVERLAY_TUTORIAL or panel == self.INTRO_OVERLAY
			or panel == self.debug_tools or panel == self.online_leaderboard
			or panel == self.achievement_notification
		if not is_special then draw_with_container(panel) end
	end
	perf_checkpoint('panels', 'draw')

	if self.placement_table and WORD_GAME and WORD_GAME.TableBoard then
		WORD_GAME.TableBoard.draw_hud()
		WORD_GAME.TableBoard.draw_board(self)
	end

	if WORD_GAME and WORD_GAME.TableBoard then
		WORD_GAME.TableBoard.draw_reward_passes()
		WORD_GAME.TableBoard.draw_attention_passes(self)
	end

	if G.SPLASH_FRONT then draw_with_container(G.SPLASH_FRONT) end

	G.under_overlay = false
	if self.OVERLAY_TUTORIAL then self:draw_spotlight_overlay(self.OVERLAY_TUTORIAL) end
	if self.INTRO_OVERLAY then self:draw_spotlight_overlay(self.INTRO_OVERLAY) end
	if self.HAND_CLEAR_OVERLAY then
		G.under_overlay = true
		self:draw_spotlight_overlay(self.HAND_CLEAR_OVERLAY)
	end
end

--- Menu pass: the active overlay menu (unless being dragged), the marketplace
--- trade layer, and the devtools panel. Runs even when the background is hidden.
function Game:render_menu_pass()
	local show_background = (not self.OVERLAY_MENU) or (not self.F_HIDE_BG)

	if self.OVERLAY_MENU and self.OVERLAY_MENU ~= self.INPUT.dragging.target then
		if WORD_GAME and WORD_GAME.TradeUI and WORD_GAME.TradeUI.backdrop_pass then
			WORD_GAME.TradeUI.backdrop_pass()
		end
		draw_with_container(self.OVERLAY_MENU)
	end
	if (show_background or self.OVERLAY_MENU)
		and WORD_GAME and WORD_GAME.TradeUI and WORD_GAME.TradeUI.draw_pass then
		WORD_GAME.TradeUI.draw_pass()
	end

	if self.debug_tools and self.debug_tools ~= self.INPUT.dragging.target then
		draw_with_container(self.debug_tools)
	end
end

--- Chrome pass: alerts, card interaction effects, popups, achievement toast,
--- the screen wipe, the custom pointer, and the hold-to-redraw ring.
function Game:render_chrome_pass()
	G.ALERT_ON_SCREEN = nil
	for _, alert in pairs(self.LIVE.ALERT) do
		draw_with_container(alert)
		G.ALERT_ON_SCREEN = true
	end

	if self.placement_table and WORD_GAME and WORD_GAME.TableBoard then
		WORD_GAME.TableBoard.draw_card_interaction(self)
	end

	for _, popup in pairs(self.LIVE.POPUP) do draw_with_container(popup) end

	if self.achievement_notification then draw_with_container(self.achievement_notification) end
	if self.screenwipe then draw_with_container(self.screenwipe) end

	love.graphics.push()
	self.POINTER:translate_container()
	love.graphics.translate(
		-self.POINTER.T.w * G.TILESCALE * G.TILESIZE * 0.5,
		-self.POINTER.T.h * G.TILESCALE * G.TILESIZE * 0.5)
	self.POINTER:draw()
	love.graphics.pop()

	if WORD_GAME and WORD_GAME.PlayHoldRedraw then
		WORD_GAME.PlayHoldRedraw.draw()
	end
end

--- Composites the offscreen canvas to the screen with post-processing and the
--- debug overlay on top.
function Game:present_frame()
	if love.graphics and love.graphics.pop then love.graphics.pop() end
	if love.graphics and love.graphics.setCanvas then love.graphics.setCanvas() end
	if love.graphics and love.graphics.push then love.graphics.push() end
	if love.graphics and love.graphics.scale then love.graphics.scale(1 / G.CANVAS_SCALE) end
	if love.graphics and love.graphics.setColor then love.graphics.setColor(G.C.WHITE) end

	if self.CANVAS then
		love.graphics.draw(self.CANVAS, 0, 0)
	end
	love.graphics.pop()

	love.graphics.setShader()
	perf_checkpoint('canvas', 'draw')

	debug_overlay.draw(self)
	perf_checkpoint('debug', 'draw')
end

--- Frame render: reset hit testing, paint into the offscreen canvas through
--- the ordered passes, then composite to the screen.
function Game:draw()
	G.FRAMES.RENDER = G.FRAMES.RENDER + 1
	reset_hit_order()
	if (G.OVERLAY_TUTORIAL or G.INTRO_OVERLAY or G.HAND_CLEAR_OVERLAY) and not G.OVERLAY_MENU then
		G.under_overlay = true
	end
	perf_checkpoint('start->canvas', 'draw')

	if love.graphics and love.graphics.setCanvas and self.CANVAS then love.graphics.setCanvas{self.CANVAS} end
	if love.graphics and love.graphics.push then love.graphics.push() end
	if love.graphics and love.graphics.scale then love.graphics.scale(G.CANVAS_SCALE) end
	if love.graphics and love.graphics.setShader then love.graphics.setShader() end
	if love.graphics and love.graphics.clear then love.graphics.clear(0, 0, 0, 1) end

	-- Splash backdrop (or a green debug fill).
	if G.SPLASH_BACK then
		if G.debug_background_toggle then
			love.graphics.clear({0, 1, 0, 1})
		else
			draw_with_container(G.SPLASH_BACK)
		end
	end

	if not G.debug_UI_toggle then
		perf_checkpoint('scene', 'draw')
		self:render_scene_pass()
		self:render_board_pass()
	end

	self:render_menu_pass()
	self:render_chrome_pass()
	perf_checkpoint('rest', 'draw')
	self:present_frame()
end

function Game:state_col(_state)
	return debug_overlay.state_col(_state)
end
