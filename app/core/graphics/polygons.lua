function pointer_triangle(x, y, w, h, vert)
	local scale = 2
	if vert then
		x = x + math.min(0.6 * math.sin(G.TIMERS.REAL * 9) * scale + 0.2, 0)
		return {
			x - 3.5 * scale, y + h / 2 - 1.5 * scale,
			x - 0.5 * scale, y + h / 2,
			x - 3.5 * scale, y + h / 2 + 1.5 * scale,
		}
	end
	y = y + math.min(0.6 * math.sin(G.TIMERS.REAL * 9) * scale + 0.2, 0)
	return {
		x + w / 2 - 1.5 * scale, y - 4 * scale,
		x + w / 2, y - 1.1 * scale,
		x + w / 2 + 1.5 * scale, y - 4 * scale,
	}
end

--- Polygon points for the tail under a speech-bubble box.
--  `kind == 'mouth'` anchors along the bottom edge (`along`, clamped) with a
--  drop depth from `reach`; the default variant hangs from 14% of the width.
function get_speech_bubble_tail(x, y, w, h, kind, reach, along)
	local scale = 2.4
	local by = y + h
	if kind == 'mouth' then
		local ts = G.TILESIZE or 20
		local bx = x + w * math.max(0.08, math.min(0.92, along or 0.82))
		local drop = math.max(0.28, reach or 0.5) * ts
		return {bx - 1.6 * scale, by, bx + 1.8 * scale, by, bx, by + drop}
	end
	local bx = x + w * 0.14
	return {bx - 1.5 * scale, by, bx + 1.5 * scale, by, bx, by + 3.4 * scale}
end

function get_speech_bubble_tail_bl(x, y, w, h)
	return get_speech_bubble_tail(x, y, w, h, 'bl')
end
