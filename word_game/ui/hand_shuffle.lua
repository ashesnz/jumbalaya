--[[ word_game/ui/hand_shuffle.lua - Play button beside the dealt hand (no shuffle row) ]]

local state = require("word_game.model.state")
local felt_layout = require("word_game.ui.layout.felt")
local hand_shuffle_anim = require("word_game.ui.hand_shuffle_anim")
local hand_placement_recall_anim = require("word_game.ui.hand_placement_recall_anim")
local bonus_stack = require("word_game.ui.boss_word_stack")
local characters = { intro_step_keys = function() return nil end, intro_uses_play_button = function() return true end }

local M = {}

local ICON_PLAY = "▶"
local ICON_NEXT = "→"
local HAND_BOTTOM_MARGIN = 0.25

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

local function action_icon_sprite(size, atlas_name)
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES[atlas_name]
	if not atlas or not atlas.image then return nil end
	local icon_size = size * 0.92
	return Sprite(0, 0, icon_size, icon_size, atlas, { x = 0, y = 0 })
end

local function play_icon_sprite(size)
	return action_icon_sprite(size, "play_icon")
end

local function shuffle_icon_sprite(size)
	return action_icon_sprite(size, "shuffle_icon")
end

local function set_shuffle_icon_sprite(sprite, atlas_name, size)
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES[atlas_name]
	if not sprite or not atlas or not atlas.image then return end
	local icon_size = size * 0.92
	sprite.atlas = atlas
	sprite.scale = { x = atlas.px, y = atlas.py }
	sprite.T.w = icon_size
	sprite.T.h = icon_size
	sprite:set_sprite_pos({ x = 0, y = 0 })
	if sprite.refresh_scale then
		sprite:refresh_scale()
	end
	sprite.states.visible = true
end

local function set_shuffle_display(shuffle_btn, mode)
	if not shuffle_btn then return end
	local icon_uie = find_node(shuffle_btn, "hand_shuffle_icon")
	local sprite = icon_uie and icon_uie.config.object
	if not sprite then return end
	local size = button_size()
	local atlas_name = mode == "remove" and "remove_placement_icon" or "shuffle_icon"
	set_shuffle_icon_sprite(sprite, atlas_name, size)
end

local function shuffle_button_def(size)
	local shuffle_sprite = shuffle_icon_sprite(size)
	local nodes = {}
	if shuffle_sprite then
		nodes[#nodes + 1] = {
			n = G.UI.OBJECT,
			config = { id = "hand_shuffle_icon", object = shuffle_sprite },
		}
	end
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
			button = "shuffle_hand",
			id = "hand_shuffle_button",
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

local function snap_bar(bar)
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
local locked_anchors = nil
local SNAP_EPS = 0.004

local function layout_pos_sig()
	local felt = felt_layout.hand_felt_rect()
	return string.format(
		"%.4f|%.4f|%.4f|%.4f|%.4f|%d",
		G.TILE_W or 0,
		G.TILE_H or 0,
		G.CARD_H or 0,
		felt.x,
		felt.w,
		G.TABLE_HAND_SIZE or 7
	)
end

local function button_anchors()
	if locked_anchors and locked_anchors.sig == pos_sig then
		return locked_anchors
	end
	local size = button_size()
	local gap = play_gap()
	local hand_size = G.TABLE_HAND_SIZE or 7
	local hand_w = get_hand_area_width(hand_size)
	local hand_h = (G.CARD_H or 1.4) * 0.95
	local felt = felt_layout.hand_felt_rect()
	local hand_x = felt.x + math.max(0, (felt.w - hand_w) * 0.5)
	local hand_y = G.TILE_H - hand_h - HAND_BOTTOM_MARGIN
	local center_y = hand_y + hand_h * 0.5
	locked_anchors = {
		sig = pos_sig,
		size = size,
		shuffle_x = hand_x - gap - size,
		play_x = hand_x + hand_w + gap,
		y = center_y - size * 0.5,
	}
	return locked_anchors
end

