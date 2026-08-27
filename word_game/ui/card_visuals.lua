--[[ word_game/ui/card_visuals.lua - sprites and motion/dissolve/draw ]]

---@class (partial) Card : EaseNode

local Scheduler = require "app.effects.scheduler"
local DissolveFX = require "app.effects.dissolve_fx"
local LetterFaces = require "word_game.ui.letter_card_faces"

-- Finish editions rendered as shader overlays, keyed by edition flag.
local FINISH_SHADERS = {
	foil = "foil",
	holo = "holo",
	polychrome = "polychrome",
}

-- Sets whose body sprite doubles as the letter-tile face. Letter cards render
-- as a tinted frame (center) plus a shared glyph layer (front).
local FLAT_LETTER_SETS = { Default = true, Enhanced = true }

-- Data-driven placeholder art for locked/undiscovered centers. Entries name
-- globals holding the sprite pos; `veil_usable_only` sets additionally
-- require the center to be flagged usable before veiling.
local PLACEHOLDER_ART = {
	locked = {
		Companion = { atlas = "Companion", pos = "companion_locked" },
		Perk = { atlas = "Perk", pos = "perk_locked" },
	},
	demo = { atlas = "Charm", pos = "letter_locked" },
	undiscovered = {
		Companion = "companion_undiscovered",
		Finish = "companion_undiscovered",
		Perk = "perk_undiscovered",
		Bundle = "booster_undiscovered",
	},
	veil_usable_only = {
		Charm = "charm_undiscovered",
		Orbit = "orbit_undiscovered",
		Phantom = "phantom_undiscovered",
	},
}

--- Picks placeholder art for a center the player hasn't earned/discovered,
--- or nil when real art should be shown.
---@param self Card
---@param center table
---@return table|nil {atlas: table, pos: table}
local function placeholder_art(self, center)
	if not center or not center.set then return nil end
	if self.params.bypass_discovery_center then return nil end

	local locked = PLACEHOLDER_ART.locked[center.set]
	if locked and not center.unlocked then
		return { atlas = G.TEXTURE_ATLASES[locked.atlas], pos = G[locked.pos].pos }
	end

	if center.usable and center.demo then
		local demo = PLACEHOLDER_ART.demo
		return { atlas = G.TEXTURE_ATLASES[demo.atlas], pos = G[demo.pos].pos }
	end

	local veil_pos = PLACEHOLDER_ART.undiscovered[center.set]
		or (center.usable and PLACEHOLDER_ART.veil_usable_only[center.set])
	if veil_pos and not center.discovered then
		return { atlas = G.TEXTURE_ATLASES[center.atlas or center.set], pos = G[veil_pos].pos }
	end

	return nil
end

