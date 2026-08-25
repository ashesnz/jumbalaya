return function(Target)
function LayoutView:calculate_xywh(node, _T, recalculate, _scale)
	node.ARGS.xywh_node_trans = node.ARGS.xywh_node_trans or {}
	local node_t = node.ARGS.xywh_node_trans
	local content = {x = 0, y = 0, w = 0, h = 0}

	local padding = node.config.padding or G.UI.padding

	if node.ui_kind == G.UI.BOX or node.ui_kind == G.UI.TEXT or node.ui_kind == G.UI.OBJECT then
		-- Leaves take their size from config or from an embedded object.
		node_t.x, node_t.y = _T.x, _T.y
		node_t.w = node.config.w or (node.config.object and node.config.object.T.w)
		node_t.h = node.config.h or (node.config.object and node.config.object.T.h)

		if node.ui_kind == G.UI.TEXT then
			node.config.text_drawable = nil
			local scale = node.config.scale or 1
			if node.config.ref_table and node.config.ref_value then
				node.config.text = tostring(node.config.ref_table[node.config.ref_value])
				if node.config.func and not recalculate then G.FUNCS[node.config.func](node) end
			end
			if not node.config.text then node.config.text = '[UI ERROR]' end

			node.config.lang = node.config.lang or G.LANG
			local font_obj = node.config.font or (node.config.lang and node.config.lang.font)
			local font_face = font_obj and font_obj.FONT
			local squish = (font_obj and font_obj.squish) or 1
			local font_scale = (font_obj and font_obj.FONTSCALE) or 0.12
			local height_scale = (font_obj and font_obj.TEXT_HEIGHT_SCALE) or 0.7
			local text_w = (font_face and font_face.getWidth and font_face:getWidth(node.config.text))
				or (string.len(node.config.text) * 12)
			local text_h = (font_face and font_face.getHeight and font_face:getHeight()) or 20
			local px_w = text_w * squish * scale * G.TILESCALE * font_scale
			local px_h = text_h * scale * G.TILESCALE * font_scale * height_scale
			if node.config.vert then px_w, px_h = px_h, px_w end
			node_t.x, node_t.y = _T.x, _T.y
			node_t.w = px_w / (G.TILESIZE * G.TILESCALE)
			node_t.h = px_h / (G.TILESIZE * G.TILESCALE)

			node.content_dimensions = node.content_dimensions or {}
			node.content_dimensions.w = _T.w
			node.content_dimensions.h = _T.h
			node:set_values(node_t, recalculate)
		elseif node.ui_kind == G.UI.BOX or node.ui_kind == G.UI.OBJECT then
			node.content_dimensions = node.content_dimensions or {}
			node.content_dimensions.w = node_t.w
			node.content_dimensions.h = node_t.h
			node:set_values(node_t, recalculate)
		end
		return node_t.w, node_t.h
	end

	-- Containers lay out like a column: children stack downward until an R
	-- (row) child breaks the line.
	for pass = 1, 2 do
		local over_maxw = node.config.maxw and content.w > node.config.maxw
		local over_maxh = node.config.maxh and content.h > node.config.maxh
		if pass == 1 or (pass == 2 and (over_maxw or over_maxh)) then
			-- Second pass scales every child down to fit the binding constraint.
			local fac = _scale or 1
			if pass == 2 then
				local restriction = node.config.maxw or node.config.maxh
				fac = fac * restriction / (node.config.maxw and content.w or content.h)
			end

			node_t.x, node_t.y = _T.x, _T.y
			node_t.w = node.config.minw or 0
			node_t.h = node.config.minh or 0
			if node.ui_kind == G.UI.ROOT then
				node_t.x, node_t.y = 0, 0
				node_t.w, node_t.h = node.config.minw or 0, node.config.minh or 0
			end
			content.x, content.y = node_t.x + padding, node_t.y + padding
			content.w, content.h = 0, 0

			for _, v in ipairs(node.children) do
				if getmetatable(v) == LayoutNode then
					if v.config and v.config.scale then v.config.scale = v.config.scale * fac end
					local child_w, child_h = self:calculate_xywh(v, content, recalculate, fac)
					if child_h and child_w then
						if v.ui_kind == G.UI.ROW then
							content.h = content.h + child_h + padding
							content.y = content.y + child_h + padding
							if child_w + padding > content.w then content.w = child_w + padding end
							if v.config and v.config.emboss then
								content.h = content.h + v.config.emboss
								content.y = content.y + v.config.emboss
							end
						else
							content.w = content.w + child_w + padding
							content.x = content.x + child_w + padding
							if child_h + padding > content.h then content.h = child_h + padding end
							if v.config and v.config.emboss then
								content.h = content.h + v.config.emboss
							end
						end
					end
				end
			end
		end
	end

	node.content_dimensions = node.content_dimensions or {}
	node.content_dimensions.w = content.w + padding
	node.content_dimensions.h = content.h + padding
	node_t.w = math.max(content.w + padding, node_t.w)
	node_t.h = math.max(content.h + padding, node_t.h)
	node:set_values(node_t, recalculate)
	return node_t.w, node_t.h
end
end
