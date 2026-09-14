--[[ word_game/ui/cards/visuals/draw.lua - Card shadow, tilt, and draw passes ]]

---@class (partial) Card : EaseNode
local game = require("word_game.ui.util.game_runtime").game
local LetterFaces = require("word_game.ui.cards.letter_faces")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")
local Tables = require("jumbalaya-engine.util.tables")
local HitOrder = require("jumbalaya-engine.graphics.hit_order")

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

--- Resting table cards skip dissolve/tilt shaders until hover, drag, or FX need them.
function Card:is_shader_idle()
	if self.states.hover.is or self.states.focus.is or self.states.drag.is then
		return false
	end
	if self.selected or self.inspecting then return false end
	if self.debuff or self.greyed or self.bonus_card then return false end
	if self.dissolve and math.abs(self.dissolve) > 0.001 then return false end
	if self.dissolve_wipe and self.dissolve_wipe > 0 then return false end
	if self.ambient_tilt then return false end
	if self.bounce and (self.bounce.x ~= 0 or self.bounce.y ~= 0 or self.bounce.r ~= 0) then return false end
	return true
end

local function draw_sprite(sprite, overlay)
	if overlay then
		sprite:draw(overlay)
	else
		sprite:draw()
	end
end

local function apply_dissolve(sprite, card, tint)
	if tint then
		sprite:apply_shader_effect("dissolve", nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, tint)
	else
		sprite:apply_shader_effect("dissolve")
	end
end

function Card:sync_shadow_state()
	if self:is_shader_idle() then return end
	self.ARGS.send_to_shader = self.ARGS.send_to_shader or {}
	self.ARGS.send_to_shader[1] = math.min(self.VT.r*3, 1) + game().TIMERS.REAL/(28) + (self.bounce and self.bounce.r*20 or 0) + self.tilt_var.amt
	self.ARGS.send_to_shader[2] = game().TIMERS.REAL

	for _, child in pairs(self.children) do
		child.VT.scale = self.VT.scale
	end
end

function Card:draw_shadow()
	local wants_shadow = not self.no_shadow
		and game().SETTINGS.GRAPHICS.shadows == "On"
		and self.ability.effect ~= "Glass Card"
		and not self.greyed
		and ((self.area and self.area ~= game().recycle_stash and self.area.config.type ~= "deck")
			or not self.area or self.states.drag.is)
		and not self:is_shader_idle()

	if wants_shadow then
		self.shadow_height = (self.selected or self.states.drag.is) and 0.35
			or (self.area and self.area.config.type == 'title_2') and 0.04
			or 0.1
		if self.inspecting then
			self.shadow_height = self.shadow_height + 0.22
		end
		game().shared_shadow:apply_shader_effect('dissolve', self.shadow_height)
	end
end

function Card:update_tilt()
	self.tilt_var = self.overwrite_tilt_var or self.tilt_var
		or {mx = 0, my = 0, dx = self.tilt_var.dx or 0, dy = self.tilt_var.dy or 0, amt = 0}
	if self.overwrite_tilt_var then return end

	local tilt_factor = 0.3
	if self.states.focus.is then
		self.tilt_var.mx, self.tilt_var.my =
			game().INPUT.cursor_position.x + self.tilt_var.dx*self.T.w*game().TILESCALE*game().TILESIZE,
			game().INPUT.cursor_position.y + self.tilt_var.dy*self.T.h*game().TILESCALE*game().TILESIZE
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1 + self.tilt_var.dx + self.tilt_var.dy - 1)*tilt_factor
	elseif self.states.hover.is then
		self.tilt_var.mx, self.tilt_var.my = game().INPUT.cursor_position.x, game().INPUT.cursor_position.y
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1)*tilt_factor
	elseif self.ambient_tilt then
		local tilt_angle = game().TIMERS.REAL*(1.56 + (self.ID/1.14212)%1) + self.ID/1.35122
		self.tilt_var.mx = ((0.5 + 0.5*self.ambient_tilt*math.cos(tilt_angle))*self.VT.w+self.VT.x+game().ROOM.T.x)*game().TILESIZE*game().TILESCALE
		self.tilt_var.my = ((0.5 + 0.5*self.ambient_tilt*math.sin(tilt_angle))*self.VT.h+self.VT.y+game().ROOM.T.y)*game().TILESIZE*game().TILESCALE
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
			if self:is_shader_idle() then
				draw_sprite(self.children.center)
				if self.children.front then draw_sprite(self.children.front) end
			else
				apply_dissolve(self.children.center, self, tint)
				if self.bonus_card then
					draw_bonus_gold_shimmer(self)
				end
				if self.children.front then
					apply_dissolve(self.children.front, self)
				end
			end
		else
			if self:is_shader_idle() then
				draw_sprite(self.children.center)
				if self.children.front then draw_sprite(self.children.front) end
			else
				apply_dissolve(self.children.center, self)
				if self.children.front then
					apply_dissolve(self.children.front, self)
				end
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
	local overlay = game().C.WHITE
	if self.area and self.area.config.type == "deck" then
		overlay = {0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50, 1}
		draw_sprite(self.children.back, overlay)
	elseif self:is_shader_idle() then
		draw_sprite(self.children.back)
	else
		apply_dissolve(self.children.back, self)
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
		if not self:is_shader_idle() then
			self:sync_shadow_state()
		end
	end

	game().shared_shadow = self.sprite_facing == 'front' and self.children.center or self.children.back

	if layer == 'shadow' or layer == 'both' then
		self:draw_shadow()
	end

	if layer == 'card' or layer == 'both' then
		if self.area ~= game().dealt_letters and self.children.focused_ui then
			self.children.focused_ui:draw()
		end

		if not self:is_shader_idle() then
			self:update_tilt()
		end

		if self.children.particles then self.children.particles:draw() end
		self:draw_market_widgets()

		if self.sprite_facing == 'front' then
			self:draw_front()
		else
			self:draw_back()
		end

		if self.children.overwrite and self.tilt_var then
			self.children.overwrite.overwrite_tilt_var = Tables.deep_clone(self.tilt_var)
		end

		self:draw_leftover_children()

		if self.children.overwrite then
			love.graphics.push()
			love.graphics.setColor(game().C.BLUE)
			game().OVERLAY_TINT = {1, 1, 1, math.sin(5*game().TIMERS.REAL)}
			self.children.overwrite:draw('card')
			game().OVERLAY_TINT = nil
			love.graphics.pop()
		end

		if self.area == game().dealt_letters and self.children.focused_ui then
			self.children.focused_ui:draw()
		end

		HitOrder.track_hit_target(self)
		self:draw_boundingrect()
	end
end