--- Creates/updates the card's body sprite (center), optional flat letter
--- face, and back sprite. Locked/undiscovered centers get placeholder art via
--- the PLACEHOLDER_ART table.
--- @param _center table|nil center definition to build/refresh the center+back sprites for
--- @param _front table|nil base card data to build/refresh the letter face for
function Card:set_sprites(_center, _front)
	if _center and _center.set then
		local ph = placeholder_art(self, _center)
		local atlas, pos
		if ph then
			atlas, pos = ph.atlas, ph.pos
		elseif _center.set == 'Companion' or _center.usable or _center.set == 'Perk' then
			atlas = G.TEXTURE_ATLASES[_center.set]
			pos = self.config.center.pos
		else
			atlas = G.TEXTURE_ATLASES[_center.atlas or 'centers']
			pos = _center.pos
		end

		if self.children.center then
			self.children.center.atlas = atlas
			self.children.center:set_sprite_pos(pos)
		else
			self.children.center = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, atlas, pos)
			self.children.center.states.hover = self.states.hover
			self.children.center.states.click = self.states.click
			self.children.center.states.drag = self.states.drag
			self.children.center.states.collide.can = false
			self.children.center:set_role({major = self, role_type = 'Glued', draw_major = self})
		end

		if not self.children.back then
			local back_atlas = G.TEXTURE_ATLASES["playing_back"] or G.TEXTURE_ATLASES["centers"]
			local default_back = G.P_CENTERS and G.P_CENTERS['deck_alpha']
			local back_pos = G.TEXTURE_ATLASES["playing_back"] and {x = 0, y = 0}
				or (self.params.bypass_back or (self.playing_card and G.GAME and G.GAME[self.back] and G.GAME[self.back].pos)
				or (default_back and default_back.pos) or {x = 0, y = 0})
			self.children.back = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, back_atlas, back_pos)
			self.children.back.states.hover = self.states.hover
			self.children.back.states.click = self.states.click
			self.children.back.states.drag = self.states.drag
			self.children.back.states.collide.can = false
			self.children.back:set_role({major = self, role_type = 'Glued', draw_major = self})
		elseif G.TEXTURE_ATLASES["playing_back"] and self.children.back.atlas ~= G.TEXTURE_ATLASES["playing_back"] then
			self.children.back.atlas = G.TEXTURE_ATLASES["playing_back"]
			self.children.back:set_sprite_pos({x = 0, y = 0})
		end
	end

	-- Letter cards: tinted frame on center, shared glyph atlas on front.
	if _front then
		local is_letter = self.config.center and FLAT_LETTER_SETS[self.config.center.set]
			and LetterFaces.is_letter_face(_front)
		if is_letter then
			local frame_atlas = LetterFaces.frame_atlas()
			local letters_atlas = LetterFaces.letters_atlas()
			local glyph_pos = _front.pos or LetterFaces.glyph_pos(_front.letter)

			if frame_atlas and self.children.center then
				self.children.center.atlas = frame_atlas
				self.children.center:set_sprite_pos({ x = 0, y = 0 })
			end

			if letters_atlas then
				if self.children.front then
					self.children.front.atlas = letters_atlas
					self.children.front:set_sprite_pos(glyph_pos)
				else
					self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, letters_atlas, glyph_pos)
					self.children.front.states.hover = self.states.hover
					self.children.front.states.click = self.states.click
					self.children.front.states.drag = self.states.drag
					self.children.front.states.collide.can = false
					self.children.front:set_role({major = self, role_type = 'Glued', draw_major = self})
				end
			end
		else
			local face_atlas = G.TEXTURE_ATLASES[_front.atlas] or G.TEXTURE_ATLASES.letters
			local face_pos = self.config.card and self.config.card.pos
			if self.children.front then
				self.children.front.atlas = face_atlas
				self.children.front:set_sprite_pos(face_pos)
			else
				self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, face_atlas, face_pos)
				self.children.front.states.hover = self.states.hover
				self.children.front.states.click = self.states.click
				self.children.front.states.drag = self.states.drag
				self.children.front.states.collide.can = false
				self.children.front:set_role({major = self, role_type = 'Glued', draw_major = self})
			end
		end
	end
end


-- ============ Visual effects (destroy / dissolve / materialize) ============
-- Timed, event-driven animations (via `G.TIMELINE`) for card destruction
-- and creation. These schedule multiple `Tween`s with delays rather than
-- blocking, so callers should not assume the card is gone/visible
-- immediately after calling these.

