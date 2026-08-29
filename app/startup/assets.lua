--[[ app/startup/assets.lua - Shaders, atlases, and shared card sprites ]]

local M = {}

local ASSETS_DIR = "resources/assets"

local function asset_path(filename)
	return ASSETS_DIR .. "/" .. filename
end

local function resolve_asset_path(filename, alternates)
	if love.filesystem.getInfo(asset_path(filename)) then
		return asset_path(filename)
	end
	for _, alt in ipairs(alternates or {}) do
		local path = asset_path(alt)
		if love.filesystem.getInfo(path) then
			return path
		end
	end
	return asset_path(filename)
end

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
	local atlas = game.TEXTURE_ATLASES.letter_frame or game.TEXTURE_ATLASES.playing_back
	if atlas then
		game.shared_debuff = Sprite(0, 0, game.CARD_W, game.CARD_H, atlas, { x = 0, y = 0 })
		game.shared_undiscovered_companion = Sprite(0, 0, game.CARD_W, game.CARD_H, atlas, { x = 0, y = 0 })
	end

	local seal_atlas = game.TEXTURE_ATLASES.letter_frame or game.TEXTURE_ATLASES.playing_back
	game.shared_seals = seal_atlas and {
		Gold = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Purple = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Red = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
		Blue = Sprite(0, 0, game.CARD_W, game.CARD_H, seal_atlas, { x = 0, y = 0 }),
	} or {}
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
		{ name = "letters", path = asset_path("JumbalayaLetters.png"), px = 71, py = 95 },
		{ name = "letter_frame", path = asset_path("JumbalayaCardFrame.png"), px = 71, py = 95 },
		{ name = "playing_back", path = asset_path("PlayingDeck.png"), px = 71, py = 95 },
		{ name = "Perk", path = asset_path("Perks.png"), px = 303, py = 138 },
		{ name = "ui_1", path = asset_path("ui_assets.png"), px = 18, py = 18 },
		{ name = "Jumbalaya", path = asset_path("Jumbalaya.png"), px = 466.5, py = 133.5 },
		{ name = "jumbalaya_base", path = asset_path("Jumbalaya_base.png"), px = 933, py = 267 },
		{ name = "jumbalaya_start_a", path = asset_path("Jumbalaya_start_A.png"), px = 103, py = 143 },
		{ name = "jumbalaya_end_a", path = asset_path("Jumbalaya_end_A.png"), px = 123, py = 152 },
		{ name = "title_garden", path = asset_path("title_garden.png"), px = 1536, py = 1024 },
		{ name = 'gamepad_ui', path = asset_path("gamepad_ui.png"), px = 32, py = 32 },
		{ name = 'icons', path = asset_path("icons.png"), px = 66, py = 66 },
		{ name = 'bin', path = asset_path("Bin.png"), px = 249, py = 251, frames = 4, cols = 2, rows = 2 },
		{ name = 'shuffle_icon', path = asset_path("shuffle_icon.png"), px = 112, py = 112 },
		{ name = 'remove_placement_icon', path = asset_path("remove_placement_icon.png"), px = 112, py = 112 },
		{ name = 'play_icon', path = asset_path("play_icon.png"), px = 112, py = 112 },
		{ name = 'tokens', path = asset_path("coin_stack.png"), px = 521, py = 479 },
		{ name = 'coin', path = asset_path("coin.png"), px = 521, py = 478 },
		{ name = 'boss_banner', path = asset_path("banner.png"), px = 1180, py = 211 },
		{ name = 'marketplace_bg', path = resolve_asset_path("Marketplace.png", { "Marketplace.jpeg" }), px = 1408, py = 768 },
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
		if love.filesystem.getInfo(path) then
			local dpiscale = (
				spec.name == "playing_back" or spec.name == "Jumbalaya" or spec.name == "title_garden"
				or spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a" or spec.name == "boss_banner"
				or spec.name == "marketplace_bg" or spec.name == "Perk"
			) and 1 or self.SETTINGS.GRAPHICS.texture_scaling
			self.TEXTURE_ATLASES[spec.name] = {}
			self.TEXTURE_ATLASES[spec.name].name = spec.name
			self.TEXTURE_ATLASES[spec.name].image = love.graphics.newImage(path, { mipmaps = true, dpiscale = dpiscale })
			if spec.name == 'bin' then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('nearest', 'nearest')
				self.TEXTURE_ATLASES[spec.name].frames = spec.frames or 160
				if spec.cols then self.TEXTURE_ATLASES[spec.name].cols = spec.cols end
				if spec.rows then self.TEXTURE_ATLASES[spec.name].rows = spec.rows end
			elseif spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a" then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('nearest', 'nearest')
			end
			self.TEXTURE_ATLASES[spec.name].type = spec.type
			if spec.name == "playing_back" or spec.name == "shuffle_icon" or spec.name == "remove_placement_icon"
				or spec.name == "play_icon" or spec.name == "tokens"
				or spec.name == "coin" or spec.name == "boss_banner" or spec.name == "marketplace_bg"
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
		self.TEXTURE_ATLASES.centers = self.TEXTURE_ATLASES.letter_frame or self.TEXTURE_ATLASES.playing_back
	end
	if not self.TEXTURE_ATLASES.Companion then
		self.TEXTURE_ATLASES.Companion = self.TEXTURE_ATLASES.letter_frame or self.TEXTURE_ATLASES.centers
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
end

return M
