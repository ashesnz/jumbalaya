return function(InputRouter)
function InputRouter:update_focus(dir)
	self.focused.prev_target = self.focused.target

	-- Mouse/touch never keeps gamepad focus.
	if not self.HID.controller or self.interrupt.focus
		or (self.locked and (not G.SETTINGS.paused or G.screenwipe)) then
		if self.focused.target then self.focused.target.states.focus.is = false end
		self.focused.target = nil
		return
	end

	G.ARGS.focus_list = clear_table(G.ARGS.focus_list)
	G.ARGS.focusables = clear_table(G.ARGS.focusables)

	-- Drop the current target once it stops being valid.
	if self.focused.target then
		self.focused.target.states.focus.is = false
		if not self:is_node_focusable(self.focused.target)
			or not self.focused.target:collides_with_point(G.POINTER.T)
			or self.HID.axis_cursor then
			self.focused.target = nil
		end
	end

	if not dir and self.focused.target then
		-- Keep the current target.
		self.focused.target.states.focus.can = true
		G.ARGS.focusables[#G.ARGS.focusables + 1] = self.focused.target
	else
		if not dir then
			-- Take the first focusable under the cursor.
			for _, v in ipairs(self.nodes_at_cursor) do
				v.states.focus.can = false
				v.states.focus.is = false
				if #G.ARGS.focusables == 0 and self:is_node_focusable(v) then
					v.states.focus.can = true
					G.ARGS.focusables[#G.ARGS.focusables + 1] = v
				end
			end
		else
			-- Directional search considers every moveable.
			for _, v in pairs(G.TRANSFORMS) do
				v.states.focus.can = false
				v.states.focus.is = false
				if self:is_node_focusable(v) then
					v.states.focus.can = true
					G.ARGS.focusables[#G.ARGS.focusables + 1] = v
				end
			end
		end
	end

	if #G.ARGS.focusables > 0 then
		if dir then
			if (dir == 'L' or dir == '') and self.focused.target and self.focused.target:is_kind(Card)
				and self.focused.target.area == G.hand and G.hand then
				-- Inside the hand, walk card ranks with wraparound.
				local slot = self.focused.target.slot or 1
				local next_slot = slot + (dir == 'L' and -1 or 1)
				if next_rank > #G.hand.cards then next_rank = 1 end
				if next_rank == 0 then next_rank = #G.hand.cards end
				if next_slot ~= slot then G.ARGS.focus_list[1] = {node = G.hand.cards[next_slot]} end
			else
				-- Origin: focused node midpoint (funneled), else hover/cursor pos.
				G.ARGS.focus_cursor_pos = G.ARGS.focus_cursor_pos or {}
				G.ARGS.focus_cursor_pos.x = G.POINTER.T.x - G.ROOM.T.x
				G.ARGS.focus_cursor_pos.y = G.POINTER.T.y - G.ROOM.T.y

				if self.focused.target then
					local origin = self.focused.target
					if origin.config.focus_args and origin.config.focus_args.funnel_to then
						origin = origin.config.focus_args.funnel_to
					end
					G.ARGS.focus_cursor_pos.x = origin.T.x + 0.5 * origin.T.w
					G.ARGS.focus_cursor_pos.y = origin.T.y + 0.5 * origin.T.h
				elseif self.hovering.target and self.hovering.target.states.focus.can then
					G.ARGS.focus_cursor_pos.x, G.ARGS.focus_cursor_pos.y = self.hovering.target:put_focused_cursor()
					G.ARGS.focus_cursor_pos.x = G.ARGS.focus_cursor_pos.x / (G.TILESCALE * G.TILESIZE) - G.ROOM.T.x
					G.ARGS.focus_cursor_pos.y = G.ARGS.focus_cursor_pos.y / (G.TILESCALE * G.TILESIZE) - G.ROOM.T.y
				end

				-- Score every focusable in the requested direction.
				for _, v in pairs(G.ARGS.focusables) do
					if v ~= self.hovering.target and v ~= self.focused.target then
						local eligible = false
						if v.config.focus_args and v.config.focus_args.funnel_to then
							v = v.config.focus_args.funnel_to
						end

						G.ARGS.focus_vec = G.ARGS.focus_vec or {}
						local vx = v.T.x + 0.5 * v.T.w - G.ARGS.focus_cursor_pos.x
						local vy = v.T.y + 0.5 * v.T.h - G.ARGS.focus_cursor_pos.y
						G.ARGS.focus_vec.x = vx
						G.ARGS.focus_vec.y = vy

						if v.config.focus_args and v.config.focus_args.nav then
							-- Layout hints: rows accept vertical steps or horizontal
							-- overlap; columns mirror that.
							if v.config.focus_args.nav == 'wide' then
								if vy > 0.1 and dir == 'D' then eligible = true
								elseif vy < -0.1 and dir == 'U' then eligible = true
								elseif math.abs(vy) < v.T.h / 2 then eligible = true end
							elseif v.config.focus_args.nav == 'tall' then
								if vx > 0.1 and dir == 'R' then eligible = true
								elseif vx < -0.1 and dir == 'L' then eligible = true
								elseif math.abs(vx) < v.T.w / 2 then eligible = true end
							end
						elseif math.abs(vx) > math.abs(vy) then
							if vx > 0 and dir == 'R' then eligible = true
							elseif vx < 0 and dir == 'L' then eligible = true end
						else
							if vy > 0 and dir == 'D' then eligible = true
							elseif vy < 0 and dir == 'U' then eligible = true end
						end

						if eligible then
							G.ARGS.focus_list[#G.ARGS.focus_list + 1] = {node = v, dist = math.abs(vx) + math.abs(vy)}
						end
					end
				end

				if #G.ARGS.focus_list < 1 then
					-- Nowhere to go: keep the current focus selected.
					if self.focused.target then self.focused.target.states.focus.is = true end
					return
				end
				table.sort(G.ARGS.focus_list, function(a, b) return a.dist < b.dist end)
			end
		else
			if self.focused.target then
				G.ARGS.focus_list[#G.ARGS.focus_list + 1] = {node = self.focused.target, dist = 0}
			else
				G.ARGS.focus_list[#G.ARGS.focus_list + 1] = {node = G.ARGS.focusables[1], dist = 0}
			end
		end
	end

	-- Commit the winner (funnel sources redirect to their funnel target).
	if G.ARGS.focus_list[1] then
		local winner = G.ARGS.focus_list[1].node
		if winner.config and winner.config.focus_args and winner.config.focus_args.funnel_from then
			self.focused.target = winner.config.focus_args.funnel_from
		else
			self.focused.target = winner
		end
		if self.focused.target ~= self.focused.prev_target then
			G.VIBRATION = G.VIBRATION + 0.7
		end
	else
		self.focused.target = nil
	end

	if self.focused.target then self.focused.target.states.focus.is = true end
end
end
