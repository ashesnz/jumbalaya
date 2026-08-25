--[[ word_game/ui/widgets/sliders.lua - Tabs, text input, and on-screen keyboard ]]
local Components = require "word_game.ui.widgets.components"

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
    tab_buttons[#tab_buttons+1] = Components.button({id = 'tab_but_'..(v.label or ''), ref_table = v, onClick = 'switch_tab', label = {v.label}, height = 0.8*args.scale, width = 2.5*args.scale, col = true, choice = true, textSize = args.text_scale, chosen = v.chosen, onTick = v.func, focus_args = {type = 'none'}})
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
