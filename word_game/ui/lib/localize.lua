--[[
	word_game/ui/localize.lua - parse localization strings and build UI copy.

	loc_parse_string turns `{C:red}text{}` markup into node parts. localize()
	picks the right parsed blob for names, unlocks, and descriptions.
]]

function init_localization()
  G.localization.misc.v_dictionary_parsed = {}
  for k, v in pairs(G.localization.misc.v_dictionary or {}) do
    if type(v) == 'table' then
      G.localization.misc.v_dictionary_parsed[k] = {multi_line = true}
      for kk, vv in ipairs(v) do
        G.localization.misc.v_dictionary_parsed[k][kk] = loc_parse_string(vv)
      end
    else
      G.localization.misc.v_dictionary_parsed[k] = loc_parse_string(v)
    end
  end
  G.localization.misc.v_text_parsed = {}
  for k, v in pairs(G.localization.misc.v_text or {}) do
    G.localization.misc.v_text_parsed[k] = {}
    for kk, vv in ipairs(v) do
      G.localization.misc.v_text_parsed[k][kk] = loc_parse_string(vv)
    end
  end
  G.localization.tutorial_parsed = {}
  for k, v in pairs(G.localization.misc.tutorial or {}) do
    G.localization.tutorial_parsed[k] = {multi_line = true}
      for kk, vv in ipairs(v) do
        G.localization.tutorial_parsed[k][kk] = loc_parse_string(vv)
      end
  end
  G.localization.quips_parsed = {}
  for k, v in pairs(G.localization.misc.quips or {}) do
    G.localization.quips_parsed[k] = {multi_line = true}
      for kk, vv in ipairs(v) do
        G.localization.quips_parsed[k][kk] = loc_parse_string(vv)
      end
  end
  for g_k, group in pairs(G.localization) do
    if g_k == 'descriptions' then
      for _, set in pairs(group) do
        for _, center in pairs(set) do
          center.text_parsed = {}
          for _, line in ipairs(center.text) do
            center.text_parsed[#center.text_parsed+1] = loc_parse_string(line)
          end
          center.name_parsed = {}
          for _, line in ipairs(type(center.name) == 'table' and center.name or {center.name}) do
            center.name_parsed[#center.name_parsed+1] = loc_parse_string(line)
          end
          if center.unlock then
            center.unlock_parsed = {}
            for _, line in ipairs(center.unlock) do
              center.unlock_parsed[#center.unlock_parsed+1] = loc_parse_string(line)
            end
          end
        end
      end
    end
  end
end

--[[
	loc_parse_string - markup parser for localization lines.

	Input grammar:
	  line    := span*
	  span    := styled_text | '{' section '}'
	  section := field (',' field)*          -- e.g. {C:red}, {V:1,s:0.8}, {}
	  field   := name (':' value)?           -- bare fields are ignored
	  styled_text := (literal | '#' ref '#')*

	Text following a section carries that section's style; an empty section
	({}) clears it. A `#..#` pair becomes a reference run resolved later
	against `vars` by index ({strings = {..., {'1'}, ...}}). Sections whose
	text is empty produce no part. When a style declares `X`, whitespace is
	stripped from its text (used for solid background chips).

	Output: array of { strings = (string|{ref})[], control = table } parts,
	consumed by `localize()`.
]]

--- Appends a literal run, dropping empties (and whitespace under `X` styles).
local function push_literal(runs, text, strip_spaces)
	if strip_spaces then text = text:gsub('%s+', '') end
	if text ~= '' then
		runs[#runs + 1] = text
	end
end

--- Splits styled text on `#ref#` markers into literal and reference runs.
local function split_text_runs(text, strip_spaces)
	local runs = {}
	local i, n = 1, #text
	while i <= n do
		local open = text:find('#', i, true)
		push_literal(runs, text:sub(i, (open or n + 1) - 1), strip_spaces)
		if not open then break end

		local close = text:find('#', open + 1, true)
		if close then
			runs[#runs + 1] = { text:sub(open + 1, close - 1) }
			i = close + 1
		else
			break -- unterminated reference: the tail is discarded
		end
	end
	return runs
end

--- Parses the body of one `{...}` section into a style table. The value is
--- everything after the first ':'; fields without a value are ignored,
--- matching how consumers read the result.
local function parse_control(body)
	local control = {}
	if body == '' then return control end
	for field in body:gmatch('[^,]+') do
		local name, value = field:match('^([^:]*)[:](.*)$')
		if name and value ~= nil and name ~= '' then
			control[name] = value
		end
	end
	return control
end

function loc_parse_string(line)
	local parts = {}
	if type(line) ~= 'string' then return parts end

	local control = {}
	local pos = 1
	while pos <= #line do
		local open = line:find('{', pos, true)
		local text = line:sub(pos, (open or #line + 1) - 1)
		if text ~= '' then
			parts[#parts + 1] = {
				strings = split_text_runs(text, control.X ~= nil),
				control = control,
			}
		end
		if not open then break end

		local close = line:find('}', open + 1, true)
		control = parse_control(line:sub(open + 1, (close or #line + 1) - 1))
		pos = (close or #line + 1) + 1
	end
	return parts
end

--UTF8 handler for special characters, from https://github.com/blitmap/lua-utf8-simple
---@class Utf8Simple
---@field pattern string
---@field map function
---@field chars fun(s: string, no_subs: boolean|nil): fun(): integer, string
---@type Utf8Simple
utf8 = {pattern = '[%z\1-\127\194-\244][\128-\191]*'}
utf8.map =
	function (s, f, no_subs)
		local i = 0

		if no_subs then
			for b, e in s:gmatch('()' .. utf8.pattern .. '()') do
				i = i + 1
				local c = e - b
				f(i, c, b)
			end
		else
			for b, c in s:gmatch('()(' .. utf8.pattern .. ')') do
				i = i + 1
				f(i, c, b)
			end
		end
	end
utf8.chars =
	function (s, no_subs)
		return coroutine.wrap(function () return utf8.map(s, coroutine.yield, no_subs) end)
	end

---@param s string
---@return fun(): string|nil
function each_utf8_char(s)
	return s:gmatch(utf8.pattern)
end

function localize(args, misc_cat)
  if not G.localization or not G.localization.misc then
    if type(args) == 'string' then return args end
    if type(args) == 'table' and args.key then return tostring(args.key) end
    return 'ERROR'
  end

  if args and not (type(args) == 'table') then
    if misc_cat and G.localization.misc[misc_cat] then return G.localization.misc[misc_cat][args] or 'ERROR' end
    return (G.localization.misc.dictionary and G.localization.misc.dictionary[args]) or 'ERROR'
  end

  local loc_target = nil
  local ret_string = nil
  local desc_set = function(set_name)
    return G.localization.descriptions[set_name]
  end
  if args.type == 'other' then
    loc_target = desc_set('Other') and desc_set('Other')[args.key]
  elseif args.type == 'descriptions' or args.type == 'unlocks' then 
    loc_target = desc_set(args.set) and desc_set(args.set)[args.key]
  elseif args.type == 'tutorial' then 
    loc_target = G.localization.tutorial_parsed[args.key]
  elseif args.type == 'quips' then 
    loc_target = G.localization.quips_parsed[args.key]
  elseif args.type == 'raw_descriptions' then 
    loc_target = desc_set(args.set) and desc_set(args.set)[args.key]
    local multi_line = {}
    if loc_target then 
      for _, lines in ipairs(args.type == 'unlocks' and loc_target.unlock_parsed or args.type == 'name' and loc_target.name_parsed or args.type == 'text' and loc_target or loc_target.text_parsed) do
        local final_line = ''
        for _, part in ipairs(lines) do
          local assembled_string = ''
          for _, subpart in ipairs(part.strings) do
            assembled_string = assembled_string..(type(subpart) == 'string' and subpart or args.vars[tonumber(subpart[1])] or 'ERROR')
          end
          final_line = final_line..assembled_string
        end
        multi_line[#multi_line+1] = final_line
      end
    end
    return multi_line
  elseif args.type == 'text' then
    loc_target = G.localization.misc.v_text_parsed[args.key]
  elseif args.type == 'variable' then 
    loc_target = G.localization.misc.v_dictionary_parsed[args.key]
    if not loc_target then return 'ERROR' end 
    if loc_target.multi_line then
      local assembled_strings = {}
      for k, v in ipairs(loc_target) do
        local assembled_string = ''
        for _, subpart in ipairs(v[1].strings) do
          assembled_string = assembled_string..(type(subpart) == 'string' and subpart or args.vars[tonumber(subpart[1])])
        end
        assembled_strings[k] = assembled_string
      end
      return assembled_strings or {'ERROR'}
    else
      local assembled_string = ''
      for _, subpart in ipairs(loc_target[1].strings) do
        assembled_string = assembled_string..(type(subpart) == 'string' and subpart or args.vars[tonumber(subpart[1])])
      end
      ret_string = assembled_string or 'ERROR'
    end
  elseif args.type == 'name_text' then
    if pcall(function() ret_string = G.localization.descriptions[(args.set or args.node.config.center.set)][args.key or args.node.config.center.key].name end) then
    else ret_string = "ERROR" end
  elseif args.type == 'name' then
    local set = desc_set(args.set or args.node.config.center.set)
    loc_target = set and set[args.key or args.node.config.center.key]
  end

  if ret_string then return ret_string end

  if loc_target then 
    for _, lines in ipairs(args.type == 'unlocks' and loc_target.unlock_parsed or args.type == 'name' and loc_target.name_parsed or (args.type == 'text' or args.type == 'tutorial' or args.type == 'quips') and loc_target or loc_target.text_parsed) do
      local final_line = {}
      for _, part in ipairs(lines) do
        local assembled_string = ''
        for _, subpart in ipairs(part.strings) do
          assembled_string = assembled_string..(type(subpart) == 'string' and subpart or args.vars[tonumber(subpart[1])] or 'ERROR')
        end
        local desc_scale = G.LANG.font.DESCSCALE
        if args.type == 'name' then
          final_line[#final_line+1] = {n=G.UI.OBJECT, config={
            object = FlowText({string = {assembled_string},
              colours = {(part.control.V and args.vars.colours[tonumber(part.control.V)]) or (part.control.C and loc_colour(part.control.C)) or G.C.UI.TEXT_LIGHT},
              bump = true,
              silent = true,
              pop_in = 0,
              pop_in_rate = 4,
              maxw = 5,
              shadow = true,
              y_offset = -0.6,
              spacing = math.max(0, 0.32*(17 - #assembled_string)),
              scale =  (0.55 - 0.004*#assembled_string)*(part.control.s and tonumber(part.control.s) or 1)*desc_scale
            })
          }}
        elseif part.control.E then
          local _float, _silent, _pop_in, _bump, _spacing = nil, true, nil, nil, nil
          if part.control.E == '1' then
            _float = true; _silent = true; _pop_in = 0
          elseif part.control.E == '2' then
            _bump = true; _spacing = 1
          end
          final_line[#final_line+1] = {n=G.UI.OBJECT, config={
            object = FlowText({string = {assembled_string}, colours = {part.control.V and args.vars.colours[tonumber(part.control.V)] or loc_colour(part.control.C or nil)},
            float = _float,
            silent = _silent,
            pop_in = _pop_in,
            bump = _bump,
            spacing = _spacing,
            scale = 0.32*(part.control.s and tonumber(part.control.s) or 1)*desc_scale})
          }}
        elseif part.control.X then
          final_line[#final_line+1] = {n=G.UI.COLUMN, config={align = "m", colour = loc_colour(part.control.X), r = 0.05, padding = 0.03, res = 0.15}, nodes={
              {n=G.UI.TEXT, config={
                text = assembled_string,
                colour = loc_colour(part.control.C or nil),
                scale = 0.32*(part.control.s and tonumber(part.control.s) or 1)*desc_scale}},
          }}
        else
          final_line[#final_line+1] = {n=G.UI.TEXT, config={
          detailed_tooltip = part.control.T and G.P_CENTERS[part.control.T] or nil,
          text = assembled_string,
          shadow = args.shadow,
          colour = part.control.V and args.vars.colours[tonumber(part.control.V)] or loc_colour(part.control.C or nil, args.default_col),
          scale = 0.32*(part.control.s and tonumber(part.control.s) or 1)*desc_scale},}
        end
      end
        if args.type == 'name' or args.type == 'text' then return final_line end
        args.nodes[#args.nodes+1] = final_line
    end
  end
end
