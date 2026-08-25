--[[ word_game/ui/widgets/buttons.lua - Button and chrome UI builders ]]
local Scheduler = require "app.effects.scheduler"
local Components = require "word_game.ui.widgets.components"


local button_font
function alpha_button_font()
  if not button_font then
    local ok, font = pcall(love.graphics.newFont, "resources/fonts/Outfit-Bold.ttf", G.TILESIZE * 7)
    button_font = {
      FONT = ok and font or love.graphics.newFont(G.TILESIZE * 7),
      TEXT_HEIGHT_SCALE = 0.7,
      TEXT_OFFSET = {x = 0, y = -28},
      FONTSCALE = 0.12,
      squish = 1,
    }
  end
  return button_font
end

function build_character_button(args)
  local button = args.button or "NONE"
  local func = args.func or nil
  local colour = args.colour or G.C.UI.BUTTON
  local update_func = args.update_func or nil

  local t = {n=G.UI.ROOT, config = {align = "cm", padding = 0.1, colour = G.C.CLEAR}, nodes={
    {n=G.UI.COLUMN, config={align = "tm", minw = 1.9, padding = 0.34, minh = 1.2, r = Components.CHROME.radius, hover = true, colour = colour, hover_colour = G.C.UI.BUTTON_HOVER, button = func, func = update_func, shadow = true, maxw = args.maxw}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=G.UI.TEXT, config={text = button, scale = 0.55, font = alpha_button_font(), colour = G.C.UI.BUTTON_TEXT, focus_args = {button = 'x', orientation = 'bm'}, func = 'set_button_pip'}}
      }}
    }},
    }}
  return t
end


function build_card_alert(args)
  args = args or {}
  return {n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR, refresh_movement = true}, nodes={
      {n=G.UI.ROW, config={align = "cm", r = 0.15, minw = 0.42, minh = 0.42, colour = args.no_bg and G.C.CLEAR or args.bg_col or (args.red_bad and shade(G.C.RED, 0.1) or G.C.RED), draw_layer = 1, emboss = 0.05, refresh_movement = true}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = args.text or '!', colours = {G.C.WHITE},shadow = true, rotate = true,H_offset = args.y_offset or 0,bump_rate = args.text and 3 or 7, bump_amount = args.bump_amount or 3, bump = true,maxw = args.maxw, text_rot = args.text_rot or  0.2, spacing = 3*(args.scale or 1), scale = args.scale or 0.48})}}
      }},
  }}
end

function make_keyboard_key(key, binding)
  local key_label = (key == 'backspace' and 'Backspace') or (key == ' ' and 'Space') or (key == 'back' and 'Back') or (key == 'return' and 'Enter') or key
  return Components.button{ label = {key_label}, onClick = "key_button", ref_table = {key = key == 'back' and 'return' or key},
      width = key == ' ' and 6 or key == 'return' and 2.5 or key == 'backspace' and 2.5 or key == 'back' and 2.5 or 0.8,
      height = key == 'return' and 1.5 or key == 'backspace' and 1.5 or key == 'back' and 0.8 or 0.7,
      col = true, colour = G.C.GREY, focus_args = binding and {button = binding, orientation = (key == ' ' or key == 'back') and 'cr' or 'bm', set_button_pip= true} or nil}
end


function make_bind_pip(args)

  local button_sprite_map = {
    ['a'] = G.F_SWAP_AB_PIPS and 1 or 0,
    ['b'] = G.F_SWAP_AB_PIPS and 0 or 1,
    ['x'] = 2,
    ['y'] = 3,
    ['leftshoulder'] = 4,
    ['rightshoulder'] = 5,
    ['triggerleft'] = 6,
    ['triggerright'] = 7,
    ['start'] = 8,
    ['back'] = 9,
    ['dpadup'] = 10,
    ['dpadright'] = 11,
    ['dpaddown'] = 12,
    ['dpadleft'] = 13,
    ['left'] = 14,
    ['right'] = 15,
    ['leftstick'] = 16,
    ['rightstick'] = 17,
    ['guide'] = 19
  }
  local BUTTON_SPRITE = Sprite(0,0,args.scale or 0.45,args.scale or 0.45,G.TEXTURE_ATLASES["gamepad_ui"],
    {x=button_sprite_map[args.button],
     y=G.INPUT.GAMEPAD_CONSOLE == 'Nintendo' and 2 or G.INPUT.GAMEPAD_CONSOLE == 'Playstation' and (G.F_PS4_PLAYSTATION_GLYPHS and 3 or 1) or 0})

  return {n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR}, nodes={
        {n=G.UI.OBJECT, config={object = BUTTON_SPRITE}},
    }}
