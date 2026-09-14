--[[
	jumbalaya-engine/graphics/flow_text_envelopes.lua - FlowText letter motion math.

	Reveal/out easing and idle decoration helpers used by flow_text.lua.
]]

local M = {}

M.GOLDEN_ANGLE = 2.399963229728653

--- Ease-out-back curve: fast rise, brief overshoot above 1, settle at 1.
function M.spring_rise(t)
	if t <= 0 then return 0 end
	if t >= 1 then return 1 end
	local c = 1.35
	t = t - 1
	return t * t * ((c + 1) * t + c) + 1
end

--- Smoothstep fade, used for the reveal-out envelope.
function M.smoothstep(t)
	if t <= 0 then return 0 end
	if t >= 1 then return 1 end
	return t * t * (3 - 2 * t)
end

function M.rotate_sway(k, mid, letter_count, now, direction)
	local dir = direction == 2 and -1 or 1
	return dir * (0.18 * (k - mid) / letter_count
		+ 0.03 * math.sin(1.7 * now + k * M.GOLDEN_ANGLE))
end

function M.pulse_scale(now, pulse, k, mid, letter_count)
	local head = (now - pulse.start) * pulse.speed
	local d = (head - k) / math.max(pulse.width * 0.5, 0.001)
	local bell = math.exp(-d * d)
	local scale = 1 + 1.5 * pulse.amount * bell
	local extra_r = (scale - 1) * 0.02 * (k - mid)
	local done = head > letter_count + pulse.width
	return scale, extra_r, done
end

function M.quiver_motion(now, quiver, k)
	local wobble = math.sin(now * quiver.speed * 23.7 + k * 12.9898)
		+ 0.5 * math.cos(now * quiver.speed * 41.3 + k * 78.233)
		+ 0.25 * math.sin(now * quiver.speed * 67.1 + k * 39.425)
	return 0.08 * quiver.amount, 0.22 * quiver.amount * wobble
end

function M.float_offset(now, k, scale, font_scale, tilesize)
	return math.sqrt(scale)
		* (2 + (font_scale / tilesize) * 1500
			* (math.cos(2.6 * now + k * M.GOLDEN_ANGLE)
				+ 0.3 * math.sin(4.3 * now + k * 1.618)))
end

function M.bump_offset(now, k, hop_rate, hop_height, scale)
	local phase = (hop_rate * now + k * M.GOLDEN_ANGLE / (2 * math.pi)) % 1
	local hop = math.sin(phase * math.pi)
	hop = hop * hop * (3 - 2 * hop)
	return hop_height * math.sqrt(scale) * 12 * hop
end

return M
