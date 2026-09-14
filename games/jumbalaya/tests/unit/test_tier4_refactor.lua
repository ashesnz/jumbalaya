--[[ tests/unit/test_tier4_refactor.lua - Tier 4 god-object refactor audits ]]

local T = require("tests.framework")
local shell_audit = require("tests.helpers.game_shell_audit")

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return "" end
	local content = file:read("*a")
	file:close()
	return content
end

T.describe("tier 4 refactor", function()
	T.it("word_game shell field writes go through shell_access", function()
		local violations = shell_audit.direct_shell_assignments()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("Card model keeps presentation mixins out of card.lua", function()
		local paths = require("bootstrap_paths").resolve()
		local card_path = paths.game_root .. "/word_game/model/cards/card.lua"
		local content = read_file(card_path)
		T.assert_nil(content:find("function%s+Card:update_alert"), "update_alert belongs in ui/cards/alerts.lua")
		T.assert_nil(content:find("function%s+Card:align"), "align belongs in ui/cards/align.lua")
		T.assert_nil(content:find("UIViewHost"), "card model must not import UIViewHost")
	end)

	T.it("discard_bin init is a thin facade", function()
		local paths = require("bootstrap_paths").resolve()
		local init = read_file(paths.game_root .. "/word_game/ui/perks/discard_bin/init.lua")
		T.assert_true(init:find("discard_bin%.rules"), "init should delegate to rules submodule")
		T.assert_true(init:find("discard_bin%.draw"), "init should delegate to draw submodule")
		T.assert_nil(init:find("love%.graphics%.rectangle"), "draw logic belongs in draw.lua")
	end)

	T.it("table board uses update and draw pass modules", function()
		local paths = require("bootstrap_paths").resolve()
		local board = read_file(paths.game_root .. "/word_game/ui/table/board.lua")
		T.assert_true(board:find("board_update_passes"), "board should require update pass list")
		T.assert_true(board:find("board_draw_passes"), "board should require draw pass list")
	end)

	T.it("trade definition delegates node builders", function()
		local paths = require("bootstrap_paths").resolve()
		local def = read_file(paths.game_root .. "/word_game/ui/trade/definition.lua")
		T.assert_true(def:find("trade%.nodes%.action"), "definition should compose from action nodes")
		T.assert_nil(def:find("function%s+make_face_card"), "face builder moved to nodes/face.lua")
	end)

	T.it("word_feedback delegates spawn and geometry", function()
		local paths = require("bootstrap_paths").resolve()
		local wf = read_file(paths.game_root .. "/word_game/ui/feedback/word_feedback.lua")
		T.assert_true(wf:find("word_feedback_spawn"), "spawn factory extracted")
		T.assert_true(wf:find("word_feedback_geometry"), "geometry extracted")
		T.assert_nil(wf:find("Scheduler%.add"), "scheduler wiring belongs in spawn module")
	end)

	T.it("WORD_GAME exports Shell accessor module", function()
		T.assert_not_nil(WORD_GAME.Shell)
		T.assert_not_nil(WORD_GAME.Shell.dealt_letters)
		T.assert_not_nil(WORD_GAME.Shell.next_sort_id)
	end)
end)