end


function build_generic_options(args)
  args = args or {}
  local back_func = args.back_func or "close_overlay"
  local contents = args.contents or ({n=G.UI.TEXT, config={text = "EMPTY",colour = G.C.UI.RED, scale = 0.4}})
  if args.infotip then
    Scheduler.add{
      blocking = false,
      blockable = false,
      timer = 'REAL',
      func = function()
          if G.OVERLAY_MENU then
            local _infotip_object = G.OVERLAY_MENU:find_node_by_id('overlay_menu_infotip')
            if _infotip_object then
              _infotip_object.config.object:remove()
              _infotip_object.config.object = LayoutView{
                definition = overlay_infotip(args.infotip),
                config = {offset = {x=0,y=0}, align = 'bm', parent = _infotip_object}
              }
            end
          end
          return true
        end
    }
  end

  return {n=G.UI.ROOT, config = {align = "cm", minw = args.root_minw or G.ROOM.T.w*5, minh = args.root_minh or G.ROOM.T.h*5,padding = 0.1, r = 0.1, colour = args.bg_colour or {G.C.GREY[1], G.C.GREY[2], G.C.GREY[3],0.7}}, nodes={
    {n=G.UI.ROW, config={align = "cm", minh = 1,r = 0.3, padding = 0.07, minw = 1, colour = args.outline_colour or G.C.MUTED_GREY, emboss = 0.1}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", minh = 1,r = 0.2, padding = 0.2, minw = 1, colour = args.colour or G.C.L_BLACK}, nodes={
        {n=G.UI.ROW, config={align = "cm",padding = args.padding or 0.2, minw = args.minw or 7}, nodes=
          contents
        },
        not args.no_back and {n=G.UI.ROW, config={id = args.back_id or 'overlay_menu_back_button', align = "cm", minw = 2.5, button_delay = args.back_delay, padding =0.24, r = Components.CHROME.radius, hover = true, colour = args.back_colour or G.C.UI.BUTTON, hover_colour = G.C.UI.BUTTON_HOVER, button = back_func, shadow = true, focus_args = {nav = 'wide', button = 'b', snap_to = args.snap_back}}, nodes={
          {n=G.UI.ROW, config={align = "cm", padding = 0, no_fill = true}, nodes={
            {n=G.UI.TEXT, config={id = args.back_id or nil, text = args.back_label or localize('ui_back'), scale = 0.5, font = alpha_button_font(), colour = G.C.UI.BUTTON_TEXT, shadow = true, func = not args.no_pip and 'set_button_pip' or nil, focus_args =  not args.no_pip and {button = args.back_button or 'b'} or nil}}
          }}
        }} or nil
      }},
    }},
    {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.OBJECT, config={id = 'overlay_menu_infotip', object = EaseNode()}},
    }},
  }}
end


function UIBox_dyn_container(inner_table, horizontal, colour_override, background_override, flipped, padding)
  return {n=G.UI.ROW, config = {align = "cm", padding= 0.03, colour = G.C.UI.TRANSPARENT_DARK, r=0.1}, nodes={
    {n=G.UI.ROW, config = {align = "cm", padding= 0.05, colour = colour_override or G.C.DYN_UI.MAIN, r=0.1}, nodes={
    {n=G.UI.ROW, config={align = horizontal and "cl" or (flipped and 'bm' or "tm"), colour = background_override or G.C.DYN_UI.BOSS_DARK, minw = horizontal and 100 or 0, minh = horizontal and 0 or 30, r=0.1, padding = padding or 0.08}, nodes=
      inner_table
  }}}}}
end


function simple_text_container(_loc, args)
  if not _loc then return nil end
  args = args or {}
  local container = {}
  local loc_result = localize(_loc)
  if loc_result and type(loc_result) == 'table' then
    for k, v in ipairs(loc_result) do
      container[#container+1] =
        {n=G.UI.ROW, config = {align = "cm", padding= 0}, nodes={
          {n=G.UI.TEXT, config={text = v, scale = args.scale or 0.35, colour = args.colour or G.C.UI.TEXT_DARK, shadow = args.shadow}}
        }}
    end
    return {n=args.col and G.UI.COLUMN or G.UI.ROW, config = {align = "cm", padding= args.padding or 0.03}, nodes=container}
  end
end

