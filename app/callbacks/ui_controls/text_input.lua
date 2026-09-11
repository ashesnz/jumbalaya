--[[ app/callbacks/ui_controls/ ]]

local Easing = require "app.effects.easing"
local ViewHost = require("jumbalaya-engine.view_host")

local BridgeRuntime = require("bridge.runtime")
local Funcs = require("bridge.funcs_registry")
local function g() return BridgeRuntime.game() end

--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
--                                         TEXT ENTRY
--||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

--passes a keyboard input to the controller when a key UI button is pressed
--
---@param e table
--
--[e is the UI Element that calls this update function, contains ARGS in e.config.ref_table]
Funcs.register("key_button",  function(e)
  local args = e.config.ref_table
  if args.key then g().INPUT:key_press_update(args.key) end
end)

--Modifies the text input to show the current text value being modified. Shows the prompt text if\
--the text input area is not hooked. Also modifies the UIE colour to show the hooked/non hooked colour\
--If using a keyboard, pops it up here or removes it if using KBM
--
---@param e table
--
--[e is the UI Element that calls this update function, contains ARGS in e.config.ref_table]
Funcs.register("text_input",  function(e)
  local args =e.config.ref_table
  if g().INPUT.text_capture == e then
    e.parent.parent.config.colour = args.hooked_colour
    args.current_prompt_text = ''
    args.current_position_text = args.position_text
  else
    e.parent.parent.config.colour = args.colour
    args.current_prompt_text = (args.text.ref_table[args.text.ref_value] == '' and args.prompt_text or '')
    args.current_position_text = ''
  end

  local OSkeyboard_e = e.parent.parent.parent
  if g().INPUT.text_capture == e and g().INPUT.HID.controller then
    if not OSkeyboard_e.children.controller_keyboard then 
      OSkeyboard_e.children.controller_keyboard = ViewHost.create{
        definition = make_onscreen_keyboard{backspace_key = true, return_key = true, space_key = false},
        config = {
          align= 'cm',
          offset = {x = 0, y = g().INPUT.text_capture.config.ref_table.keyboard_offset or -4},
          major = e.panel, parent = OSkeyboard_e}
      }
      g().INPUT.screen_keyboard = OSkeyboard_e.children.controller_keyboard
      g().INPUT:shift_context_layer(1)
    end
  elseif OSkeyboard_e.children.controller_keyboard then
    OSkeyboard_e.children.controller_keyboard:remove()
    OSkeyboard_e.children.controller_keyboard = nil
    g().INPUT.screen_keyboard = nil
    g().INPUT:shift_context_layer(-1)
  end
end)

Funcs.register("paste_run_seed",  function(e)
  g().INPUT.text_capture = e.panel:find_node_by_id('text_input').children[1].children[1]
  for i = 1, 8 do
    Funcs.dispatch("text_field_key", {key = 'right'})
  end
  for i = 1, 8 do
      Funcs.dispatch("text_field_key", {key = 'backspace'})
  end
  local clipboard = (g().F_LOCAL_CLIPBOARD and g().CLIPBOARD or love.system.getClipboardText()) or ''
  for i = 1, #clipboard do
    local c = clipboard:sub(i,i)
    Funcs.dispatch("text_field_key", {key = c})
  end
  Funcs.dispatch("text_field_key", {key = 'return'})
end)

--When clicked, hooks the text input defined by e->1->1, which should be the text input UIE
--
---@param e table
--
--[e is the UI Element that calls this click function]
Funcs.register("focus_text_field",  function(e)
  g().INPUT.text_capture = e.children[1].children[1]

  --Start by setting the cursor position to the correct location
  TRANSPOSE_TEXT_INPUT(0)
  e.panel:recalculate(true)
end)

