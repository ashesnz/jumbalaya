--[[ word_game/ui/hand_shuffle/definition.lua - Shuffle/play button chrome and definitions ]]

local M = {}

M.ICON_PLAY = "▶"
M.ICON_NEXT = "→"

function M.button_size()
	return math.max(0.92, (G.CARD_H or 1.4) * 0.68)
end

function M.play_gap()
	local card_w = (G.hand and G.hand.card_w) or G.CARD_W or 1
	return math.max(0.32, card_w * 0.24)
end

function M.play_button_colour()
	return G.C.CLEAR
end

function M.find_node(uie, id)
	if not uie then return nil end
	if uie.config and uie.config.id == id then return uie end
	for _, child in pairs(uie.children or {}) do
		local found = M.find_node(child, id)
		if found then return found end
	end
	return nil
end

function M.set_play_display(play_btn, mode, icon)
	if not play_btn then return end
	local sprite_uie = M.find_node(play_btn, "play_hand_icon")
	local text_uie = M.find_node(play_btn, "play_hand_icon_text")
	if sprite_uie then
		sprite_uie.states.visible = mode == "sprite"
		if sprite_uie.config.object then
			sprite_uie.config.object.states.visible = mode == "sprite"
		end
	end
	if text_uie then
		text_uie.states.visible = mode == "text"
		if mode == "text" and text_uie.config then
			text_uie.config.text = icon or M.ICON_NEXT
		end
	end
end

function M.action_icon_sprite(size, atlas_name)
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES[atlas_name]
	if not atlas or not atlas.image then return nil end
	local icon_size = size * 0.92
	return Sprite(0, 0, icon_size, icon_size, atlas, { x = 0, y = 0 })
end

local function play_icon_sprite(size)
	return M.action_icon_sprite(size, "play_icon")
end

local function shuffle_icon_sprite(size)
	return M.action_icon_sprite(size, "shuffle_icon")
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

function M.set_shuffle_display(shuffle_btn, mode)
	if not shuffle_btn then return end
	local icon_uie = M.find_node(shuffle_btn, "hand_shuffle_icon")
	local sprite = icon_uie and icon_uie.config.object
	if not sprite then return end
	local size = M.button_size()
	local atlas_name = mode == "remove" and "remove_placement_icon" or "shuffle_icon"
	set_shuffle_icon_sprite(sprite, atlas_name, size)
end

function M.shuffle_button_def(size)
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
			colour = M.play_button_colour(),
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

function M.play_button_def(size)
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
			text = M.ICON_PLAY,
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
			colour = M.play_button_colour(),
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

return M
