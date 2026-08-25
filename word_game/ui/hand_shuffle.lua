--[[ word_game/ui/hand_shuffle.lua - Play button beside the dealt hand (no shuffle row) ]]

local state = require("word_game.model.state")
local characters = { intro_step_keys = function() return nil end, intro_uses_play_button = function() return true end }

local M = {}

local ICON_PLAY = "▶"
local ICON_NEXT = "→"

local function button_size()
	return math.max(0.92, (G.CARD_H or 1.4) * 0.68)
end

local function play_gap()
	local card_w = (G.hand and G.hand.card_w) or G.CARD_W or 1
	return math.max(0.32, card_w * 0.24)
end

local function play_button_colour()
	return G.C.CLEAR
end

local function jumble_active()
	return WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()
end

local function find_node(uie, id)
	if not uie then return nil end
	if uie.config and uie.config.id == id then return uie end
	for _, child in pairs(uie.children or {}) do
		local found = find_node(child, id)
		if found then return found end
	end
	return nil
end

local function set_play_display(play_btn, mode, icon)
	if not play_btn then return end
	local sprite_uie = find_node(play_btn, "play_hand_icon")
	local text_uie = find_node(play_btn, "play_hand_icon_text")
	if sprite_uie then
		sprite_uie.states.visible = mode == "sprite"
		if sprite_uie.config.object then
			sprite_uie.config.object.states.visible = mode == "sprite"
		end
	end
	if text_uie then
		text_uie.states.visible = mode == "text"
		if mode == "text" and text_uie.config then
			text_uie.config.text = icon or ICON_NEXT
		end
	end
end

local function play_icon_sprite(size)
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.play_icon
	if not atlas or not atlas.image then return nil end
	local icon_size = size * 0.92
	return Sprite(0, 0, icon_size, icon_size, atlas, { x = 0, y = 0 })
end

local function play_button_def(size)
	local nodes = {}
	local sprite = play_icon_sprite(size)
	if sprite then
		nodes[#nodes + 1] = {
			n = G.UI.OBJECT,
			config = { id = "play_hand_icon", object = sprite },
		}
	end
	nodes[#nodes + 1] = {
		n = G.UI.TEXT,
		config = {
			id = "play_hand_icon_text",
			text = ICON_PLAY,
			scale = 0.48,
			colour = G.C.WHITE,
			shadow = true,
		},
	}
	return {
		n = G.UI.COLUMN,
		config = {
			align = "cm",
			padding = 0,
			r = 0.5,
			minw = size,
			minh = size,
			maxw = size,
			maxh = size,
			hover = true,
			colour = play_button_colour(),
			button = "play_placement_word",
			id = "hand_play_button",
			no_jiggle = true,
			shadow = false,
			button_dist = 0,
			can_collide = true,
			force_collision = true,
			focus_args = { snap_to = true },
		},
		nodes = nodes,
	}
end

local function clear_bounce(node)
	if not node then return end
	node.bounce = nil
	if node.velocity then
		node.velocity.x = 0
		node.velocity.y = 0
		node.velocity.r = 0
		node.velocity.scale = 0
	end
	for _, child in pairs(node.children or {}) do
		clear_bounce(child)
	end
end

local function snap_bar()
	local bar = G.hand_action_bar
	if not bar then return end
	clear_bounce(bar)
	if bar.root_node then
		clear_bounce(bar.root_node)
	end
	if bar.snap_VT then
		bar:snap_VT()
	end
	if bar.root_node and bar.root_node.snap_VT then
		bar.root_node:snap_VT()
	end
	bar.STATIONARY = true
end

local pos_sig = nil
local SNAP_EPS = 0.004

local function hand_pos_sig()
	if not G.hand then return nil end
	return string.format("%.4f|%.4f|%.4f", G.hand.T.x, G.hand.T.y, G.hand.T.w)
end

local function dragging_hand_card()
	local target = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	return target and target.states and target.states.drag and target.states.drag.is
		and target.area == G.hand
end

local function hand_position_drift()
	if not G.hand then return false end
	if math.abs((G.hand.VT.x or 0) - (G.hand.T.x or 0)) > SNAP_EPS then return true end
	if math.abs((G.hand.VT.y or 0) - (G.hand.T.y or 0)) > SNAP_EPS then return true end
	for _, card in ipairs(G.hand.cards or {}) do
		if card.states and card.states.drag and card.states.drag.is then
			goto continue
		end
		local vt, t = card.VT, card.T
		if vt and t and (math.abs(vt.x - t.x) > SNAP_EPS or math.abs(vt.y - t.y) > SNAP_EPS) then
			return true
		end
		::continue::
	end
	return false
end

local function snap_hand_container()
	if not G.hand or dragging_hand_card() then return end
	G.hand:snap_VT()
	if G.hand.velocity then
		G.hand.velocity.x = 0
		G.hand.velocity.y = 0
		G.hand.velocity.r = 0
		G.hand.velocity.scale = 0
	end
end

