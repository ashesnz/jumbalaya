--[[ word_game/ui/table/token_reward/session.lua - Active flyer session state ]]

local facade = require("word_game.ui.facade")
local Busy = facade.busy()

local M = {}

local flyers = {}
local active = false
local on_done = nil
local total = 0
local spawned = 0
local landed = 0
local spawn_acc = 0
local captured_time = nil
local captured_score = nil
local tokens_left = 0
local grant_per_flyer = 1
local grant_on_land = true
local fly_from_x, fly_from_y, fly_to_x, fly_to_y

function M.flyers()
	return flyers
end

function M.clear_flyers()
	flyers = {}
end

function M.is_active()
	return active
end

function M.set_active(value)
	active = value == true
	Busy.set("token_reward_busy", value)
end

function M.on_done()
	return on_done
end

function M.set_on_done(cb)
	on_done = cb
end

function M.total()
	return total
end

function M.set_total(value)
	total = value
end

function M.spawned()
	return spawned
end

function M.set_spawned(value)
	spawned = value
end

function M.add_spawned()
	spawned = spawned + 1
end

function M.landed()
	return landed
end

function M.set_landed(value)
	landed = value
end

function M.add_landed()
	landed = landed + 1
end

function M.spawn_acc()
	return spawn_acc
end

function M.add_spawn_acc(dt)
	spawn_acc = spawn_acc + dt
end

function M.subtract_spawn_acc(value)
	spawn_acc = spawn_acc - value
end

function M.reset_spawn_acc()
	spawn_acc = 0
end

function M.captured_time()
	return captured_time
end

function M.set_captured_time(value)
	captured_time = value
end

function M.captured_score()
	return captured_score
end

function M.set_captured_score(value)
	captured_score = value
end

function M.tokens_left()
	return tokens_left
end

function M.set_tokens_left(value)
	tokens_left = value
end

function M.subtract_tokens_left(amount)
	tokens_left = tokens_left - amount
end

function M.grant_per_flyer()
	return grant_per_flyer
end

function M.set_grant_per_flyer(value)
	grant_per_flyer = value
end

function M.grant_on_land()
	return grant_on_land
end

function M.set_grant_on_land(value)
	grant_on_land = value
end

function M.set_fly_route(from_x, from_y, to_x, to_y)
	fly_from_x, fly_from_y = from_x, from_y
	fly_to_x, fly_to_y = to_x, to_y
end

function M.fly_from()
	return fly_from_x, fly_from_y
end

function M.fly_to()
	return fly_to_x, fly_to_y
end

function M.reset()
	active = false
	Busy.set("token_reward_busy", false)
	flyers = {}
	on_done = nil
	total = 0
	spawned = 0
	landed = 0
	spawn_acc = 0
	captured_time = nil
	captured_score = nil
	tokens_left = 0
	grant_per_flyer = 1
	grant_on_land = true
end

return M
