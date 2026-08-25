--[[ app/callbacks/ui_controls/ ]]


--Modifies the slider value if it is being dragged. e contains the 'container' for the bar and
--c contains the 'child' for the bar. either can be dragged. The value is lerped between the size
--of the child bar and the parent bar depending on any min/max values. Also changes the display text for the slider.
--
---@param e {}
--**e** Is the slider UIE that called this function
function G.FUNCS.drag_slider(e)
  local c = e.children[1]
  e.states.drag.can = true
  c.states.drag.can = true
  if G.INPUT and G.INPUT.dragging.target and
  (G.INPUT.dragging.target == e or
  G.INPUT.dragging.target == c) then
    local rt = c.config.ref_table
    rt.ref_table[rt.ref_value] = math.min(rt.max,math.max(rt.min, rt.min + (rt.max - rt.min)*(G.POINTER.T.x - e.parent.T.x - G.ROOM.T.x)/e.T.w))
    rt.text = string.format("%."..tostring(rt.decimal_places).."f", rt.ref_table[rt.ref_value])
    c.T.w = (rt.ref_table[rt.ref_value] - rt.min)/(rt.max - rt.min)*rt.w
    c.config.w = c.T.w
    if rt.callback then G.FUNCS[rt.callback](rt) end
  end
end

--Modifies the slider value descreetly by percentage
--c contains the 'child' for the bar. either can be dragged. The value is lerped between the size
--of the child bar and the parent bar depending on any min/max values. Also changes the display text for the slider.
--
---@param e {}
--**e** Is the slider UIE that called this function
function G.FUNCS.slider_step(e, per)
  local c = e.children[1]
  e.states.drag.can = true
  c.states.drag.can = true
  if per then
    local rt = c.config.ref_table
    rt.ref_table[rt.ref_value] = math.min(rt.max,math.max(rt.min, rt.ref_table[rt.ref_value] + per*(rt.max - rt.min)))
    rt.text = string.format("%."..tostring(rt.decimal_places).."f", rt.ref_table[rt.ref_value])
    c.T.w = (rt.ref_table[rt.ref_value] - rt.min)/(rt.max - rt.min)*rt.w
    c.config.w = c.T.w
  end
end

--When clicked, changes the selected option from an option cycle. Wraps around.
--Modifies any pips to show the currently selected option and resets last pip.
--Calls any functions from opt_callback defined in the option cycle when the value changes.
--
---@param e {}
--**e** Is the UIE that called this function
G.FUNCS.cycle_option = function(e)
  local from_val = e.config.ref_table.options[e.config.ref_table.current_option]
  local from_key = e.config.ref_table.current_option
  local old_pip = e.LayoutView:find_node_by_id('pip_'..e.config.ref_table.current_option, e.parent.parent)
  local cycle_main = e.LayoutView:find_node_by_id('cycle_main', e.parent.parent)

  if cycle_main and cycle_main.config.h_popup then
    cycle_main:stop_hover()
    Scheduler.add{
      func = function()
        cycle_main:hover()
      return true
    end
    }
  end

  if e.config.ref_value == 'l' then
    --cycle left
    e.config.ref_table.current_option = e.config.ref_table.current_option - 1
    if e.config.ref_table.current_option <= 0 then e.config.ref_table.current_option = #e.config.ref_table.options end
  else
    --cycle right
    e.config.ref_table.current_option = e.config.ref_table.current_option + 1
    if e.config.ref_table.current_option > #e.config.ref_table.options then e.config.ref_table.current_option = 1 end
  end
  local to_val = e.config.ref_table.options[e.config.ref_table.current_option]
  local to_key = e.config.ref_table.current_option
  e.config.ref_table.current_option_val = e.config.ref_table.options[e.config.ref_table.current_option]

  local new_pip = e.LayoutView:find_node_by_id('pip_'..e.config.ref_table.current_option, e.parent.parent)

  if old_pip then old_pip.config.colour = G.C.BLACK end
  if new_pip then new_pip.config.colour = G.C.WHITE end

  if e.config.ref_table.opt_callback then
      G.FUNCS[e.config.ref_table.opt_callback]{
      from_val = from_val,
      to_val = to_val,
      from_key = from_key,
      to_key = to_key,
      cycle_config = e.config.ref_table
    }
  end
end
