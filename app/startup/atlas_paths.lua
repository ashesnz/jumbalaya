--[[ app/startup/atlas_paths.lua - AlphaCards-style 1x/2x texture path resolution ]]

local AtlasDpiscale = require("app.startup.atlas_dpiscale")

local M = {}

function M.scale_suffix(texture_scaling)
	return (texture_scaling or 2) > 1 and "2x" or "1x"
end

--- Prefer resources/textures/{1x|2x}/filename (Balatro/AlphaCards layout), then
--- fall back to resources/assets/ (legacy single @2x copy).
---@return string path
---@return string|nil source "1x", "2x", or "legacy"
function M.resolve(filename, texture_scaling, legacy_path)
	local suffix = M.scale_suffix(texture_scaling)
	local scaled_path = string.format("resources/textures/%s/%s", suffix, filename)
	if love.filesystem.getInfo(scaled_path) then
		return scaled_path, suffix
	end
	if legacy_path and love.filesystem.getInfo(legacy_path) then
		return legacy_path, "legacy"
	end
	local assets_path = "resources/assets/" .. filename
	if love.filesystem.getInfo(assets_path) then
		return assets_path, "legacy"
	end
	return legacy_path or assets_path, nil
end

--- dpiscale must match the folder tier: 1x files → 1, 2x files → 2.
--- Legacy resources/assets (@2x only) uses atlas_dpiscale fallback rules.
function M.dpiscale_for_source(source, texture_scaling, atlas_name)
	if source == "1x" then
		return 1
	end
	if source == "2x" then
		return 2
	end
	return AtlasDpiscale.for_atlas(atlas_name, texture_scaling)
end

return M
