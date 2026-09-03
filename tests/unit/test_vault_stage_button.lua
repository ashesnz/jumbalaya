--[[ tests/unit/test_vault_stage_button.lua - Classic vault End Run / Next button ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Layout = require("word_game.ui.layout")

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

local function parent_row(node, root)
	if not node or not root then return nil end
	local found_parent = nil
	local function walk(n, parent)
		if n == node then
			found_parent = parent
			return
		end
		for _, child in ipairs(n.nodes or {}) do
			walk(child, n)
		end
		for _, child in pairs(n.nodes or {}) do
			if type(child) == "table" then walk(child, n) end
		end
	end
	walk(root, nil)
	return found_parent
end

T.describe("Vault stage button", function()
	T.it("advances the hand through Play.on_hand_cleared when Next is pressed", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
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

	T.it("uses a full-size blue panel for Next matching the End Run button", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD

		local dw, dh = Layout.discard_slot_size()
		local btn_h = dh * 0.88
		local button_col = {
			config = {
				id = "end_run_button",
				colour = G.C.RED,
				minw = dw,
				minh = btn_h,
				maxw = dw,
				maxh = btn_h,
			},
			states = { visible = true },
			children = {},
			nodes = {
				{
					config = { id = "end_run_label_row", align = "cm", minw = dw, minh = btn_h },
					nodes = { { config = { id = "end_run_label", text = "End Run" } } },
				},
				{
					config = { id = "end_run_arrow_row", align = "cm", minw = dw, minh = btn_h },
					nodes = { { config = { id = "end_run_next_arrow", text = "→", visible = false } } },
				},
			},
		}
		for _, child in ipairs(button_col.nodes) do
			button_col.children[#button_col.children + 1] = child
			for _, grand in ipairs(child.nodes or {}) do
				child.children = child.children or {}
				child.children[#child.children + 1] = grand
			end
		end

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
		T.assert_equal(button_col.config.minw, dw)
		T.assert_equal(button_col.config.minh, btn_h)
		T.assert_equal(button_col.config.maxw, dw)
		T.assert_equal(button_col.config.maxh, btn_h)
		T.assert_equal(button_col.config.button, "classic_stage_next")
	end)

	T.it("centers End Run label and arrow rows inside the vault button", function()
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
		local def = hud_definition.hud_definition()
		local dw, dh = Layout.discard_slot_size()
		local btn_h = dh * 0.88

		local button = find_node(def, "end_run_button")
		local label_row = find_node(def, "end_run_label_row")
		local arrow_row = find_node(def, "end_run_arrow_row")
		local label = find_node(def, "end_run_label")
		local arrow = find_node(def, "end_run_next_arrow")

		T.assert_not_nil(button)
		T.assert_not_nil(label_row)
		T.assert_not_nil(arrow_row)
		T.assert_equal(button.config.minw, dw)
		T.assert_equal(button.config.minh, btn_h)
		T.assert_equal(button.config.maxw, dw)
		T.assert_equal(button.config.maxh, btn_h)
		T.assert_equal(label_row.config.align, "cm")
		T.assert_equal(arrow_row.config.align, "cm")
		T.assert_equal(label_row.config.minw, dw)
		T.assert_equal(arrow_row.config.minw, dw)
		T.assert_equal(label_row.config.minh, btn_h)
		T.assert_equal(arrow_row.config.minh, btn_h)
		T.assert_equal(label.config.scale, arrow.config.scale, "Arrow should match End Run text scale")
		T.assert_equal(parent_row(label, def).config.id, "end_run_label_row")
		T.assert_equal(parent_row(arrow, def).config.id, "end_run_arrow_row")

		mock_env.reset_game()
	end)
end)
