--[[ tests/unit/test_vault_stage_button.lua - Classic vault End Run / Next button ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Layout = require("word_game.ui.layout")
local table_discard = require("word_game.ui.table_discard")

local function find_node(node, id)
	if not node then return nil end
	if node.config and node.config.id == id then return node end
	for _, child in ipairs(node.nodes or {}) do
		local found = find_node(child, id)
		if found then return found end
	end
	for _, child in pairs(node.nodes or {}) do
		if type(child) == "table" then
			local found = find_node(child, id)
			if found then return found end
		end
	end
	return nil
end

local function setup_vault_layout_env()
	mock_env.ensure_engine_globals()
	require("app.core.ui.panel")
	G.LANG = G.LANG or {
		font = {
			FONT = love.graphics.newFont(12),
			FONTSCALE = 0.12,
			squish = 1,
			TEXT_HEIGHT_SCALE = 0.7,
			TEXT_OFFSET = { x = 0, y = 0 },
		},
	}
	G.C.UI = G.C.UI or { TEXT_LIGHT = { 1, 1, 1, 1 }, BUTTON_HOVER = { 1, 1, 1, 0.5 } }
	G.C.DYN_UI = G.C.DYN_UI or { MAIN = { 0.22, 0.32, 0.35, 1 } }
	G.C.RED = G.C.RED or { 1, 0, 0.4, 1 }
	G.C.BLUE = G.C.BLUE or { 0.2, 0.5, 1, 1 }
	G.UI = G.UI or { ROOT = 1, ROW = 2, COL = 3, COLUMN = 3, TEXT = 4, OBJECT = 5, BOX = 6 }
	G.UI.padding = G.UI.padding or 0.1
	love.graphics.newText = love.graphics.newText or function(_font, colored)
		local text = type(colored) == "table" and colored[2] or tostring(colored or "")
		return {
			set = function(self, value)
				if type(value) == "table" then
					self._text = value[2]
				else
					self._text = tostring(value)
				end
			end,
			getWidth = function(self) return string.len(self._text or text) * 10 end,
			getHeight = function() return 20 end,
		}
	end
	G.TILESCALE = G.TILESCALE or 1
	G.TILESIZE = G.TILESIZE or 20
	G.CARD_W = G.CARD_W or 1
	G.CARD_H = G.CARD_H or 1.4
	G.TILE_H = G.TILE_H or 11.5
	G.TILE_W = G.TILE_W or 20
	G.GAME = G.GAME or { word_round = { mode = "jumble" } }
	G.STATE = G.STATES.TABLE_BOARD
	G.STAGE = G.STAGES.RUN
	G.ROOM = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
	G.ROOM_ATTACH = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
	G.VAULT_ATTACH = {
		T = { x = 17, y = 0.22, w = 3, h = 10 },
		alignment = { offset = { x = 0, y = 0 } },
		align_to_major = function() end,
	}
end

local function assert_rect_inside(inner_x, inner_y, inner_w, inner_h, outer_x, outer_y, outer_w, outer_h, eps, msg)
	eps = eps or 0.03
	msg = msg or "label should fit inside button"
	T.assert_true(inner_x >= outer_x - eps, msg .. " (left)")
	T.assert_true(inner_y >= outer_y - eps, msg .. " (top)")
	T.assert_true(inner_x + inner_w <= outer_x + outer_w + eps, msg .. " (right)")
	T.assert_true(inner_y + inner_h <= outer_y + outer_h + eps, msg .. " (bottom)")
end

local function assert_label_inside_button(button, label, eps, msg)
	eps = eps or 0.03
	msg = msg or "label should fit inside button"
	local bx = button.VT.x or button.T.x or 0
	local by = button.VT.y or button.T.y or 0
	local lx = label.VT.x or label.T.x or 0
	local ly = label.VT.y or label.T.y or 0
	local bw = button.VT.w or button.T.w or 0
	local bh = button.VT.h or button.T.h or 0
	local lw = label.VT.w or label.T.w or 0
	local lh = label.VT.h or label.T.h or 0
	assert_rect_inside(lx, ly, lw, lh, bx, by, bw, bh, eps, msg)
end

local function build_vault_view()
	local hud_definition = require("word_game.ui.sidebar.hud_definition")
	return LayoutView({
		definition = hud_definition.hud_definition(),
		config = {
			align = "tri",
			offset = { x = 0, y = 0 },
			major = G.VAULT_ATTACH,
		},
	})
end

local function mock_button_col()
	local dw, dh = Layout.discard_slot_size()
	local btn_side = math.min(dw, dh)
	local vault_btn = require("word_game.ui.vault_stage_button")
	local label = {
		config = {
			id = "end_run_label",
			text = "End Run",
			scale = vault_btn.label_scale_for("End Run"),
			colour = G.C.UI.TEXT_LIGHT,
		},
	}
	local button_col = {
		config = {
			id = "end_run_button",
			colour = G.C.RED,
			minw = btn_side,
			minh = btn_side,
			maxw = btn_side,
			maxh = btn_side,
			visible = true,
		},
		states = { visible = true },
		children = { label },
		nodes = { label },
	}
	label.parent = button_col
	return button_col, btn_side, label
end

T.describe("Vault stage button", function()
	T.it("advances the hand through Play.on_hand_cleared when Next is pressed", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 30, puzzle_points = 0, puzzle_multi = 1.0 },
		}

		local tt = require("word_game.ui.timeline_timer")
		local token_reward = require("word_game.ui.token_reward")
		local vault_btn = require("word_game.ui.vault_stage_button")
		local Play = require("word_game.model.play")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.TokenReward = token_reward
		WORD_GAME.VaultStageButton = vault_btn
		WORD_GAME.Play = Play
		token_reward.reset()
		G.GAME.word_score_animating = false
		tt.reset_progress(25)
		tt.sync_progress()

		local cleared = false
		local original_clear = Play.on_hand_cleared
		Play.on_hand_cleared = function()
			cleared = true
		end

		vault_btn.reset()
		T.assert_true(vault_btn.is_next_mode())
		T.assert_true(vault_btn.collect_and_advance())
		T.assert_true(cleared, "Next should clear the hand via Play.on_hand_cleared")

		Play.on_hand_cleared = original_clear
	end)

	T.it("does not call on_hand_cleared when the stage score is zero", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.GAME.word_round = {
			target = 25,
			jumble = { total_score = 0, puzzle_points = 0, puzzle_multi = 1.0 },
		}
		local vault_btn = require("word_game.ui.vault_stage_button")
		local Play = require("word_game.model.play")
		WORD_GAME.Play = Play

		local cleared = false
		local original_clear = Play.on_hand_cleared
		Play.on_hand_cleared = function()
			cleared = true
		end

		vault_btn.reset()
		T.assert_false(vault_btn.collect_and_advance())
		T.assert_false(cleared)

		Play.on_hand_cleared = original_clear
	end)

	T.it("animates to a full-size blue square with Next when the classic target is met", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN

		local button_col, btn_side, label = mock_button_col()
		G.VAULT_HUD = {
			find_node_by_id = function(_, id)
				if id == "end_run_button" then return button_col end
			end,
		}

		local tt = require("word_game.ui.timeline_timer")
		local vault_btn = require("word_game.ui.vault_stage_button")
		WORD_GAME.TimelineTimer = tt
		G.GAME.word_round = {
			target = 25,
			jumble = { total_score = 30, puzzle_points = 0, puzzle_multi = 1.0 },
		}
		tt.reset_progress(25)
		tt.sync_progress()

		vault_btn.reset()
		vault_btn.update(0.6)
		T.assert_equal(button_col.config.colour, G.C.BLUE)
		T.assert_equal(button_col.config.minw, btn_side)
		T.assert_equal(button_col.config.minh, btn_side)
		T.assert_equal(button_col.config.maxw, btn_side)
		T.assert_equal(button_col.config.maxh, btn_side)
		T.assert_equal(button_col.config.button, "classic_stage_next")
		T.assert_equal(label.config.text, "Next", "Next label should replace End Run after animation")
	end)

	T.it("keeps the End Run button visible on the table board", function()
		mock_env.reset_game()
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		T.assert_true(table_discard.end_run_button_visible())
		T.assert_true(table_discard.should_show_end_run())

		local button_col = mock_button_col()
		G.VAULT_HUD = {
			find_node_by_id = function(_, id)
				if id == "end_run_button" then return button_col end
			end,
		}
		local vault_btn = require("word_game.ui.vault_stage_button")
		vault_btn.sync()
		T.assert_equal(button_col.config.visible, true)
		T.assert_equal(button_col.states.visible, true)
	end)

	T.it("hides the End Run button off the table board", function()
		mock_env.reset_game()
		G.STATE = G.STATES.MENU or 2
		G.STAGE = G.STAGES.RUN
		T.assert_false(table_discard.end_run_button_visible())

		local button_col = mock_button_col()
		G.VAULT_HUD = {
			find_node_by_id = function(_, id)
				if id == "end_run_button" then return button_col end
			end,
		}
		local vault_btn = require("word_game.ui.vault_stage_button")
		vault_btn.sync()
		T.assert_equal(button_col.config.visible, false)
		T.assert_equal(button_col.states.visible, false)
	end)

	T.it("lays out End Run text inside the square after recalculate", function()
		setup_vault_layout_env()
		local view = build_vault_view()
		view:recalculate()

		local button = view:find_node_by_id("end_run_button")
		local label = view:find_node_by_id("end_run_label")
		T.assert_not_nil(button)
		T.assert_not_nil(label)
		label:update_text()

		T.assert_equal(label.config.text, "End Run")
		T.assert_not_nil(label.config.text_drawable, "End Run label should build a drawable")
		T.assert_true((label.config.colour[4] or 0) > 0.01, "End Run label should be visible")

		assert_label_inside_button(button, label, 0.03, "End Run should fit inside the button")

		view:remove()
		mock_env.reset_game()
	end)

	T.it("lays out Next text inside the square after the classic transition", function()
		setup_vault_layout_env()
		G.GAME.run_mode = "classic"
		G.GAME.word_round = {
			target = 25,
			jumble = { total_score = 30, puzzle_points = 0, puzzle_multi = 1.0 },
		}
		local tt = require("word_game.ui.timeline_timer")
		local vault_btn = require("word_game.ui.vault_stage_button")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.VaultStageButton = vault_btn
		tt.reset_progress(25)
		tt.sync_progress()

		local view = build_vault_view()
		G.VAULT_HUD = view
		view:recalculate()

		vault_btn.reset()
		vault_btn.update(0.6)
		view:recalculate()

		local button = view:find_node_by_id("end_run_button")
		local label = view:find_node_by_id("end_run_label")
		label:update_text()

		T.assert_equal(label.config.text, "Next")
		T.assert_not_nil(label.config.text_drawable, "Next label should build a drawable")
		T.assert_equal(button.config.colour, G.C.BLUE)

		assert_label_inside_button(button, label, 0.03, "Next should fit inside the button")

		view:remove()
		G.VAULT_HUD = nil
		mock_env.reset_game()
	end)

	T.it("defines a square vault button with a direct centered label child", function()
		mock_env.setup()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { mode = "jumble" }
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.TILE_H = 11.5
		G.TILE_W = 20
		G.ROOM = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
		G.ROOM_ATTACH = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
		G.VAULT_ATTACH = { T = { x = 17, y = 0.22, w = 3, h = 10 } }

		local hud_definition = require("word_game.ui.sidebar.hud_definition")
		local vault_btn = require("word_game.ui.vault_stage_button")
		local def = hud_definition.hud_definition()
		local dw, dh = Layout.discard_slot_size()
		local btn_side = math.min(dw, dh)

		local button = find_node(def, "end_run_button")
		local label = find_node(def, "end_run_label")

		T.assert_not_nil(button)
		T.assert_not_nil(label)
		T.assert_equal(button.config.padding, 0, "Button chrome should not eat label space")
		T.assert_equal(button.config.align, "cm")
		T.assert_equal(button.config.minw, btn_side)
		T.assert_equal(button.config.minh, btn_side)
		T.assert_equal(button.config.maxw, btn_side)
		T.assert_equal(button.config.maxh, btn_side)
		T.assert_equal(button.config.minw, button.config.minh, "Vault button should be square")
		T.assert_equal(button.config.visible, true, "End Run button should start visible in the HUD definition")
		T.assert_equal(label.config.text, "End Run")
		T.assert_true(label.config.scale <= vault_btn.label_scale_for("End Run") + 0.001)
		T.assert_nil(find_node(def, "end_run_label_row"), "Label should be a direct child of the button")
		T.assert_nil(find_node(def, "end_run_next_arrow"), "Next uses the same label node, not a separate arrow")

		mock_env.reset_game()
	end)
end)
