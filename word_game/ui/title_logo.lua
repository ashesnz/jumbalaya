--[[
	ui/title_logo.lua - Animated Jumbalaya title with juggling start/end A sprites.
]]

local BASE_W = 933
local BASE_H = 267

-- Pixel placement on the 1x title canvas (from Jumbalaya.png alignment).
local LETTER_ANCHORS = {
	start = {x = 419, y = 28, w = 103, h = 143, ox = 51.5, oy = 71.5},
	["end"] = {x = 721, y = 79, w = 123, h = 152, ox = 61.5, oy = 76},
}

local LETTER_ORDER = {"start", "end"}

local CYCLE_HOME_REST = 0.5
local CYCLE_SWAP = 1.6
local CYCLE_SWAPPED_REST = 0.8
local CYCLE_RETURN = 1.6
local JUGGLE_HEIGHT = 0.42
local FLIPS_PER_SWAP = 2

---@class TitleLogo : EaseNode
---@field base_image love.Image
---@field full_image love.Image
---@field a_images table<string, love.Image>
---@field anchors table
---@field anim_time number
---@field dissolve number|nil
---@field dissolve_colours table|nil
TitleLogo = EaseNode:derive("TitleLogo")

TitleLogo.LETTER_ANCHORS = LETTER_ANCHORS
TitleLogo.CYCLE_TIMINGS = {
	home_rest = CYCLE_HOME_REST,
	swap = CYCLE_SWAP,
	swapped_rest = CYCLE_SWAPPED_REST,
	return_swap = CYCLE_RETURN,
}

function TitleLogo:construct(X, Y, W, H)
	EaseNode.construct(self, X, Y, W, H)
	self.anim_time = 0
	self.dissolve = 1
	self.dissolve_colours = {G.C.WHITE, G.C.WHITE}

	local base_atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.jumbalaya_base
	if not base_atlas or not base_atlas.image then
		self.states.visible = false
		return
	end

	self.base_image = base_atlas.image
	self.base_w = base_atlas.px or BASE_W
	self.base_h = base_atlas.py or BASE_H
	local full_atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.Jumbalaya
	self.full_image = full_atlas and full_atlas.image or self.base_image

	self.a_images = {}
	for _, key in ipairs(LETTER_ORDER) do
		local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES["jumbalaya_"..key.."_a"]
		self.a_images[key] = atlas and atlas.image or nil
	end

	self.anchors = LETTER_ANCHORS
end

function TitleLogo:remove()
	EaseNode.remove(self)
end

function TitleLogo:update(dt)
	if not self.states.visible then return end
	-- Do not start the juggling cycle until the complete title artwork has
	-- finished dissolving in.
	if (self.dissolve or 0) <= 0 then
		self.anim_time = self.anim_time + dt
	end
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function slot_center(anchor)
	return anchor.x + anchor.ox, anchor.y + anchor.oy
end

-- The letters juggle into the air, flip, replace each other (swap positions),
-- rest at the swapped positions, and then juggle back to their normal home positions.
local function juggle_pose(letter_key, t)
	local own = LETTER_ANCHORS[letter_key]
	local partner_key = letter_key == "start" and "end" or "start"
	local partner = LETTER_ANCHORS[partner_key]

	local own_cx, own_cy = slot_center(own)
	local partner_cx, partner_cy = slot_center(partner)

	local cycle = CYCLE_HOME_REST + CYCLE_SWAP + CYCLE_SWAPPED_REST + CYCLE_RETURN
	local phase = t % cycle

	local p1 = CYCLE_HOME_REST
	local p2 = p1 + CYCLE_SWAP
	local p3 = p2 + CYCLE_SWAPPED_REST

	local dir = letter_key == "start" and 1 or -1

	if phase < p1 then
		return own_cx, own_cy, 0, 1
	elseif phase < p2 then
		local u = (phase - p1) / CYCLE_SWAP
		local height_mult = letter_key == "start" and 1.15 or 0.85
		local height = math.sin(u * math.pi) * (JUGGLE_HEIGHT * height_mult * BASE_H)
		local cx = lerp(own_cx, partner_cx, u)
		local cy = lerp(own_cy, partner_cy, u) - height
		local rot = dir * u * math.pi * 2 * FLIPS_PER_SWAP
		return cx, cy, rot, 1
	elseif phase < p3 then
		return partner_cx, partner_cy, 0, 1
	else
		local u = (phase - p3) / CYCLE_RETURN
		local height_mult = letter_key == "start" and 0.85 or 1.15
		local height = math.sin(u * math.pi) * (JUGGLE_HEIGHT * height_mult * BASE_H)
		local cx = lerp(partner_cx, own_cx, u)
		local cy = lerp(partner_cy, own_cy, u) - height
		local rot = -dir * u * math.pi * 2 * FLIPS_PER_SWAP
		return cx, cy, rot, 1
	end
