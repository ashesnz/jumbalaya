--[[ tests/unit/test_run_lifecycle.lua - G.GAME identity and run teardown ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local RunScope = require("word_game.model.run_scope")

T.describe("Run lifecycle (RunScope)", function()
	mock_env.ensure_engine_globals()
	require("word_game.model.game")

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

	T.it("teardown clears G.GAME and marks the run inactive", function()
		G.GAME = { deck_left_count = 0 }
		G.RUN = { generation = 1, active = true }
		RunScope.teardown()
		T.assert_nil(G.GAME, "Teardown should drop the previous run table")
		T.assert_equal(G.RUN.active, false, "Teardown should mark the run inactive")
	end)

	T.it("begin_run assigns a fresh table and bumps generation", function()
		local game = Game()
		local first = game:init_game_object()
		RunScope.begin_run(first, { from_save = false })
		local gen = G.ARGS.run_generation
		T.assert_equal(G.GAME, first, "begin_run should publish the new run table")
		T.assert_equal(G.GAME.run_generation, gen, "Run table should mirror ARGS generation")
		T.assert_true(G.RUN.active, "New run should be active")
		T.assert_true(G.GAME.alpha ~= nil, "Fresh runs should allocate alpha state")

		RunScope.teardown()
		local second = game:init_game_object()
		RunScope.begin_run(second, { from_save = false })
		T.assert_true(G.ARGS.run_generation > gen, "Second run should advance generation")
		T.assert_true(G.GAME.alpha ~= first.alpha, "Each run should get its own alpha table")
	end)

	T.it("teardown_run_ui destroys run-scoped layout views via registered hooks", function()
		local game = Game()
		G.VAULT_HUD = {
			remove = function(self)
				self.removed = true
			end,
		}
		G.hand_shuffle_bar = {
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
		WORD_GAME.Sidebar = {
			destroy = function()
				if G.VAULT_HUD and G.VAULT_HUD.remove then
					G.VAULT_HUD:remove()
				end
				G.VAULT_HUD = nil
			end,
		}
		WORD_GAME.HandShuffle = {
			destroy = function()
				if G.hand_shuffle_bar then G.hand_shuffle_bar:remove() end
				if G.hand_action_bar then G.hand_action_bar:remove() end
				G.hand_shuffle_bar = nil
				G.hand_action_bar = nil
			end,
		}
		WORD_GAME.TableDeck = { reset = function() end }
		WORD_GAME.PerkStamp = { clear_runtime = function() end }

		RunScope.on_teardown("Sidebar", WORD_GAME.Sidebar.destroy)
		RunScope.on_teardown("HandShuffle", WORD_GAME.HandShuffle.destroy)
		RunScope.on_teardown("PerkStamp", WORD_GAME.PerkStamp.clear_runtime)

		game:teardown_run_ui()

		T.assert_nil(G.VAULT_HUD, "Vault HUD should be torn down before a new run")
		T.assert_nil(G.hand_shuffle_bar, "Hand action bar should be torn down before a new run")
		T.assert_nil(G.hand_action_bar, "Hand shuffle bar should be torn down before a new run")
	end)

	T.it("state.get returns nil while run is inactive", function()
		local state = require("word_game.model.state")
		G.GAME = { alpha = state.new() }
		G.RUN = { active = false }
		T.assert_nil(state.get(), "Alpha accessor should not serve stale run data during teardown")
	end)
end)