--Handles all key inputs for the hooked text input.
--
---@param args {key: string, caps: boolean}
--**key** the key being pressed\
--**caps** if the key should be capitalized
Funcs.register("text_field_key",  function(args)
  args = args or {}

  if args.key == '[' or args.key == ']' then return end
  if args.key == '0' then args.key = 'o' end

  --shortcut to hook config
  local hook_config = g().INPUT.text_capture.config.ref_table
  hook_config.orig_colour = hook_config.orig_colour or deep_clone(hook_config.colour)

  args.key = args.key or '%'
  args.caps = args.caps or g().INPUT.capslock or hook_config.all_caps --capitalize if caps lock or hook requires

  --Some special keys need to be mapped accordingly before passing through the corpus
  local keymap = {
    space = ' ',
    backspace = 'BACKSPACE',
    delete = 'DELETE',
    ['return'] = 'RETURN',
    right = 'RIGHT',
    left = 'LEFT'
  }
  local hook = g().INPUT.text_capture
  local corpus = '123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'..(hook.config.ref_table.extended_corpus and " 0!$&()<>?:{}+-=,.[]_" or '')
  
  if hook.config.ref_table.extended_corpus then 
    local lower_ext = '1234567890-=;\',./'
    local upper_ext = '!@#$%^&*()_+:"<>?'
    if string.find(lower_ext, args.key) and args.caps then 
      args.key = string.sub(string.sub(upper_ext,string.find(lower_ext, args.key)), 0, 1)
    end
  end
  local text = hook_config.text

  --set key to mapped key or upper if caps is true
  args.key = keymap[args.key] or (args.caps and string.upper(args.key) or args.key)
  
  --Start by setting the cursor position to the correct location
  TRANSPOSE_TEXT_INPUT(0)

  if string.len(text.ref_table[text.ref_value]) > 0 and args.key == 'BACKSPACE' then --If not at start, remove preceding letter
    MODIFY_TEXT_INPUT{
      letter = '',
      text_table = text,
      pos = text.current_position,
      delete = true
    }
    TRANSPOSE_TEXT_INPUT(-1)
  elseif string.len(text.ref_table[text.ref_value]) > 0 and args.key == 'DELETE' then --if not at end, remove following letter
    MODIFY_TEXT_INPUT{
      letter = '',
      text_table = text,
      pos = text.current_position+1,
      delete = true
    }
    TRANSPOSE_TEXT_INPUT(0)
  elseif args.key == 'RETURN' then --Release the hook
    if hook.config.ref_table.callback then hook.config.ref_table.callback() end
    hook.parent.parent.config.colour = hook_config.colour
    local temp_colour = deep_clone(hook_config.orig_colour)
    hook_config.colour[1] = g().C.WHITE[1]
    hook_config.colour[2] = g().C.WHITE[2]
    hook_config.colour[3] = g().C.WHITE[3]
    Easing.colour{old_colour = hook_config.colour, new_colour = temp_colour}
    g().INPUT.text_capture = nil
  elseif args.key == 'LEFT' then --Move cursor position to the left
    TRANSPOSE_TEXT_INPUT(-1)
  elseif args.key == 'RIGHT' then --Move cursor position to the right
    TRANSPOSE_TEXT_INPUT(1)
  elseif hook_config.max_length > string.len(text.ref_table[text.ref_value]) and
        (string.len(args.key) == 1) and
        string.find( corpus,  args.key , 1, true) then --check to make sure the key is in the valid corpus, add it to the string
    MODIFY_TEXT_INPUT{
      letter = args.key,
      text_table = text,
      pos = text.current_position+1
    }
    TRANSPOSE_TEXT_INPUT(1)
  end
end)

--Helper function for g().FUNCS.text_field_key
function GET_TEXT_FROM_INPUT()
  local new_text = ''
  local hook = g().INPUT.text_capture
  for i = 1, #hook.children do
    if hook.children[i].config and hook.children[i].config.id:sub(1, 7) == 'letter_' and hook.children[i].config.text ~= '' then
      new_text = new_text..hook.children[i].config.text
    end
  end
  return new_text
end

--Helper function for g().FUNCS.text_field_key
--
---@param args {letter: string, text_table: table, pos: number, delete: boolean}
--**letter** the letter being pressed\
--**text_table** the table full of letters from hook\
--**pos** the current position of the iterator\
--**delete** if the action is a deletion action
function MODIFY_TEXT_INPUT(args)
  args = args or {}

  if args.delete and args.pos > 0 then 
    if args.pos >= #args.text_table.letters then
      args.text_table.letters[args.pos] = ''
    else
      args.text_table.letters[args.pos] = args.text_table.letters[args.pos+1]
      MODIFY_TEXT_INPUT{
        letter = args.letter,
        text_table = args.text_table,
        pos = args.pos+1,
        delete = args.delete
      }
    end
    return
  end
  local swapped_letter = args.text_table.letters[args.pos]
  args.text_table.letters[args.pos] = args.letter
  if swapped_letter and swapped_letter ~= '' then
    MODIFY_TEXT_INPUT{
      letter = swapped_letter,
      text_table = args.text_table,
      pos = args.pos+1
    }
  end
end

--Helper function for g().FUNCS.text_field_key\
--Moves the cursor left or right. Typing a key, deleting or backspacing also counts\
--as a cursor move, since empty strings are used to fill the hook
--
---@param amount number
function TRANSPOSE_TEXT_INPUT(amount)
  local position_child = nil
  local hook = g().INPUT.text_capture
  local text = g().INPUT.text_capture.config.ref_table.text
  for i = 1, #hook.children do
    if hook.children[i].config then
     if hook.children[i].config.id == 'position' then
        position_child = i; break
      end
    end
  end

  local dir = (amount/math.abs(amount)) or 0
  
  while amount ~= 0 do
    if position_child + dir < 1 or position_child + dir >= #hook.children then break end
    local real_letter = hook.children[position_child+dir].config.id:sub(1, 7) == 'letter_' and hook.children[position_child+dir].config.text ~= ''
    swap_slots(hook.children, position_child, position_child + dir)
    if real_letter then amount = amount - dir end
    position_child = position_child + dir
  end

  text.current_position = math.min(position_child-1, string.len(text.ref_table[text.ref_value]))
  hook.panel:recalculate(true)
  text.ref_table[text.ref_value] = GET_TEXT_FROM_INPUT()
end
