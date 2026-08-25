return function(Target)
local function rounded_rect_vertices(w, h, radius, ext_up, segs)
	radius = math.max(1, radius or 8)
	segs = segs or 8
	ext_up = ext_up or 0
	local verts = {w * 0.5, h * 0.5 - ext_up}
	local function arc(cx, cy, a0, a1)
		for i = 0, segs do
			local a = a0 + (a1 - a0) * (i / segs)
			verts[#verts + 1] = cx + radius * math.cos(a)
			verts[#verts + 1] = cy + radius * math.sin(a) - ext_up
		end
	end
	arc(radius, radius, math.pi, 1.5 * math.pi)
	arc(w - radius, radius, 1.5 * math.pi, 2 * math.pi)
	arc(w - radius, h - radius, 0, 0.5 * math.pi)
	arc(radius, h - radius, 0.5 * math.pi, math.pi)
	verts[#verts + 1] = verts[3] -- close the loop back to the start point
	verts[#verts + 1] = verts[4]
	return verts
end

--- Cached rounded-rect vertex sets (fill/shadow/line/emboss variants),
--- invalidated whenever size, parallax, progress, or speech-ness changes.
function LayoutNode:draw_pixellated_rect(_type, _parallax, _emboss, _progress)
	if not self.pixellated_rect
		or #self.pixellated_rect[_type].vertices < 1
		or _parallax ~= self.pixellated_rect.parallax
		or self.pixellated_rect.w ~= self.VT.w
		or self.pixellated_rect.h ~= self.VT.h
		or self.pixellated_rect.sw ~= self.shadow_parallax.x
		or self.pixellated_rect.sh ~= self.shadow_parallax.y
		or self.pixellated_rect.progress ~= (_progress or 1)
		or self.pixellated_rect.speech ~= (not not self.config.speech_tail) then

		self.pixellated_rect = {
			w = self.VT.w,
			h = self.VT.h,
			sw = self.shadow_parallax.x,
			sh = self.shadow_parallax.y,
			progress = (_progress or 1),
			speech = not not self.config.speech_tail,
			fill = {vertices = {}},
			shadow = {vertices = {}},
			line = {vertices = {}},
			emboss = {vertices = {}},
			line_emboss = {vertices = {}},
			parallax = _parallax,
		}

		local ext_up = self.config.ext_up and self.config.ext_up * G.TILESIZE or 0
		local totw, toth, vertices
		if self.config.speech_tail then
			totw = self.VT.w * G.TILESIZE
			toth = (self.VT.h + math.abs(ext_up) / G.TILESIZE) * G.TILESIZE
			local radius = math.min(totw * 0.5 - 1, toth * 0.5 - 1,
				math.max(10, (self.config.r or 0.22) * G.TILESIZE))
			vertices = rounded_rect_vertices(totw, toth, radius, ext_up, 8)
		else
			totw, toth = self.VT.w * G.TILESIZE, (self.VT.h + math.abs(ext_up) / G.TILESIZE) * G.TILESIZE
			local radius = math.min(totw * 0.5 - 1, toth * 0.5 - 1,
				math.max(1, (self.config.r or 0.22) * G.TILESIZE))
			vertices = rounded_rect_vertices(totw, toth, radius, ext_up, 16)
		end

		-- Derive all variant vertex sets from the base outline. Even indices
		-- are y (shifted down for shadow / up for emboss); odd are x (also
		-- truncated beyond `progress` for delay/progress bars).
		for k, v in ipairs(vertices) do
			if k % 2 == 1 and v > totw * self.pixellated_rect.progress then
				v = totw * self.pixellated_rect.progress
			end
			self.pixellated_rect.fill.vertices[k] = v
			if k > 4 then
				self.pixellated_rect.line.vertices[k - 4] = v
				if _emboss then
					self.pixellated_rect.line_emboss.vertices[k - 4] =
						v + (k % 2 == 0 and -_emboss * self.shadow_parallax.y or -0.7 * _emboss * self.shadow_parallax.x)
				end
			end
			if k % 2 == 0 then
				self.pixellated_rect.shadow.vertices[k] = v - self.shadow_parallax.y * _parallax
				if _emboss then self.pixellated_rect.emboss.vertices[k] = v + _emboss * G.TILESIZE end
			else
				self.pixellated_rect.shadow.vertices[k] = v - self.shadow_parallax.x * _parallax
				if _emboss then self.pixellated_rect.emboss.vertices[k] = v end
			end
		end
	end

	love.graphics.polygon((_type == 'line' or _type == 'line_emboss') and 'line' or 'fill',
		self.pixellated_rect[_type].vertices)
end

--- Stroke the cached outline while skipping bottom-edge segments inside
--- [gap_x1, gap_x2] — used for speech-bubble outlines around the tail.
function LayoutNode:draw_pixellated_rect_line_with_gap(parallax_dist, gap_x1, gap_x2, bottom_y)
	local verts = self.pixellated_rect and self.pixellated_rect.line.vertices
	if not verts or #verts < 2 then return end

	local count = #verts / 2
	local tolerance = 4
	for i = 1, count do
		local j = i % count + 1
		local x1, y1 = verts[(i - 1) * 2 + 1], verts[(i - 1) * 2 + 2]
		local x2, y2 = verts[(j - 1) * 2 + 1], verts[(j - 1) * 2 + 2]
		local on_bottom = math.abs(y1 - bottom_y) < tolerance and math.abs(y2 - bottom_y) < tolerance
		local overlaps_gap = math.min(x1, x2) < gap_x2 and math.max(x1, x2) > gap_x1
		if not (on_bottom and overlaps_gap) then
			love.graphics.line(x1, y1, x2, y2)
		end
	end
end
end