local function snap_hand_cards()
	if not G.hand or dragging_hand_card() then return end
	for _, card in ipairs(G.hand.cards or {}) do
		if card.states and card.states.drag and card.states.drag.is then
			goto continue
		end
		if card.bounce then
			goto continue
		end
		if card.hard_set_T then
			card:hard_set_T()
		end
		::continue::
	end
end

local function refresh_bar_tree(bar)
	if not bar or not bar.root_node then return end
	if bar.align_to_major then
		bar:align_to_major()
	end
	bar.root_node:move_with_major(0)
	bar.root_node:initialize_VT()
end

local function place_bar(bar, x, y, size)
	bar.T.x = x
	bar.T.y = y
	bar.T.w = size
	bar.T.h = size
	if bar.hard_set_T then
		bar:hard_set_T(x, y, size, size)
	end
	refresh_bar_tree(bar)
	snap_bar()
end

function M.play_button_uie()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED then return nil end
	return G.hand_action_bar:find_node_by_id("hand_play_button")
end

function M.sync_position()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED or not G.hand then return end
	local sig = hand_pos_sig()
	if sig == pos_sig then return end
	pos_sig = sig
	local size = button_size()
	local gap = play_gap()
	local x = G.hand.T.x + G.hand.T.w + gap
	local y = G.hand.T.y + (G.hand.T.h - size) * 0.5
	place_bar(G.hand_action_bar, x, y, size)
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

local function sync_play_button(play_btn, show)
	if not play_btn then return end
	if not show then
		play_btn.states.visible = false
		play_btn.config.button = nil
		return
	end

	play_btn.states.visible = true

	if jumble_active() then
		play_btn.config.button = "play_placement_word"
		play_btn.config.colour = play_button_colour()
		set_play_display(play_btn, "sprite")
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
		set_play_display(play_btn, "text", ICON_NEXT)
	elseif intro and not use_play then
		play_btn.config.button = "character_intro_next"
		play_btn.config.colour = G.C.BLUE
		set_play_display(play_btn, "text", ICON_NEXT)
	else
		play_btn.config.button = "play_placement_word"
		play_btn.config.colour = play_button_colour()
		set_play_display(play_btn, "sprite")
	end

	play_btn.config.force_collision = true
	play_btn.states.collide.can = true
end

function M.sync_visibility(_opts)
	if not G.hand_action_bar or G.hand_action_bar.REMOVED then return end
	local play_btn = M.play_button_uie()
	sync_play_button(play_btn, action_visible())
end

function M.stabilize()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED or not G.hand then return end
	M.sync_position()
	refresh_bar_tree(G.hand_action_bar)
	snap_bar()
end

function M.stabilize_table_board()
	M.stabilize()
	snap_hand_container()
	local settle = G.GAME and G.GAME.hand_layout_settle or 0
	if settle > 0 or hand_position_drift() then
		snap_hand_cards()
		if settle > 0 and G.GAME then
			G.GAME.hand_layout_settle = settle - 1
		end
	end
end

function M.mark_layout_settle(frames)
	if G.GAME then
		G.GAME.hand_layout_settle = frames or 4
	end
end

function M.snap()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED or not G.hand then return end
	M.sync_position()
end

M.sync_action_buttons = M.sync_visibility

function M.invalidate_layout()
	pos_sig = nil
end

function M.shuffle_hand()
	if not G.hand or #G.hand.cards < 2 then return end
	if G.GAME and G.GAME.hand_redraw_animating then return end
	if G.GAME and G.GAME.word_score_animating then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target then return end
	G.hand:clear_selection()
	G.hand:shuffle("hand_shuffle")
	G.hand:relayout()
	G.hand:snap_VT()
	G.hand:hard_set_cards()
	M.sync_position()
	if play_sfx then
		play_sfx("hover_card")
	end
end

function M.ensure()
	if not M.visible() then
		M.destroy()
		return
	end
	if G.hand_action_bar and not G.hand_action_bar.REMOVED then
		if not G.hand_action_bar:find_node_by_id("play_hand_icon")
			and not G.hand_action_bar:find_node_by_id("play_hand_icon_text") then
			M.destroy()
		else
			M.sync_visibility()
			return
		end
	end

	local size = button_size()
	pos_sig = nil
	G.hand_action_bar = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = { align = "cm", colour = G.C.CLEAR, minw = size, minh = size },
			nodes = { play_button_def(size) },
		},
		config = {
			align = "cm",
			offset = { x = 0, y = 0 },
		},
	}

	G.hand_shuffle_button = nil
	G.hand_play_button = G.hand_action_bar
	G.PLAY_WORD_UI = G.hand_action_bar

	M.sync_visibility()
end

function M.destroy()
	pos_sig = nil
	if G.hand_action_bar then
		G.hand_action_bar:remove()
		G.hand_action_bar = nil
	end
	G.hand_shuffle_button = nil
	G.hand_play_button = nil
	if G.PLAY_WORD_UI then
		G.PLAY_WORD_UI = nil
	end
end

function M.sync()
	if M.visible() then
		M.ensure()
	else
		M.destroy()
	end
end

return M
