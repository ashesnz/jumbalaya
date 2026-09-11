--[[ tests/unit/test_screen_wipe.lua - Loading bubble must show a centered card ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Funcs = require("bridge.funcs_registry")
local BridgeRuntime = require("bridge.runtime")

local function shell()
	return BridgeRuntime.game()
end

local function cleanup_wipe()
	local game = shell()
	if game and game.screenwipe and game.screenwipe.remove then
		pcall(function() game.screenwipe:remove() end)
	end
	if game then
		game.screenwipe = nil
		game.screenwipecard = nil
	end
end

local function boot_for_wipe()
	mock_env.setup()
	cleanup_wipe()
	mock_env.ensure_card_class()
	require("word_game.ui.cardarea.init")
	require("word_game.model.game")
	require("word_game.model.game.globals")
	require("app.effects")
	local game = shell()
	game:define_constants()
	game.TIMELINE = Scheduler()
	game:load_card_definitions()
	game.INPUT = game.INPUT or {}
	game.INPUT.locks = game.INPUT.locks or {}
	game.ROOM = SceneNode { T = { x = 0, y = 0, w = game.TILE_W, h = game.TILE_H } }
	game.ROOM:set_container(game.ROOM)
	game.ROOM_ATTACH = EaseNode { T = { x = 0, y = 0, w = game.TILE_W, h = game.TILE_H } }
	game.ROOM_ATTACH:set_container(game.ROOM)
	game.smoothing = { xy = 0.5, scale = 0.5, r = 0.5, max_vel = 58 }
	BridgeRuntime.bind_game(game)
	package.loaded["app.screen_wipe"] = nil
	require("app.screen_wipe")
end

local function advance_frames(n)
	local game = shell()
	for _ = 1, n do
		game.FRAMES.TRANSFORM = game.FRAMES.TRANSFORM + 1
		game.TIMERS.REAL = game.TIMERS.REAL + 0.016
		for _, node in ipairs(game.TRANSFORMS or {}) do
			if node.move then node:move(0.016) end
		end
	end
end

local function wipe_card_draw_width()
	local card = shell().screenwipecard
	if not card or not card.children or not card.children.back then return 0 end
	return card.children.back.VT.w or 0
end

local function card_center_x(card)
	return (card.T.x or 0) + (card.T.w or 0) * 0.5
end

T.describe("Screen wipe loading bubble", function()
	T.it("creates a visible centered card for the default new-run wipe", function()
		boot_for_wipe()
		local game = shell()
		Funcs.dispatch("wipe_in")
		T.assert_not_nil(game.screenwipe, "wipe_in must create the loading overlay")
		T.assert_not_nil(game.screenwipecard, "wipe_in must create the loading card")
		T.assert_true(game.screenwipecard.states.visible, "loading card must stay visible")
		T.assert_equal(game.screenwipecard.role.role_type, "Minor",
			"loading card must weld to the centered wipe object, not float as a Major")
		advance_frames(3)
		T.assert_true(wipe_card_draw_width() > 0,
			"loading card back must have drawable width after motion")
		local room_center = game.TILE_W * 0.5
		T.assert_almost_equal(card_center_x(game.screenwipecard), room_center, 1.5,
			"loading card must sit in the middle of the loading bubble")
	end)

	T.it("omits the card only when no_card is requested", function()
		boot_for_wipe()
		local game = shell()
		Funcs.dispatch("wipe_in", nil, true)
		T.assert_not_nil(game.screenwipe)
		T.assert_nil(game.screenwipecard, "no_card wipes must not spawn a loading card")
	end)

	T.it("begin_run keeps the loading card registered through discard_run", function()
		boot_for_wipe()
		local game = shell()
		package.loaded["app.callbacks.settings"] = nil
		require("app.callbacks.settings")
		game.discard_run = function()
			require("word_game.model.run.scope").teardown()
		end
		game.start_run = function() end
		game.start_gameplay_board = function() end

		Funcs.dispatch("begin_run")
		T.assert_not_nil(game.screenwipecard, "begin_run wipe must show the loading card")
		local found = false
		for _, card in ipairs(game.LIVE.CARD or {}) do
			if card == game.screenwipecard then found = true break end
		end
		T.assert_true(found, "discard_run must keep the active loading card registered")
		advance_frames(3)
		T.assert_true(wipe_card_draw_width() > 0,
			"begin_run loading card must be drawable")
	end)
end)
