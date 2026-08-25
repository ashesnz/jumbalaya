--[[
	word_game/ui/widgets/components.lua - component API over the UI node tree.

	Wraps the declarative {n=G.UI.*, config={...}} DSL in composable
	component constructors with friendlier keys (`onClick`, `width`,
	`height`, `textSize`) and Jumbalaya's own chrome language: flat
	panels with soft corners and hover tints instead of embossed,
	drop-shadowed boxes.

	Legacy builder keys (button/minw/minh/scale/func) remain accepted so
	existing call sites keep working.
]]

local Components = {}

-- Shared chrome constants. Tune here, applies everywhere.
local CHROME = {
	radius = 0.12,
	padding = 0.1,
	label_gap = 0,
}

Components.CHROME = CHROME

local action_seq = 0

--- Turns an action spec into an engine callback name. Functions are
--- registered as generated G.FUNCS entries so closures work as handlers;
--- strings pass through untouched.
---@param action function|string|nil
---@param fallback string|nil
---@return string|nil
local function resolve_action(action, fallback)
	if type(action) == "function" then
		action_seq = action_seq + 1
		local name = "__component_action_" .. action_seq
		G.FUNCS[name] = function(node) action(node) end
		return name
	end
	if action == "nil" then return nil end
	return action or fallback
end

Components.resolve_action = resolve_action

--------------------------------------------------------------------
-- Button
--------------------------------------------------------------------

--- Builds a push button.
--- Friendly keys: onClick (function or G.FUNCS name), onTick, width,
--- height, textSize, textColour. Legacy keys still honoured.
---@param def table
function Components.button(def)
	def = def or {}

	local click = resolve_action(def.onClick or def.button, "close_overlay")
	local tick = resolve_action(def.onTick or def.func)

	local minw = def.minw or def.width or 2.7
	local maxw = def.maxw or (minw - 0.2)
	if minw < maxw then maxw = minw - 0.2 end
	local minh = def.minh or def.height or 0.9
	local scale = def.scale or def.textSize or 0.5

	local labels = def.label or {'LABEL'}
	if type(labels) ~= 'table' then labels = {labels} end

	local rows = {}
	for k, v in ipairs(labels) do
		local wants_pip = k == #labels and def.focus_args and def.focus_args.set_button_pip
		rows[#rows + 1] = {n=G.UI.ROW, config={align = "cm", padding = CHROME.label_gap, minw = minw, maxw = maxw}, nodes={
			{n=G.UI.TEXT, config={text = v, scale = scale, font = alpha_button_font(), colour = def.textColour or def.text_colour or G.C.UI.TEXT_LIGHT, shadow = def.shadow, focus_args = wants_pip and def.focus_args or nil, func = wants_pip and 'set_button_pip' or nil, ref_table = def.ref_table}}
		}}
	end

	if def.count then
		rows[#rows + 1] = {n=G.UI.ROW, config={align = "cm", minh = 0.4}, nodes={
			{n=G.UI.TEXT, config={scale = 0.35, text = def.count.tally..' / '..def.count.of, colour = {1, 1, 1, 0.9}}}
		}}
	end

	return {n=(def.col == true and G.UI.COLUMN or G.UI.ROW), config={align = 'cm'}, nodes={
		{n=G.UI.COLUMN, config={
			align = "cm",
			padding = def.padding or CHROME.padding,
			r = CHROME.radius,
			hover = true,
			colour = def.colour or G.C.RED,
			hover_colour = def.hover_colour or G.C.UI.BUTTON_HOVER,
			one_press = def.one_press,
			button = click,
			choice = def.choice,
			chosen = def.chosen,
			focus_args = def.focus_args,
			minh = minh - 0.3 * (def.count and 1 or 0),
			shadow = false,
			func = tick,
			id = def.id,
			back_func = def.back_func,
			ref_table = def.ref_table,
			mid = def.mid,
		}, nodes = rows},
	}}
end

--------------------------------------------------------------------
-- Slider
--------------------------------------------------------------------

