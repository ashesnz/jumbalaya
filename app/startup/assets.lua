--[[ app/startup/assets.lua - Shaders, atlases, and shared card sprites ]]

local M = {}

function M.load_shaders(game)
	game.SHADERS = {}
	for _, filename in ipairs(love.filesystem.getDirectoryItems("resources/shaders")) do
		if string.sub(filename, -3) == '.fs' then
			local shader_name = string.sub(filename, 1, -4)
			game.SHADERS[shader_name] = love.graphics.newShader("resources/shaders/" .. filename)
		end
	end
end

function M.init_shared_sprites(game)
	local atlas = game.TEXTURE_ATLASES.cards_1 or game.TEXTURE_ATLASES.centers
	if atlas then
		game.shared_debuff = Sprite(0, 0, game.CARD_W, game.CARD_H, atlas, { x = 0, y = 0 })
		game.shared_undiscovered_companion = Sprite(0, 0, game.CARD_W, game.CARD_H, atlas, { x = 0, y = 0 })
		game.shared_undiscovered_charm = Sprite(0, 0, game.CARD_W, game.CARD_H, atlas, { x = 0, y = 0 })
	end

	game.shared_stickers = {
		White = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 1, y = 0 }),
		Red = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 2, y = 0 }),
		Green = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 3, y = 0 }),
		Black = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 0, y = 1 }),
		Blue = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 4, y = 0 }),
		Purple = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 1, y = 1 }),
		Orange = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 2, y = 1 }),
		Gold = Sprite(0, 0, game.CARD_W, game.CARD_H, game.TEXTURE_ATLASES["stickers"], { x = 3, y = 1 }),
	}
	local seal_atlas = game.TEXTURE_ATLASES.cards_1 or game.TEXTURE_ATLASES.centers
	game.shared_seals = seal_atlas and {
		Gold = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Purple = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Red = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Blue = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
	} or {}
	game.sticker_map = { 'White', 'Red', 'Green', 'Black', 'Blue', 'Purple', 'Orange', 'Gold' }
end

