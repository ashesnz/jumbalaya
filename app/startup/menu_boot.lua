--[[ app/startup/menu_boot.lua - Tween manager, cursor, and first screen after assets load ]]

function Game:boot_initial_screen()
	G.STAGE_OBJECT_INTERRUPT = true
	self.POINTER = Sprite(0, 0, 0.3, 0.3, self.TEXTURE_ATLASES['gamepad_ui'], { x = 18, y = 0 })
	self.POINTER.states.collide.can = false
	G.STAGE_OBJECT_INTERRUPT = false

	self.TIMELINE = Scheduler()
	self.TIME_SCALE = 1

	local skip_title = self.F_SKIP_TITLE_SCREEN
		or (self.SETTINGS and self.SETTINGS.skip_title_screen)
		or (self.SETTINGS and self.SETTINGS.title_screen == false)
	if skip_title then
		G.SETTINGS.tutorial_complete = true
		if G.queue_during_wipe then
			G:queue_during_wipe(function()
				G:start_run({})
				G:start_gameplay_board()
			end)
		else
			self:start_run({})
			self:start_gameplay_board()
		end
	else
		self:open_main_menu()
	end

	local os_name = love.system.getOS()
	if os_name == 'iOS' or os_name == 'Android' then
		local Window = require "app.core.platform.window"
		Window.sync_resize()
	end
	G.LOADING = nil
end

return true
