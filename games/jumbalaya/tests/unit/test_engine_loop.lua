--[[ tests/unit/test_engine_loop.lua - Transform registry and scene root list ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Tables = require("jumbalaya-engine.util.tables")
local SceneRoots = require("jumbalaya-engine.scene.roots")
local shell = require("jumbalaya-engine.shell")

T.describe("engine loop", function()
	mock_env.ensure_engine_globals()

	T.describe("transform registry", function()
		T.it("remove_swap_last drops a value in O(1) without leaving holes", function()
			local list = { "a", "b", "c" }
			T.assert_true(Tables.remove_swap_last(list, "b"))
			T.assert_equal(#list, 2)
			T.assert_equal(list[1], "a")
			T.assert_equal(list[2], "c")
		end)
	end)

	T.describe("scene roots", function()
		T.it("tracks root nodes and drops them when parent is set", function()
			local game = shell.game() or {}
			shell.bind_game(game)
			game.SCENE_ROOTS = {}

			local root = { states = { visible = true } }
			SceneRoots.register(root, "node")
			T.assert_equal(#game.SCENE_ROOTS, 1)

			SceneRoots.set_parent(root, { id = "parent" })
			T.assert_equal(#game.SCENE_ROOTS, 0)

			SceneRoots.set_parent(root, nil)
			T.assert_equal(#game.SCENE_ROOTS, 1)

			SceneRoots.unregister(root)
			T.assert_equal(#game.SCENE_ROOTS, 0)
		end)
	end)
end)