function Game:set_render_settings()
	self.SETTINGS.GRAPHICS.texture_scaling = self.SETTINGS.GRAPHICS.texture_scaling or 2

	if love.graphics and love.graphics.setDefaultFilter then
		love.graphics.setDefaultFilter(
			self.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear',
			self.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear', 1)
	end

	if love.graphics and love.graphics.setLineStyle then
		love.graphics.setLineStyle("rough")
	end

	---@type GameAtlasSpec[]
	self.animation_atli = {}
	---@type GameAtlasSpec[]
	self.asset_atli = {
		{ name = "cards_1", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/JumbalayaDeck.png", px = 71, py = 95 },
		{ name = "cards_2", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/JumbalayaDeck_opt2.png", px = 71, py = 95 },
		{ name = "playing_back", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/PlayingDeck.png", px = 71, py = 95 },
		{ name = "Charm", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Charms.png", px = 71, py = 95 },
		{ name = "Perk", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Perks.png", px = 71, py = 95 },
		{ name = "Bundle", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/bundles.png", px = 71, py = 95 },
		{ name = "ui_1", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/ui_assets.png", px = 18, py = 18 },
		{ name = "ui_2", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/ui_assets_opt2.png", px = 18, py = 18 },
		{ name = "Jumbalaya", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Jumbalaya.png", px = 466.5, py = 133.5 },
		{ name = "jumbalaya_base", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Jumbalaya_base.png", px = 933, py = 267 },
		{ name = "jumbalaya_start_a", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Jumbalaya_start_A.png", px = 103, py = 143 },
		{ name = "jumbalaya_end_a", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Jumbalaya_end_A.png", px = 123, py = 152 },
		{ name = "title_garden", path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/title_garden.png", px = 1536, py = 1024 },
		{ name = 'gamepad_ui', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/gamepad_ui.png", px = 32, py = 32 },
		{ name = 'icons', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/icons.png", px = 66, py = 66 },
		{ name = 'stickers', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/stickers.png", px = 71, py = 95 },
		{ name = 'characters', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Characters.png", px = 88, py = 188, frames = 19, cols = 5, rows = 4 },
		{ name = 'bin', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Bin.png", px = 249, py = 251, frames = 4, cols = 2, rows = 2 },
		{ name = 'shuffle_icon', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/shuffle_icon.png", px = 112, py = 112 },
		{ name = 'play_icon', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/play_icon.png", px = 112, py = 112 },
		{ name = 'tokens', path = "resources/textures/" .. self.SETTINGS.GRAPHICS.texture_scaling .. "x/Tokens.png", px = 140, py = 101 },
	}
	---@type GameAtlasSpec[]
	self.asset_images = {}

	for i = 1, #self.animation_atli do
		local spec = self.animation_atli[i]
		if love.filesystem.getInfo(spec.path) then
			self.ANIM_SHEETS[spec.name] = {}
			self.ANIM_SHEETS[spec.name].name = spec.name
			self.ANIM_SHEETS[spec.name].image = love.graphics.newImage(spec.path, { mipmaps = true, dpiscale = self.SETTINGS.GRAPHICS.texture_scaling })
			self.ANIM_SHEETS[spec.name].px = spec.px
			self.ANIM_SHEETS[spec.name].py = spec.py
			self.ANIM_SHEETS[spec.name].frames = spec.frames
		end
	end

	for i = 1, #self.asset_atli do
		local spec = self.asset_atli[i]
		local path = spec.path
		if not love.filesystem.getInfo(path) and spec.name == "playing_back" then
			path = "resources/textures/2x/PlayingDeck.png"
			if not love.filesystem.getInfo(path) then
				path = "resources/textures/1x/PlayingDeck.png"
			end
		end
		if not love.filesystem.getInfo(path) and (
			spec.name == "Jumbalaya" or spec.name == "title_garden"
			or spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
			or spec.name == "jumbalaya_end_a") then
			local file = "title_garden.png"
			if spec.name == "Jumbalaya" then
				file = "Jumbalaya.png"
			elseif spec.name == "jumbalaya_base" then
				file = "Jumbalaya_base.png"
			elseif spec.name == "jumbalaya_start_a" then
				file = "Jumbalaya_start_A.png"
			elseif spec.name == "jumbalaya_end_a" then
				file = "Jumbalaya_end_A.png"
			end
			local fallback = "resources/textures/2x/" .. file
			if not love.filesystem.getInfo(fallback) then
				fallback = "resources/textures/1x/" .. file
			end
			path = fallback
		end
		if love.filesystem.getInfo(path) then
			local dpiscale = (
				spec.name == "playing_back" or spec.name == "Jumbalaya" or spec.name == "title_garden"
				or spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a"
			) and 1 or self.SETTINGS.GRAPHICS.texture_scaling
			self.TEXTURE_ATLASES[spec.name] = {}
			self.TEXTURE_ATLASES[spec.name].name = spec.name
			self.TEXTURE_ATLASES[spec.name].image = love.graphics.newImage(path, { mipmaps = true, dpiscale = dpiscale })
			if spec.name == 'bin' or spec.name == 'characters' then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('nearest', 'nearest')
				self.TEXTURE_ATLASES[spec.name].frames = spec.frames or 160
				if spec.cols then self.TEXTURE_ATLASES[spec.name].cols = spec.cols end
				if spec.rows then self.TEXTURE_ATLASES[spec.name].rows = spec.rows end
			elseif spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a" then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('nearest', 'nearest')
			end
			self.TEXTURE_ATLASES[spec.name].type = spec.type
			if spec.name == "playing_back" or spec.name == "shuffle_icon" or spec.name == "play_icon" or spec.name == "tokens"
				or spec.name == "Jumbalaya" or spec.name == "title_garden"
				or spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a" then
				local iw, ih = self.TEXTURE_ATLASES[spec.name].image:getDimensions()
				self.TEXTURE_ATLASES[spec.name].px = iw
				self.TEXTURE_ATLASES[spec.name].py = ih
			else
				self.TEXTURE_ATLASES[spec.name].px = spec.px
				self.TEXTURE_ATLASES[spec.name].py = spec.py
			end
		end
	end
	if not self.TEXTURE_ATLASES.centers then
		self.TEXTURE_ATLASES.centers = self.TEXTURE_ATLASES.cards_1 or self.TEXTURE_ATLASES.playing_back
	end
	if not self.TEXTURE_ATLASES.Companion then
		self.TEXTURE_ATLASES.Companion = self.TEXTURE_ATLASES.characters or self.TEXTURE_ATLASES.centers
	end
	for i = 1, #self.asset_images do
		self.TEXTURE_ATLASES[self.asset_images[i].name] = {}
		self.TEXTURE_ATLASES[self.asset_images[i].name].name = self.asset_images[i].name
		self.TEXTURE_ATLASES[self.asset_images[i].name].image = love.graphics.newImage(self.asset_images[i].path, { mipmaps = true, dpiscale = 1 })
		self.TEXTURE_ATLASES[self.asset_images[i].name].type = self.asset_images[i].type
		self.TEXTURE_ATLASES[self.asset_images[i].name].px = self.asset_images[i].px
		self.TEXTURE_ATLASES[self.asset_images[i].name].py = self.asset_images[i].py
	end

	for _, v in pairs(G.LIVE.SPRITE) do
		v:reset()
	end

	self.TEXTURE_ATLASES.Orbit = self.TEXTURE_ATLASES.Charm
	self.TEXTURE_ATLASES.Phantom = self.TEXTURE_ATLASES.Charm
end

return M
