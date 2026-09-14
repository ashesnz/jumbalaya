--[[ word_game/ui/perks/discard_bin/counter.lua - Discard counter and odometer overlay ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local Odometer = require("word_game.ui.widgets.odometer")
local rules = require("word_game.ui.perks.discard_bin.rules")

local M = {
	COUNTER_HEIGHT_FRAC = 0.52,
	COUNTER_X_FRAC = 0.78,
	COUNTER_COLOUR = { 0.08, 0.10, 0.14, 1 },
}

local discards_used_count = 0
local overlay_odometer

local function read_discards_used()
	local game = game_access.get()
	if game and game.voucher_discards_used ~= nil then
		discards_used_count = game.voucher_discards_used
	elseif game and game.discard_bin_count ~= nil then
		discards_used_count = game.discard_bin_count
	end
	return discards_used_count
end

local function write_discards_used(count)
	discards_used_count = math.max(0, count or 0)
	game_access.patch({
		voucher_discards_used = discards_used_count,
		discard_bin_count = discards_used_count,
	})
end

local function ensure_overlay_odometer()
	if overlay_odometer then return overlay_odometer end
	overlay_odometer = Odometer({
		label = "",
		text_shadow = true,
		value = M.discards_left(),
		value_fn = function() return M.discards_left() end,
		colour = M.COUNTER_COLOUR,
	})
	return overlay_odometer
end

function M.reset()
	write_discards_used(0)
	overlay_odometer = nil
	M.sync_voucher_counter(true)
end

function M.discards_used()
	return read_discards_used()
end

function M.discards_left()
	return math.max(0, rules.max_fills() - read_discards_used())
end

function M.is_full()
	return read_discards_used() >= rules.max_fills()
end

function M.overlay_odometer()
	if not rules.voucher_discard_unlocked() then return nil end
	return ensure_overlay_odometer()
end

function M.sync_voucher_counter(force)
	local left = M.discards_left()
	local odometer = M.overlay_odometer()
	if not odometer then return end
	if force or not odometer.roll then
		odometer.display_count = left
	end
end

function M.roll_discards_left(from_left, to_left)
	local odometer = M.overlay_odometer()
	if odometer and odometer.start_roll then
		odometer:start_roll(from_left, to_left)
	else
		M.sync_voucher_counter(true)
	end
end

function M.record_discard()
	local used = read_discards_used()
	if used >= rules.max_fills() then return false end
	local from_left = M.discards_left()
	write_discards_used(used + 1)
	M.roll_discards_left(from_left, M.discards_left())
	return true
end

function M.ensure_odometer()
	ensure_overlay_odometer()
end

function M.visible_counter_digit()
	local odometer = M.overlay_odometer()
	if not odometer then return nil end
	if odometer.roll then
		return tostring(odometer.roll.from)
	end
	return tostring(odometer.display_count or odometer:current_value())
end

return M
