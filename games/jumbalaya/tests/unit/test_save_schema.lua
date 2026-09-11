--[[ tests/unit/test_save_schema.lua - Run snapshot schema version and load upgrades ]]

local T = require("tests.framework")
local SaveSchema = require("word_game.model.persistence.save_schema")

T.describe("save schema", function()
	T.it("stamps SAVE_SCHEMA on write snapshots", function()
		local snapshot = { VERSION = "test", GAME = { run_state = { tokens = 0 } } }
		SaveSchema.stamp_write(snapshot)
		T.assert_equal(snapshot.SAVE_SCHEMA, SaveSchema.CURRENT)
	end)

	T.it("accepts versioned snapshots with run_state", function()
		local snapshot = {
			SAVE_SCHEMA = SaveSchema.CURRENT,
			GAME = { run_state = { tokens = 3, perks = {} } },
		}
		T.assert_true(SaveSchema.is_loadable(snapshot))
		T.assert_nil(snapshot.GAME.alpha)
	end)

	T.it("upgrades pre-schema saves with alpha into run_state", function()
		local legacy = {
			VERSION = "0.9.5",
			GAME = { alpha = { tokens = 7, perks = { "discard_bin" } } },
		}
		T.assert_true(SaveSchema.prepare_loaded(legacy))
		T.assert_equal(legacy.SAVE_SCHEMA, SaveSchema.CURRENT)
		T.assert_equal(legacy.GAME.run_state.tokens, 7)
		T.assert_nil(legacy.GAME.alpha)
	end)

	T.it("accepts pre-schema saves that already use run_state", function()
		local snapshot = {
			GAME = { run_state = { tokens = 1, perks = {} } },
		}
		T.assert_true(SaveSchema.prepare_loaded(snapshot))
		T.assert_equal(snapshot.SAVE_SCHEMA, SaveSchema.CURRENT)
	end)

	T.it("rejects saves without run economy state", function()
		local snapshot = { GAME = { word_round = { mode = "jumble" } } }
		T.assert_false(SaveSchema.is_loadable(snapshot))
	end)

	T.it("rejects future schema versions", function()
		local snapshot = {
			SAVE_SCHEMA = SaveSchema.CURRENT + 1,
			GAME = { run_state = { tokens = 0 } },
		}
		T.assert_false(SaveSchema.is_loadable(snapshot))
	end)
end)
