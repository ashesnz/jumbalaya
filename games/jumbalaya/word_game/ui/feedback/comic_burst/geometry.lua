--[[ word_game/ui/feedback/comic_burst/geometry.lua - Procedural starburst verts ]]

local M = {}

function M.make_rng(seed)
	seed = math.floor(seed) % 2147483647
	if seed <= 0 then seed = 1 end
	return function()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
end

function M.scale_verts(src, s, ox, oy)
	ox, oy = ox or 0, oy or 0
	local out = {}
	for i = 1, #src, 2 do
		out[i] = src[i] * s + ox
		out[i + 1] = src[i + 1] * s + oy
	end
	return out
end

function M.star_verts(rng, n, r_in, r_out, sx, sy)
	n = n or 14
	local verts = {}
	local rot = (rng() - 0.5) * 0.35
	for i = 0, n - 1 do
		local a = (i / n) * math.pi * 2 + rot
		local long = (i % 2 == 0)
		local jitter = rng()
		local r
		if long then
			r = r_out * (0.78 + 0.22 * jitter)
			if jitter > 0.72 then
				r = r * 1.14
			end
		else
			r = r_in * (0.86 + 0.18 * jitter)
		end
		verts[#verts + 1] = math.cos(a) * r * sx
		verts[#verts + 1] = math.sin(a) * r * sy
	end
	return verts
end

local function shard_verts(angle, inner, outer, half_w)
	local c, s = math.cos(angle), math.sin(angle)
	local px, py = -s, c
	local mid = inner + (outer - inner) * 0.22
	return {
		c * inner + px * half_w * 0.15, s * inner + py * half_w * 0.15,
		c * mid + px * half_w, s * mid + py * half_w,
		c * outer, s * outer,
		c * mid - px * half_w, s * mid - py * half_w,
		c * inner - px * half_w * 0.15, s * inner - py * half_w * 0.15,
	}
end

function M.build_shards(rng, r_out)
	local shards = {}
	local clusters = {
		{ angle = 0.04, count = 4, spread = 0.38, inner = 0.92, outer = 1.55 },
		{ angle = math.pi - 0.06, count = 4, spread = 0.40, inner = 0.90, outer = 1.58 },
		{ angle = -0.62, count = 2, spread = 0.18, inner = 0.88, outer = 1.28 },
		{ angle = math.pi + 0.55, count = 2, spread = 0.16, inner = 0.86, outer = 1.24 },
		{ angle = math.pi * 0.52, count = 2, spread = 0.22, inner = 0.78, outer = 1.12 },
		{ angle = -math.pi * 0.48, count = 2, spread = 0.20, inner = 0.80, outer = 1.16 },
	}
	for _, cluster in ipairs(clusters) do
		for i = 1, cluster.count do
			local t = (i - 0.5) / cluster.count - 0.5
			local a = cluster.angle + t * cluster.spread + (rng() - 0.5) * 0.08
			local inner = r_out * cluster.inner * (0.92 + 0.1 * rng())
			local outer = r_out * cluster.outer * (0.90 + 0.16 * rng())
			local hw = 0.018 + rng() * 0.022
			shards[#shards + 1] = shard_verts(a, inner, outer, hw)
		end
	end
	return shards
end

function M.build_dots(rng, r_out, sx, sy)
	local dots = {}
	local clusters = {
		{ x = 0.02 * r_out, y = -0.38 * r_out, rx = 0.42 * r_out, ry = 0.18 * r_out },
		{ x = -0.04 * r_out, y = 0.40 * r_out, rx = 0.40 * r_out, ry = 0.16 * r_out },
	}
	for _, c in ipairs(clusters) do
		local cols, rows = 7, 4
		for iy = 0, rows - 1 do
			for ix = 0, cols - 1 do
				local u = (ix + 0.5) / cols * 2 - 1
				local v = (iy + 0.5) / rows * 2 - 1
				local nx, ny = u * c.rx, v * c.ry
				local d = math.sqrt((nx / c.rx) ^ 2 + (ny / c.ry) ^ 2)
				if d < 1 and rng() > 0.18 then
					local fall = 1 - d
					dots[#dots + 1] = {
						x = (c.x + nx) * sx,
						y = (c.y + ny) * sy,
						r = (0.010 + 0.016 * fall) * (0.7 + 0.4 * rng()),
					}
				end
			end
		end
	end
	return dots
end

return M