--- Builds a drag slider bound to ref_table[ref_value].
function Components.slider(def)
	def = def or {}
	def.colour = def.colour or G.C.RED
	def.w = def.w or def.width or 1
	def.h = def.h or def.height or 0.5
	def.label_scale = def.label_scale or 0.5
	def.text_scale = def.text_scale or 0.3
	def.min = def.min or 0
	def.max = def.max or 1
	def.decimal_places = def.decimal_places or 0
	def.text = string.format("%."..tostring(def.decimal_places).."f", def.ref_table[def.ref_value])
	local startval = def.w * (def.ref_table[def.ref_value] - def.min) / (def.max - def.min)

	local t =
		{n=G.UI.COLUMN, config={align = "cm", minw = def.w, min_h = def.h, padding = 0.07, r = CHROME.radius * 0.6, colour = G.C.CLEAR, focus_args = {type = 'slider'}}, nodes={
			{n=G.UI.COLUMN, config={align = "cl", minw = def.w, r = CHROME.radius * 0.6, min_h = def.h, collideable = true, hover = true, colour = G.C.BLACK, func = 'drag_slider', refresh_movement = true}, nodes={
				{n=G.UI.BOX, config={w = startval, h = def.h, r = CHROME.radius * 0.6, colour = def.colour, ref_table = def, refresh_movement = true}},
			}},
			{n=G.UI.COLUMN, config={align = "cm", minh = def.h, r = CHROME.radius * 0.6, minw = 0.8, colour = G.C.CLEAR}, nodes={
				{n=G.UI.TEXT, config={ref_table = def, ref_value = 'text', scale = def.text_scale, colour = G.C.UI.TEXT_LIGHT, decimal_places = def.decimal_places}}
			}},
		}}

	if def.label then
		t = {n=G.UI.ROW, config={align = "cm", minh = 1, minw = 1, padding = 0.1 * def.label_scale, colour = G.C.CLEAR}, nodes={
			{n=G.UI.ROW, config={align = "cm", padding = CHROME.label_gap}, nodes={
				{n=G.UI.TEXT, config={text = def.label, scale = def.label_scale, colour = G.C.UI.TEXT_LIGHT}}
			}},
			{n=G.UI.ROW, config={align = "cm", padding = CHROME.label_gap}, nodes={t}},
		}}
	end
	return t
end

--------------------------------------------------------------------
-- Toggle switch
--------------------------------------------------------------------

--- Builds a flip toggle bound to ref_table[ref_value].
function Components.toggle(def)
	def = def or {}
	def.active_colour = def.active_colour or G.C.RED
	def.inactive_colour = def.inactive_colour or G.C.BLACK
	def.w = def.w or def.width or 3
	def.h = def.h or def.height or 0.5
	def.scale = def.scale or 1
	def.label = def.label or 'TEST?'
	def.label_scale = def.label_scale or 0.4
	def.ref_table = def.ref_table or {}
	def.ref_value = def.ref_value or 'test'

	local check = Sprite(0, 0, 0.5 * def.scale, 0.5 * def.scale, G.TEXTURE_ATLASES["icons"], {x = 1, y = 0})
	check.states.drag.can = false
	check.states.visible = false

	local info = nil
	if def.info then
		info = {}
		for _, v in ipairs(def.info) do
			table.insert(info, {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
				{n=G.UI.TEXT, config={text = v, scale = 0.25, colour = G.C.UI.TEXT_LIGHT}}
			}})
		end
		info = {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes = info}
	end

	local t =
		{n=def.col and G.UI.COLUMN or G.UI.ROW, config={align = "cm", padding = CHROME.padding, r = CHROME.radius, colour = G.C.CLEAR, focus_args = {funnel_from = true}}, nodes={
			{n=G.UI.COLUMN, config={align = "cr", minw = def.w}, nodes={
				{n=G.UI.TEXT, config={text = def.label, scale = def.label_scale, colour = G.C.UI.TEXT_LIGHT}},
				{n=G.UI.BOX, config={w = 0.1, h = 0.1}},
			}},
			{n=G.UI.COLUMN, config={align = "cl", minw = 0.3 * def.w}, nodes={
				{n=G.UI.COLUMN, config={align = "cm", r = CHROME.radius, colour = G.C.BLACK}, nodes={
					{n=G.UI.COLUMN, config={align = "cm", r = CHROME.radius, padding = 0.03, minw = 0.4 * def.scale, minh = 0.4 * def.scale, outline_colour = G.C.WHITE, outline = 1.2 * def.scale, line_emboss = 0.5 * def.scale, ref_table = def,
						colour = def.inactive_colour,
						hover_colour = def.active_colour,
						button = 'flip_switch', button_dist = 0.2, hover = true, toggle_callback = def.callback, func = 'flip_switch', focus_args = {funnel_to = true}}, nodes={
						{n=G.UI.OBJECT, config={object = check}},
					}},
				}}
			}},
		}}

	if def.info then
		t = {n=def.col and G.UI.COLUMN or G.UI.ROW, config={align = "cm"}, nodes={t, info}}
	end
	return t
end

--------------------------------------------------------------------
-- Option cycler
--------------------------------------------------------------------