local function room_center_offset(x, y, size)
	return {
		x = x + size * 0.5 - (G.TILE_W or 20) * 0.5,
		y = y + size * 0.5 - (G.TILE_H or 11.5) * 0.5,
	}
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
		if card.placement_recall_slide then
			goto continue
		end
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
		if card.bounce or card.shuffle_hop or card.placement_recall_slide then
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
	bar.root_node:move_with_major(0)
	bar.root_node:initialize_VT()
end

local function place_bar(bar, x, y, size)
	if not bar then return end
	local offset = room_center_offset(x, y, size)
	bar.config.major = G.ROOM_ATTACH
	bar.config.align = "cm"
	bar.config.offset = offset
	if bar.set_alignment then
		bar:set_alignment({
			major = G.ROOM_ATTACH,
			type = "cm",
			offset = offset,
		})
	end
	bar.T.w = size
	bar.T.h = size
	if bar.align_to_major then
		bar:align_to_major()
	end
	if bar.hard_set_T then
		bar:hard_set_T(bar.T.x, bar.T.y, size, size)
	end
	refresh_bar_tree(bar)
	snap_bar(bar)
end

local function place_action_bars()
	if not G.ROOM_ATTACH then return end
	local sig = layout_pos_sig()
	if locked_anchors and locked_anchors.sig ~= sig then
		locked_anchors = nil
	end
	pos_sig = sig
	local anchors = button_anchors()
	local size = anchors.size
	if G.hand_shuffle_bar and not G.hand_shuffle_bar.REMOVED then
		place_bar(G.hand_shuffle_bar, anchors.shuffle_x, anchors.y, size)
	end
	if G.hand_action_bar and not G.hand_action_bar.REMOVED then
		place_bar(G.hand_action_bar, anchors.play_x, anchors.y, size)
	end
end

function M.play_button_uie()
	if not G.hand_action_bar or G.hand_action_bar.REMOVED then return nil end
	return G.hand_action_bar:find_node_by_id("hand_play_button")
end

function M.shuffle_button_uie()
	if not G.hand_shuffle_bar or G.hand_shuffle_bar.REMOVED then return nil end
	return G.hand_shuffle_bar:find_node_by_id("hand_shuffle_button")
end

local function placement_area()
	return G.placement_table and G.placement_table.area
end

function M.placement_has_cards()
	local area = placement_area()
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
	opts = opts or {}
	if placement_area() and placement_area().cards then
		local p_area = placement_area()
		for i = #p_area.cards, 1, -1 do
			local card = p_area.cards[i]
			if G.placement_table then
				G.placement_table:on_remove_card(card)
			end
			p_area:remove_card(card)
			if bonus_stack.is_bonus_card(card) then
				bonus_stack.return_card(card)
			elseif G.hand then
				G.hand:emplace(card)
			end
		end
		if p_area.hard_set_cards then
			p_area:hard_set_cards()
		end
	end
	if jumble_active() then
		local wr = G.GAME and G.GAME.word_round
		if wr and wr.jumble and wr.jumble.slots then
			WORD_GAME.Jumble.clear_blank_cards(wr.jumble.slots)
			WORD_GAME.Jumble.sync_placement_cards(wr.jumble.slots)
		end
		if G.placement_table and G.placement_table.jumble_geometry then
			G.placement_table.jumble_geometry.relayout(G.placement_table)
		end
	end
	local placement_word = require("word_game.model.placement_word")
	placement_word.clear()
	if G.hand then
		if G.hand.clear_selection then G.hand:clear_selection() end
		if G.hand.set_ranks then G.hand:set_ranks() end
		if G.hand.relayout then G.hand:relayout() end
		if not opts.skip_hand_snap then
			if G.hand.hard_set_cards then G.hand:hard_set_cards() end
			if G.hand.snap_VT then G.hand:snap_VT() end
		end
	end
end

function M.return_placement_cards_to_hand()
	if not M.placement_has_cards() then return end
	if G.GAME and G.GAME.hand_redraw_animating then return end
	if G.GAME and G.GAME.word_score_animating then return end
	if G.GAME and G.GAME.hand_shuffle_animating then return end
	if G.GAME and G.GAME.placement_recall_animating then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target then return end
	if hand_placement_recall_anim.animate(function()
		M.sync_visibility()
	end) then
		return
	end
	M.recall_placement_cards()
	M.sync_visibility()
	if play_sfx then
		play_sfx("card_slide1", 0.9, 0.7)
	end