--- Plays a shake-and-burst destruction animation (particles + bounce wobble),
--- ending in a dissolve. Used for cards destroyed dramatically (vs. a plain
--- `start_dissolve`).
--- @param dissolve_colours table|nil particle/dissolve tint colours (default white)
--- @param explode_time_fac number|nil multiplier on the base explosion duration
function Card:explode(dissolve_colours, explode_time_fac)
    local explode_time = 1.3*(explode_time_fac or 1)*(math.sqrt(G.SETTINGS.GAMESPEED))
    self.dissolve = 0
    self.dissolve_colours = dissolve_colours
        or {G.C.WHITE}

    local start_time = G.TIMERS.TOTAL
    local percent = 0
    play_sfx('explosion_buildup1')
    self.bounce = {
        scale = 0,
        r = 0,
        handled_elsewhere = true,
        start_time = start_time, 
        end_time = start_time + explode_time
    }

    local childParts1 = Particles(0, 0, 0,0, {
        timer_type = 'TOTAL',
        timer = 0.01*explode_time,
        scale = 0.2,
        speed = 2,
        lifespan = 0.2*explode_time,
        attach = self,
        colours = self.dissolve_colours,
        fill = true
    })
    local childParts2 = nil

    Scheduler.add{
        blockable = false,
        func = (function()
                if self.bounce then 
                    percent = (G.TIMERS.TOTAL - start_time)/explode_time
                    self.bounce.r = 0.05*(math.sin(5*G.TIMERS.TOTAL) + math.cos(0.33 + 41.15332*G.TIMERS.TOTAL) + math.cos(67.12*G.TIMERS.TOTAL))*percent
                    self.bounce.scale = percent*0.15
                end
                if G.TIMERS.TOTAL - start_time > 1.5*explode_time then return true end
            end)
    }
    Scheduler.add{
        mode = 'tween',
        blockable = false,
        ref_table = self,
        ref_value = 'dissolve',
        ease_to = 0.3,
        delay =  0.9*explode_time,
        func = function(t) return t end
    }

    Scheduler.add{
        mode = 'delayed',
        blockable = false,
        delay =  0.9*explode_time,
        func = (function()
            childParts2 = Particles(0, 0, 0,0, {
                timer_type = 'TOTAL',
                pulse_max = 30,
                timer = 0.003,
                scale = 0.6,
                speed = 15,
                lifespan = 0.5,
                attach = self,
                colours = self.dissolve_colours,
            })
            childParts2:set_role({r_bond = 'Weak'})
            Scheduler.add{
                mode = 'tween',
                blockable = false,
                ref_table = self,
                ref_value = 'dissolve',
                ease_to = 1,
                delay =  0.1*explode_time,
                func = function(t) return t end
            }
            self:pulse()
            G.VIBRATION = G.VIBRATION + 1
            play_sfx('explosion_release1')
            childParts1:fade(0.3*explode_time) return true end)
    }

    Scheduler.add{
        mode = 'delayed',
        blockable = false,
        delay =  1.4*explode_time,
        func = function()
            Scheduler.add{
                mode = 'tween',
                blockable = false, 
                blocking = false,
                ref_value = 'scale',
                ref_table = childParts2,
                ease_to = 0,
                delay = 0.1*explode_time
            }
            return true end
    }

    Scheduler.add{
        mode = 'delayed',
        blockable = false,
        delay =  1.5*explode_time,
        func = function() self:remove() return true end
    }
end

--- Glass-shatter destruction effect: quick, snappy dissolve with glass
--- sound effects. Built on the generic DissolveFX timeline.
function Card:shatter()
	local dt = 0.7
	self.shattered = true
	DissolveFX.run(self, {
		duration = dt,
		remove = true,
		colours = {{1, 1, 1, 0.8}},
		pulse = true,
		particle = {timer = 0.007, scale = 0.3, speed = 4, lifespan = 0.5},
		fade = {delay = 0.5 * dt, duration = 0.15 * dt},
		tween_delay = 0.5 * dt,
		on_start = function()
			play_sfx('glass'..math.random(1, 6), math.random()*0.2 + 0.9, 0.5)
			play_sfx('generic1', math.random()*0.2 + 0.9, 0.5)
		end,
	})
end

--- Standard dissolve-away destruction effect (fade + particles), the default
--- way most cards are removed with visual feedback (discards, companions being
--- destroyed by effects, etc.). Built on the generic DissolveFX timeline.
--- @param dissolve_colours table|nil dissolve/particle tint colours
--- @param silent boolean|nil skip sound effects
--- @param dissolve_time_fac number|nil multiplier on the base dissolve duration
--- @param no_bounce boolean|nil skip the bounce-up wobble animation
function Card:start_dissolve(dissolve_colours, silent, dissolve_time_fac, no_bounce)
	local dt = 0.7*(dissolve_time_fac or 1)
	DissolveFX.run(self, {
		mode = 'out',
		duration = dt,
		remove = true,
		colours = dissolve_colours
			or {G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.MUTED_GREY},
		pulse = not no_bounce,
		fade = {delay = 0.7 * dt, duration = 0.3 * dt},
		on_start = not silent and function()
			play_sfx('whoosh2', math.random()*0.2 + 0.9, 0.5)
			play_sfx('crumple'..math.random(1, 5), math.random()*0.2 + 0.9, 0.5)
		end or nil,
	})
