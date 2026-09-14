--[[ word_game/ui/table/controls/play_hold_redraw/redraw.lua - Discard hand and deal replacements ]]

local game = require("word_game.ui.util.game_runtime").game
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local facade = require("word_game.ui.facade")
local Random = require("jumbalaya-engine.util.random")
local button = require("word_game.ui.table.controls.play_hold_redraw.button")
local state = require("word_game.ui.table.controls.play_hold_redraw.state")

local M = {}


local function safe_sound(name, pitch, vol)
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
	if type(play_sfx) == "function" then
		play_sfx(name, pitch, vol)
	end
end

local function safe_random(seed_key)
	return Random.seeded_random(seed_key)
end

local function refresh_card_input()
	if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	else
		if game().dealt_letters and game().dealt_letters.set_ranks then
			game().dealt_letters:set_ranks()
		end
		if game().pattern_row and game().pattern_row.area and game().pattern_row.area.set_ranks then
			game().pattern_row.area:set_ranks()
		end
	end
end

local function recall_placement_cards()
	if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.recall_placement_cards then
		WORD_GAME_UI.TableControls.recall_placement_cards()
	end
end

function M.finish_redraw()
	state.set_animating(false)
	state.set_block_click(true)
	refresh_card_input()
	if game().dealt_letters and game().dealt_letters.relayout then
		game().dealt_letters:relayout()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

function M.discard_hand_down(on_complete, constants)
	if not game().TIMELINE then
		if on_complete then on_complete() end
		return 0
	end

	recall_placement_cards()

	local cards_to_discard = {}
	if game().dealt_letters and game().dealt_letters.cards then
		for _, card in ipairs(game().dealt_letters.cards) do
			cards_to_discard[#cards_to_discard + 1] = card
		end
	end

	local n = #cards_to_discard
	if n <= 0 then
		if on_complete then on_complete() end
		return 0
	end

	local target_offscreen_y = (game().ROOM and (game().ROOM.T.y + game().ROOM.T.h) or 11) + 2.5
	local stagger = constants.DISCARD_STAGGER

	for i, card in ipairs(cards_to_discard) do
		Scheduler.add{
			mode = "delayed",
			delay = stagger * (i - 1),
			func = function()
				if card.area == game().dealt_letters then
					game().dealt_letters:remove_card(card)
				end
				if card.T then
					card.T.y = target_offscreen_y
					card.T.r = (card.T.r or 0) + (safe_random("redraw_tilt") - 0.5) * 0.25
				end
				if card.pulse then
					card:pulse(0.1, 0.05)
				end
				safe_sound("card_slide1", 0.85 + (i / math.max(1, n)) * 0.2, 0.6)
				return true
			end,
		}
	end

	local tail = (n - 1) * stagger + 0.35
	Scheduler.add{
		mode = "delayed",
		delay = tail,
		blocking = true,
		func = function()
			for _, card in ipairs(cards_to_discard) do
				if game().draw_pile then
					game().draw_pile:emplace(card)
				end
			end
			if game().draw_pile then
				game().draw_pile:shuffle("play_hold_redraw")
				game().draw_pile:hard_set_T()
			end
			if game().dealt_letters then
				game().dealt_letters:relayout()
				game().dealt_letters:hard_set_cards()
			end
			if on_complete then
				on_complete()
			end
			return true
		end,
	}

	return n
end

function M.trigger(can_hold_fn, constants)
	if state.is_animating() or not can_hold_fn() then
		state.reset_hold()
		return
	end
	local wr = facade.game_access().word_round()
	local j = wr and wr.jumble
	if not facade.perks_effects().consume_redraw(j) then
		state.reset_hold()
		return
	end

	state.set_animating(true)
	state.set_block_click(true)
	state.set_peak_hold_t(constants.HOLD_DURATION)
	state.reset_hold()

	safe_sound("whoosh1", 0.9, 0.75)

	M.discard_hand_down(function()
		facade.deck().deal_into_hand(facade.hand_size().get(), M.finish_redraw)
	end, constants)
end

return M
