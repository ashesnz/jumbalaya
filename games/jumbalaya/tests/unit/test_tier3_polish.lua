--[[ tests/unit/test_tier3_polish.lua - Tier 3 polish audits (flow_text, card model, globals, indent) ]]

local T = require("tests.framework")
local kind_audit = require("tests.helpers.kind_globals_audit")
local indent_audit = require("tests.helpers.ui_indent_audit")

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return "" end
	local content = file:read("*a")
	file:close()
	return content
end

T.describe("tier 3 polish", function()
	T.it("word_game does not assign Kind globals outside easing.install_globals", function()
		local violations = kind_audit.word_game_global_assignments()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("engine assigns legacy globals only via M.install (except globals.lua)", function()
		local violations = kind_audit.engine_kind_global_assignments()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("word_game/ui uses tabs for indentation", function()
		local violations = indent_audit.space_indented_files()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("Card model keeps draw in ui/cards mixins", function()
		local paths = require("bootstrap_paths").resolve()
		local card_path = paths.game_root .. "/word_game/model/cards/card.lua"
		local content = read_file(card_path)
		T.assert_nil(content:find("function%s+Card:draw"), "Card:draw belongs in word_game/ui/cards/")
		T.assert_nil(content:find("require%([\"']word_game%.ui"), "card model must not import UI")
	end)

	T.it("flow_text envelope math lives in flow_text_envelopes module", function()
		local paths = require("bootstrap_paths").resolve()
		local flow = read_file(paths.repo_root .. "/packages/jumbalaya-engine/graphics/flow_text.lua")
		T.assert_true(flow:find("flow_text_envelopes"), "flow_text should require envelope module")
		T.assert_nil(flow:find("local function spring_rise"), "spring_rise moved to envelopes module")
	end)
end)
