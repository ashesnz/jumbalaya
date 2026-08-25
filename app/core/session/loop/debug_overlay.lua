--[[ app/loop/debug_overlay.lua - Performance overlay drawing in Game:draw ]]

local TableBoard = require "word_game.ui.table_board"

local M = {}

function M.state_col(_state)
	return (_state * 15251252.2 / 5.132) % 1, (_state * 1422.5641311 / 5.42) % 1, (_state * 1522.1523122 / 5.132) % 1, 1
end

function M.draw(game)
	if _RELEASE_MODE or G.video_control or not G.F_VERBOSE then
		if TableBoard.is_active() then
			TableBoard.draw_debug_answers()
		end
		return
	end

	love.graphics.push()
	love.graphics.setColor(0, 1, 1, 1)
	local fps = love.timer.getFPS()
	love.graphics.print("Current FPS: " .. fps, 10, 10)

	if G.check and G.SETTINGS.perf_mode then
		local section_h = 30
		local resolution = 60 * section_h
		local poll_w = 1
		local v_off = 100
		for a, b in ipairs({G.check.update, G.check.draw}) do
			for k, v in ipairs(b.checkpoint_list) do
				love.graphics.setColor(0, 0, 0, 0.2)
				love.graphics.rectangle('fill', 12, 20 + v_off, poll_w + poll_w * #v.trend, -section_h + 5)
				for kk, vv in ipairs(v.trend) do
					if a == 2 then
						love.graphics.setColor(0.3, 0.7, 0.7, 1)
					else
						love.graphics.setColor(M.state_col(v.states[kk] or 123))
					end
					love.graphics.rectangle('fill', 10 + poll_w * kk, 20 + v_off, 5 * poll_w, -(vv) * resolution)
				end
				love.graphics.setColor(a == 2 and 0.5 or 1, a == 2 and 1 or 0.5, 1, 1)
				love.graphics.print(v.label .. ': ' .. (string.format("%.2f", 1000 * (v.average or 0))) .. '\n', 10, -section_h + 30 + v_off)
				v_off = v_off + section_h
			end
		end
	end

	love.graphics.pop()

	if TableBoard.is_active() then
		TableBoard.draw_debug_answers()
	end
end

return M