--- Builds a `< value >` option cycler bound to an opt_callback.
function Components.cycler(def)
	def = def or {}
	def.colour = def.colour or G.C.RED
	def.options = def.options or {'Option 1', 'Option 2'}
	def.current_option = def.current_option or 1
	def.current_option_val = def.options[def.current_option]
	-- Engine's cycle handler dispatches through `opt_callback`; `onChange`
	-- is the public name (and accepts closures via resolve_action).
	def.opt_callback = resolve_action(def.onChange or def.opt_callback)
	def.scale = def.scale or 1
	def.ref_table = def.ref_table or nil
	def.ref_value = def.ref_value or nil
	def.w = (def.w or 2.5) * def.scale
	def.h = (def.h or 0.8) * def.scale
	def.text_scale = (def.text_scale or 0.5) * def.scale
	def.l = '<'
	def.r = '>'
	def.focus_args = def.focus_args or {}
	def.focus_args.type = 'cycle'

	local info = nil
	if def.info then
		info = {}
		for _, v in ipairs(def.info) do
			table.insert(info, {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={
				{n=G.UI.TEXT, config={text = v, scale = 0.3 * def.scale, colour = G.C.UI.TEXT_LIGHT}}
			}})
		end
		info = {n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes = info}
	end

	local disabled = #def.options < 2
	local pips = {}
	for i = 1, #def.options do
		pips[#pips + 1] = {n=G.UI.BOX, config={w = 0.1 * def.scale, h = 0.1 * def.scale, r = 0.05, id = 'pip_'..i, colour = def.current_option == i and G.C.WHITE or G.C.BLACK}}
	end

	local choice_pips = not def.no_pips and {n=G.UI.ROW, config={align = "cm", padding = (0.05 - (#def.options > 15 and 0.03 or 0)) * def.scale}, nodes = pips} or nil

	local arrow_chip = {
		align = "cm",
		r = CHROME.radius,
		minw = 0.6 * def.scale,
		hover = not disabled,
		hover_colour = def.hover_colour or G.C.UI.BUTTON_HOVER,
		colour = not disabled and def.colour or G.C.BLACK,
		button = not disabled and 'cycle_option' or nil,
		ref_table = def,
		focus_args = {type = 'none'},
	}

	local t =
		{n=G.UI.COLUMN, config={align = "cm", padding = CHROME.padding, r = CHROME.radius, colour = G.C.CLEAR, id = def.id and (not def.label and def.id or nil) or nil, focus_args = def.focus_args}, nodes={
			{n=G.UI.COLUMN, config=arrow_chip, nodes={
				{n=G.UI.TEXT, config={ref_table = def, ref_value = 'l', scale = def.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
			}},
			def.mid and
			{n=G.UI.COLUMN, config={id = 'cycle_main'}, nodes={
				{n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={def.mid}},
				not disabled and choice_pips or nil,
			}}
			or {n=G.UI.COLUMN, config={id = 'cycle_main', align = "cm", minw = def.w, minh = def.h, r = CHROME.radius, padding = 0.05, colour = def.colour, hover = true, hover_colour = def.hover_colour or G.C.UI.BUTTON_HOVER, can_collide = true, on_demand_tooltip = def.on_demand_tooltip}, nodes={
				{n=G.UI.ROW, config={align = "cm"}, nodes={
					{n=G.UI.ROW, config={align = "cm"}, nodes={
						{n=G.UI.OBJECT, config={object = FlowText({string = {{ref_table = def, ref_value = "current_option_val"}}, colours = {G.C.UI.TEXT_LIGHT}, pop_in = 0, pop_in_rate = 8, reset_pop_in = true, shadow = true, float = true, silent = true, bump = true, scale = def.text_scale, non_recalc = true})}},
					}},
					{n=G.UI.ROW, config={align = "cm", minh = 0.05}, nodes={}},
					not disabled and choice_pips or nil,
				}}
			}},
			{n=G.UI.COLUMN, config=arrow_chip, nodes={
				{n=G.UI.TEXT, config={ref_table = def, ref_value = 'r', scale = def.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
			}},
		}}

	if def.cycle_shoulders then
		t =
		{n=G.UI.ROW, config={align = "cm", colour = G.C.CLEAR}, nodes = {
			{n=G.UI.COLUMN, config={minw = 0.7, align = "cm", colour = G.C.CLEAR, func = 'set_button_pip', focus_args = {button = 'leftshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = -0.1, y = 0}}}, nodes = {}},
			{n=G.UI.COLUMN, config={id = 'cycle_shoulders', padding = CHROME.padding}, nodes = {t}},
			{n=G.UI.COLUMN, config={minw = 0.7, align = "cm", colour = G.C.CLEAR, func = 'set_button_pip', focus_args = {button = 'rightshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}},
		}}
	else
		t =
		{n=G.UI.ROW, config={align = "cm", colour = G.C.CLEAR, padding = 0.0}, nodes = {t}}
	end

	if def.label or def.info then
		t = {n=G.UI.ROW, config={align = "cm", padding = 0.05, id = def.id or nil}, nodes={
			def.label and {n=G.UI.ROW, config={align = "cm"}, nodes={
				{n=G.UI.TEXT, config={text = def.label, scale = 0.5 * def.scale, colour = G.C.UI.TEXT_LIGHT}}
			}} or nil,
			t,
			info,
		}}
	end
	return t
end

return Components
