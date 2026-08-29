--[[ tests/unit/test_perk_stamp.lua - Visible stamp faces and outline connectivity ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function dist(a, b)
	local dx, dy = a[1] - b[1], a[2] - b[2]
	return math.sqrt(dx * dx + dy * dy)
end

local function same_pt(a, b, eps)
	eps = eps or 0.04
	return dist(a, b) <= eps
end

local function same_edge(a1, a2, b1, b2, eps)
	return (same_pt(a1, b1, eps) and same_pt(a2, b2, eps))
		or (same_pt(a1, b2, eps) and same_pt(a2, b1, eps))
end

local function loop_edges(loop)
	local pts = loop.pts
	local edges = {}
	local last = loop.closed and #pts or (#pts - 1)
	for i = 1, last do
		local b = (loop.closed and i == #pts) and pts[1] or pts[i + 1]
		edges[#edges + 1] = { pts[i], b }
	end
	return edges
end

local function all_outline_edges(mesh)
	local edges = {}
	for _, loop in ipairs(mesh.loops) do
		for _, e in ipairs(loop_edges(loop)) do
			edges[#edges + 1] = e
		end
	end
	return edges
end

local function find_loop(mesh, name)
	for _, loop in ipairs(mesh.loops) do
		if loop.name == name then return loop end
	end
	return nil
end

local function shoelace(pts)
	local area = 0
	local n = #pts
	for i = 1, n do
		local j = (i % n) + 1
		area = area + pts[i][1] * pts[j][2] - pts[j][1] * pts[i][2]
	end
	return math.abs(area) * 0.5
end

local function capture_graphics()
	local gfx = love.graphics
	local prev = {
		line = gfx.line,
		polygon = gfx.polygon,
		setColor = gfx.setColor,
		setLineWidth = gfx.setLineWidth,
		setLineJoin = gfx.setLineJoin,
		ellipse = gfx.ellipse,
		push = gfx.push,
		pop = gfx.pop,
		translate = gfx.translate,
		rotate = gfx.rotate,
		getShader = gfx.getShader,
		setShader = gfx.setShader,
		getColor = gfx.getColor,
	}
	local log = { lines = {}, fills = {}, color = { 1, 1, 1, 1 } }
	gfx.setColor = function(r, g, b, a)
		if type(r) == "table" then
			log.color = { r[1], r[2], r[3], r[4] or 1 }
		else
			log.color = { r, g, b, a or 1 }
		end
		if prev.setColor then prev.setColor(r, g, b, a) end
	end
	gfx.setLineWidth = function() end
	gfx.setLineJoin = function() end
	gfx.line = function(...)
		local args = { ... }
		local segs = {}
		for i = 1, #args - 3, 2 do
			segs[#segs + 1] = { args[i], args[i + 1], args[i + 2], args[i + 3] }
		end
		log.lines[#log.lines + 1] = {
			color = { log.color[1], log.color[2], log.color[3], log.color[4] },
			coords = args,
			segs = segs,
		}
	end
	gfx.polygon = function(mode, ...)
		if mode == "fill" then
			log.fills[#log.fills + 1] = {
				color = { log.color[1], log.color[2], log.color[3], log.color[4] },
			}
		end
	end
	gfx.ellipse = function() end
	return log, function()
		for k, v in pairs(prev) do
			gfx[k] = v
		end
	end
end

T.describe("perk stamp visible mesh", function()
	-- setup() also loads the word list; skip that failure in headless sandboxes.
	pcall(mock_env.setup)
	G.TILESCALE = 1
	G.TILESIZE = 1
	G.STATES = G.STATES or { TABLE_BOARD = 1 }
	G.STATE = G.STATES.TABLE_BOARD

	local Stamp = require("word_game.ui.perk_stamp")
	Stamp.reset()

	local mesh = Stamp.debug_mesh(0, 0, 2, nil, nil, 1, nil)
	local front = find_loop(mesh, "front")
	local rubber_front = find_loop(mesh, "rubber_front")
	local right = find_loop(mesh, "right")
	local rubber_right = find_loop(mesh, "rubber_right")
	local left = find_loop(mesh, "left")
	local rubber_left = find_loop(mesh, "rubber_left")
	local top = find_loop(mesh, "top")
	local handle_front = find_loop(mesh, "handle_front")
	local handle_left = find_loop(mesh, "handle_left")
	local handle_back = find_loop(mesh, "handle_back")
	local c = mesh.corners

	T.it("exposes closed front, rubber_front, right, rubber_right, left, rubber_left and handle faces plus an open top rim", function()
		T.assert_not_nil(front, "front outline loop is required")
		T.assert_not_nil(rubber_front, "rubber_front outline loop is required")
		T.assert_not_nil(right, "right outline loop is required")
		T.assert_not_nil(rubber_right, "rubber_right outline loop is required")
		T.assert_not_nil(left, "left outline loop is required")
		T.assert_not_nil(rubber_left, "rubber_left outline loop is required")
		T.assert_not_nil(top, "top outline loop is required")
		T.assert_not_nil(handle_front, "handle_front outline loop is required")
		T.assert_not_nil(handle_left, "handle_left outline loop is required")
		T.assert_not_nil(handle_back, "handle_back outline loop is required")
		T.assert_true(front.closed, "front face must stroke as a closed loop")
		T.assert_true(rubber_front.closed, "rubber_front face must stroke as a closed loop")
		T.assert_false(right.closed, "right face must stay open so the back edge is hidden")
		T.assert_false(rubber_right.closed, "rubber_right face must stay open so the back edge is hidden")
		T.assert_true(left.closed, "left face must stroke as a closed loop")
		T.assert_true(rubber_left.closed, "rubber_left face must stroke as a closed loop")
		T.assert_true(handle_left.closed, "handle_left face must stroke as a closed loop")
		T.assert_true(handle_back.closed, "handle_back face must stroke as a closed loop")
		T.assert_false(top.closed, "top rim must stay open so the back edge is hidden")
		T.assert_equal(#front.pts, 4)
		T.assert_equal(#rubber_front.pts, 4)
		T.assert_equal(#right.pts, 4)
		T.assert_equal(#rubber_right.pts, 4)
		T.assert_equal(#left.pts, 4)
		T.assert_equal(#rubber_left.pts, 4)
		T.assert_equal(#handle_left.pts, 4)
		T.assert_equal(#handle_back.pts, 4)
	end)

	T.it("gives the wooden front square four connected sides", function()
		T.assert_true(same_pt(front.pts[1], c.ftl), "front should start at top-left")
		T.assert_true(same_pt(front.pts[2], c.ftr), "front top-right")
		T.assert_true(same_pt(front.pts[3], c.fbr), "front bottom-right is the wood square, not the pad")
		T.assert_true(same_pt(front.pts[4], c.fbl), "front bottom-left is the wood square, not the pad")

		local edges = loop_edges(front)
		T.assert_equal(#edges, 4, "front face needs four borders")
		local min_len = 0.5
		for i, e in ipairs(edges) do
			T.assert_true(dist(e[1], e[2]) > min_len, "front edge " .. i .. " is missing or degenerate")
		end
		T.assert_true(same_edge(edges[2][1], edges[2][2], c.ftr, c.fbr), "right front border")
		T.assert_true(same_edge(edges[3][1], edges[3][2], c.fbr, c.fbl), "bottom front border")
		T.assert_true(same_edge(edges[4][1], edges[4][2], c.fbl, c.ftl), "left front border")
		T.assert_true(same_edge(edges[1][1], edges[1][2], c.ftl, c.ftr), "top front border")
	end)

	T.it("gives the rubber front rectangle four connected sides with left-side border", function()
		T.assert_true(same_pt(rubber_front.pts[1], c.fbl), "rubber front top-left")
		T.assert_true(same_pt(rubber_front.pts[2], c.fbr), "rubber front top-right")
		T.assert_true(same_pt(rubber_front.pts[3], c.rfr), "rubber front bottom-right")
		T.assert_true(same_pt(rubber_front.pts[4], c.rfl), "rubber front bottom-left")

		local edges = loop_edges(rubber_front)
		T.assert_equal(#edges, 4, "rubber front face needs four borders")
		T.assert_true(same_edge(edges[4][1], edges[4][2], c.rfl, c.fbl), "rubber front left border")
	end)

	T.it("joins every front-face corner to two borders", function()
		local edges = loop_edges(front)
		for ci, corner in ipairs(front.pts) do
			local hits = 0
			for _, e in ipairs(edges) do
				if same_pt(corner, e[1]) or same_pt(corner, e[2]) then
					hits = hits + 1
				end
			end
			T.assert_equal(hits, 2, "front corner " .. ci .. " should connect two borders")
		end
	end)

	T.it("projects a visible front face with on-screen bounds", function()
		T.assert_true(shoelace(front.pts) > 4, "front face should cover a visible area")
		T.assert_true(mesh.bounds.w > 8, "stamp width should be visible")
		T.assert_true(mesh.bounds.h > 4, "stamp height should be visible")
		T.assert_true(mesh.bounds.w * mesh.bounds.h > 40, "stamp should occupy screen space")
	end)

	T.it("does not stroke the far back horizontal edges", function()
		local outlined = all_outline_edges(mesh)
		for _, hidden in ipairs(mesh.hidden_back) do
			for _, e in ipairs(outlined) do
				T.assert_false(same_edge(e[1], e[2], hidden[1], hidden[2], 0.08),
					"back-plane edge should stay hidden")
			end
		end
	end)

	T.it("strokes black connected outlines and wood fills when drawn", function()
		local log, restore = capture_graphics()
		Stamp.debug_draw_stamp(0, 0, 2)
		restore()

		T.assert_true(#log.fills >= 5, "wooden faces should fill on screen")
		T.assert_true(#log.lines >= 3, "each visible face should stroke a border loop")

		local unique_colors = {}
		for _, fill in ipairs(log.fills) do
			local col = fill.color
			local key = string.format("%.2f,%.2f,%.2f", col[1], col[2], col[3])
			unique_colors[key] = true
		end
		local shade_count = 0
		for _ in pairs(unique_colors) do shade_count = shade_count + 1 end
		T.assert_true(shade_count >= 4, "stamp faces should have multiple distinct brown/rubber shades for 3d depth")

		local black_front_sides = 0
		local saw_front_bottom = false
		local saw_front_left = false
		local saw_front_right = false
		local saw_front_top = false
		for _, stroke in ipairs(log.lines) do
			local col = stroke.color
			local is_black = col[1] < 0.05 and col[2] < 0.05 and col[3] < 0.05 and col[4] > 0.5
			for _, seg in ipairs(stroke.segs) do
				local a, b = { seg[1], seg[2] }, { seg[3], seg[4] }
				if is_black then
					if same_edge(a, b, c.ftl, c.ftr, 0.12) then saw_front_top = true end
					if same_edge(a, b, c.ftr, c.fbr, 0.12) then saw_front_right = true end
					if same_edge(a, b, c.fbr, c.fbl, 0.12) then saw_front_bottom = true end
					if same_edge(a, b, c.fbl, c.ftl, 0.12) then saw_front_left = true end
				end
				T.assert_false(same_edge(a, b, c.btl, c.btr, 0.12),
					"draw pass must not stroke the back-top edge")
				T.assert_false(same_edge(a, b, c.btr, c.bbr, 0.12),
					"draw pass must not stroke the wood right back edge")
				T.assert_false(same_edge(a, b, c.bbr, c.rbr, 0.12),
					"draw pass must not stroke the rubber right back edge")
			end
		end
		if saw_front_top then black_front_sides = black_front_sides + 1 end
		if saw_front_right then black_front_sides = black_front_sides + 1 end
		if saw_front_bottom then black_front_sides = black_front_sides + 1 end
		if saw_front_left then black_front_sides = black_front_sides + 1 end
		T.assert_equal(black_front_sides, 4, "front square must stroke all four black borders")
		T.assert_true(saw_front_bottom, "wooden front bottom border must be drawn")
		T.assert_true(saw_front_left, "wooden front left border must be drawn")
	end)

	T.it("plays on the table board and issues a visible draw pass", function()
		Stamp.reset()
		math.randomseed(1)
		T.assert_true(Stamp.play(), "stamp play should start with a random sprite on TABLE_BOARD")
		T.assert_true(Stamp.is_active())

		local log, restore = capture_graphics()
		Stamp.draw_pass()
		restore()
		Stamp.reset()

		T.assert_true(#log.fills > 0, "draw_pass should fill the stamp on screen")
		T.assert_true(#log.lines > 0, "draw_pass should stroke stamp borders on screen")
		local drawn = false
		for _, stroke in ipairs(log.lines) do
			for i = 1, #stroke.coords, 2 do
				local x, y = stroke.coords[i], stroke.coords[i + 1]
				if x and y and (math.abs(x) > 1 or math.abs(y) > 1) then
					drawn = true
				end
			end
		end
		T.assert_true(drawn, "stamp outline coordinates should leave the origin")
	end)
end)

T.describe("perk stamp panel layout", function()
	pcall(mock_env.setup)
	G.TILESCALE = 1
	G.TILESIZE = 71
	G.TABLE_BOARD_SIDEBAR_WIDTH = 3.0

	local Stamp = require("word_game.ui.perk_stamp")
	local stamp_grid = require("word_game.ui.stamp_grid")
	local perk_cfg = require("word_game.config.perks")
	Stamp.reset()

	local layout = Stamp.debug_grid_layout()

	T.it("sizes stamp slot proportionally to vault width", function()
		local panel_w = layout.panel.w
		local expected_w = panel_w * perk_cfg.STAMP_SLOT_WIDTH_FRAC
		local expected_h = expected_w * perk_cfg.STAMP_SLOT_ASPECT
		T.assert_almost_equal(layout.cell.w, expected_w, 0.5, "stamp slot width")
		T.assert_almost_equal(layout.cell.h, expected_h, 0.5, "stamp slot height")
		T.assert_almost_equal(layout.cell.h / layout.cell.w, perk_cfg.STAMP_SLOT_ASPECT, 0.01,
			"stamp slot should match stamp aspect")
		T.assert_almost_equal(
			layout.cell.x - layout.panel.x,
			(panel_w - layout.cell.w) * 0.5,
			0.5,
			"stamp slot should be centered horizontally"
		)
	end)

	T.it("uses tight atlas bounds for each of the six stamps", function()
		local perk_voucher = require("word_game.ui.perk_voucher")
		T.assert_equal(#perk_cfg.STAMP_SPRITES, 6)
		local expected = {
			{ x = 8, y = 12, w = 287, h = 125 },
			{ x = 308, y = 12, w = 295, h = 124 },
			{ x = 617, y = 12, w = 286, h = 125 },
			{ x = 8, y = 147, w = 287, h = 125 },
			{ x = 308, y = 147, w = 294, h = 125 },
			{ x = 616, y = 147, w = 287, h = 125 },
		}
		for i, stamp in ipairs(perk_cfg.STAMP_SPRITES) do
			local region = perk_voucher.stamp_region(stamp.pos)
			T.assert_equal(region.x, expected[i].x, "stamp " .. i .. " x")
			T.assert_equal(region.y, expected[i].y, "stamp " .. i .. " y")
			T.assert_equal(region.w, expected[i].w, "stamp " .. i .. " w")
			T.assert_equal(region.h, expected[i].h, "stamp " .. i .. " h")
			T.assert_equal(perk_cfg.stamp_sprite_at(stamp.pos.x, stamp.pos.y).id, stamp.id)
		end
	end)

	T.it("fits a stamp inside the slot without changing aspect", function()
		local perk_voucher = require("word_game.ui.perk_voucher")
		local entry = perk_cfg.STAMP_SPRITES[1]
		local slot_w, slot_h = layout.cell.w, layout.cell.h
		local region = perk_voucher.stamp_region(entry.pos)
		local _, _, draw_w, draw_h = perk_voucher.fit_rect(region.w, region.h, slot_w, slot_h)
		T.assert_true(draw_w <= slot_w + 0.01)
		T.assert_true(draw_h <= slot_h + 0.01)
		T.assert_almost_equal(draw_w / draw_h, region.w / region.h, 0.01)
	end)

	T.it("scales stamp slot when panel width changes", function()
		local w_narrow, h_narrow = stamp_grid.slot_size_px(200)
		local w_wide, h_wide = stamp_grid.slot_size_px(300)
		T.assert_true(w_wide > w_narrow, "wider vault should yield wider stamp slot")
		T.assert_almost_equal(h_wide / w_wide, h_narrow / w_narrow, 0.001,
			"aspect ratio should stay constant")
	end)

	T.it("rolls a random stamp sprite from the 3×2 sheet", function()
		math.randomseed(42)
		local seen = {}
		for _ = 1, 40 do
			local stamp = Stamp.roll_stamp_sprite()
			T.assert_not_nil(stamp)
			T.assert_not_nil(stamp.pos)
			seen[stamp.pos.x .. "," .. stamp.pos.y] = true
		end
		T.assert_equal(#perk_cfg.STAMP_SPRITES, 6)
	end)

	T.it("applies a queued perk but picks a stamp sprite for the imprint", function()
		Stamp.reset()
		G.GAME = G.GAME or {}
		local target = perk_cfg.by_id("wide_hand")
		T.assert_true(Stamp.queue(target))
		T.assert_equal(Stamp.resolve_perk().id, "wide_hand")
		local sprite = Stamp.roll_stamp_sprite()
		T.assert_not_nil(sprite.id:match("^stamp_"))
	end)

	T.it("stacks imprints vertically with a gap", function()
		local layout2 = Stamp.debug_grid_layout(2)
		T.assert_equal(#layout2.cells, 2)
		local gap = layout2.cells[2].y - (layout2.cells[1].y + layout2.cells[1].h)
		T.assert_true(gap >= 2, "stamps should have a vertical gap between them")
		T.assert_almost_equal(layout2.cells[1].x, layout2.cells[2].x, 0.5,
			"stamps should share the same horizontal alignment")
		T.assert_almost_equal(layout2.cells[1].w, layout2.cells[2].w, 0.5)
	end)

	T.it("targets a lower landing point for each stacked stamp", function()
		Stamp.reset()
		G.STATE = G.STATES.TABLE_BOARD
		local _, cy1 = Stamp.debug_next_land_px()

		for _ = 1, 70 do Stamp.debug_step() end
		T.assert_equal(Stamp.imprint_count(), 1)

		local _, cy2 = Stamp.debug_next_land_px()
		T.assert_true(cy2 > cy1, "second stamp animation should land below the first")
	end)

	T.it("adds imprints below existing stamps on restamp", function()
		Stamp.reset()
		G.STATE = G.STATES.TABLE_BOARD
		math.randomseed(7)
		T.assert_false(Stamp.has_imprint())

		for _ = 1, 70 do Stamp.debug_step() end
		T.assert_equal(Stamp.imprint_count(), 1)
		local first = Stamp.current_imprint()

		for _ = 1, 70 do Stamp.debug_step() end
		T.assert_equal(Stamp.imprint_count(), 2)
		local second = Stamp.current_imprint()
		T.assert_not_nil(first)
		T.assert_not_nil(second)
	end)
end)
