--[[ app/startup/atlas_diagnostics.lua - Runtime atlas loading report (iOS debug) ]]

local M = {}

local WATCH = {
	"letters", "letter_frame", "Jumbalaya", "jumbalaya_base",
	"jumbalaya_start_a", "jumbalaya_end_a", "playing_back",
}

function M.reset()
	M.lines = {}
	M.recorded = {}
end

function M.record(name, path, source, dpiscale, px, py, image)
	if M.recorded[name] then return end
	M.recorded[name] = true
	local iw, ih = image:getDimensions()
	local min_f, mag_f = image:getFilter()
	M.lines[#M.lines + 1] = string.format(
		"%s path=%s src=%s dpiscale=%s gpu=%dx%d atlas_px=%sx%s filter=%s,%s",
		name, path or "?", source or "?", tostring(dpiscale), iw, ih,
		tostring(px), tostring(py), tostring(min_f), tostring(mag_f))
end

function M.header(game)
	local os_name = love.system and love.system.getOS and love.system.getOS() or "?"
	local ts = game.SETTINGS and game.SETTINGS.GRAPHICS and game.SETTINGS.GRAPHICS.texture_scaling or "?"
	local ww, wh = love.graphics.getDimensions()
	M.lines[#M.lines + 1] = string.format(
		"os=%s texture_scaling=%s window=%dx%d", os_name, tostring(ts), ww, wh)
end

function M.finalize(game)
	M.header(game)
	for _, name in ipairs(WATCH) do
		local atlas = game.TEXTURE_ATLASES and game.TEXTURE_ATLASES[name]
		if atlas and atlas.image and not M.recorded[name] then
			M.record(name, atlas.path, atlas.source, atlas.dpiscale, atlas.px, atlas.py, atlas.image)
		end
	end
	local text = table.concat(M.lines, "\n")
	game.ATLAS_DEBUG_REPORT = text
	if game.F_VERBOSE then
		print("[atlas]\n" .. text)
	end
	if love.filesystem and love.filesystem.getSaveDirectory then
		pcall(function()
			love.filesystem.write("atlas_debug.txt", text .. "\n")
		end)
	end
end

function M.draw_overlay()
	if not G or not G.F_ATLAS_DEBUG_OVERLAY or not G.ATLAS_DEBUG_REPORT then return end
	if not love.graphics then return end
	local font = love.graphics.getFont()
	local line_h = font:getHeight() * 0.22
	love.graphics.push("all")
	love.graphics.setColor(0, 0, 0, 0.72)
	love.graphics.rectangle("fill", 4, 4, 520, line_h * (#M.lines + 1) + 8)
	love.graphics.setColor(0.3, 1, 0.4, 1)
	love.graphics.print(G.ATLAS_DEBUG_REPORT, 8, 8, 0, 0.22, 0.22)
	love.graphics.pop()
end

return M
