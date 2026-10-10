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

		T.it("never draws bound card-layer sprites as scene roots", function()
			local game = shell.game() or {}
			shell.bind_game(game)
			game.SCENE_ROOTS = {}

			local bound = {
				states = { visible = true },
				attach = { mode = "bind" },
			}
			SceneRoots.register(bound, "transform")
			T.assert_equal(#game.SCENE_ROOTS, 0, "raw letter_frame sprites must not paint themselves")
		end)
	end)

	T.describe("spatial attach", function()
		T.it("set_rect writes the layout target", function()
			mock_env.reset_game()
			mock_env.ensure_engine_globals()
			local Spatial = require("jumbalaya-engine.scene.animated.init")
			local node = Spatial(0, 0, 1, 1)
			node:set_rect(2, 3, 4, 5)
			T.assert_equal(node:get_rect().x, 2)
			T.assert_equal(node.T.x, 2)
			T.assert_equal(node.target.x, 2)
			T.assert_equal(node:get_rect().w, 4)
		end)

		T.it("bind_to copies the host drawn rect on tick", function()
			mock_env.reset_game()
			mock_env.ensure_engine_globals()
			local Spatial = require("jumbalaya-engine.scene.animated.init")
			local host = Spatial(1, 2, 3, 4)
			host:snap_rect(1, 2, 3, 4)
			local face = Spatial(0, 0, 3, 4)
			face:bind_to(host)
			host.FRAME.TRANSFORM = -1
			face.FRAME.TRANSFORM = -1
			local game = shell.game()
			game.FRAMES.TRANSFORM = (game.FRAMES.TRANSFORM or 0) + 1
			face:tick(0.016)
			T.assert_equal(face.VT.x, host.VT.x)
			T.assert_equal(face.VT.y, host.VT.y)
			T.assert_equal(face.attach.mode, "bind")
		end)

		T.it("follow offsets the layout target from the host", function()
			mock_env.reset_game()
			mock_env.ensure_engine_globals()
			local Spatial = require("jumbalaya-engine.scene.animated.init")
			local host = Spatial(1, 2, 3, 4)
			host:snap_rect(1, 2, 3, 4)
			local child = Spatial(0, 0, 3, 4)
			child:follow(host, { x = 0.5, y = -0.25 })
			host.FRAME.TRANSFORM = -1
			child.FRAME.TRANSFORM = -1
			local game = shell.game()
			game.FRAMES.TRANSFORM = (game.FRAMES.TRANSFORM or 0) + 1
			child:tick(0.016)
			T.assert_equal(child.attach.mode, "follow")
			T.assert_equal(child.T.x, host.T.x + 0.5)
			T.assert_equal(child.T.y, host.T.y - 0.25)
		end)
	end)

	T.describe("motion freeze", function()
		T.it("does not reintroduce retired Spatial APIs", function()
			local paths = require("bootstrap_paths").resolve()
			local banned = { "hard_set_T", "align_to_major", "function Spatial:set_role" }
			local roots = {
				paths.repo_root .. "/packages/jumbalaya-engine",
				paths.game_root .. "/word_game",
			}
			local hits = {}
			for _, root in ipairs(roots) do
				local handle = io.popen(string.format('find %s -name "*.lua" -type f 2>/dev/null', root))
				if handle then
					for file in handle:lines() do
						local fh = io.open(file, "r")
						if fh then
							local text = fh:read("*a")
							fh:close()
							for _, token in ipairs(banned) do
								if text and text:find(token, 1, true) then
									hits[#hits + 1] = file .. ":" .. token
								end
							end
						end
					end
					handle:close()
				end
			end
			T.assert_equal(#hits, 0, table.concat(hits, "\n"))
		end)
	end)
end)