end

function M.sync_position()
	if not G.hand or not G.ROOM_ATTACH then return end
	local sig = layout_pos_sig()
	if sig == pos_sig and locked_anchors then return end
	locked_anchors = nil
	place_action_bars()
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
	shuffle_btn.config.colour = play_button_colour()
	shuffle_btn.config.force_collision = true
	shuffle_btn.states.collide.can = true

	if M.placement_has_cards() then
		shuffle_btn.config.button = "return_placement_cards"
		set_shuffle_display(shuffle_btn, "remove")
	else
		shuffle_btn.config.button = "shuffle_hand"
		set_shuffle_display(shuffle_btn, "shuffle")
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
	if G.hand_shuffle_bar and not G.hand_shuffle_bar.REMOVED then
		sync_shuffle_button(M.shuffle_button_uie(), action_visible())
	end
	if G.hand_action_bar and not G.hand_action_bar.REMOVED then
		sync_play_button(M.play_button_uie(), action_visible())
	end
end

function M.stabilize()
	if not G.hand or (not G.hand_action_bar and not G.hand_shuffle_bar) then return end
	place_action_bars()
end

function M.stabilize_table_board()
	if M.visible() and not M.buttons_present() then
		M.sync()
	end
	M.stabilize()
	snap_hand_container()
	if G.GAME and G.GAME.placement_recall_animating then return end
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
	if not G.hand then return end
	if (not G.hand_action_bar or G.hand_action_bar.REMOVED)
		and (not G.hand_shuffle_bar or G.hand_shuffle_bar.REMOVED) then
		return
	end
	M.sync_position()
end

M.sync_action_buttons = M.sync_visibility

function M.invalidate_layout()
	pos_sig = nil
	locked_anchors = nil
end

function M.is_animating()
	return hand_shuffle_anim.is_animating() or hand_placement_recall_anim.is_animating()
end

function M.shuffle_hand()
	if M.placement_has_cards() then return end
	if not G.hand or #G.hand.cards < 2 then return end
	if G.GAME and G.GAME.hand_redraw_animating then return end
	if G.GAME and G.GAME.word_score_animating then return end
	if G.GAME and G.GAME.hand_shuffle_animating then return end
	if G.GAME and G.GAME.placement_recall_animating then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target then return end
	G.hand:clear_selection()
	hand_shuffle_anim.animate(G.hand)
end

function M.ensure()
	if not M.visible() then
		M.destroy()
		return
	end
	local has_play = G.hand_action_bar
		and not G.hand_action_bar.REMOVED
		and G.hand_action_bar:find_node_by_id("hand_play_button")
	local has_shuffle = G.hand_shuffle_bar
		and not G.hand_shuffle_bar.REMOVED
		and G.hand_shuffle_bar:find_node_by_id("hand_shuffle_button")
	if has_play and has_shuffle then
		M.sync_visibility()
		return
	end
	if G.hand_action_bar or G.hand_shuffle_bar then
		M.destroy()
	end

	local size = button_size()
	pos_sig = nil
	locked_anchors = nil
	G.hand_shuffle_bar = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = { align = "cm", colour = G.C.CLEAR, minw = size, minh = size },
			nodes = { shuffle_button_def(size) },
		},
		config = {
			align = "cm",
			major = G.ROOM_ATTACH,
			offset = { x = 0, y = 0 },
		},
	}
	G.hand_action_bar = LayoutView{
		definition = {
			n = G.UI.ROOT,
			config = { align = "cm", colour = G.C.CLEAR, minw = size, minh = size },
			nodes = { play_button_def(size) },
		},
		config = {
			align = "cm",
			major = G.ROOM_ATTACH,
			offset = { x = 0, y = 0 },
		},
	}

	G.hand_shuffle_button = G.hand_shuffle_bar
	G.hand_play_button = G.hand_action_bar
	G.PLAY_WORD_UI = G.hand_action_bar

	M.sync_position()
	M.sync_visibility()
end

function M.destroy()
	pos_sig = nil
	locked_anchors = nil
	if G.hand_shuffle_bar then
		G.hand_shuffle_bar:remove()
		G.hand_shuffle_bar = nil
	end
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