end

--- Inverse of `start_dissolve`: fades a newly-created card in, with tint
--- colour defaulting based on the card's set (rarity colour for companions,
--- set colour for charm/orbit/phantom/etc.) if not given explicitly.
--- Built on the generic DissolveFX timeline.
--- @param dissolve_colours table|nil override tint colours
--- @param silent boolean|nil skip sound effects
--- @param timefac number|nil multiplier on the base materialize duration
function Card:begin_materialize(dissolve_colours, silent, timefac)
	local dt = 0.6*(timefac or 1)
	self.states.visible = true
	self.states.hover.can = false
	self.children.particles = DissolveFX.run(self, {
		mode = 'in',
		duration = dt,
		colours = dissolve_colours or
		(self.ability.set == 'Companion' and {G.C.RARITY[self.config.center.rarity]}) or
		(self.ability.set == 'Orbit'  and {G.C.SECONDARY_SET.Orbit}) or
		(self.ability.set == 'Charm' and {G.C.SECONDARY_SET.Charm}) or
		(self.ability.set == 'Phantom' and {G.C.SECONDARY_SET.Phantom}) or
		(self.ability.set == 'Bundle' and {G.C.BOOSTER}) or
		(self.ability.set == 'Perk' and {G.C.SECONDARY_SET.Perk, G.C.CLEAR}) or
		{G.C.GREEN},
		pulse = true,
		particle = {timer = 0.025, scale = 0.25, speed = 3, lifespan = 0.7},
		fade = {delay = 0.5 * dt, cap = true},
		on_finish = function(card)
			card.states.hover.can = true
			if card.children.particles then
				card.children.particles:remove()
				card.children.particles = nil
			end
		end,
	})
	if not silent then
		if not G.last_materialized or G.last_materialized +0.01 < G.TIMERS.REAL or G.last_materialized > G.TIMERS.REAL then
			G.last_materialized = G.TIMERS.REAL
			Scheduler.add{
				blockable = false,
				func = function()
						play_sfx('whoosh1', math.random()*0.1 + 0.6,0.3)
						play_sfx('crumple'..math.random(1,5), math.random()*0.2 + 1.2,0.8)
					return true end
			}
		end
	end
end


function Card:flip()
    if self.facing == 'front' then 
        self.flipping = 'f2b'
        self.facing='back'
        self.pinch.x = true
    elseif self.facing == 'back' then
        self.ability.wheel_flipped = nil
        self.flipping = 'b2f'
        self.facing='front'
        self.pinch.x = true
    end
end


function Card:hard_set_T(X, Y, W, H)
    local x = (X or self.T.x)
    local y = (Y or self.T.y)
    local w = (W or self.T.w)
    local h = (H or self.T.h)
    EaseNode.hard_set_T(self,x, y, w, h)
    if self.children.front then self.children.front:hard_set_T(x, y, w, h) end
    self.children.back:hard_set_T(x, y, w, h)
    self.children.center:hard_set_T(x, y, w, h)
end


function Card:move(dt)
    EaseNode.move(self, dt)
    --self:align()
    if self.children.h_popup then
        self.children.h_popup:set_alignment(self:align_h_popup())
    end
end


function Card:pulse(scale, rot_amount)
    --G.VIBRATION = G.VIBRATION + 0.4
    local rot_amt = rot_amount and 0.4*pick_random({rot_amount, -rot_amount}) or pick_random({0.16, -0.16})
    scale = scale and scale*0.4 or 0.11
    EaseNode.pulse(self, scale, rot_amt)
end


