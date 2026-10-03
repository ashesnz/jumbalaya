--[[ word_game/ui/table/token_reward/flyers.lua - Spawn, update, and grant token flyers ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local config = require("word_game.ui.table.token_reward.config")
local session = require("word_game.ui.table.token_reward.session")
local capture = require("word_game.ui.table.token_reward.capture")
local layout = require("word_game.ui.table.token_reward.layout")

local RunMode = facade.run_mode()
local state = facade.run_state()

local M = {}


local function clamp01(t)
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_in_out(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
end

local function spawn_flyer()
	local fly_from_x, fly_from_y = session.fly_from()
	local fly_to_x, fly_to_y = session.fly_to()
	local sx = (fly_from_x or 0) + (math.random() - 0.5) * 18
	local sy = (fly_from_y or 0) + (math.random() - 0.5) * 10
	local tx = (fly_to_x or sx) + (math.random() - 0.5) * 14
	local ty = (fly_to_y or sy) + (math.random() - 0.5) * 10
	local dx, dy = tx - sx, ty - sy
	local len = math.sqrt(dx * dx + dy * dy)
	local nx, ny = 0, -1
	if len > 0.001 then
		nx, ny = -dy / len, dx / len
	end
	local flyers = session.flyers()
	flyers[#flyers + 1] = {
		sx = sx,
		sy = sy,
		ex = tx,
		ey = ty,
		nx = nx,
		ny = ny,
		t = 0,
		dur = config.FLY_DUR + math.random() * 0.08,
		spin = (math.random() - 0.5) * 10,
		phase = math.random() * math.pi * 2,
	}
end

local function refresh_token_display()
	if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.set_token_count_immediate then
		WORD_GAME_UI.TableDeck.set_token_count_immediate(state.tokens())
	end
end

function M.grant_up_to(earned)
	earned = math.max(0, math.floor(earned or 0))
	while session.tokens_granted() < earned do
		session.add_tokens_granted(1)
		state.add_tokens(1)
		refresh_token_display()
	end
end

function M.on_classic_score_tick(score_left)
	if not session.is_active() or not session.sync_score_roll() then return end
	local amount = session.reward_amount()
	if amount <= 0 then return end
	local earned = amount - math.floor((score_left or 0) + 0.5)
	M.grant_up_to(earned)
end

function M.on_classic_score_roll_done()
	if not session.is_active() or not session.sync_score_roll() then return end
	M.grant_up_to(session.reward_amount())
end

local function on_flyer_landed()
	if session.grant_on_land() then
		local grant = math.min(session.grant_per_flyer(), session.tokens_left())
		session.subtract_tokens_left(grant)
		if grant > 0 then
			state.add_tokens(grant)
			if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.bump_token_display then
				for _ = 1, grant do
					WORD_GAME_UI.TableDeck.bump_token_display()
				end
			end
			if play_sfx then
				play_sfx("coin2", 0.85 + math.random() * 0.2, 0.55 + math.random() * 0.15)
			end
		end
	end
	session.add_landed()
end

local function finish()
	if session.sync_score_roll() then
		M.grant_up_to(session.reward_amount())
	else
		if session.grant_on_land() and session.tokens_left() > 0 then
			state.add_tokens(session.tokens_left())
			session.set_tokens_left(0)
		end
	end
	if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.sync_token_display then
		WORD_GAME_UI.TableDeck.sync_token_display()
	end
	local cb = session.on_done()
	session.reset()
	if cb then cb() end
end

function M.try_award(callback)
	if session.is_active() then return true end
	if not capture.is_eligible() then return false end

	capture.capture_reward({ refresh = true })
	local amount = capture.earned_amount()
	if amount <= 0 then
		session.set_captured_time(nil)
		session.set_captured_score(nil)
		return false
	end

	local tt = WORD_GAME_UI.TimelineTimer
	local flyer_count = math.min(amount, config.MAX_REWARD_FLYERS)
	local score_roll_dur = math.min(
		config.SCORE_ROLL_MAX,
		math.max(config.SCORE_ROLL_MIN, amount * config.SCORE_ROLL_SEC_PER_POINT)
	)
	local fly_stagger = score_roll_dur / math.max(1, flyer_count)
	local fuse_payout = session.captured_time() ~= nil
	local sync_score = amount > 0 and not fuse_payout and tt and type(tt.start_score_roll) == "function"
	session.set_reward_amount(amount)
	session.set_tokens_granted(0)
	session.set_sync_score_roll(sync_score)
	session.set_fly_stagger(fly_stagger)
	if sync_score then
		tt.start_score_roll(amount, 0, score_roll_dur)
		if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.set_token_count_immediate then
			WORD_GAME_UI.TableDeck.set_token_count_immediate(state.tokens())
		end
	elseif tt and tt.freeze_reward_display then
		tt.freeze_reward_display(amount)
	elseif tt then
		tt.is_active = false
		if RunMode.is_classic() then
			tt.progress_score = amount
			tt.progress_pending = 0
		else
			tt.time_remaining = amount
		end
	end

	local total = math.min(amount, config.MAX_REWARD_FLYERS)
	session.clear_flyers()
	session.set_total(total)
	session.set_tokens_left(amount)
	session.set_grant_per_flyer(math.max(1, math.ceil(amount / total)))
	session.set_spawned(0)
	session.set_landed(0)
	session.reset_spawn_acc()
	session.set_on_done(callback)
	session.set_active(true)
	session.set_grant_on_land(not sync_score)
	local end_x, end_y = layout.resolve_target_px()
	session.set_fly_route(layout.timeline_center_px(), end_x, end_y)

	if attention then
		attention("+" .. tostring(amount) .. " tokens", game().C.GOLD or { 1, 0.85, 0.35, 1 }, 1.4)
	end
	if play_sfx then
		play_sfx("coin1", 1, 0.75)
	end

	return true
end

function M.spend_fly(amount, callback)
	amount = math.floor(amount or 0)
	if amount <= 0 then
		if callback then callback() end
		return
	end

	if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.spend_tokens_display then
		WORD_GAME_UI.TableDeck.spend_tokens_display(amount)
	end

	if session.is_active() then
		if callback then callback() end
		return
	end

	session.clear_flyers()
	session.set_total(math.min(amount, 12))
	session.set_spawned(0)
	session.set_landed(0)
	session.reset_spawn_acc()
	session.set_on_done(callback)
	session.set_active(true)
	session.set_grant_on_land(false)
	local from_x, from_y = layout.resolve_target_px()
	local room = game() and game().ROOM
	local ts = (game().TILESCALE or 1) * (game().TILESIZE or 1)
	session.set_fly_route(from_x, from_y, (room and room.T.w or game().TILE_W or 20) * ts + 80, from_y - 24)

	if attention then
		attention("-" .. tostring(amount) .. " tokens", game().C.RED or { 1, 0.35, 0.35, 1 }, 1.2)
	end
	if play_sfx then
		play_sfx("coin2", 0.9, 0.65)
	end
end

function M.update(dt)
	if not session.is_active() then return end
	dt = dt or (game() and game().real_dt) or 0.016

	local stagger = session.fly_stagger() or config.STAGGER
	session.add_spawn_acc(dt)
	while session.spawned() < session.total() and session.spawn_acc() >= stagger do
		session.subtract_spawn_acc(stagger)
		session.add_spawned()
		spawn_flyer()
	end

	local flyers = session.flyers()
	for i = #flyers, 1, -1 do
		local f = flyers[i]
		f.t = f.t + dt
		local u = ease_in_out(f.t / f.dur)
		local arc = math.sin(u * math.pi) * config.ARC
		f.x = f.sx + (f.ex - f.sx) * u + f.nx * arc
		f.y = f.sy + (f.ey - f.sy) * u + f.ny * arc
		f.rot = f.spin * u + math.sin(f.phase + u * 8) * 0.18
		f.scale = 0.42 + 0.58 * math.sin(u * math.pi)
		f.alpha = u < 0.92 and 1 or math.max(0, 1 - (u - 0.92) / 0.08)
		if f.t >= f.dur then
			on_flyer_landed()
			table.remove(flyers, i)
		end
	end

	if session.spawned() >= session.total() and session.landed() >= session.total() and #flyers == 0 then
		if session.sync_score_roll() then
			M.on_classic_score_roll_done()
			local tt = WORD_GAME_UI.TimelineTimer
			if tt then
				tt.score_roll = nil
				tt.progress_score = 0
			end
		end
		finish()
	end
end

return M
