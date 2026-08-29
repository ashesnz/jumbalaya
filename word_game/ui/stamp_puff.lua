--[[ word_game/ui/stamp_puff.lua - Soft burst when a perk stamp lands ]]

local M = {}

local PUFF_DUR = 0.62
local puffs = {}

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_out_quad(t)
	t = clamp01(t)
	local u = 1 - t
	return 1 - u * u
end

function M.spawn(cx, cy, w, h)
	puffs[#puffs + 1] = {
		cx = cx,
		cy = cy,
		w = w,
		h = h,
		age = 0,
		seed = math.random(1, 99999),
	}
end

function M.update(dt)
	dt = dt or 0
	if dt <= 0 then return end
	local write = 1
	for i = 1, #puffs do
		local puff = puffs[i]
		puff.age = puff.age + dt
		if puff.age < PUFF_DUR then
			puffs[write] = puff
			write = write + 1
		end
	end
	for i = write, #puffs do
		puffs[i] = nil
	end
end

function M.draw()
	if not love or not love.graphics then return end
	for _, puff in ipairs(puffs) do
		local u = puff.age / PUFF_DUR
		if u >= 1 then goto continue end
		local fade = 1 - ease_out_quad(u)
		local expand = 0.55 + u * 0.95
		local cx, cy, w, h = puff.cx, puff.cy, puff.w, puff.h

		love.graphics.setColor(0.98, 0.90, 0.72, 0.28 * fade)
		love.graphics.ellipse("fill", cx, cy, w * 0.56 * expand, h * 0.42 * expand)

		love.graphics.setColor(1, 1, 1, 0.22 * fade)
		love.graphics.ellipse("fill", cx, cy, w * 0.34 * expand, h * 0.26 * expand)

		local n = 12
		for i = 1, n do
			local angle = (i / n) * math.pi * 2 + puff.seed * 0.017
			local dist = (w * 0.18 + u * w * 0.42) * (0.75 + 0.25 * math.sin(i * 1.7 + puff.seed))
			local px = cx + math.cos(angle) * dist
			local py = cy + math.sin(angle) * dist * 0.62
			local r = math.max(1.5, (2.8 + 2.2 * (1 - u)) * ((G.TILESCALE or 1) * 0.12 + 0.8))
			love.graphics.setColor(1, 0.94, 0.78, 0.5 * fade)
			love.graphics.circle("fill", px, py, r)
		end

		love.graphics.setColor(1, 0.98, 0.88, 0.18 * fade)
		love.graphics.setLineWidth(1.4)
		love.graphics.ellipse("line", cx, cy, w * 0.48 * expand, h * 0.36 * expand)

		::continue::
	end
end

function M.reset()
	puffs = {}
end

function M.active_count()
	return #puffs
end

return M
