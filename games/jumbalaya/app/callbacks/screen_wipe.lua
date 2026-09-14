-- Application screen transitions and their particle effects.
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"

local BridgeRuntime = require("app.runtime")
local Funcs = require("app.callbacks.funcs")
local function game() return BridgeRuntime.game() end

local function sync_screen_wipe_card()
	local card = game().screenwipecard
	if not card or not game().screenwipe then return end
	local host = game().screenwipe.find_node_by_id and game().screenwipe:find_node_by_id('screenwipe_card')
	if host then
		card:set_role({
			role_type = 'Minor',
			major = host,
			xy_bond = 'Strong',
			wh_bond = 'Weak',
			scale_bond = 'Weak',
		})
	end
	card.states.visible = true
	card:hard_set_T(card.T.x, card.T.y, game().CARD_W, game().CARD_H)
	if card.move_with_major then
		card:move_with_major(0)
	end
end

Funcs.register("wipe_in",  function(message, no_card, timefac, alt_colour)
  timefac = timefac or 1
  if game().screenwipe then return end
  game().INPUT.locks.wipe = true
  game().STAGE_OBJECT_INTERRUPT = true
  local colours = {
    black = colour_from_hex("4f6367FF"),
    white = {1, 1, 1, 1}
  }
  if not no_card then
    local face, center = nil, nil
    local deck = rawget(_G, "WORD_GAME") and WORD_GAME.Deck
    if deck and deck.random_wipe_card then
      face, center = deck.random_wipe_card()
    end
    if face and center then
      game().screenwipecard = Card(0, 0, game().CARD_W, game().CARD_H, face, center)
      game().screenwipecard.sprite_facing = 'back'
      game().screenwipecard.facing = 'back'
      game().screenwipecard.states.hover.can = false
      game().screenwipecard.states.visible = true
      game().screenwipecard:pulse(0.5, 1)
      game().screenwipecard:hard_set_T(0, 0, game().CARD_W, game().CARD_H)
    end
  end
  local message_t = nil
  if message then
    message_t = {}
    for k, v in ipairs(message) do
      table.insert(message_t, {n=game().UI.ROW, config={align = "cm"}, nodes={{n=game().UI.OBJECT, config={object = FlowText({string = v or '', colours = {math.min(game().C.BACKGROUND.C[1], game().C.BACKGROUND.C[2]) > 0.5 and game().C.BLACK or game().C.WHITE},shadow = true, silent = k ~= 1, float = true, scale = 1.3, pop_in = 0, pop_in_rate = 2, rotate = 1})}}}})
    end
  end

  local row_nodes = {}
  if message then
    row_nodes[#row_nodes + 1] = {n=game().UI.ROW, config={id = 'text', align = "cm", padding = 0.7}, nodes=message_t}
  end
  if not no_card then
    row_nodes[#row_nodes + 1] = {n=game().UI.OBJECT, config={
      id = 'screenwipe_card',
      object = game().screenwipecard,
      w = game().CARD_W,
      h = game().CARD_H,
    }}
  end

  local ViewHost = require("jumbalaya-engine.panels.view_host")
  game().screenwipe = ViewHost.create{
    definition =
      {n=game().UI.ROOT, config = {align = "cm", minw =0, minh =0 ,padding = 0.15, r = 0.1, colour = game().C.CLEAR}, nodes={
        {n=game().UI.ROW, config={align = "cm"}, nodes=row_nodes},
      }},
    config = {align="cm", offset = {x=0,y=0}, major = game().ROOM_ATTACH}
  }
  game().screenwipe.colours = colours
  game().screenwipe.children.particles = Particles(0, 0, 0,0, {
    timer = 0, max = 1, scale = 40, speed = 0, lifespan = 1.7*timefac,
    attach = game().screenwipe, colours = {alt_colour or game().C.BACKGROUND.C}
  })
  game().STAGE_OBJECT_INTERRUPT = nil
  game().screenwipe.alignment.offset.y = 0
  if game().screenwipe.recalculate then game().screenwipe:recalculate() end
  sync_screen_wipe_card()
  if message then
    for _, v in ipairs(game().screenwipe:find_node_by_id('text').children) do
      v.children[1].config.object:pulse()
    end
  end
  Scheduler.add{
    mode = 'window', delay = 0.7, persistent = true, blockable = false, timer = 'REAL',
    func = function()
      if not no_card and game().screenwipecard and game().screenwipecard.flip then game().screenwipecard:flip() end
      return true
    end
  }
end)

Funcs.register("wipe_out",  function()
  Scheduler.add{
    persistent = true,
    func = function()
      Scheduler.delayed{delay = 0.3}
      game().screenwipe.children.particles.max = 0
      for _, colour in ipairs({'black', 'white'}) do
        Scheduler.add{mode = 'tween', persistent = true, blockable = false,
          blocking = false, timer = 'REAL', ref_table = game().screenwipe.colours[colour],
          ref_value = 4, ease_to = 0, delay = 0.3, func = function(t) return t end}
      end
      return true
    end
  }
  Scheduler.add{
    mode = 'delayed', delay = 0.55, persistent = true, blocking = false, timer = 'REAL',
    func = function()
      if game().screenwipecard then game().screenwipecard:start_dissolve({game().C.BLACK, game().C.ORANGE,game().C.GOLD, game().C.RED}) end
      local text = game().screenwipe:find_node_by_id('text')
      if text then for _, v in ipairs(text.children) do v.children[1].config.object:pop_out(4) end end
      return true
    end
  }
  Scheduler.add{
    mode = 'delayed', delay = 1.1, persistent = true, blocking = false, timer = 'REAL',
    func = function()
      game().screenwipe.children.particles:remove(); game().screenwipe:remove()
      game().screenwipe.children.particles = nil; game().screenwipe = nil; game().screenwipecard = nil
      game().INPUT.locks.wipe = false
      return true
    end
  }
  Scheduler.add{mode = 'delayed', delay = 1.2, persistent = true,
    blocking = true, timer = 'REAL', func = function() return true end}
end)

function Game:queue_during_wipe(fn)
  Funcs.dispatch("wipe_in")
  fn()
  Funcs.dispatch("wipe_out")
end

function Game:queue_wipe_transition(steps, opts)
  opts = opts or {}
  if opts.flush_timeline and game().TIMELINE then game().TIMELINE:flush() end
  if opts.pause then game().SETTINGS.paused = true end
  Funcs.dispatch("wipe_in", opts.message, opts.no_card, opts.timefac, opts.alt_colour)
  for _, step in ipairs(steps or {}) do
    local fn = type(step) == "function" and step or step.func
    Scheduler.add{
      persistent = true,
      blockable = type(step) == "table" and step.blockable ~= false or true,
      blocking = type(step) == "table" and step.blocking or false,
      func = function()
        return fn()
      end,
    }
  end
  Funcs.dispatch("wipe_out")
end

return true