end

TitleLogo.juggle_pose = juggle_pose

function TitleLogo:apply_shader_effect()
	local sh = G.SHADERS and G.SHADERS.dissolve
	if not sh then return end

	local _draw_major = self.role.draw_major or self
	self.ARGS.prep_shader = self.ARGS.prep_shader or {}
	self.ARGS.prep_shader.cursor_pos = self.ARGS.prep_shader.cursor_pos or {}
	self.ARGS.prep_shader.cursor_pos[1] = _draw_major.tilt_var and _draw_major.tilt_var.mx * G.CANVAS_SCALE
		or (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.x * G.CANVAS_SCALE or 0)
	self.ARGS.prep_shader.cursor_pos[2] = _draw_major.tilt_var and _draw_major.tilt_var.my * G.CANVAS_SCALE
		or (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.y * G.CANVAS_SCALE or 0)

	pcall(function()
		sh:send("mouse_screen_pos", self.ARGS.prep_shader.cursor_pos)
		sh:send("screen_scale", G.TILESCALE * G.TILESIZE * (_draw_major.mouse_damping or 1) * G.CANVAS_SCALE)
		sh:send("hovering", (_draw_major.hover_tilt or 0))
		sh:send("dissolve", math.abs(_draw_major.dissolve or 0))
		sh:send("dissolve_wipe", _draw_major.dissolve_wipe or 0)
		sh:send("time", 123.33412 * ((_draw_major.ID or 1) / 1.14212) % 3000)
		sh:send("texture_details", {0, 0, self.base_w, self.base_h})
		sh:send("image_details", {self.base_w, self.base_h})
		sh:send("burn_colour_1", _draw_major.dissolve_colours and _draw_major.dissolve_colours[1] or G.C.CLEAR)
		sh:send("burn_colour_2", _draw_major.dissolve_colours and _draw_major.dissolve_colours[2] or G.C.CLEAR)
		sh:send("shadow", false)
	end)
	love.graphics.setShader(sh)
end

function TitleLogo:draw()
	if not self.states.visible or not self.base_image then return end

	local canvas_scale_x = self.VT.w / BASE_W
	local canvas_scale_y = self.VT.h / BASE_H
	local t = self.anim_time

	push_node_transform(self, 1)
	self:apply_shader_effect()
	love.graphics.setColor(G.C.WHITE)
	-- Keep the authored, complete logo intact during its initial reveal. Once
	-- the reveal is complete, use the base artwork so the A sprites can move
	-- independently without leaving duplicate letters behind.
	local title_image = (self.dissolve or 0) > 0 and self.full_image or self.base_image
	local title_w, title_h = title_image:getDimensions()
	love.graphics.draw(title_image, 0, 0, 0, self.VT.w / title_w, self.VT.h / title_h)
	love.graphics.setShader()

	if (self.dissolve or 0) <= 0 then
		for _, key in ipairs(LETTER_ORDER) do
			local img = self.a_images[key]
			local anchor = self.anchors[key]
			if img and anchor then
				local cx, cy, rot, sx = juggle_pose(key, t)
				local draw_x = cx * canvas_scale_x
				local draw_y = cy * canvas_scale_y
				local img_w, img_h = img:getDimensions()
				local a_scale_x = (anchor.w / BASE_W) * (self.VT.w / img_w) * sx
				local a_scale_y = (anchor.h / BASE_H) * (self.VT.h / img_h)
				love.graphics.draw(
					img,
					draw_x,
					draw_y,
					rot,
					a_scale_x,
					a_scale_y,
					img_w * 0.5,
					img_h * 0.5
				)
			end
		end
	end

	love.graphics.pop()
	track_hit_target(self)
	self:draw_boundingrect()
end

function TitleLogo.create(major, width, height)
	local logo = TitleLogo(0, 0, width, height)
	logo:set_alignment({
		major = major,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})
	return logo
end

return TitleLogo
