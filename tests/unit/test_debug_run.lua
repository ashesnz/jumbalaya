--[[ tests/unit/test_debug_run.lua
     Tests for debug run controls.
]]

local T = require("tests.framework")

T.describe("Debug Run Controls", function()
	T.it("registers a delete save action that removes the current save", function()
		local run_section = require("devtools.sections.run")
		local called = false
		local deleted = false
		local previous_remove_save = _G.delete_saved_run
		local previous_game = _G.G
		_G.delete_saved_run = function() called = true end
		_G.G = {discard_run = function() deleted = true end}

		local actions = {}
		run_section.register({
			action = function(_, name, callback)
				actions[name] = callback
			end,
		})
		actions.delete_save()

		_G.delete_saved_run = previous_remove_save
		_G.G = previous_game
		T.assert_true(called, "Delete Save should call delete_saved_run")
		T.assert_true(deleted, "Delete Save should clear the active run")
	end)

	T.it("queues save deletion after pending asynchronous writes", function()
		local previous_game = _G.G
		local requests = {}
		_G.G = {
			SETTINGS = {profile = 2},
			STORED_RUN = {},
			WRITE_FLAGS = {run = true},
			DISK_WORKER = {channel = {push = function(_, request) requests[#requests + 1] = request end}},
		}
		local previous_remove = love.filesystem.remove
		love.filesystem.remove = function() end
		delete_saved_run()
		love.filesystem.remove = previous_remove
		_G.G = previous_game
		T.assert_equal(#requests, 1, "Delete should enqueue one worker request")
		T.assert_equal(requests[1].op, "purge", "Worker request should delete the run")
		T.assert_equal(requests[1].profile_num, 2, "Worker request should target the active profile")
	end)
end)