--[[ word_game/ui/cards/visuals/sprites.lua - LetterTile frame / glyph / back sprites ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
---@class (partial) LetterTile : EaseNode
local game = require("word_game.ui.util.game_runtime").game
local LetterFaces = require("word_game.ui.cards.letter_faces")

local function bind_atlas(sprite, atlas, pos)
	if not sprite or not atlas then return end
	sprite.atlas = atlas
	sprite.scale = {
		x = atlas.px or (sprite.scale and sprite.scale.x) or 71,
		y = atlas.py or (sprite.scale and sprite.scale.y) or 95,
	}
	if sprite.refresh_scale then
		sprite:refresh_scale()
	end
	sprite:set_sprite_pos(pos)
end

local function glue_sprite(self, sprite)
	sprite.states.hover = self.states.hover
	sprite.states.click = self.states.click
	sprite.states.drag = self.states.drag
	sprite.states.collide.can = false
	sprite:set_role({ major = self, role_type = "Glued", draw_major = self })
end

function Card:set_sprites(front)
	front = front or self.config and self.config.card
	if type(front) == "table" and front.set and not front.letter then
		front = self.config and self.config.card
	end

	local frame_atlas = LetterFaces.frame_atlas()
		or (game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.letter_frame)
	if frame_atlas then
		if self.children.center then
			bind_atlas(self.children.center, frame_atlas, { x = 0, y = 0 })
		else
			self.children.center = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, frame_atlas, { x = 0, y = 0 })
			glue_sprite(self, self.children.center)
		end
	end

	if not self.children.back then
		local back_atlas = game().TEXTURE_ATLASES["playing_back"] or game().TEXTURE_ATLASES["centers"]
		local shell = game_access.get()
		local game_back_pos = shell and shell[self.back] and shell[self.back].pos
		local back_pos = game().TEXTURE_ATLASES["playing_back"] and { x = 0, y = 0 }
			or (self.params and self.params.bypass_back)
			or (self.letter_card_id and game_back_pos)
			or { x = 0, y = 0 }
		self.children.back = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, back_atlas, back_pos)
		glue_sprite(self, self.children.back)
	elseif game().TEXTURE_ATLASES["playing_back"] and self.children.back.atlas ~= game().TEXTURE_ATLASES["playing_back"] then
		self.children.back.atlas = game().TEXTURE_ATLASES["playing_back"]
		self.children.back:set_sprite_pos({ x = 0, y = 0 })
	end

	if not front then return end

	local letters_atlas = LetterFaces.letters_atlas()
		or (game().TEXTURE_ATLASES and (game().TEXTURE_ATLASES[front.atlas] or game().TEXTURE_ATLASES.letters))
	local glyph_pos = front.pos or LetterFaces.glyph_pos(front.letter)
	if letters_atlas then
		if self.children.front then
			bind_atlas(self.children.front, letters_atlas, glyph_pos)
		else
			self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, letters_atlas, glyph_pos)
			glue_sprite(self, self.children.front)
		end
	end
end
