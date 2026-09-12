--[[ word_game/ui/cards/visuals/draw.lua - Card shadow, tilt, and draw passes ]]

---@class (partial) Card : EaseNode
local GameRT = require("word_game.ui.util.game_runtime")
local LetterFaces = require("word_game.ui.cards.letter_faces")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")

local function runtime() return GameRT.game() end

local function letter_card_tint(card)
	if card.bonus_card then
		return LetterPalette.fill(LetterPalette.BONUS_FACE_COLOR)
	end
	return LetterFaces.fill_color(card.base and card.base.color)
end

local function draw_bonus_gold_shimmer(card)
	local center = card.children and card.children.center
	if not center then return end
	center:apply_shader_effect("gold_seal", nil, card.ARGS and card.ARGS.send_to_shader)
end

function Card:sync_shadow_state()
	self.ARGS.send_to_shader = self.ARGS.send_to_shader or {}
	self.ARGS.send_to_shader[1] = math.min(self.VT.r*3, 1) + runtime().TIMERS.REAL/(28) + (self.bounce and self.bounce.r*20 or 0) + self.tilt_var.amt
	self.ARGS.send_to_shader[2] = runtime().TIMERS.REAL

	for _, child in pairs(self.children) do
		child.VT.scale = self.VT.scale
	end
end

function Card:draw_shadow()
	local wants_shadow = not self.no_shadow
		and runtime().SETTINGS.GRAPHICS.shadows == 'On'
		and self.ability.effect ~= 'Glass Card'
		and not self.greyed
		and ((self.area and self.area ~= runtime().recycle_stash and self.area.config.type ~= 'deck')
			or not self.area or self.states.drag.is)

	if wants_shadow then
		self.shadow_height = (self.selected or self.states.drag.is) and 0.35
			or (self.area and self.area.config.type == 'title_2') and 0.04
			or 0.1
		if self.inspecting then
			self.shadow_height = self.shadow_height + 0.22
		end
		runtime().shared_shadow:apply_shader_effect('dissolve', self.shadow_height)
	end
end

function Card:update_tilt()
	self.tilt_var = self.overwrite_tilt_var or self.tilt_var
		or {mx = 0, my = 0, dx = self.tilt_var.dx or 0, dy = self.tilt_var.dy or 0, amt = 0}
	if self.overwrite_tilt_var then return end

	local tilt_factor = 0.3
	if self.states.focus.is then
		self.tilt_var.mx, self.tilt_var.my =
			runtime().INPUT.cursor_position.x + self.tilt_var.dx*self.T.w*runtime().TILESCALE*runtime().TILESIZE,
			runtime().INPUT.cursor_position.y + self.tilt_var.dy*self.T.h*runtime().TILESCALE*runtime().TILESIZE
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1 + self.tilt_var.dx + self.tilt_var.dy - 1)*tilt_factor
	elseif self.states.hover.is then
		self.tilt_var.mx, self.tilt_var.my = runtime().INPUT.cursor_position.x, runtime().INPUT.cursor_position.y
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1)*tilt_factor
	elseif self.ambient_tilt then
		local tilt_angle = runtime().TIMERS.REAL*(1.56 + (self.ID/1.14212)%1) + self.ID/1.35122
		self.tilt_var.mx = ((0.5 + 0.5*self.ambient_tilt*math.cos(tilt_angle))*self.VT.w+self.VT.x+runtime().ROOM.T.x)*runtime().TILESIZE*runtime().TILESCALE
		self.tilt_var.my = ((0.5 + 0.5*self.ambient_tilt*math.sin(tilt_angle))*self.VT.h+self.VT.y+runtime().ROOM.T.y)*runtime().TILESIZE*runtime().TILESCALE
		self.tilt_var.amt = self.ambient_tilt*(0.5+math.cos(tilt_angle))*tilt_factor
	end
end

function Card:draw_market_widgets()
	if self.children.price then self.children.price:draw() end
	if self.children.buy_button then
		if self.selected then
			self.children.buy_button.states.visible = true
			self.children.buy_button:draw()
			if self.children.buy_and_use_button then
				self.children.buy_and_use_button:draw()
			end
		else
			self.children.buy_button.states.visible = false
		end
	end
	if self.children.use_button and self.selected then self.children.use_button:draw() end
end

function Card:draw_front()
	if not self.greyed then
		if LetterFaces.is_letter_card(self) then
			local tint = letter_card_tint(self)
			self.children.center:apply_shader_effect('dissolve', nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, tint)
			if self.bonus_card then
				draw_bonus_gold_shimmer(self)
			end
			if self.children.front then
				self.children.front:apply_shader_effect('dissolve')
			end
		else
			self.children.center:apply_shader_effect('dissolve')
			if self.children.front then
				self.children.front:apply_shader_effect('dissolve')
			end
		end
	end

	if self.debuff or self.greyed then
		if self.debuff then
			self.children.center:apply_shader_effect('debuff', nil, self.ARGS.send_to_shader)
			if self.children.front then
				self.children.front:apply_shader_effect('debuff', nil, self.ARGS.send_to_shader)
			end
		end
		if self.greyed then
			self.children.center:apply_shader_effect('played', nil, self.ARGS.send_to_shader)
			if self.children.front then
				self.children.front:apply_shader_effect('played', nil, self.ARGS.send_to_shader)
			end
		end
	end
end

function Card:draw_back()
	local overlay = runtime().C.WHITE
	if self.area and self.area.config.type == 'deck' then
		overlay = {0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50, 1}
		self.children.back:draw(overlay)
	else
		self.children.back:apply_shader_effect('dissolve')
	end
end

local PASS_DRAWN_CHILDREN = {
	focused_ui = true, front = true, back = true, center = true,
	overwrite = true, soul_parts = true, floating_sprite = true,
	shadow = true, use_button = true, buy_button = true,
	buy_and_use_button = true, debuff = true, price = true,
	particles = true, h_popup = true,
}

function Card:draw_leftover_children()
	for key, child in pairs(self.children) do
		if not PASS_DRAWN_CHILDREN[key] then child:draw() end
	end
end

function Card:draw(layer)
	layer = layer or 'both'

	self.hover_tilt = 1
	if not self.states.visible then return end

	if layer == 'shadow' or layer == 'both' then
		self:sync_shadow_state()
	end

	runtime().shared_shadow = self.sprite_facing == 'front' and self.children.center or self.children.back

	if layer == 'shadow' or layer == 'both' then
		self:draw_shadow()
	end

	if layer == 'card' or layer == 'both' then
		if self.area ~= runtime().dealt_letters and self.children.focused_ui then
			self.children.focused_ui:draw()
		end

		self:update_tilt()

		if self.children.particles then self.children.particles:draw() end
		self:draw_market_widgets()

		if self.sprite_facing == 'front' then
			self:draw_front()
		else
			self:draw_back()
		end

		if self.children.overwrite and self.tilt_var then
			self.children.overwrite.overwrite_tilt_var = deep_clone(self.tilt_var)
		end

		self:draw_leftover_children()

		if self.children.overwrite then
			love.graphics.push()
			love.graphics.setColor(runtime().C.BLUE)
			runtime().OVERLAY_TINT = {1, 1, 1, math.sin(5*runtime().TIMERS.REAL)}
			self.children.overwrite:draw('card')
			runtime().OVERLAY_TINT = nil
			love.graphics.pop()
		end

		if self.area == runtime().dealt_letters and self.children.focused_ui then
			self.children.focused_ui:draw()
		end

		track_hit_target(self)
		self:draw_boundingrect()
	end
end
