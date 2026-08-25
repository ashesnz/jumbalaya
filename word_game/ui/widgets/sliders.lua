--[[ word_game/ui/widgets/sliders.lua - Sliders, toggles, tabs, and text input ]]

function make_slider(args)
  args = args or {}
  args.colour = args.colour or G.C.RED
  args.w = args.w or 1
  args.h = args.h or 0.5
  args.label_scale = args.label_scale or 0.5
  args.text_scale = args.text_scale or 0.3
  args.min = args.min or 0
  args.max = args.max or 1
  args.decimal_places = args.decimal_places or 0
  args.text = string.format("%."..tostring(args.decimal_places).."f", args.ref_table[args.ref_value])
  local startval = args.w * (args.ref_table[args.ref_value] - args.min)/(args.max - args.min)

  local t =
        {n=G.UI.COLUMN, config={align = "cm", minw = args.w, min_h = args.h, padding = 0.1, r = 0.1, colour = G.C.CLEAR, focus_args = {type = 'slider'}}, nodes={
          {n=G.UI.COLUMN, config={align = "cl", minw = args.w, r = 0.1,min_h = args.h,collideable = true, hover = true, colour = G.C.BLACK,emboss = 0.05,func = 'drag_slider', refresh_movement = true}, nodes={
            {n=G.UI.BOX, config={w=startval,h=args.h, r = 0.1, colour = args.colour, ref_table = args, refresh_movement = true}},
          }},
          {n=G.UI.COLUMN, config={align = "cm", minh = args.h,r = 0.1, minw = 0.8, colour = args.colour,shadow = true}, nodes={
            {n=G.UI.TEXT, config={ref_table = args, ref_value = 'text', scale = args.text_scale, colour = G.C.UI.TEXT_LIGHT, decimal_places = args.decimal_places}}
          }},
        }}
  if args.label then
    t = {n=G.UI.ROW, config={align = "cm", minh = 1, minw = 1, padding = 0.1*args.label_scale, colour = G.C.CLEAR}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=G.UI.TEXT, config={text = args.label, scale = args.label_scale, colour = G.C.UI.TEXT_LIGHT}}
      }},
      {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
        t
      }}
    }}
  end
  return t
end


function make_toggle_switch(args)
  args = args or {}
  args.active_colour = args.active_colour or G.C.RED
  args.inactive_colour = args.inactive_colour or G.C.BLACK
  args.w = args.w or 3
  args.h = args.h or 0.5
  args.scale = args.scale or 1
  args.label = args.label or 'TEST?'
  args.label_scale = args.label_scale or 0.4
  args.ref_table = args.ref_table or {}
  args.ref_value = args.ref_value or 'test'

  local check = Sprite(0,0,0.5*args.scale,0.5*args.scale,G.TEXTURE_ATLASES["icons"], {x=1, y=0})
  check.states.drag.can = false
  check.states.visible = false

  ---@type table|nil
  local info = nil
  if args.info then
    info = {}
    for k, v in ipairs(args.info) do
      table.insert(info, {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
        {n=G.UI.TEXT, config={text = v, scale = 0.25, colour = G.C.UI.TEXT_LIGHT}}
      }})
    end
    info =  {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes=info}
  end

  ---@type table
  local t =
        {n=args.col and G.UI.COLUMN or G.UI.ROW, config={align = "cm", padding = 0.1, r = 0.1, colour = G.C.CLEAR, focus_args = {funnel_from = true}}, nodes={
          {n=G.UI.COLUMN, config={align = "cr", minw = args.w}, nodes={
            {n=G.UI.TEXT, config={text = args.label, scale = args.label_scale, colour = G.C.UI.TEXT_LIGHT}},
            {n=G.UI.BOX, config={w = 0.1, h = 0.1}},
          }},
          {n=G.UI.COLUMN, config={align = "cl", minw = 0.3*args.w}, nodes={
            {n=G.UI.COLUMN, config={align = "cm", r = 0.1, colour = G.C.BLACK}, nodes={
              {n=G.UI.COLUMN, config={align = "cm", r = 0.1, padding = 0.03, minw = 0.4*args.scale, minh = 0.4*args.scale, outline_colour = G.C.WHITE, outline = 1.2*args.scale, line_emboss = 0.5*args.scale, ref_table = args,
                  colour = args.inactive_colour,
                  button = 'flip_switch', button_dist = 0.2, hover = true, toggle_callback = args.callback, func = 'flip_switch', focus_args = {funnel_to = true}}, nodes={
                  {n=G.UI.OBJECT, config={object = check}},
              }},
            }}
          }},
        }}
   if args.info then
     t = {n=args.col and G.UI.COLUMN or G.UI.ROW, config={align = "cm"}, nodes={
       t,
       info,
     }}
   end
  return t
