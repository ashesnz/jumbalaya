--[[ word_game/ui/hand_shuffle/init.lua - Play button beside the dealt hand (no shuffle row) ]]

local state = require("word_game.model.state")
local RunMode = require("word_game.model.run_mode")
local definition = require("word_game.ui.hand_shuffle.definition")
local layout = require("word_game.ui.hand_shuffle.layout")
local animate = require("word_game.ui.hand_shuffle.animate")

local characters = { intro_step_keys = function() return nil end, intro_uses_play_button = function() return true end }

local M = {}

local function jumble_active()
	return WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()
end

function M.play_button_uie()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED then return nil end
	return G.hand_action_bar:find_node_by_id("hand_play_button")
end

function M.shuffle_button_uie()
	if not G.hand_shuffle_bar or G.hand_shuffle_bar.REMOVED then return nil end
	return G.hand_shuffle_bar:find_node_by_id("hand_shuffle_button")
end

function M.placement_has_cards()
	local area = G.placement_table and G.placement_table.area
	if area and area.cards and #area.cards > 0 then
		return true
	end
	if jumble_active() then
		local j = WORD_GAME.Jumble.state()
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
	if not G.hand_action_bar or G.hand_action_bar.REMOVED then return false end
	if not G.hand_shuffle_bar or G.hand_shuffle_bar.REMOVED then return false end
	return M.play_button_uie() ~= nil and M.shuffle_button_uie() ~= nil
end

function M.visible()
	return G.STATE == G.STATES.TABLE_BOARD
		and G.ROOM_ATTACH ~= nil
		and G.hand ~= nil
end

local function action_visible()
	if not M.visible() then return false end
	if jumble_active() then return true end
	local alpha = state.get()
	local waiting = alpha and alpha.intro_waiting_score
	local cinematic = alpha and alpha.stage3_cinematic
	local ally_talk = cinematic and (alpha.stage3_ally_line or alpha.stage3_guest_line)
	if waiting or (cinematic and not ally_talk) then return false end
	return true
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

	local alpha = state.get()
	local intro = alpha and alpha.character_intro_active
	local cinematic = alpha and alpha.stage3_cinematic
	local ally_talk = cinematic and (alpha.stage3_ally_line or alpha.stage3_guest_line)
	local keys = characters.intro_step_keys()
	local current_key = keys and alpha and keys[alpha.character_intro_step or 1]
	local use_play = (not intro) or characters.intro_uses_play_button(current_key)

	if ally_talk then
		play_btn.config.button = "stage3_ally_next"
		play_btn.config.colour = G.C.BLUE
		definition.set_play_display(play_btn, "text", definition.ICON_NEXT)
	elseif intro and not use_play then
		play_btn.config.button = "character_intro_next"
		play_btn.config.colour = G.C.BLUE
		definition.set_play_display(play_btn, "text", definition.ICON_NEXT)
	else
		play_btn.config.button = "play_placement_word"
		play_btn.config.colour = definition.play_button_colour()
		definition.set_play_display(play_btn, "sprite")
	end

	play_btn.config.force_collision = true
	play_btn.states.collide.can = true
end

function M.sync_visibility(_opts)
	if G.hand_shuffle_bar and not G.hand_shuffle_bar.REMOVED then
		sync_shuffle_button(M.shuffle_button_uie(), action_visible())
	end
	if G.hand_action_bar and not G.hand_action_bar.REMOVED then
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

M.sync_action_buttons = M.sync_visibility

function M.invalidate_layout()
	layout.invalidate_layout()
end

function M.is_animating()
	return animate.is_animating()
end

function M.shuffle_hand()
	animate.shuffle_hand(M.placement_has_cards)
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

function M.try_sync()
	return M.sync()
end

return M
