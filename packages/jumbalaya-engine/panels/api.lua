--[[
	jumbalaya-engine/panels/api.lua - String-kind Panel builder.

	Game screens author Panel.column / Panel.button; this module compiles to
	the existing { n = game().UI.*, config, nodes } tables LayoutNode expects.
	Do not use game().UI integers at call sites.
]]

local shell = require("jumbalaya-engine.shell")
local game = shell.game

local M = {}

local KIND_TO_UI = {
	text = "TEXT",
	box = "BOX",
	column = "COLUMN",
	row = "ROW",
	object = "OBJECT",
	root = "ROOT",
	slider = "SLIDER",
	input = "INPUT",
}

local ALIGN = {
	center = "cm",
	centre = "cm",
	left = "cl",
	right = "cr",
	top = "tm",
	bottom = "bm",
}

local BUILDER_ONLY = {
	gap = true,
	on_press = true,
	on_update = true,
}

local function ui_kind(name)
	local g = game()
	if not g or not g.UI then
		error("Panel API requires game().UI (shell not bound)", 3)
	end
	local field = KIND_TO_UI[name]
	if not field then
		error("unknown panel kind: " .. tostring(name), 3)
	end
	local n = g.UI[field]
	if n == nil and field == "COLUMN" then
		n = g.UI.COL
	end
	if n == nil then
		error("game().UI." .. field .. " is missing", 3)
	end
	return n
end

local function compile_align(align)
	if type(align) ~= "string" then
		return align
	end
	if ALIGN[align] then
		return ALIGN[align]
	end
	if #align == 2 then
		return align
	end
	error("unknown panel align: " .. align, 3)
end

--- Maps builder opts onto LayoutNode config (padding, button, func, align).
function M.compile_opts(opts)
	opts = opts or {}
	local config = {}
	for key, value in pairs(opts) do
		if not BUILDER_ONLY[key] then
			config[key] = value
		end
	end
	if opts.gap ~= nil and config.padding == nil then
		config.padding = opts.gap
	end
	if config.align ~= nil then
		config.align = compile_align(config.align)
	end
	if opts.on_press ~= nil then
		config.button = opts.on_press
	end
	if opts.on_update ~= nil then
		config.func = opts.on_update
	end
	return config
end

local function is_list(value)
	return type(value) == "table" and value.n == nil and value[1] ~= nil
end

local function container(kind_name, opts, children)
	if children == nil and is_list(opts) then
		children = opts
		opts = {}
	end
	return {
		n = ui_kind(kind_name),
		config = M.compile_opts(opts),
		nodes = children,
	}
end

function M.column(opts, children)
	return container("column", opts, children)
end

function M.row(opts, children)
	return container("row", opts, children)
end

function M.root(opts, children)
	return container("root", opts, children)
end

function M.label(text_or_opts, maybe_opts)
	local opts
	if type(text_or_opts) == "string" then
		opts = {}
		for key, value in pairs(maybe_opts or {}) do
			opts[key] = value
		end
		opts.text = text_or_opts
	else
		opts = text_or_opts or {}
	end
	return {
		n = ui_kind("text"),
		config = M.compile_opts(opts),
	}
end

function M.box(opts)
	return {
		n = ui_kind("box"),
		config = M.compile_opts(opts),
	}
end

function M.object(opts)
	return {
		n = ui_kind("object"),
		config = M.compile_opts(opts),
	}
end

function M.slider(opts, children)
	return container("slider", opts, children)
end

function M.input(opts, children)
	return container("input", opts, children)
end

function M.button(opts, children)
	opts = opts or {}
	local config_src = {}
	for key, value in pairs(opts) do
		if key ~= "text" and key ~= "label" then
			config_src[key] = value
		end
	end
	if config_src.hover == nil then
		config_src.hover = true
	end
	children = children
	if (not children or #children == 0) and (opts.text or opts.label) then
		local caption = opts.text or opts.label
		if type(caption) == "table" then
			caption = caption[1]
		end
		children = { M.label(tostring(caption or ""), {
			scale = opts.scale,
			colour = opts.text_colour,
			shadow = opts.shadow,
			font = opts.font,
			id = opts.label_id,
		}) }
	end
	return {
		n = ui_kind("column"),
		config = M.compile_opts(config_src),
		nodes = children,
	}
end

M.kind = ui_kind

return M
