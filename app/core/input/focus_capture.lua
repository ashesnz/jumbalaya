return function(InputRouter)
function InputRouter:capture_focused_input(button, input_type, dt)
	local captured = false
	local focused = self.focused.target
	local extern_button = false
	self.no_holdcap = nil

	-- Coyote time: a very recent 'a' press lets dpad flicks move between
	-- selectable cards without completing the full press cycle.
	if input_type == 'press' and (button == 'dpleft' or button == 'dpright')
		and focused and self.dragging.target
		and (self.held_button_times['a'] and self.held_button_times['a'] < 0.12)
		and focused.area and focused.area:can_select(focused) then
		self:L_cursor_release()
		self:navigate_focus(button == 'dpleft' and 'L' or 'R')
		self.held_button_times['a'] = nil
		self.COYOTE_FOCUS = true
		captured = true

	-- While actively dragging the focused card, dpad reorders it in its area.
	elseif input_type == 'press' and focused and focused.area and focused == self.dragging.target then
		focused.states.drag.is = false
		local slot_index = focused.slot
		local area = focused.area
		if button == 'dpleft' and slot_index and slot_index > 1 and area then
			focused.slot = slot_index - 1
			local swap = area.cards[focused.slot]
			if swap then swap.slot = slot_index end
			table.sort(area.cards, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
			area:relayout()
			self:update_cursor()
		elseif button == 'dpright' and slot_index and area and slot_index < #area.cards then
			focused.slot = slot_index + 1
			local swap = area.cards[focused.slot]
			if swap then swap.slot = slot_index end
			table.sort(area.cards, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
			area:relayout()
			self:update_cursor()
		end
		focused.states.drag.is = true
		captured = true
	end

	-- Overlay shoulder buttons hijack L/R for tab strips and option cycles.
	if G.OVERLAY_MENU and not self.screen_keyboard and input_type == 'press'
		and (button == 'leftshoulder' or button == 'rightshoulder') then
		if G.OVERLAY_MENU:find_node_by_id('tab_shoulders') then
			focused = G.OVERLAY_MENU:find_node_by_id('tab_shoulders')
			extern_button = true
		end
		local cycle = G.OVERLAY_MENU:find_node_by_id('cycle_shoulders')
		if cycle then
			focused = cycle.children[1]
			extern_button = true
		end
	end

	if focused and focused.config.focus_args then
		local args = focused.config.focus_args
		local left = (extern_button and button == 'leftshoulder') or (not extern_button and button == 'dpleft')
		local right = (extern_button and button == 'rightshoulder') or (not extern_button and button == 'dpright')

		if args.type == 'cycle' and input_type == 'press' then
			if left and focused.children[1] then focused.children[1]:click(); captured = true end
			if right and focused.children[3] then focused.children[3]:click(); captured = true end
		end

		if args.type == 'tab' and input_type == 'press' then
			local box = focused.LayoutView
			local proto_choices = box and box:get_group(nil, focused.children[1].children[1].config.group) or {}
			local choices = {}
			for _, v in ipairs(proto_choices) do
				if v.config.choice and v.config.button then choices[#choices + 1] = v end
			end
			for index, choice in ipairs(choices) do
				if choice.config.chosen then
					local next_index
					if left then
						next_index = index ~= 1 and index - 1 or #choices
						if args.no_loop and next_index > index then captured = false
						else choices[next_index]:click(); captured = true end
					elseif right then
						next_index = index ~= #choices and index + 1 or 1
						if args.no_loop and next_index < index then captured = false
						else choices[next_index]:click(); captured = true end
					end
					if captured then
						self:snap_to({node = choices[next_index]})
						self:update_cursor()
					end
					break
				end
			end
		end

		if args.type == 'slider' then
			-- Steps on press, continuous drift while held past 0.2 s.
			if button == 'dpleft' or button == 'dpright' then
				self.no_holdcap = true
				local step = button == 'dpleft' and -0.01 or 0.01
				local drift = (button == 'dpleft' and -dt or dt) * (self.held_button_times[button] or 0) * 0.6
				if input_type == 'hold' and (self.held_button_times[button] or 0) > 0.2 then
					G.FUNCS.slider_step(focused.children[1], drift)
				elseif input_type == 'press' then
					G.FUNCS.slider_step(focused.children[1], step)
				end
				captured = true
			end
		end
	end

	if captured then G.VIBRATION = G.VIBRATION + 1 end
	return captured
end

--- Update focus toward `dir` (if given), then move the cursor onto the target.
function InputRouter:navigate_focus(dir)
	self:update_focus(dir)
	self:update_cursor()
end
end
