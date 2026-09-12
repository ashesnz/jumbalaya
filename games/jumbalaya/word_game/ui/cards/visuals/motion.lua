--[[ word_game/ui/cards/visuals/motion.lua - Card motion, flip, and timed FX ]]

---@class (partial) Card : EaseNode
local GameRT = require("word_game.ui.util.game_runtime")
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local DissolveFX = require "word_game.ui.effects.dissolve_fx"

local function runtime() return GameRT.game() end

function Card:explode(dissolve_colours, explode_time_fac)
    local explode_time = 1.3*(explode_time_fac or 1)*(math.sqrt(runtime().SETTINGS.GAMESPEED))
    self.dissolve = 0
    self.dissolve_colours = dissolve_colours
        or {runtime().C.WHITE}

    local start_time = runtime().TIMERS.TOTAL
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
                    percent = (runtime().TIMERS.TOTAL - start_time)/explode_time
                    self.bounce.r = 0.05*(math.sin(5*runtime().TIMERS.TOTAL) + math.cos(0.33 + 41.15332*runtime().TIMERS.TOTAL) + math.cos(67.12*runtime().TIMERS.TOTAL))*percent
                    self.bounce.scale = percent*0.15
                end
                if runtime().TIMERS.TOTAL - start_time > 1.5*explode_time then return true end
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
            runtime().VIBRATION = runtime().VIBRATION + 1
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

function Card:start_dissolve(dissolve_colours, silent, dissolve_time_fac, no_bounce)
	local dt = 0.7*(dissolve_time_fac or 1)
	DissolveFX.run(self, {
		mode = 'out',
		duration = dt,
		remove = true,
		colours = dissolve_colours
			or {runtime().C.BLACK, runtime().C.ORANGE, runtime().C.RED, runtime().C.GOLD, runtime().C.MUTED_GREY},
		pulse = not no_bounce,
		fade = {delay = 0.7 * dt, duration = 0.3 * dt},
		on_start = not silent and function()
			play_sfx('whoosh2', math.random()*0.2 + 0.9, 0.5)
			play_sfx('crumple'..math.random(1, 5), math.random()*0.2 + 0.9, 0.5)
		end or nil,
	})
end

function Card:begin_materialize(dissolve_colours, silent, timefac)
	local dt = 0.6*(timefac or 1)
	self.states.visible = true
	self.states.hover.can = false
	self.children.particles = DissolveFX.run(self, {
		mode = 'in',
		duration = dt,
		colours = dissolve_colours or
		(self.ability.set == 'Companion' and {runtime().C.RARITY[self.config.center.rarity]}) or
		(self.ability.set == 'Perk' and {runtime().C.SECONDARY_SET.Perk, runtime().C.CLEAR}) or
		{runtime().C.GREEN},
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
		if not runtime().last_materialized or runtime().last_materialized +0.01 < runtime().TIMERS.REAL or runtime().last_materialized > runtime().TIMERS.REAL then
			runtime().last_materialized = runtime().TIMERS.REAL
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
    if self.children.h_popup then
        self.children.h_popup:set_alignment(self:align_h_popup())
    end
end

function Card:pulse(scale, rot_amount)
    local rot_amt = rot_amount and 0.4*pick_random({rot_amount, -rot_amount}) or pick_random({0.16, -0.16})
    scale = scale and scale*0.4 or 0.11
    EaseNode.pulse(self, scale, rot_amt)
end
