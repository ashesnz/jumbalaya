-- Application screen transitions and their particle effects.
local Scheduler = require "app.effects.scheduler"

G.FUNCS.wipe_in = function(message, no_card, timefac, alt_colour)
  timefac = timefac or 1
  if G.screenwipe then return end
  G.INPUT.locks.wipe = true
  G.STAGE_OBJECT_INTERRUPT = true
  local colours = {
    black = colour_from_hex("4f6367FF"),
    white = {1, 1, 1, 1}
  }
  if not no_card then
    G.screenwipecard = Card(1, 1, G.CARD_W, G.CARD_H, pick_random(G.P_CARDS), G.P_CENTERS.letter_base)
    G.screenwipecard.sprite_facing = 'back'
    G.screenwipecard.facing = 'back'
    G.screenwipecard.states.hover.can = false
    G.screenwipecard:pulse(0.5, 1)
  end
  local message_t = nil
  if message then
    message_t = {}
    for k, v in ipairs(message) do
      table.insert(message_t, {n=G.UI.ROW, config={align = "cm"}, nodes={{n=G.UI.OBJECT, config={object = FlowText({string = v or '', colours = {math.min(G.C.BACKGROUND.C[1], G.C.BACKGROUND.C[2]) > 0.5 and G.C.BLACK or G.C.WHITE},shadow = true, silent = k ~= 1, float = true, scale = 1.3, pop_in = 0, pop_in_rate = 2, rotate = 1})}}}})
    end
  end

  G.screenwipe = LayoutView{
    definition =
      {n=G.UI.ROOT, config = {align = "cm", minw =0, minh =0 ,padding = 0.15, r = 0.1, colour = G.C.CLEAR}, nodes={
        {n=G.UI.ROW, config={align = "cm"}, nodes={
          message and {n=G.UI.ROW, config={id = 'text', align = "cm", padding = 0.7}, nodes=message_t} or nil,
          not no_card and {n=G.UI.OBJECT, config={object = G.screenwipecard, role = {role_type = 'Major'}}} or nil
        }},
      }},
    config = {align="cm", offset = {x=0,y=0}, major = G.ROOM_ATTACH}
  }
  G.screenwipe.colours = colours
  G.screenwipe.children.particles = Particles(0, 0, 0,0, {
    timer = 0, max = 1, scale = 40, speed = 0, lifespan = 1.7*timefac,
    attach = G.screenwipe, colours = {alt_colour or G.C.BACKGROUND.C}
  })
  G.STAGE_OBJECT_INTERRUPT = nil
  G.screenwipe.alignment.offset.y = 0
  if message then
    for _, v in ipairs(G.screenwipe:find_node_by_id('text').children) do
      v.children[1].config.object:pulse()
    end
  end
  Scheduler.add{
    mode = 'window', delay = 0.7, persistent = true, blockable = false, timer = 'REAL',
    func = function()
      if not no_card and G.screenwipecard and G.screenwipecard.flip then G.screenwipecard:flip() end
      return true
    end
  }
end

G.FUNCS.wipe_out = function()
  Scheduler.add{
    persistent = true,
    func = function()
      Scheduler.delayed{delay = 0.3}
      G.screenwipe.children.particles.max = 0
      for _, colour in ipairs({'black', 'white'}) do
        Scheduler.add{mode = 'tween', persistent = true, blockable = false,
          blocking = false, timer = 'REAL', ref_table = G.screenwipe.colours[colour],
          ref_value = 4, ease_to = 0, delay = 0.3, func = function(t) return t end}
      end
      return true
    end
  }
  Scheduler.add{
    mode = 'delayed', delay = 0.55, persistent = true, blocking = false, timer = 'REAL',
    func = function()
      if G.screenwipecard then G.screenwipecard:start_dissolve({G.C.BLACK, G.C.ORANGE,G.C.GOLD, G.C.RED}) end
      local text = G.screenwipe:find_node_by_id('text')
      if text then for _, v in ipairs(text.children) do v.children[1].config.object:pop_out(4) end end
      return true
    end
  }
  Scheduler.add{
    mode = 'delayed', delay = 1.1, persistent = true, blocking = false, timer = 'REAL',
    func = function()
      G.screenwipe.children.particles:remove(); G.screenwipe:remove()
      G.screenwipe.children.particles = nil; G.screenwipe = nil; G.screenwipecard = nil
      G.INPUT.locks.wipe = false
      return true
    end
  }
  Scheduler.add{mode = 'delayed', delay = 1.2, persistent = true,
    blocking = true, timer = 'REAL', func = function() return true end}
end

return true