--[[ tests/unit/test_screen_wipe.lua - Loading bubble must show a centered card ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function cleanup_wipe()
	if G.screenwipe and G.screenwipe.remove then
		pcall(function() G.screenwipe:remove() end)
	end
	G.screenwipe = nil
	G.screenwipecard = nil
end

local function boot_for_wipe()
	mock_env.setup()
	cleanup_wipe()
	require("word_game.model.cards.card")
	require("word_game.ui.cardarea")
	require("word_game.model.game")
	require("word_game.model.globals")
	require("app.effects")
	G:define_constants()
	G.TIMELINE = Scheduler()
	G:load_card_definitions()
	G.ROOM = SceneNode { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
	G.ROOM:set_container(G.ROOM)
	G.ROOM_ATTACH = EaseNode { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
	G.ROOM_ATTACH:set_container(G.ROOM)
	G.smoothing = { xy = 0.5, scale = 0.5, r = 0.5, max_vel = 58 }
	package.loaded["app.screen_wipe"] = nil
	require("app.screen_wipe")
end

local function advance_frames(n)
	for _ = 1, n do
		G.FRAMES.TRANSFORM = G.FRAMES.TRANSFORM + 1
		G.TIMERS.REAL = G.TIMERS.REAL + 0.016
		for _, node in ipairs(G.TRANSFORMS or {}) do
			if node.move then node:move(0.016) end
		end
	end
end

local function wipe_card_draw_width()
	local card = G.screenwipecard
	if not card or not card.children or not card.children.back then return 0 end
	return card.children.back.VT.w or 0
end

local function card_center_x(card)
	return (card.T.x or 0) + (card.T.w or 0) * 0.5
end

T.describe("Screen wipe loading bubble", function()
	T.it("creates a visible centered card for the default new-run wipe", function()
		boot_for_wipe()
		G.FUNCS.wipe_in()
		T.assert_not_nil(G.screenwipe, "wipe_in must create the loading overlay")
		T.assert_not_nil(G.screenwipecard, "wipe_in must create the loading card")
		T.assert_true(G.screenwipecard.states.visible, "loading card must stay visible")
		T.assert_equal(G.screenwipecard.role.role_type, "Minor",
			"loading card must weld to the centered wipe object, not float as a Major")
		advance_frames(3)
		T.assert_true(wipe_card_draw_width() > 0,
			"loading card back must have drawable width after motion")
		local room_center = G.TILE_W * 0.5
		T.assert_almost_equal(card_center_x(G.screenwipecard), room_center, 1.5,
			"loading card must sit in the middle of the loading bubble")
	end)

	T.it("omits the card only when no_card is requested", function()
		boot_for_wipe()
		G.FUNCS.wipe_in(nil, true)
		T.assert_not_nil(G.screenwipe)
		T.assert_nil(G.screenwipecard, "no_card wipes must not spawn a loading card")
	end)

	T.it("begin_run keeps the loading card registered through discard_run", function()
		boot_for_wipe()
		package.loaded["app.callbacks.settings"] = nil
		require("app.callbacks.settings")
		G.discard_run = function()
			require("word_game.model.run_scope").teardown()
		end
		G.start_run = function() end
		G.start_gameplay_board = function() end

		G.FUNCS.begin_run()
		T.assert_not_nil(G.screenwipecard, "begin_run wipe must show the loading card")
		local found = false
		for _, card in ipairs(G.LIVE.CARD or {}) do
			if card == G.screenwipecard then found = true break end
		end
		T.assert_true(found, "discard_run must keep the active loading card registered")
		advance_frames(3)
		T.assert_true(wipe_card_draw_width() > 0,
			"begin_run loading card must be drawable")
	end)
end)
