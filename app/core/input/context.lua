return function(InputRouter)
function InputRouter:shift_context_layer(delta)
	if delta == 1 then
		self.cursor_context.stack[self.cursor_context.layer] = {
			node = self.focused.target,
			cursor_pos = {x = G.POINTER.T.x, y = G.POINTER.T.y},
			interrupt = self.interrupt.focus,
		}
		self.cursor_context.layer = self.cursor_context.layer + 1
	elseif delta == -1 then
		self.cursor_context.stack[self.cursor_context.layer] = nil
		self.cursor_context.layer = self.cursor_context.layer - 1
	elseif delta == -1000 then
		self.cursor_context.layer = 1
		self.cursor_context.stack = {self.cursor_context.stack[1]}
	elseif delta == -2000 then
		self.cursor_context.layer = 1
		self.cursor_context.stack = {}
	end

	self:navigate_focus()
end

--- Queues a next-frame snap onto `args.node` (or raw `args.T`).
function InputRouter:snap_to(args)
	self.snap_cursor_to = {node = args.node, T = args.T, type = args.node and 'node' or 'transform'}
end

--- Remembers which card in an area had focus (e.g. before a shop reroll).
function InputRouter:save_cardarea_focus(_cardarea)
	if G[_cardarea] then
		if self.focused.target and self.focused.target.area and self.focused.target.area == G[_cardarea] then
			self.cardarea_context[_cardarea] = self.focused.target.slot
			return true
		else
			self.cardarea_context[_cardarea] = nil
		end
	end
end

--- Restores focus into a card area at the previously-saved slot.
function InputRouter:recall_cardarea_focus(_cardarea)
	local ca_string = nil
	if type(_cardarea) == 'string' then ca_string = _cardarea; _cardarea = G[_cardarea] end

	if _cardarea and (not self.focused.target
		or self.interrupt.focus
		or (not self.interrupt.focus and self.focused.target.area and self.focused.target.area == _cardarea)) then
		if ca_string and self.cardarea_context[ca_string] then
			for i = self.cardarea_context[ca_string], 1, -1 do
				if _cardarea.cards[i] then
					self:snap_to({node = _cardarea.cards[i]})
					self.interrupt.focus = false
					break
				end
			end
		elseif _cardarea.cards and _cardarea.cards[1] then
			self:snap_to({node = _cardarea.cards[1]})
			self.interrupt.focus = false
		end
	end
	if ca_string then self.cardarea_context[ca_string] = nil end
end

--- Places the cursor: hard-set to `hard_set_T`, or centered on the focus target.
function InputRouter:update_cursor(hard_set_T)
	local units = G.TILESCALE * G.TILESIZE
	if hard_set_T then
		G.POINTER.T.x = hard_set_T.x
		G.POINTER.T.y = hard_set_T.y
		self.cursor_position.x = G.POINTER.T.x * units
		self.cursor_position.y = G.POINTER.T.y * units
		G.POINTER.VT.x = G.POINTER.T.x
		G.POINTER.VT.y = G.POINTER.T.y
		return
	end
	if self.focused.target then
		self.cursor_position.x, self.cursor_position.y = self.focused.target:put_focused_cursor()
		G.POINTER.T.x = self.cursor_position.x / units
		G.POINTER.T.y = self.cursor_position.y / units
		G.POINTER.VT.x = G.POINTER.T.x
		G.POINTER.VT.y = G.POINTER.T.y
	end
end
end
