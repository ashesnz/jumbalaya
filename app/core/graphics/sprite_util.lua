--[[ app/core/graphics/sprite_util.lua - shared helpers for GfxSprite mixins ]]

local M = {}

function M.unregister_instance(registry, instance)
	if not registry then return end
	for index = #registry, 1, -1 do
		if registry[index] == instance then table.remove(registry, index) end
	end
end

function M.atlas_dimensions(atlas)
	if atlas and atlas.image and atlas.image.getDimensions then
		return atlas.image:getDimensions()
	end
	return 1, 1
end

function M.shader_for(name)
	if not G.SHADERS then return nil end
	return G.SHADERS[name] or G.SHADERS.dissolve
end

return M
