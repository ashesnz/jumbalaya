local EffectsScheduler = require("app.effects.timeline_scheduler")

return function(InputRouter)
function InputRouter:update_frame(dt)
	-- Locks: any truthy lock blocks input (with pause/wipe nuances).
	self.locked = false
	for _, v in pairs(self.locks) do
		if v then self.locked = true end
	end

	-- locks.frame is armed with locks.frame_set and auto-clears shortly after;
	-- a stuck menu can't hold it forever (overlay_timer escape hatch).
	if self.locks.frame_set then
		self.locks.frame_set = nil
		self.overlay_timer = 0
		EffectsScheduler.add{
			mode = 'delayed',
			delay = 0.1,
			timer = 'UPTIME',
			blocking = false,
			blockable = false,
			persistent = true,
			func = function()
				self.locks.frame = nil
				return true
			end,
		}
	end

	self.overlay_timer = self.overlay_timer or 0
	if G.OVERLAY_MENU then
		self.overlay_timer = self.overlay_timer + dt
	else
		self.overlay_timer = 0
	end
	if self.overlay_timer > 1.5 then self.locks.frame = nil end

	self:cull_registry()

	-- Stick/trigger activity may switch HID mode for this frame.
	self:set_HID_flags(self:update_axis(dt))

	-- Soft cursor sprite visible only for stick-driven pointing.
	if self.HID.pointer and not (self.HID.mouse or self.HID.touch) and not self.interrupt.focus then
		G.POINTER.states.visible = true
	else
		G.POINTER.states.visible = false
	end

	self:set_cursor_position()

	-- Key/button phase (suppressed during screen wipes).
	if not G.screenwipe then
		for k, v in pairs(self.pressed_keys) do
			if v then self:key_press_update(k, dt) end
		end
		for k, v in pairs(self.held_keys) do
			if v then self:key_hold_update(k, dt) end
		end
		for k, v in pairs(self.released_keys) do
			if v then self:key_release_update(k, dt) end
		end

		for k, v in pairs(self.pressed_buttons) do
			if v then self:button_press_update(k, dt) end
		end
		for k, v in pairs(self.held_buttons) do
			if v then self:button_hold_update(k, dt) end
		end
		for k, v in pairs(self.released_buttons) do
			if v then self:button_release_update(k, dt) end
		end
	end

	self.frame_buttonpress = false

	self.pressed_keys = clear_table(self.pressed_keys)
	self.released_keys = clear_table(self.released_keys)
	self.pressed_buttons = clear_table(self.pressed_buttons)
	self.released_buttons = clear_table(self.released_buttons)

	if self.HID.controller then
		-- Restore saved cursor/focus when returning to a lower menu layer.
		local pending_context = self.cursor_context.stack[self.cursor_context.layer]
		if pending_context then
			self:snap_to{
				node = (pending_context.node and not pending_context.node.REMOVED and pending_context.node),
				T = pending_context.cursor_pos,
			}
			self.interrupt.stack = pending_context.interrupt
			self.cursor_context.stack[self.cursor_context.layer] = nil
		end

		-- Snap back onto a card we just dropped (unless coyote-focused).
		if self.dragging.prev_target and not self.dragging.target
			and getmetatable(self.dragging.prev_target) == Card
			and not self.dragging.prev_target.REMOVED then
			if not self.COYOTE_FOCUS then
				self:snap_to{node = self.dragging.prev_target}
			else
				self.COYOTE_FOCUS = nil
			end
		end

		if self.snap_cursor_to then
			self.interrupt.focus = self.interrupt.stack
			self.interrupt.stack = false
			if self.snap_cursor_to.type == 'node' and self.snap_cursor_to.node
				and not self.snap_cursor_to.node.REMOVED then
				self.focused.prev_target = self.focused.target
				self.focused.target = self.snap_cursor_to.node
				self:update_cursor()
			elseif self.snap_cursor_to.type == 'transform' then
				self:update_cursor(self.snap_cursor_to.T)
			end
			if self.focused.prev_target ~= self.focused.target and self.focused.prev_target then
				self.focused.prev_target.states.focus.is = false
			end
			self.snap_cursor_to = nil
		end
	end
end
end
