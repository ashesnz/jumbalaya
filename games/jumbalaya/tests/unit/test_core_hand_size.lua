local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local HandSize = require("jumbalaya_core.rules.hand_size")

T.describe("jumbalaya_core hand size", function()
	T.it("defaults to 7 and adds wide hand bonus", function()
		T.assert_equal(HandSize.get(), 7)
		T.assert_equal(HandSize.get(7, { wide_hand = true }), 8)
	end)
end)
