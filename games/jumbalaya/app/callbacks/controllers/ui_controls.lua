--[[ app/controllers/ui_controls.lua - Phase 4 UI control controller (sliders, cycles) ]]

local dispatch_wrap = require("app.callbacks.controllers.dispatch_wrap")

local BridgeRuntime = require("app.runtime")
local Funcs = require("app.callbacks.funcs")
local function g() return BridgeRuntime.game() end

local M = {}

local function drag_slider_impl(e)
	local c = e.children[1]
	e.states.drag.can = true
	c.states.drag.can = true
	if g().INPUT and g().INPUT.dragging.target
		and (g().INPUT.dragging.target == e or g().INPUT.dragging.target == c) then
		local rt = c.config.ref_table
		rt.ref_table[rt.ref_value] = math.min(rt.max, math.max(rt.min, rt.min + (rt.max - rt.min) * (g().POINTER.T.x - e.parent.T.x - g().ROOM.T.x) / e.T.w))
		rt.text = string.format("%." .. tostring(rt.decimal_places) .. "f", rt.ref_table[rt.ref_value])
		c.T.w = (rt.ref_table[rt.ref_value] - rt.min) / (rt.max - rt.min) * rt.w
		c.config.w = c.T.w
		if rt.callback then Funcs.dispatch(rt.callback, rt) end
	end
end

function M.slider_step(e, per)
	local c = e.children[1]
	e.states.drag.can = true
	c.states.drag.can = true
	if per then
		local rt = c.config.ref_table
		rt.ref_table[rt.ref_value] = math.min(rt.max, math.max(rt.min, rt.ref_table[rt.ref_value] + per * (rt.max - rt.min)))
		rt.text = string.format("%." .. tostring(rt.decimal_places) .. "f", rt.ref_table[rt.ref_value])
		c.T.w = (rt.ref_table[rt.ref_value] - rt.min) / (rt.max - rt.min) * rt.w
		c.config.w = c.T.w
	end
end

function M.cycle_option(e)
	local from_val = e.config.ref_table.options[e.config.ref_table.current_option]
	local from_key = e.config.ref_table.current_option
	local old_pip = e.panel:find_node_by_id('pip_' .. e.config.ref_table.current_option, e.parent.parent)
	local cycle_main = e.panel:find_node_by_id('cycle_main', e.parent.parent)

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
		e.config.ref_table.current_option = e.config.ref_table.current_option - 1
		if e.config.ref_table.current_option <= 0 then e.config.ref_table.current_option = #e.config.ref_table.options end
	else
		e.config.ref_table.current_option = e.config.ref_table.current_option + 1
		if e.config.ref_table.current_option > #e.config.ref_table.options then e.config.ref_table.current_option = 1 end
	end
	local to_val = e.config.ref_table.options[e.config.ref_table.current_option]
	local to_key = e.config.ref_table.current_option
	e.config.ref_table.current_option_val = e.config.ref_table.options[e.config.ref_table.current_option]

	local new_pip = e.panel:find_node_by_id('pip_' .. e.config.ref_table.current_option, e.parent.parent)

	if old_pip then old_pip.config.colour = g().C.BLACK end
	if new_pip then new_pip.config.colour = g().C.WHITE end

	if e.config.ref_table.opt_callback then
		Funcs.dispatch(e.config.ref_table.opt_callback, {
			from_val = from_val,
			to_val = to_val,
			from_key = from_key,
			to_key = to_key,
			cycle_config = e.config.ref_table
		})
	end
end

M.drag_slider = dispatch_wrap.wrap("drag_slider", drag_slider_impl)

return M
