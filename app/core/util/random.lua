--[[
	app/core/util/random.lua - seeded streams and general randomness.

	Gameplay rolls flow through named streams kept in `G.GAME.seed_streams`,
	so a run started under a given seed replays identically. The numeric
	constants below double as part of that replay contract: altering one
	alters every roll that follows it.
]]

--- In-place Fisher-Yates. Lists of cards are pre-ordered by `sort_id`, so
--  the result never depends on how Lua happens to iterate the table.
---@param list table array to shuffle, mutated
function shuffle_seeded(list, seed)
	if seed then math.randomseed(seed) end

	if list[1] and list[1].sort_id then
		table.sort(list, function(a, b) return (a.sort_id or 1) < (b.sort_id or 2) end)
	end

	for i = #list, 2, -1 do
		local j = math.random(i)
		list[i], list[j] = list[j], list[i]
	end
end

-- Entries sort by card order when they hold cards, otherwise by key, so
-- "random pick from a table" is reproducible across runs.
local function stable_order(entries)
	local first = entries[1] and entries[1].v
	if type(first) == 'table' and first.sort_id then
		table.sort(entries, function(a, b) return a.v.sort_id < b.v.sort_id end)
	else
		table.sort(entries, function(a, b) return a.k < b.k end)
	end
end

--- Draws a uniformly random element of any table; returns value and key.
---@param t table
---@return any, any
function pick_random(t, seed)
	if seed then math.randomseed(seed) end

	local entries = {}
	for k, v in pairs(t) do entries[#entries + 1] = {k = k, v = v} end
	stable_order(entries)

	local key = entries[math.random(#entries)].k
	return t[key], key
end

-- Character bands for generated codes: digits, then two consonant-heavy
-- letter ranges (avoids accidentally spelling words).
local CODE_BANDS = {
	{floor = 0.72, lo = string.byte('1'), hi = string.byte('9')},
	{floor = 0.41, lo = string.byte('B'), hi = string.byte('K')},
	{floor = 0.00, lo = string.byte('M'), hi = string.byte('X')},
}

--- Builds a random identifier of `length` characters.
---@return string uppercase code
function random_code(length, seed)
	if seed then math.randomseed(seed) end
	local chars = {}
	for _ = 1, length do
		local roll = math.random()
		local band
		for _, candidate in ipairs(CODE_BANDS) do
			if not band and roll > candidate.floor then band = candidate end
		end
		chars[#chars + 1] = string.char(math.random(band.lo, band.hi))
	end
	return string.upper(table.concat(chars))
end

--- Folds a string into [0, 1). Bytes are consumed back to front.
function hash_text(str)
	local num = 1
	for i = #str, 1, -1 do
		num = ((1.1239285023 / num) * string.byte(str, i) * math.pi + math.pi * i) % 1
	end
	return num
end

--- Steps one named stream forward and yields its current value. Streams are
--- born from `hash_text(key .. run seed)`; each step applies a Marsaglia-style
--- twist blended with the hashed run seed, so separate runs diverge while a
--- single run stays replayable.
function advance_seed(key)
	if key == 'seed' then return math.random() end

	local streams = G.GAME.seed_streams
	if not streams[key] then
		streams[key] = hash_text(key .. (streams.seed or ''))
	end

	streams[key] =
		math.abs(tonumber(string.format("%.13f", (2.134453429141 + streams[key] * 1.72431234) % 1)) or 0)

	return (streams[key] + (streams.hashed_seed or 0)) / 2
end

--- Seeded roll: `key` names a stream (string) or is used as a raw seed.
--- With `min`/`max`, yields an inclusive integer; otherwise [0, 1).
function seeded_random(key, min, max)
	if type(key) == 'string' then key = advance_seed(key) end
	math.randomseed(key)
	if min and max then return math.random(min, max) end
	return math.random()
end