end


function make_option_cycler(args)
  args = args or {}
  args.colour = args.colour or G.C.RED
  args.options = args.options or {
    'Option 1',
    'Option 2'
  }
  args.current_option = args.current_option or 1
  args.current_option_val = args.options[args.current_option]
  args.opt_callback = args.opt_callback or nil
  args.scale = args.scale or 1
  args.ref_table = args.ref_table or nil
  args.ref_value = args.ref_value or nil
  args.w = (args.w or 2.5)*args.scale
  args.h = (args.h or 0.8)*args.scale
  args.text_scale = (args.text_scale or 0.5)*args.scale
  args.l = '<'
  args.r = '>'
  args.focus_args = args.focus_args or {}
  args.focus_args.type = 'cycle'

  ---@type table|nil
  local info = nil
  if args.info then
    info = {}
    for k, v in ipairs(args.info) do
      table.insert(info, {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
        {n=G.UI.TEXT, config={text = v, scale = 0.3*args.scale, colour = G.C.UI.TEXT_LIGHT}}
      }})
    end
    info =  {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes=info}
  end

  local disabled = #args.options < 2
  local pips = {}
  for i = 1, #args.options do
    pips[#pips+1] = {n=G.UI.BOX, config={w = 0.1*args.scale, h = 0.1*args.scale, r = 0.05, id = 'pip_'..i, colour = args.current_option == i and G.C.WHITE or G.C.BLACK}}
  end

  local choice_pips = not args.no_pips and {n=G.UI.ROW, config={align = "cm", padding = (0.05 - (#args.options > 15 and 0.03 or 0))*args.scale}, nodes=pips} or nil

  ---@type table
  local t =
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.1, r = 0.1, colour = G.C.CLEAR, id = args.id and (not args.label and args.id or nil) or nil, focus_args = args.focus_args}, nodes={
          {n=G.UI.COLUMN, config={align = "cm",r = 0.1, minw = 0.6*args.scale, hover = not disabled, colour = not disabled and args.colour or G.C.BLACK,shadow = not disabled, button = not disabled and 'cycle_option' or nil, ref_table = args, ref_value = 'l', focus_args = {type = 'none'}}, nodes={
            {n=G.UI.TEXT, config={ref_table = args, ref_value = 'l', scale = args.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
          }},
          args.mid and
          {n=G.UI.COLUMN, config={id = 'cycle_main'}, nodes={
              {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
                args.mid
              }},
              not disabled and choice_pips or nil
          }}
          or {n=G.UI.COLUMN, config={id = 'cycle_main', align = "cm", minw = args.w, minh = args.h, r = 0.1, padding = 0.05, colour = args.colour,emboss = 0.1, hover = true, can_collide = true, on_demand_tooltip = args.on_demand_tooltip}, nodes={
            {n=G.UI.ROW, config={align = "cm"}, nodes={
              {n=G.UI.ROW, config={align = "cm"}, nodes={
                {n=G.UI.OBJECT, config={object = FlowText({string = {{ref_table = args, ref_value = "current_option_val"}}, colours = {G.C.UI.TEXT_LIGHT},pop_in = 0, pop_in_rate = 8, reset_pop_in = true,shadow = true, float = true, silent = true, bump = true, scale = args.text_scale, non_recalc = true})}},
              }},
              {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
              }},
              not disabled and choice_pips or nil
            }}
          }},
          {n=G.UI.COLUMN, config={align = "cm",r = 0.1, minw = 0.6*args.scale, hover = not disabled, colour = not disabled and args.colour or G.C.BLACK,shadow = not disabled, button = not disabled and 'cycle_option' or nil, ref_table = args, ref_value = 'r', focus_args = {type = 'none'}}, nodes={
            {n=G.UI.TEXT, config={ref_table = args, ref_value = 'r', scale = args.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
          }},
        }}

  if args.cycle_shoulders then
    t =
    {n=G.UI.ROW, config={align = "cm", colour = G.C.CLEAR}, nodes = {
      {n=G.UI.COLUMN, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'leftshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = -0.1, y = 0}}}, nodes = {}},
      {n=G.UI.COLUMN, config={id = 'cycle_shoulders', padding = 0.1}, nodes={t}},
      {n=G.UI.COLUMN, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'rightshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}},
    }}
  else
    t =
    {n=G.UI.ROW, config={align = "cm", colour = G.C.CLEAR, padding = 0.0}, nodes = {
      t
    }}
  end
  if args.label or args.info then
    t = {n=G.UI.ROW, config={align = "cm", padding = 0.05, id = args.id or nil}, nodes={
      args.label and {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = args.label, scale = 0.5*args.scale, colour = G.C.UI.TEXT_LIGHT}}
      }} or nil,
      t,
      info,
    }}
  end
  return t
end


function make_tab_strip(args)
  args = args or {}
  args.colour = args.colour or G.C.RED
  args.tab_alignment = args.tab_alignment or 'cm'
  args.opt_callback = args.opt_callback or nil
  args.scale = args.scale or 1
  args.tab_w = args.tab_w or 0
  args.tab_h = args.tab_h or 0
  args.text_scale = (args.text_scale or 0.5)
  args.tabs = args.tabs or {
    {
      label = 'tab 1',
      chosen = true,
      func = nil,
      tab_definition_function = function() return  {n=G.UI.ROOT, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = 'A', scale = 1, colour = G.C.UI.TEXT_LIGHT}}
      }} end
    },
    {
      label = 'tab 2',
      chosen = false,
      tab_definition_function = function() return  {n=G.UI.ROOT, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = 'B', scale = 1, colour = G.C.UI.TEXT_LIGHT}}
      }} end
    },
    {
      label = 'tab 3',
      chosen = false,
      tab_definition_function = function() return  {n=G.UI.ROOT, config={align = "cm"}, nodes={
        {n=G.UI.TEXT, config={text = 'C', scale = 1, colour = G.C.UI.TEXT_LIGHT}}
      }} end
    }
  }

  local tab_buttons = {}

  for k, v in ipairs(args.tabs) do
    if v.chosen then args.current = {k = k, v = v} end
    tab_buttons[#tab_buttons+1] = make_button({id = 'tab_but_'..(v.label or ''), ref_table = v, button = 'switch_tab', label = {v.label}, minh = 0.8*args.scale, minw = 2.5*args.scale, col = true, choice = true, scale = args.text_scale, chosen = v.chosen, func = v.func, focus_args = {type = 'none'}})
  end

  local t =
  {n=G.UI.ROW, config={padding = 0.0, align = "cm", colour = G.C.CLEAR}, nodes={
    {n=G.UI.ROW, config={align = "cm", colour = G.C.CLEAR}, nodes = {
      (#args.tabs > 1 and not args.no_shoulders) and {n=G.UI.COLUMN, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'leftshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = -0.1, y = 0}}}, nodes = {}} or nil,
      {n=G.UI.COLUMN, config={id = args.no_shoulders and 'no_shoulders' or 'tab_shoulders', ref_table = args, align = "cm", padding = 0.15, group = 1, collideable = true, focus_args = #args.tabs > 1 and {type = 'tab', nav = 'wide',snap_to = args.snap_to_nav, no_loop = args.no_loop} or nil}, nodes=tab_buttons},
      (#args.tabs > 1 and not args.no_shoulders) and {n=G.UI.COLUMN, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'rightshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}} or nil,
    }},
    {n=G.UI.ROW, config={align = args.tab_alignment, padding = args.padding or 0.1, no_fill = true, minh = args.tab_h, minw = args.tab_w}, nodes={
      {n=G.UI.OBJECT, config={id = 'tab_contents', object = LayoutView{definition = args.current.v.tab_definition_function(args.current.v.tab_definition_function_args), config = {offset = {x=0,y=0}}}}}
    }},
  }}

  return t
end


function make_text_field(args)
  args = args or {}
  args.colour = deep_clone(args.colour) or deep_clone(G.C.BLUE)
  args.hooked_colour = deep_clone(args.hooked_colour) or shade(deep_clone(G.C.BLUE), 0.3)
  args.w = args.w or 2.5
  args.h = args.h or 0.7
  args.text_scale = args.text_scale or 0.4
  args.max_length = args.max_length or 16
  args.all_caps = args.all_caps or false
  args.prompt_text = args.prompt_text or localize('term_enter_text')
  args.current_prompt_text = ''

  local text = {ref_table = args.ref_table, ref_value = args.ref_value, letters = {}, current_position = string.len(args.ref_table[args.ref_value])}
  local ui_letters = {}
  for i = 1, args.max_length do
    text.letters[i] = (args.ref_table[args.ref_value] and (string.sub(args.ref_table[args.ref_value], i, i) or '')) or ''
    ui_letters[i] = {n=G.UI.TEXT, config={ref_table = text.letters, ref_value = i, scale = args.text_scale, colour = G.C.UI.TEXT_LIGHT, id = 'letter_'..i}}
  end
  args.text = text

  local position_text_colour = tint(deep_clone(G.C.BLUE), 0.4)

  ui_letters[#ui_letters+1] = {n=G.UI.TEXT, config={ref_table = args, ref_value = 'current_prompt_text', scale = args.text_scale, colour = tint(deep_clone(args.colour), 0.4), id = 'prompt'}}
  ui_letters[#ui_letters+1] = {n=G.UI.BOX, config={r = 0.03,w=0.1, h=0.4, colour = position_text_colour, id = 'position', func = 'pulse_node'}}

  local t =
       {n=G.UI.COLUMN, config={align = "cm", draw_layer = 1, colour = G.C.CLEAR}, nodes = {
          {n=G.UI.COLUMN, config={id = 'text_input', align = "cm", padding = 0.05, r = 0.1, draw_layer = 2, hover = true, colour = args.colour,minw = args.w, min_h = args.h, button = 'focus_text_field', shadow = true}, nodes={
            {n=G.UI.ROW, config={ref_table = args, padding = 0.05, align = "cm", r = 0.1, colour = G.C.CLEAR}, nodes={
              {n=G.UI.ROW, config={ref_table = args, align = "cm", r = 0.1, colour = G.C.CLEAR, func = 'text_input'}, nodes=
                ui_letters
              }
            }}
          }}
        }}
  return t
end


function make_onscreen_keyboard(args)
  local keyboard_rows = {
    '1234567890',
    'QWERTYUIOP',
    'ASDFGHJKL',
    'ZXCVBNM',
    args.space_key and ' ' or nil
  }
  local keyboard_button_rows = {
      {},{},{},{},{}
  }
  for k, v in ipairs(keyboard_rows) do
      for i = 1, #v do
          local c = v:sub(i,i)
          keyboard_button_rows[k][#keyboard_button_rows[k] +1] = make_keyboard_key(c, c == ' ' and 'y' or nil)
      end
  end
  return {n=G.UI.ROOT, config={align = "cm", padding = 15, r = 0.1, colour = {G.C.GREY[1], G.C.GREY[2], G.C.GREY[3],0.7}}, nodes={
    {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes = {
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, colour = G.C.BLACK, emboss = 0.05, r = 0.1, mid = true}, nodes = {
        {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes = {
          {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes = {
              {n=G.UI.ROW, config={align = "cm", padding = 0.07, colour = G.C.CLEAR}, nodes=keyboard_button_rows[1]},
              {n=G.UI.ROW, config={align = "cm", padding = 0.07, colour = G.C.CLEAR}, nodes=keyboard_button_rows[2]},
              {n=G.UI.ROW, config={align = "cm", padding = 0.07, colour = G.C.CLEAR}, nodes=keyboard_button_rows[3]},
              {n=G.UI.ROW, config={align = "cm", padding = 0.07, colour = G.C.CLEAR}, nodes=keyboard_button_rows[4]},
              {n=G.UI.ROW, config={align = "cm", padding = 0.07, colour = G.C.CLEAR}, nodes=keyboard_button_rows[5]}
          }},
          (args.backspace_key or args.return_key) and {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes = {
              args.backspace_key and {n=G.UI.ROW, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={make_keyboard_key('backspace', 'x')}} or nil,
              args.return_key and {n=G.UI.ROW, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={make_keyboard_key('return', 'start')}} or nil,
              {n=G.UI.ROW, config={align = "cm", padding = 0.05, colour = G.C.CLEAR}, nodes={make_keyboard_key('back', 'b')}}
          }} or nil
        }},
      }}
    }},

  }}
end
