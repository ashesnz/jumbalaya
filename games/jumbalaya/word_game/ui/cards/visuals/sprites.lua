--[[ word_game/ui/cards/visuals/sprites.lua - Card body/front/back sprite setup ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
---@class (partial) Card : EaseNode
local GameRT = require("word_game.ui.util.game_runtime")
local LetterFaces = require("word_game.ui.cards.letter_faces")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")

local function runtime() return GameRT.game() end

local FLAT_LETTER_SETS = { Default = true, Enhanced = true }

function Card:set_sprites(_center, _front)
	if _center and _center.set then
		local atlas = runtime().TEXTURE_ATLASES[_center.atlas or 'centers']
		local pos = _center.pos

		if self.children.center then
			self.children.center.atlas = atlas
			self.children.center:set_sprite_pos(pos)
		else
			self.children.center = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, atlas, pos)
			self.children.center.states.hover = self.states.hover
			self.children.center.states.click = self.states.click
			self.children.center.states.drag = self.states.drag
			self.children.center.states.collide.can = false
			self.children.center:set_role({major = self, role_type = 'Glued', draw_major = self})
		end

		if not self.children.back then
			local back_atlas = runtime().TEXTURE_ATLASES["playing_back"] or runtime().TEXTURE_ATLASES["centers"]
			local default_back = runtime().LETTERS.centers and runtime().LETTERS.centers['deck_alpha']
			local game = game_access.get()
			local game_back_pos = game and game[self.back] and game[self.back].pos
			local back_pos = runtime().TEXTURE_ATLASES["playing_back"] and {x = 0, y = 0}
				or (self.params.bypass_back or (self.letter_card_id and game_back_pos)
				or (default_back and default_back.pos) or {x = 0, y = 0})
			self.children.back = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, back_atlas, back_pos)
			self.children.back.states.hover = self.states.hover
			self.children.back.states.click = self.states.click
			self.children.back.states.drag = self.states.drag
			self.children.back.states.collide.can = false
			self.children.back:set_role({major = self, role_type = 'Glued', draw_major = self})
		elseif runtime().TEXTURE_ATLASES["playing_back"] and self.children.back.atlas ~= runtime().TEXTURE_ATLASES["playing_back"] then
			self.children.back.atlas = runtime().TEXTURE_ATLASES["playing_back"]
			self.children.back:set_sprite_pos({x = 0, y = 0})
		end
	end

	if _front then
		local is_letter = self.config.center and FLAT_LETTER_SETS[self.config.center.set]
			and LetterFaces.is_letter_face(_front)
		if is_letter then
			local frame_atlas = LetterFaces.frame_atlas()
			local letters_atlas = LetterFaces.letters_atlas()
			local glyph_pos = _front.pos or LetterFaces.glyph_pos(_front.letter)

			if frame_atlas and self.children.center then
				self.children.center.atlas = frame_atlas
				self.children.center:set_sprite_pos({ x = 0, y = 0 })
			end

			if letters_atlas then
				if self.children.front then
					self.children.front.atlas = letters_atlas
					self.children.front:set_sprite_pos(glyph_pos)
				else
					self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, letters_atlas, glyph_pos)
					self.children.front.states.hover = self.states.hover
					self.children.front.states.click = self.states.click
					self.children.front.states.drag = self.states.drag
					self.children.front.states.collide.can = false
					self.children.front:set_role({major = self, role_type = 'Glued', draw_major = self})
				end
			end
		else
			local face_atlas = runtime().TEXTURE_ATLASES[_front.atlas] or runtime().TEXTURE_ATLASES.letters
			local face_pos = self.config.card and self.config.card.pos
			if self.children.front then
				self.children.front.atlas = face_atlas
				self.children.front:set_sprite_pos(face_pos)
			else
				self.children.front = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, face_atlas, face_pos)
				self.children.front.states.hover = self.states.hover
				self.children.front.states.click = self.states.click
				self.children.front.states.drag = self.states.drag
				self.children.front.states.collide.can = false
				self.children.front:set_role({major = self, role_type = 'Glued', draw_major = self})
			end
		end
	end
end
