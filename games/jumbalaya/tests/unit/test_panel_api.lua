--[[ tests/unit/test_panel_api.lua - Panel compiler + function callbacks ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local invoke = require("jumbalaya-engine.panels.invoke")
local Panel = require("jumbalaya-engine.panels.api")

local function bind_ui()
	mock_env.reset_game()
	local g = shell.game()
	g.UI = {
		TEXT = 1,
		BOX = 2,
		COLUMN = 3,
		ROW = 4,
		OBJECT = 5,
		ROOT = 7,
		SLIDER = 8,
		INPUT = 9,
		padding = 0,
	}
end

T.describe("Panel API compiler", function()
	T.it("compiles string kinds to game().UI integers", function()
		bind_ui()
		local tree = Panel.column({ align = "center", gap = 8 }, {
			Panel.label("Play"),
		})
		T.assert_equal(tree.n, shell.game().UI.COLUMN)
		T.assert_equal(tree.config.align, "cm")
		T.assert_equal(tree.config.padding, 8)
		T.assert_equal(tree.nodes[1].n, shell.game().UI.TEXT)
		T.assert_equal(tree.nodes[1].config.text, "Play")
	end)

	T.it("maps on_press onto config.button without stringifying", function()
		bind_ui()
		local pressed = false
		local fn = function() pressed = true end
		local tree = Panel.button({ id = "play", on_press = fn })
		T.assert_equal(tree.config.id, "play")
		T.assert_equal(tree.config.button, fn)
		T.assert_equal(type(tree.config.button), "function")
		tree.config.button()
		T.assert_true(pressed)
	end)

	T.it("rejects unknown align words", function()
		bind_ui()
		local ok = pcall(Panel.column, { align = "diagonal" }, {})
		T.assert_false(ok)
	end)
end)

T.describe("Panel callback invoke", function()
	T.it("calls function handlers without a catalog name", function()
		local seen
		invoke.call(function(node) seen = node end, { id = "play" })
		T.assert_equal(seen.id, "play")
	end)

	T.it("dispatches string handlers through Funcs", function()
		local called = false
		shell.bind_funcs({
			get = function(name) return name == "catalog_press" end,
			dispatch = function(name, extra)
				called = name == "catalog_press" and extra == "node"
			end,
		})
		invoke.call("catalog_press", "node")
		T.assert_true(called)
		invoke.call("missing_name", "node")
		shell.bind_funcs(nil)
	end)
end)

T.describe("ViewHost", function()
	T.it("__index does not recurse after remove or nested wrap", function()
		local ViewHost = require("jumbalaya-engine.panels.view_host")
		local inner = ViewHost.wrap({
			T = { x = 1 },
			VT = {},
			config = { id = "inner" },
			children = {},
			root_node = {},
			REMOVED = false,
		})
		local outer = ViewHost.wrap(inner)
		T.assert_equal(outer.T.x, 1)
		T.assert_nil(outer.no_such_field)
		outer:remove()
		T.assert_true(outer.REMOVED)
		T.assert_nil(outer.no_such_field)
		T.assert_nil(inner.no_such_field)
	end)
end)
