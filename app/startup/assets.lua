--[[ app/startup/assets.lua - Shaders, atlases, and shared card sprites ]]

local M = {}

local ASSETS_DIR = "resources/assets"
local AtlasDpiscale = require("app.startup.atlas_dpiscale")
local AtlasPaths = require("app.startup.atlas_paths")
local AtlasDiagnostics = require("app.startup.atlas_diagnostics")

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
	AtlasDiagnostics.reset()

	if love.graphics and love.graphics.setDefaultFilter then
		local os_name = love.system and love.system.getOS and love.system.getOS() or ""
		local mobile = os_name == "iOS" or os_name == "Android"
		local filter = (not mobile and self.SETTINGS.GRAPHICS.texture_scaling == 1) and "nearest" or "linear"
		love.graphics.setDefaultFilter(filter, filter, 1)
	end

	if love.graphics and love.graphics.setLineStyle then
		love.graphics.setLineStyle("rough")
	end

	---@type GameAtlasSpec[]
	self.animation_atli = {}
	---@type GameAtlasSpec[]
	self.asset_atli = {
		{ name = "letters", filename = "JumbalayaLetters.png", px = 71, py = 95 },
		{ name = "letter_frame", filename = "JumbalayaCardFrame.png", px = 71, py = 95 },
		{ name = "playing_back", filename = "PlayingDeck.png", px = 71, py = 95 },
		{ name = "Perk", filename = "Perks.png", px = 303, py = 138 },
		{ name = "ui_1", filename = "ui_assets.png", px = 18, py = 18 },
		{ name = "Jumbalaya", filename = "Jumbalaya.png", px = 466.5, py = 133.5 },
		{ name = "jumbalaya_base", filename = "Jumbalaya_base.png", px = 933, py = 267 },
		{ name = "jumbalaya_start_a", filename = "Jumbalaya_start_A.png", px = 103, py = 143 },
		{ name = "jumbalaya_end_a", filename = "Jumbalaya_end_A.png", px = 123, py = 152 },
		{ name = "title_garden", filename = "title_garden.png", px = 1536, py = 1024 },
		{ name = 'gamepad_ui', filename = "gamepad_ui.png", px = 32, py = 32 },
		{ name = 'icons', filename = "icons.png", px = 66, py = 66 },
		{ name = 'bin', filename = "Bin.png", px = 249, py = 251, frames = 4, cols = 2, rows = 2 },
		{ name = 'shuffle_icon', filename = "shuffle_icon.png", px = 112, py = 112 },
		{ name = 'remove_placement_icon', filename = "remove_placement_icon.png", px = 112, py = 112 },
		{ name = 'play_icon', filename = "play_icon.png", px = 112, py = 112 },
		{ name = 'tokens', filename = "coin_stack.png", px = 521, py = 479 },
		{ name = 'coin', filename = "coin.png", px = 521, py = 478 },
		{ name = 'boss_banner', filename = "banner.png", px = 1180, py = 211 },
		{ name = 'marketplace_bg', filename = "Marketplace.png", px = 1408, py = 768, alternates = { "Marketplace.jpeg" } },
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
		local legacy = asset_path(spec.filename)
		if spec.alternates then
			legacy = resolve_asset_path(spec.filename, spec.alternates)
		end
		local path, source = AtlasPaths.resolve(spec.filename, self.SETTINGS.GRAPHICS.texture_scaling, legacy)
		if love.filesystem.getInfo(path) then
			local dpiscale = AtlasPaths.dpiscale_for_source(source, self.SETTINGS.GRAPHICS.texture_scaling, spec.name)
			local retina_atlas = AtlasDpiscale.is_retina_atlas(spec.name)
			self.TEXTURE_ATLASES[spec.name] = {}
			self.TEXTURE_ATLASES[spec.name].name = spec.name
			self.TEXTURE_ATLASES[spec.name].path = path
			self.TEXTURE_ATLASES[spec.name].source = source
			self.TEXTURE_ATLASES[spec.name].dpiscale = dpiscale
			self.TEXTURE_ATLASES[spec.name].image = love.graphics.newImage(path, {
				mipmaps = not retina_atlas,
				dpiscale = dpiscale,
			})
			if spec.name == 'bin' then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('nearest', 'nearest')
				self.TEXTURE_ATLASES[spec.name].frames = spec.frames or 160
				if spec.cols then self.TEXTURE_ATLASES[spec.name].cols = spec.cols end
				if spec.rows then self.TEXTURE_ATLASES[spec.name].rows = spec.rows end
			elseif AtlasDpiscale.is_letter_atlas(spec.name) then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('linear', 'linear')
			elseif spec.name == "jumbalaya_base" or spec.name == "jumbalaya_start_a"
				or spec.name == "jumbalaya_end_a" or spec.name == "Jumbalaya" then
				self.TEXTURE_ATLASES[spec.name].image:setFilter('linear', 'linear')
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
			AtlasDiagnostics.record(spec.name, path, source, dpiscale,
				self.TEXTURE_ATLASES[spec.name].px, self.TEXTURE_ATLASES[spec.name].py,
				self.TEXTURE_ATLASES[spec.name].image)
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

	AtlasDiagnostics.finalize(self)
end

return M
