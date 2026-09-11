--[[ tests/unit/test_run_lifecycle.lua - Run scope store binding and teardown ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local RunScope = require("word_game.model.run.scope")
local game_access = require("word_game.model.game_access")
local store_sync = require("app.bootstrap.store_sync")
local runtime = require("app.runtime")

T.describe("Run lifecycle (RunScope)", function()
	mock_env.reset_game()
	require("word_game.model.game")
	store_sync.ensure_test_binding()

	local function shell()
		return runtime.game()
	end

	T.it("init_game_object returns a distinct table on every call", function()
		local game = Game()
		local first = game:init_game_object()
		local second = game:init_game_object()
		T.assert_true(first ~= second, "Each call should allocate a new run-state table")
	end)

	T.it("reset_args bumps generation and clears run-scoped HUD mirrors", function()
		shell().ARGS = { run_generation = 3, deck_left_count = 9, pending_layout = true }
		RunScope.reset_args()
		T.assert_equal(shell().ARGS.run_generation, 4, "Run generation should advance")
		T.assert_equal(shell().ARGS.deck_left_count, 0, "Run-scoped HUD mirrors should reset")
		T.assert_nil(shell().ARGS.pending_layout, "Pending layout should clear between runs")
	end)

	T.it("teardown resets store snapshot and marks the run inactive", function()
		local store = runtime.store()
		store_sync.bind_run(store, { deck_left_count = 0, word_round = { set = 9, hand_index = 1 } })
		shell().RUN = { generation = 1, active = true }
		RunScope.teardown()
		T.assert_nil(shell().GAME, "Teardown should clear shell GAME pointer")
		T.assert_equal(shell().RUN.active, false, "Teardown should mark the run inactive")
		T.assert_equal(game_access.get().word_round.set, 1, "Store should reset to default snapshot")
	end)

	T.it("begin_run assigns a fresh table and bumps generation", function()
		local game = Game()
		local first = game:init_game_object()
		RunScope.begin_run(first, { from_save = false })
		local gen = shell().ARGS.run_generation
		T.assert_equal(game_access.get(), first, "begin_run should publish the new run table via store")
		T.assert_equal(game_access.get().run_generation, gen, "Run table should mirror ARGS generation")
		T.assert_true(shell().RUN.active, "New run should be active")
		T.assert_true(game_access.get().run_state ~= nil, "Fresh runs should allocate run state")

		RunScope.teardown()
		local second = game:init_game_object()
		RunScope.begin_run(second, { from_save = false })
		T.assert_true(shell().ARGS.run_generation > gen, "Second run should advance generation")
		T.assert_true(game_access.get().run_state ~= first.run_state, "Each run should get its own run_state table")
	end)

	T.it("teardown_run_ui destroys run-scoped layout views via registered hooks", function()
		local game = Game()
		game.SIDEBAR_HUD = {
			remove = function(self)
				self.removed = true
			end,
		}
		game.table_shuffle_bar = {
			remove = function(self)
				self.removed = true
			end,
		}
		game.hand_action_bar = {
			remove = function(self)
				self.removed = true
			end,
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME_UI.Sidebar = {
			destroy = function()
				if game.SIDEBAR_HUD and game.SIDEBAR_HUD.remove then
					game.SIDEBAR_HUD:remove()
				end
				game.SIDEBAR_HUD = nil
			end,
		}
		WORD_GAME_UI.TableControls = {
			destroy = function()
				if game.table_shuffle_bar then game.table_shuffle_bar:remove() end
				if game.hand_action_bar then game.hand_action_bar:remove() end
				game.table_shuffle_bar = nil
				game.hand_action_bar = nil
			end,
		}
		WORD_GAME_UI.TableDeck = { reset = function() end }
		WORD_GAME_UI.PerkStamp = { clear_runtime = function() end }

		RunScope.on_teardown("Sidebar", WORD_GAME_UI.Sidebar.destroy)
		RunScope.on_teardown("TableControls", WORD_GAME_UI.TableControls.destroy)
		RunScope.on_teardown("PerkStamp", WORD_GAME_UI.PerkStamp.clear_runtime)

		game:teardown_run_ui()

		T.assert_nil(game.SIDEBAR_HUD, "Sidebar HUD should be torn down before a new run")
		T.assert_nil(game.table_shuffle_bar, "Hand action bar should be torn down before a new run")
		T.assert_nil(game.hand_action_bar, "Hand shuffle bar should be torn down before a new run")
	end)

	T.it("state.get returns nil while run is inactive", function()
		local state = require("word_game.model.run.state")
		local store = runtime.store()
		store_sync.bind_run(store, { alpha = state.new() })
		shell().RUN = { active = false }
		T.assert_nil(state.get(), "Alpha accessor should not serve stale run data during teardown")
	end)
end)
