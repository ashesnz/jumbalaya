
local Tables = require("jumbalaya-engine.util.tables")
local shell = require("jumbalaya-engine.shell")
local game = shell.game
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
return function(Target)
function Target:update(dt)
	game().ARGS.FUNC_TRACKER = game().ARGS.FUNC_TRACKER or {}

	-- button_delay parks the real handler aside for a cooldown window while
	-- drawing a progress fill.
	if self.config.button_delay then
		self.config.button_temp = self.config.button or self.config.button_temp
		self.config.button = nil
		self.config.button_delay_progress = (game().TIMERS.REAL - self.config.button_delay_start) / self.config.button_delay
		if game().TIMERS.REAL >= self.config.button_delay_end then self.config.button_delay = nil end
	end
	if self.config.button_temp and not self.config.button_delay then
		self.config.button = self.config.button_temp
	end
	if self.button_clicked then self.button_clicked = nil end

	if self.config and self.config.func then
		game().ARGS.FUNC_TRACKER[self.config.func] = (game().ARGS.FUNC_TRACKER[self.config.func] or 0) + 1
		if shell.get_func(self.config.func) then
			shell.dispatch_func(self.config.func, self)
		end
	end

	if self.ui_kind == game().UI.TEXT then self:update_text() end
	if self.ui_kind == game().UI.OBJECT then self:update_object() end
	Node.update(self, dt)
end

--- Elements are hit-testable only while their owning box allows collisions.
function Target:collides_with_point(cursor_trans)
	if self.panel.states.collide.can then
		return Node.collides_with_point(self, cursor_trans)
	end
	return false
end

function Target:click()
	-- Debounced, visible, non-overlayed, non-disabled buttons only.
	if self.config.button
		and (not self.last_clicked or self.last_clicked + 0.1 < game().TIMERS.REAL)
		and self.states.visible and not self.under_overlay and not self.disable_button then
		if self.config.one_press then self.disable_button = true end
		self.last_clicked = game().TIMERS.REAL

		-- The overlay back button also pops the cursor-context stack.
		if self.config.id == 'overlay_menu_back_button' then
			game().INPUT:shift_context_layer(-1)
			game().NO_MOD_CURSOR_STACK = true
		end

		if shell.get_func(self.config.button) then
			shell.dispatch_func(self.config.button, self)
		end

		game().NO_MOD_CURSOR_STACK = nil

		-- Choice-cycle groups: clear siblings' chosen flag, claim our own.
		if self.config.choice then
			local choices = self.panel:get_group(nil, self.config.group)
			for _, v in pairs(choices) do
				if v.config and v.config.choice then v.config.chosen = false end
			end
			self.config.chosen = true
		end

		play_sfx('button', 1, 0.3)
		if not self.config.no_jiggle then
			game().ROOM.jiggle = game().ROOM.jiggle + 0.5
		end
		self.button_clicked = true
	end

	-- Nested buttons chain outward (inner click activates the outer action).
	if self.config.button_UIE then
		self.config.button_UIE:click()
	end
end

--- Focus cursor placement; tab strips route into the chosen tab's content.
---@return number x
---@return number y
function Target:put_focused_cursor()
	if self.config.focus_args and self.config.focus_args.type == 'tab' then
		for _, v in pairs(self.children) do
			if v.children[1].config.chosen then
				return v.children[1]:put_focused_cursor()
			end
		end
	end
	return Node.put_focused_cursor(self)
end

function Target:remove()
	if self.config and self.config.object then
		if self.config.object.remove then self.config.object:remove() end
		self.config.object = nil
	end

	if self == game().INPUT.text_capture then
		game().INPUT.text_capture = nil
	end

	Tables.teardown_tree(self.children)
	AnimNode.remove(self)
end

--- Builds the configured tooltip popup definition before Node creates it.
function Target:hover()
	if self.config and self.config.on_demand_tooltip then
		self.config.h_popup = make_tooltip(self.config.on_demand_tooltip)
		local below = self.T.y > game().ROOM.T.h / 2
		self.config.h_popup_config = {
			align = below and 'tm' or 'bm',
			offset = {x = 0, y = below and -0.1 or 0.1},
			parent = self,
		}
	end
	if self.config.tooltip then
		self.config.h_popup = make_tooltip(self.config.tooltip)
		self.config.h_popup_config = {align = "tm", offset = {x = 0, y = -0.1}, parent = self}
	end
	if self.config.detailed_tooltip and game().INPUT.HID.pointer then
		self.config.h_popup = build_detailed_tooltip(self.config.detailed_tooltip)
		self.config.h_popup_config = {align = "tm", offset = {x = 0, y = -0.1}, parent = self}
	end
	Node.hover(self)
end

function Target:stop_hover()
	Node.stop_hover(self)
	if self.config and self.config.on_demand_tooltip then
		self.config.h_popup = nil
	end
end

function Target:release(other)
	if self.parent then self.parent:release(other) end
end
end
