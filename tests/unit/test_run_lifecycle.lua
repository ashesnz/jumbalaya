--[[ tests/unit/test_run_lifecycle.lua - Run scope store binding and teardown ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local RunScope = require("word_game.model.run.scope")
local game_access = require("word_game.model.game_access")
local store_sync = require("bridge.store_sync")
local runtime = require("bridge.runtime")

T.describe("Run lifecycle (RunScope)", function()
	mock_env.ensure_engine_globals()
	require("word_game.model.game")
	store_sync.ensure_test_binding()

	T.it("init_game_object returns a distinct table on every call", function()
		local game = Game()
		local first = game:init_game_object()
		local second = game:init_game_object()
		T.assert_true(first ~= second, "Each call should allocate a new run-state table")
	end)

	T.it("reset_args bumps generation and clears run-scoped HUD mirrors", function()
		G.ARGS = { run_generation = 3, deck_left_count = 9, pending_layout = true }
		RunScope.reset_args()
		T.assert_equal(G.ARGS.run_generation, 4, "Run generation should advance")
		T.assert_equal(G.ARGS.deck_left_count, 0, "Run-scoped HUD mirrors should reset")
		T.assert_nil(G.ARGS.pending_layout, "Pending layout should clear between runs")
	end)

	T.it("teardown clears G.GAME mirror and marks the run inactive", function()
		local store = runtime.store()
		store_sync.bind_run(store, { deck_left_count = 0 })
		G.RUN = { generation = 1, active = true }
		RunScope.teardown()
		T.assert_nil(G.GAME, "Teardown should clear the legacy mirror")
		T.assert_equal(G.RUN.active, false, "Teardown should mark the run inactive")
	end)

	T.it("begin_run assigns a fresh table and bumps generation", function()
		local game = Game()
		local first = game:init_game_object()
		RunScope.begin_run(first, { from_save = false })
		local gen = G.ARGS.run_generation
		T.assert_equal(game_access.get(), first, "begin_run should publish the new run table via store")
		T.assert_equal(game_access.get().run_generation, gen, "Run table should mirror ARGS generation")
		T.assert_true(G.RUN.active, "New run should be active")
		T.assert_true(game_access.get().run_state ~= nil, "Fresh runs should allocate run state")

		RunScope.teardown()
		local second = game:init_game_object()
		RunScope.begin_run(second, { from_save = false })
		T.assert_true(G.ARGS.run_generation > gen, "Second run should advance generation")
		T.assert_true(game_access.get().run_state ~= first.run_state, "Each run should get its own run_state table")
	end)

	T.it("teardown_run_ui destroys run-scoped layout views via registered hooks", function()
		local game = Game()
		G.SIDEBAR_HUD = {
			remove = function(self)
				self.removed = true
			end,
		}
		G.table_shuffle_bar = {
			remove = function(self)
				self.removed = true
			end,
		}
		G.hand_action_bar = {
			remove = function(self)
				self.removed = true
			end,
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME_UI.Sidebar = {
			destroy = function()
				if G.SIDEBAR_HUD and G.SIDEBAR_HUD.remove then
					G.SIDEBAR_HUD:remove()
				end
				G.SIDEBAR_HUD = nil
			end,
		}
		WORD_GAME_UI.TableControls = {
			destroy = function()
				if G.table_shuffle_bar then G.table_shuffle_bar:remove() end
				if G.hand_action_bar then G.hand_action_bar:remove() end
				G.table_shuffle_bar = nil
				G.hand_action_bar = nil
			end,
		}
		WORD_GAME_UI.TableDeck = { reset = function() end }
		WORD_GAME_UI.PerkStamp = { clear_runtime = function() end }

		RunScope.on_teardown("Sidebar", WORD_GAME_UI.Sidebar.destroy)
		RunScope.on_teardown("TableControls", WORD_GAME_UI.TableControls.destroy)
		RunScope.on_teardown("PerkStamp", WORD_GAME_UI.PerkStamp.clear_runtime)

		game:teardown_run_ui()

		T.assert_nil(G.SIDEBAR_HUD, "Sidebar HUD should be torn down before a new run")
		T.assert_nil(G.table_shuffle_bar, "Hand action bar should be torn down before a new run")
		T.assert_nil(G.hand_action_bar, "Hand shuffle bar should be torn down before a new run")
	end)

	T.it("state.get returns nil while run is inactive", function()
		local state = require("word_game.model.run.state")
		local store = runtime.store()
		store_sync.bind_run(store, { alpha = state.new() })
		G.RUN = { active = false }
		T.assert_nil(state.get(), "Alpha accessor should not serve stale run data during teardown")
	end)
end)
