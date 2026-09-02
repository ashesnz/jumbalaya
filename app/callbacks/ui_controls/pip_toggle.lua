--[[ app/callbacks/ui_controls/ ]]


local Scheduler = require "app.effects.scheduler"
local Easing = require "app.effects.easing"

--Creates a binding pip on this UIE if controller is being used
--
---@param e {}
--**e** Is the UIE that called this function
G.FUNCS.set_button_pip = function(e)
  if G.INPUT.HID.controller and e.config.focus_args and not e.children.button_pip then
    e.children.button_pip = LayoutView{
      definition = make_bind_pip{button = e.config.focus_args.button, scale = e.config.focus_args.scale},
      config = {
        align= e.config.focus_args.orientation or 'cr',
        offset = e.config.focus_args.offset or e.config.focus_args.orientation == 'bm' and {x = 0, y = 0.02} or {x = 0.1, y = 0.02},
        major = e, parent = e}
    }
    e.children.button_pip.states.collide.can = false
  end
  if not G.INPUT.HID.controller and e.children.button_pip then
    e.children.button_pip:remove()
    e.children.button_pip = nil
  end
end

--Flashes text input cursor for the hooked text input, otherwise sets the width and alpha to 0
--
---@param e {}
--**e** Is the UIE cursor that called this function
G.FUNCS.pulse_node = function(e)
  if G.INPUT.text_capture then 
    if (math.floor(G.TIMERS.REAL*2))%2 == 1 then
        e.config.colour[4] = 0
    else
      e.config.colour[4] = 1
    end
    if e.config.w ~= 0.1 then e.config.w = 0.1; e.LayoutView:recalculate(true) end
  else
    e.config.colour[4] = 0
    if e.config.w ~= 0 then e.config.w = 0; e.LayoutView:recalculate(true) end
  end
end

--for the toggle
--
---@param e {}
--**e** Is the slider UIE that called this function
function G.FUNCS.flip_switch(e)
  local ref = e.config.ref_table
  local value_table = ref.ref_table
  local key = ref.ref_value
  value_table[key] = not value_table[key]
  if e.config.toggle_callback then
    e.config.toggle_callback(value_table[key])
  end
  if not value_table[key] and e.config.toggle_active then
    e.config.toggle_active = nil
    e.config.colour = ref.inactive_colour
    e.children[1].states.visible = false
    e.children[1].config.object.states.visible = false
  elseif value_table[key] and not e.config.toggle_active then
    e.config.toggle_active = true
    e.config.colour = ref.active_colour
    e.children[1].states.visible = true
    e.children[1].config.object.states.visible = true
  end
end

