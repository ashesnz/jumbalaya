--[[ app/startup/atlas_dpiscale.lua - dpiscale selection for texture atlases ]]

local M = {}

--- Atlases addressed with 1x logical cell coordinates but shipped as @2x PNGs
--- in resources/assets/. Always load these with dpiscale=2 on every platform.
local RETINA_ATLASES = {
	letters = true,
	letter_frame = true,
	Jumbalaya = true,
	jumbalaya_base = true,
	jumbalaya_start_a = true,
	jumbalaya_end_a = true,
	ui_1 = true,
	icons = true,
	bin = true,
}

--- Full-bleed images (backgrounds, icons at native resolution) — no dpiscale halving.
local NATIVE_ATLASES = {
	playing_back = true,
	title_garden = true,
	boss_banner = true,
	marketplace_bg = true,
	Perk = true,
	shuffle_icon = true,
	remove_placement_icon = true,
	play_icon = true,
	tokens = true,
	coin = true,
	gamepad_ui = true,
}

function M.is_letter_atlas(atlas_name)
	return atlas_name == "letters" or atlas_name == "letter_frame"
end

function M.is_retina_atlas(atlas_name)
	return RETINA_ATLASES[atlas_name] == true
end

function M.is_native_atlas(atlas_name)
	return NATIVE_ATLASES[atlas_name] == true
end

function M.for_atlas(atlas_name, texture_scaling)
	if M.is_retina_atlas(atlas_name) then
		return 2
	end
	if M.is_native_atlas(atlas_name) then
		return 1
	end
	return texture_scaling
end

return M
