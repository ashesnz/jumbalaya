--[[
	word_game/ui/fx.lua - Low-level attention text primitive (UIBox + FlowText).

	Prefer word_feedback for gameplay copy; model code should use model/feedback.lua.
	These stay globals (`spawn_attention`, `build_*`) for legacy call sites.
]]
local Scheduler = require "app.effects.timeline_scheduler"


function spawn_attention(args)
    args = args or {}
    args.text = args.text or 'test'
    args.scale = args.scale or 1
    args.colour = deep_clone(args.colour or G.C.WHITE)
    args.hold = (args.hold or 0) + 0.1*(G.TIME_SCALE)
    args.pos = args.pos or {x = 0, y = 0}
    args.align = args.align or 'cm'
    args.emboss = args.emboss or nil

    args.fade = 1

    if args.cover then
      args.cover_colour = deep_clone(args.cover_colour or G.C.RED)
      args.cover_colour_l = deep_clone(tint(args.cover_colour, 0.2))
      args.cover_colour_d = deep_clone(shade(args.cover_colour, 0.2))
    else
      args.cover_colour = deep_clone(G.C.CLEAR)
    end

    args.uibox_config = {
      align = args.align or 'cm',
      offset = args.offset or {x=0,y=0}, 
      major = args.cover or args.major or nil,
    }

    Scheduler.add{
      mode = 'delayed',
      delay = 0,
      blockable = false,
      blocking = false,
      func = function()
          args.AT = LayoutView{
            T = {args.pos.x,args.pos.y,0,0},
            definition = 
              {n=G.UI.ROOT, config = {align = args.cover_align or 'cm', minw = (args.cover and args.cover.T.w or 0.001) + (args.cover_padding or 0), minh = (args.cover and args.cover.T.h or 0.001) + (args.cover_padding or 0), padding = 0.03, r = 0.1, emboss = args.emboss, colour = args.cover_colour}, nodes={
                {n=G.UI.OBJECT, config={draw_layer = 1, object = FlowText({scale = args.scale, string = args.text, maxw = args.maxw, colours = {args.colour},float = not args.bump, shadow = true, silent = not args.noisy, args.scale, pop_in = 0, pop_in_rate = 6, rotate = args.rotate or nil, bump = args.bump, bump_rate = args.bump_rate, bump_amount = args.bump_amount})}},
              }}, 
            config = args.uibox_config
          }
          args.AT.spawn_attention = true

          args.text = args.AT.root_node.children[1].config.object
          args.text:pulse(args.pulse_amount or 0.5)
          
          if args.cover then
            Particles(args.pos.x,args.pos.y, 0,0, {
              timer_type = 'TOTAL',
              timer = 0.01,
              pulse_max = 15,
              max = 0,
              scale = 0.3,
              vel_variation = 0.2,
              padding = 0.1,
              fill=true,
              lifespan = 0.5,
              speed = 2.5,
              attach = args.AT.root_node,
              colours = {args.cover_colour, args.cover_colour_l, args.cover_colour_d},
          })
          end
          if args.comic_burst then
            local ComicBurst = require("word_game.ui.comic_burst")
            args.burst = ComicBurst(args.pos.x, args.pos.y, 0, 0, {
              attach = args.AT,
              radius = args.burst_radius or 0.62,
            })
          elseif args.backdrop_colour then
            args.backdrop_colour = deep_clone(args.backdrop_colour)
            Particles(args.pos.x,args.pos.y,0,0,{
              timer_type = 'TOTAL',
              timer = 5,
              scale = 2.4*(args.backdrop_scale or 1), 
              lifespan = 5,
              speed = 0,
              attach = args.AT,
              colours = {args.backdrop_colour}
            })
          end
          return true
      end
      }

      Scheduler.add{
        mode = 'delayed',
        delay = args.hold,
        blockable = false,
        blocking = false,
        func = function()
          if not args.start_time then
            args.start_time = G.TIMERS.TOTAL
            args.text:pop_out(3)
          else
            --args.AT:align_to_attach()
            args.fade = math.max(0, 1 - 3*(G.TIMERS.TOTAL - args.start_time))
            if args.cover_colour then args.cover_colour[4] = math.min(args.cover_colour[4], 2*args.fade) end
            if args.cover_colour_l then args.cover_colour_l[4] = math.min(args.cover_colour_l[4], args.fade) end
            if args.cover_colour_d then args.cover_colour_d[4] = math.min(args.cover_colour_d[4], args.fade) end
            if args.backdrop_colour then args.backdrop_colour[4] = math.min(args.backdrop_colour[4], args.fade) end
            if args.burst then args.burst.alpha = args.fade end
            args.colour[4] = math.min(args.colour[4], args.fade)
            if args.fade <= 0 then
              args.AT:remove()
              return true
            end
          end
        end
      }
  end