--- Syncs the shader clock and child scales that shadow/dissolve passes read.
function Card:sync_shadow_state()
	self.ARGS.send_to_shader = self.ARGS.send_to_shader or {}
	self.ARGS.send_to_shader[1] = math.min(self.VT.r*3, 1) + G.TIMERS.REAL/(28) + (self.bounce and self.bounce.r*20 or 0) + self.tilt_var.amt
	self.ARGS.send_to_shader[2] = G.TIMERS.REAL

	for _, child in pairs(self.children) do
		child.VT.scale = self.VT.scale
	end
end

--- Drops the soft shadow under the card unless suppressed.
function Card:draw_shadow()
	local wants_shadow = not self.no_shadow
		and G.SETTINGS.GRAPHICS.shadows == 'On'
		and self.ability.effect ~= 'Glass Card'
		and not self.greyed
		and ((self.area and self.area ~= G.discard and self.area.config.type ~= 'deck')
			or not self.area or self.states.drag.is)

	if wants_shadow then
		-- Selected/dragged cards float higher off the felt than resting ones.
		self.shadow_height = (self.selected or self.states.drag.is) and 0.35
			or (self.area and self.area.config.type == 'title_2') and 0.04
			or 0.1
		if self.inspecting then
			self.shadow_height = self.shadow_height + 0.22
		end
		G.shared_shadow:apply_shader_effect('dissolve', self.shadow_height)
	end
end

--- Aims the dissolve shaders' light: cursor-tracking on hover/focus, a slow
--- ambient drift otherwise.
function Card:update_tilt()
	self.tilt_var = self.overwrite_tilt_var or self.tilt_var
		or {mx = 0, my = 0, dx = self.tilt_var.dx or 0, dy = self.tilt_var.dy or 0, amt = 0}
	if self.overwrite_tilt_var then return end

	local tilt_factor = 0.3
	if self.states.focus.is then
		self.tilt_var.mx, self.tilt_var.my =
			G.INPUT.cursor_position.x + self.tilt_var.dx*self.T.w*G.TILESCALE*G.TILESIZE,
			G.INPUT.cursor_position.y + self.tilt_var.dy*self.T.h*G.TILESCALE*G.TILESIZE
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1 + self.tilt_var.dx + self.tilt_var.dy - 1)*tilt_factor
	elseif self.states.hover.is then
		self.tilt_var.mx, self.tilt_var.my = G.INPUT.cursor_position.x, G.INPUT.cursor_position.y
		self.tilt_var.amt = math.abs(self.hover_offset.y + self.hover_offset.x - 1)*tilt_factor
	elseif self.ambient_tilt then
		local tilt_angle = G.TIMERS.REAL*(1.56 + (self.ID/1.14212)%1) + self.ID/1.35122
		self.tilt_var.mx = ((0.5 + 0.5*self.ambient_tilt*math.cos(tilt_angle))*self.VT.w+self.VT.x+G.ROOM.T.x)*G.TILESIZE*G.TILESCALE
		self.tilt_var.my = ((0.5 + 0.5*self.ambient_tilt*math.sin(tilt_angle))*self.VT.h+self.VT.y+G.ROOM.T.y)*G.TILESIZE*G.TILESCALE
		self.tilt_var.amt = self.ambient_tilt*(0.5+math.cos(tilt_angle))*tilt_factor
	end
end

--- Marketplace widgets: price tag plus buy / buy-and-use buttons, which are
--- only live while the card is selected in the shop.
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

