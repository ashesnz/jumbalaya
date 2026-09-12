--[[ word_game/ui/table/controls/init.lua - Play/shuffle buttons beside the dealt hand ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local Play = facade.jumble_play()
local Jumble = facade.jumble()
local RunMode = facade.run_mode()
local definition = require("word_game.ui.table.controls.definition")
local layout = require("word_game.ui.table.controls.layout")
local animate = require("word_game.ui.table.controls.animate")
local placement = require("word_game.ui.table.controls.placement")

layout.bind_animate(animate)
animate.bind_layout(layout)

local M = {}

local function jumble_active()
	return Jumble.is_active()
end

function M.play_button_uie()
	if not runtime().hand_action_bar or runtime().hand_action_bar.REMOVED then return nil end
	return runtime().hand_action_bar:find_node_by_id("hand_play_button")
end

function M.shuffle_button_uie()
	if not runtime().table_shuffle_bar or runtime().table_shuffle_bar.REMOVED then return nil end
	return runtime().table_shuffle_bar:find_node_by_id("hand_shuffle_button")
end

function M.placement_has_cards()
	local area = runtime().pattern_row and runtime().pattern_row.area
	if area and area.cards and #area.cards > 0 then
		return true
	end
	if jumble_active() then
		local j = Jumble.state()
		if j and j.slots then
			for _, slot in ipairs(j.slots) do
				if slot.kind == "blank" and slot.card then
					return true
				elseif slot.kind == "span" and slot.cards and #slot.cards > 0 then
					return true
				end
			end
		end
	end
	return false
end

function M.recall_placement_cards(opts)
	animate.recall_placement_cards(opts)
end

function M.return_placement_cards_to_hand()
	animate.return_placement_cards_to_hand(M.placement_has_cards, M.sync_visibility)
end

function M.sync_position()
	layout.sync_position()
end

function M.buttons_present()
	if not runtime().hand_action_bar or runtime().hand_action_bar.REMOVED then return false end
	if not runtime().table_shuffle_bar or runtime().table_shuffle_bar.REMOVED then return false end
	return M.play_button_uie() ~= nil and M.shuffle_button_uie() ~= nil
end

function M.visible()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
		and runtime().ROOM_ATTACH ~= nil
		and runtime().dealt_letters ~= nil
end

local function action_visible()
	return M.visible()
end

local function sync_shuffle_button(shuffle_btn, show)
	if not shuffle_btn then return end
	if not show then
		shuffle_btn.states.visible = false
		shuffle_btn.config.button = nil
		return
	end

	shuffle_btn.states.visible = true
	shuffle_btn.config.colour = definition.play_button_colour()
	shuffle_btn.config.force_collision = true
	shuffle_btn.states.collide.can = true

	if M.placement_has_cards() then
		shuffle_btn.config.button = "return_placement_cards"
		definition.set_shuffle_display(shuffle_btn, "remove")
	else
		shuffle_btn.config.button = "shuffle_hand"
		definition.set_shuffle_display(shuffle_btn, "shuffle")
	end
end

local function sync_play_button(play_btn, show)
	if not play_btn then return end
	if not show then
		play_btn.states.visible = false
		play_btn.config.button = nil
		return
	end

	play_btn.states.visible = true

	if RunMode.classic_stage_complete() then
		play_btn.config.button = "play_placement_word"
		play_btn.config.colour = definition.play_button_colour()
		play_btn.config.force_collision = true
		play_btn.states.collide.can = true
		definition.set_play_display(play_btn, "sprite")
		return
	end

	if jumble_active() then
		play_btn.config.button = "play_placement_word"
		play_btn.config.colour = definition.play_button_colour()
		definition.set_play_display(play_btn, "sprite")
		return
	end

	play_btn.config.button = "play_placement_word"
	play_btn.config.colour = definition.play_button_colour()
	definition.set_play_display(play_btn, "sprite")

	play_btn.config.force_collision = true
	play_btn.states.collide.can = true
end

function M.sync_visibility(_opts)
	if runtime().table_shuffle_bar and not runtime().table_shuffle_bar.REMOVED then
		sync_shuffle_button(M.shuffle_button_uie(), action_visible())
	end
	if runtime().hand_action_bar and not runtime().hand_action_bar.REMOVED then
		sync_play_button(M.play_button_uie(), action_visible())
	end
end

function M.stabilize()
	animate.stabilize()
end

function M.stabilize_table_board()
	animate.stabilize_table_board(M.visible, M.buttons_present, M.sync)
end

function M.mark_layout_settle(frames)
	animate.mark_layout_settle(frames)
end

function M.snap()
	layout.snap()
end

function M.invalidate_layout()
	layout.invalidate_layout()
end

function M.is_animating()
	return animate.is_animating()
end

function M.shuffle_hand()
	animate.shuffle_hand(M.placement_has_cards)
end

--- Play button: validate placement and resolve the word.
function M.play()
	placement.try_play()
end

--- Advance after a cleared jumble hand (Time Run proceed).
function M.jumble_next()
	Play.jumble_next()
	M.sync()
end

function M.ensure()
	layout.ensure(M.visible, M.sync_visibility)
end

function M.destroy()
	layout.destroy()
end

function M.sync()
	if not M.visible() then
		M.destroy()
		return false
	end
	M.ensure()
	M.sync_position()
	M.sync_visibility()
	return M.buttons_present()
end

return M