--- Front art: letter face first (unless a negative edition replaces it), then
--- the undiscovered veil, then every finish/seal/sticker/state overlay.
function Card:draw_front()
	if self.edition and self.edition.negative then
		self.children.center:apply_shader_effect('negative', nil, self.ARGS.send_to_shader)
		if self.children.front then
			self.children.front:apply_shader_effect('negative', nil, self.ARGS.send_to_shader)
		end
	elseif not self.greyed then
		if LetterFaces.is_letter_card(self) then
			G.OVERLAY_TINT = LetterFaces.fill_color(self.base and self.base.color)
			self.children.center:apply_shader_effect('dissolve')
			G.OVERLAY_TINT = nil
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

	-- Undiscovered companions/perks wear a silhouetted veil instead of their art.
	if not self.config.center.discovered and (self.ability.usable or self.config.center.unlocked)
		and not self.config.center.demo and not self.bypass_discovery_center then
		local shared_sprite = (self.ability.set == 'Finish' or self.ability.set == 'Companion')
			and G.shared_undiscovered_companion or G.shared_undiscovered_charm
		local scale_mod = -0.05 + 0.05*math.sin(1.8*G.TIMERS.REAL)
		local rotate_mod = 0.03*math.sin(1.219*G.TIMERS.REAL)

		shared_sprite.role.draw_major = self
		shared_sprite:apply_shader_effect('dissolve', nil, nil, nil, self.children.center, scale_mod, rotate_mod)
	end

	local has_overlays = self.edition or self.seal
		or self.ability.set == 'Phantom' or self.debuff or self.greyed
		or self.ability.set == 'Perk' or self.ability.set == 'Bundle'
		or self.config.center.demo
	if has_overlays then
		if self.ability.set == 'Perk' or self.config.center.demo then
			self.children.center:apply_shader_effect('perk', nil, self.ARGS.send_to_shader)
		end
		if self.ability.set == 'Bundle' or self.ability.set == 'Phantom' then
			self.children.center:apply_shader_effect('booster', nil, self.ARGS.send_to_shader)
		end

		-- Each finished edition layers its signature shine on centre and front.
		for finish_flag, shader in pairs(FINISH_SHADERS) do
			if self.edition and self.edition[finish_flag] then
				self.children.center:apply_shader_effect(shader, nil, self.ARGS.send_to_shader)
				if self.children.front then
					self.children.front:apply_shader_effect(shader, nil, self.ARGS.send_to_shader)
				end
			end
		end
		if self.edition and self.edition.negative then
			self.children.center:apply_shader_effect('negative_shine', nil, self.ARGS.send_to_shader)
		end

		if self.seal then
			G.shared_seals[self.seal].role.draw_major = self
			G.shared_seals[self.seal]:apply_shader_effect('dissolve', nil, nil, nil, self.children.center)
			if self.seal == 'Gold' then
				G.shared_seals[self.seal]:apply_shader_effect('perk', nil, self.ARGS.send_to_shader, nil, self.children.center)
			end
		end
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

--- Back art: deck-stack cards shade progressively deeper into the pile.
function Card:draw_back()
	local overlay = G.C.WHITE
	if self.area and self.area.config.type == 'deck' then
		overlay = {0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50,
			0.5 + ((#self.area.cards - self.slot)%7)/50, 1}
		self.children.back:draw(overlay)
	else
		self.children.back:apply_shader_effect('dissolve')
	end
end

--- Children with dedicated passes; anything else renders here.
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

--- Full-card render. `layer` selects 'shadow', 'card', or 'both' (default).
--- Hand-area focus UI renders above the card; everywhere else it renders below.
function Card:draw(layer)
	layer = layer or 'both'

	self.hover_tilt = 1
	if not self.states.visible then return end

	if layer == 'shadow' or layer == 'both' then
		self:sync_shadow_state()
	end

	-- The shadow quad follows whichever face is currently up.
	G.shared_shadow = self.sprite_facing == 'front' and self.children.center or self.children.back

	if layer == 'shadow' or layer == 'both' then
		self:draw_shadow()
	end

	if layer == 'card' or layer == 'both' then
		if self.area ~= G.hand and self.children.focused_ui then
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
			love.graphics.setColor(G.C.BLUE)
			G.OVERLAY_TINT = {1, 1, 1, math.sin(5*G.TIMERS.REAL)}
			self.children.overwrite:draw('card')
			G.OVERLAY_TINT = nil
			love.graphics.pop()
		end

		if self.area == G.hand and self.children.focused_ui then
			self.children.focused_ui:draw()
		end

		if WORD_GAME and WORD_GAME.LetterOverlay then
			WORD_GAME.LetterOverlay.draw(self)
		end

		track_hit_target(self)
		self:draw_boundingrect()
	end
end
