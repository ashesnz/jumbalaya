--[[ word_game/ui/trade.lua - The Card Marketplace overlay ]]

local widgets = require("word_game.ui.widgets")
local trade = require("word_game.model.trade")
local state = require("word_game.model.state")
local deck = require("word_game.model.cards.deck")
local DissolveFX = require("app.effects.dissolve_fx")
local Layout = require("word_game.ui.layout")

local M = {}
local unpack_nodes = table.unpack or unpack
local offer
local session
local standalone = false
local flyer
local flyer_callback
local FLY_TIME = 0.65
local ADD_COST_STEP = 10
local transform_item

local function reset_session(rolled)
	offer = rolled
	session = {
		add_done = false,
		remove_done = true,
		added = nil,
		removed = nil,
		add_cost_bonus = 0,
		modified = {},
		removing = {},
	}
	if rolled and rolled.showdown and not rolled.remove then
		session.remove_done = true
	end
end

function M.session_add_cost(session_state)
	return trade.ACTION_COSTS.add + (session_state and session_state.add_cost_bonus or 0)
end

local function make_face_card(item, w, h)
	if not G.GAME or not G.P_CARDS or not deck.letter_center() then
		return nil
	end
	if not item or not item.letter then return nil end
	local front = deck.front(item.letter, item.color)
	if not front then return nil end
	local card = Card(0, 0, w, h, front, deck.letter_center(), {
		bypass_discovery_center = true,
		bypass_discovery_ui = true,
		bypass_lock = true,
	})
	card.created_on_pause = true
	card.states.drag.can = false
	card.states.collide.can = false
	card.states.hover.can = false
	card.states.click.can = false
	deck.tag_card(card, item.letter, item.color)
	card.T.r = 0
	return card
end

local function face_node(item)
	if item.flying then
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W, minh = G.CARD_H }, nodes = {} }
	end
	-- A removed card whose last deck copy is gone stays gone: empty slot.
	if item.mode == "remove" and not trade.item_in_deck(item) then
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W, minh = G.CARD_H }, nodes = {} }
	end
	local w, h = G.CARD_W, G.CARD_H
	local card = make_face_card(item, w, h)
	item.market_card = card
	if card then
		return { n = G.UI.OBJECT, config = { object = card, w = w, h = h } }
	end
	return { n = G.UI.TEXT, config = {
		text = item and item.letter or "?",
		scale = 0.8,
		colour = G.C.WHITE,
		shadow = true,
	}}
end

local BUTTON_LABEL_SCALE = 0.38
local MODIFIER_TEXT_SCALE = 0.30
local MODIFIER_LINE_CHARS = 38
local TOKEN_COIN_W = 0.24

-- The coin atlas is a single non-square image, so the sprite height must be
-- derived from the image ratio or the coin renders squashed.
local function token_coin_node()
	local atlas = G and G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.coin
	if not atlas or not atlas.image then
		return nil
	end
	local pw, ph = atlas.px, atlas.py
	if not pw or not ph then
		if not atlas.image.getDimensions then return nil end
		pw, ph = atlas.image:getDimensions()
	end
	local w = TOKEN_COIN_W
	local h = w * (ph / pw)
	local sprite = Sprite(0, 0, w, h, atlas, { x = 0, y = 0 })
	sprite.states.drag.can = false
	sprite.states.hover.can = false
	sprite.states.collide.can = false
	sprite.states.click.can = false
	return { n = G.UI.OBJECT, config = { object = sprite, w = w, h = h } }
end

local function action_button_label_nodes(label, cost)
	local nodes = {
		{ n = G.UI.TEXT, config = {
			text = label,
			scale = BUTTON_LABEL_SCALE,
			font = alpha_button_font(),
			colour = G.C.UI.BUTTON_TEXT,
			shadow = true,
		}},
		{ n = G.UI.TEXT, config = {
			text = tostring(cost),
			scale = BUTTON_LABEL_SCALE,
			font = alpha_button_font(),
			colour = G.C.GOLD or G.C.UI.BUTTON_TEXT,
			shadow = true,
		}},
	}
	local coin = token_coin_node()
	if coin then
		nodes[#nodes + 1] = coin
	end
	return nodes
end

local function wrap_description(text, max_chars)
	max_chars = max_chars or MODIFIER_LINE_CHARS
	local words = {}
	for word in (text or ""):gmatch("%S+") do
		words[#words + 1] = word
	end
	local lines, current = {}, ""
	for _, word in ipairs(words) do
		local candidate = current == "" and word or (current .. " " .. word)
		if #candidate > max_chars and current ~= "" then
			lines[#lines + 1] = current
			current = word
		else
			current = candidate
		end
	end
	if current ~= "" then
		lines[#lines + 1] = current
	end
	return lines
end

local function action_button(item, action, cost, colour, disabled)
	local ref = { item = item, action = action }
	local label = action == "modifier" and "Modify" or (action:gsub("^%l", string.upper))
	return { n = G.UI.ROW, config = {
		align = "cm", padding = 0.12, r = 0.18, minw = G.CARD_W + 0.45, minh = 0.62,
		hover = not disabled, button = disabled and nil or "alpha_trade_pick", ref_table = ref, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or colour or G.C.UI.BUTTON,
	        hover_colour = G.C.UI.BUTTON_HOVER, shadow = true, emboss = 0.1, no_jiggle = true,
	    }, nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.05 }, nodes = action_button_label_nodes(label, cost) },
	}}
end

local function modifier_description_node(item)
	local text = deck.modifier_description(item and item.letter)
	if not text then return nil end
	local lines = wrap_description(text)
	local line_nodes = {}
	for _, line in ipairs(lines) do
		line_nodes[#line_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = line,
				scale = MODIFIER_TEXT_SCALE,
				font = alpha_button_font(),
				colour = G.C.UI.TEXT_LIGHT or G.C.UI.BUTTON_TEXT,
				shadow = true,
			}},
		}}
	end
	return { n = G.UI.COLUMN, config = {
		align = "cm",
		padding = 0.04,
		minw = G.CARD_W + 0.35,
		minh = math.max(0.5, #lines * 0.28),
	}, nodes = line_nodes }
end

local function action_column(item, mode, done, session_state)
	local in_deck = trade.item_in_deck(item)
	local already_modified = item.card and deck.is_modified(item.card)
	local modify_disabled = not in_deck
		or session_state.modified[item]
		or already_modified
	local remove_disabled = not in_deck
	local column_nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.14 }, nodes = { face_node(item) } },
	}
	-- No card left to describe: drop the modifier text along with the face.
	local desc = nil
	if item.mode ~= "remove" or trade.item_in_deck(item) then
		desc = modifier_description_node(item)
	end
	if desc then
		column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.1 }, nodes = { desc } }
	end
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "add", M.session_add_cost(session_state), G.C.BLUE, false),
	}}
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "remove", 20, G.C.RED, remove_disabled),
	}}
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "modifier", 30, G.C.GOLD, modify_disabled),
	}}
	return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.28, minw = G.CARD_W + 0.7 }, nodes = column_nodes }
end

local function card_row(items, mode, done, session_state)
	local cards = {}
	for _, item in ipairs(items or {}) do
		cards[#cards + 1] = action_column(item, mode, done, session_state)
		cards[#cards + 1] = { n = G.UI.COLUMN, config = { minw = 0.5 }, nodes = {} }
	end
	if #cards > 0 then
		cards[#cards] = nil
	end
	return { n = G.UI.ROW, config = {
		align = "cm",
		padding = 0.12,
		minh = 3.4 * G.CARD_H,
		minw = 3.8 * G.CARD_W,
	}, nodes = cards }
end

local function close_button_node(skip_func)
	return { n = G.UI.COLUMN, config = {
		align = "cm", minw = 2.2, minh = 0.5, r = 0.18, padding = 0.22,
		hover = true, colour = G.C.ORANGE, hover_colour = G.C.UI.BUTTON_HOVER,
		button = skip_func, shadow = true, emboss = 0.1, no_jiggle = true,
	}, nodes = {
		{ n = G.UI.TEXT, config = {
			text = "Close",
			scale = 0.35,
			font = alpha_button_font(),
			colour = G.C.UI.BUTTON_TEXT,
			shadow = true,
		}},
	}}
end

local function status_or_skip(done, done_text, skip_func)
	if done then
		return { n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = done_text,
				scale = 0.28,
				colour = G.C.GOLD,
				shadow = true,
			}},
		}}
	end
	return { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		close_button_node(skip_func)
	}}
end

local open_overlay
local refresh_overlay

open_overlay = function()
	G.SETTINGS.paused = true
	G.FUNCS.show_overlay({
		definition = M.definition(),
		config = { no_esc = true, offset = { x = 0, y = 0 }, no_jiggle = true },
	})
end

local function marketplace_content_nodes()
	trade.sync_offer_cards(offer)
	local add = offer.add or offer
	local nodes = {
		-- Red cross close button, top right of the modal.
		{ n = G.UI.ROW, config = { align = "cr", minw = 3.8 * G.CARD_W }, nodes = {
			{ n = G.UI.COLUMN, config = {
				align = "cm", minw = 0.72, minh = 0.72, r = 0.16, padding = 0.1,
				hover = true, colour = G.C.RED, hover_colour = G.C.UI.BUTTON_HOVER,
				button = "alpha_trade_skip_add", shadow = true, emboss = 0.12, no_jiggle = true,
			}, nodes = {
				{ n = G.UI.TEXT, config = {
					text = "X",
					scale = 0.62,
					font = alpha_button_font(),
					colour = G.C.WHITE,
					shadow = true,
				}},
			}},
		}},
		-- Push the cards/text/buttons down from the cross button.
		{ n = G.UI.ROW, config = { minh = 50 / (G.TILESIZE or 64) }, nodes = {} },
		card_row(add.letters, "market", session.add_done, session),
	}

	if offer.showdown then
		local remove = offer.remove
		nodes[#nodes + 1] = { n = G.UI.ROW, config = { minh = 0.12 }, nodes = {} }
		nodes[#nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.03 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "Remove a card from your pack",
				scale = 0.3,
				colour = G.C.RED,
				shadow = true,
			}},
		}}
		if remove and remove.letters and #remove.letters > 0 then
			nodes[#nodes + 1] = card_row(remove.letters, "remove", session.remove_done)
			nodes[#nodes + 1] = status_or_skip(
				session.remove_done,
				session.removed == "skipped" and "Remove skipped" or "Card removed",
				"alpha_trade_skip_remove"
			)
		else
			nodes[#nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = "No cards available to remove",
					scale = 0.28,
					colour = G.C.UI.TEXT_LIGHT,
					shadow = true,
				}},
			}}
		end
	end

	return nodes
end

local function marketplace_body_definition()
	return {
		n = G.UI.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = marketplace_content_nodes(),
	}
end

-- True when the token balance is lower than the cheapest action still
-- available on the board (Add is always offered; Remove/Modify only count
-- while an offered card is in the deck and eligible).
local function cannot_afford_anything()
	if not session or not offer then return false end
	local balance = state.tokens()
	local letters = (offer.add or offer).letters or {}
	local any_in_deck = false
	local modify_available = false
	for _, item in ipairs(letters) do
		if trade.item_in_deck(item) then
			any_in_deck = true
			if not session.modified[item]
				and not (item.card and deck.is_modified(item.card)) then
				modify_available = true
			end
			break
		end
	end
	local min_cost = M.session_add_cost(session)
	if any_in_deck then
		min_cost = math.min(min_cost, trade.ACTION_COSTS.remove)
		if modify_available then
			min_cost = math.min(min_cost, trade.ACTION_COSTS.modifier)
		end
	end
	return balance < min_cost
end

refresh_overlay = function()
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	if not G.OVERLAY_MENU then
		open_overlay()
		return
	end
	local host = G.OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	if not host or not host.config then
		open_overlay()
		return
	end
	if host.config.object and host.config.object.remove then
		host.config.object:remove()
	end
	host.config.object = LayoutView{
		definition = marketplace_body_definition(),
		config = { offset = { x = 0, y = 0 }, align = "cm", parent = host },
	}
	G.OVERLAY_MENU:recalculate()
end

function M.definition()
	if not offer then
		reset_session(trade.roll_offer())
	elseif not session then
		reset_session(offer)
	end

	return build_generic_options({
		minw = 12,
		padding = 0.35,
		bg_colour = G.C.CLEAR,
		outline_colour = G.C.CLEAR,
		colour = G.C.CLEAR,
		contents = {
			{ n = G.UI.OBJECT, config = {
				id = "trade_marketplace_body",
				object = LayoutView{
					definition = marketplace_body_definition(),
					config = { offset = { x = 0, y = 0 }, align = "cm" },
				},
			}},
		},
		no_back = true,
	})
end

local function close_menu()
	offer = nil
	session = nil
	flyer = nil
	flyer_callback = nil
	transform_item = nil
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
end

local function continue_run()
	offer = nil
	session = nil
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.continue_after_dealer()
		return
	end
	close_menu()
end

local function finish_trade()
	trade.mark_used()
	if standalone then
		standalone = false
		close_menu()
		return
	end
	continue_run()
end

local function session_complete()
	return session and session.add_done and session.remove_done
end

local function refresh_or_finish()
	if session_complete() then
		finish_trade()
		return
	end
	refresh_overlay()
end

local function fail(text)
	spawn_attention({
		scale = 0.7,
		text = tostring(text),
		hold = 1.4,
		align = "cm",
		major = G.ROOM_ATTACH,
		colour = G.C.RED,
	})
end

local function deck_target_px()
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	if G.deck and G.deck.T then
		local t = G.deck.T
		return (t.x + (t.w or 0) * 0.5) * ts, (t.y + (t.h or 0) * 0.5) * ts
	end
	local rect = Layout.deck_rect()
	return (rect.x + rect.w * 0.5) * ts, (rect.y + rect.h * 0.5) * ts
end

local function room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

local function draw_flyer_card(item, x, y, rot, alpha)
	local front = item and deck.front(item.letter, item.color)
	if not front then return end
	local atlas = G.TEXTURE_ATLASES and (G.TEXTURE_ATLASES[front.atlas] or G.TEXTURE_ATLASES["cards_" .. (G.SETTINGS.colourblind_option and 2 or 1)])
	if not atlas or not atlas.image then return end
	local pos = front.pos or { x = 0, y = 0 }
	local pw, ph = atlas.px or 71, atlas.py or 95
	local iw, ih = atlas.image:getDimensions()
	local quad = love.graphics.newQuad(pos.x * pw, pos.y * ph, pw, ph, iw, ih)
	local size = math.max(30, (G.CARD_W or 1) * (G.TILESCALE or 1) * (G.TILESIZE or 1))
	love.graphics.setColor(1, 1, 1, alpha or 1)
	love.graphics.draw(atlas.image, quad, x, y, rot or 0, size / pw, size / ph, pw * 0.5, ph * 0.5)
end

local function start_card_fly(item, callback, start_x, start_y)
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local sx, sy = start_x, start_y
	if not sx or not sy then
		local card = item and item.market_card
		local transform = card and card.T
		sx = transform and (transform.x + (transform.w or G.CARD_W) * 0.5) * ts
		sy = transform and (transform.y + (transform.h or G.CARD_H) * 0.5) * ts
	end
	if not sx or not sy then
		local room = G.ROOM and G.ROOM.T
		sx = ((room and room.w or G.TILE_W or 20) * 0.5) * ts
		sy = ((room and room.h or G.TILE_H or 11) * 0.45) * ts
	end
	local ex, ey = deck_target_px()
	flyer = {
		item = item,
		t = 0,
		sx = sx,
		sy = sy,
		ex = ex,
		ey = ey,
		rot = 0,
		landed = false,
	}
	flyer_callback = callback
end

function M.is_flying()
	return flyer ~= nil
end

--- Painted just before the overlay menu each frame while the marketplace is
--- open: dims the room, then stretches the Marketplace art edge-to-edge over
--- the modal window itself (measured live from the overlay node tree, so it
--- always matches the modal's rendered size).
function M.backdrop_pass()
	if not offer or not G.OVERLAY_MENU then return end
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.marketplace_bg
	if not atlas or not atlas.image or not love.graphics or not love.graphics.draw then return end
	local room = G.ROOM and G.ROOM.T
	if not room then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local iw, ih = atlas.image:getDimensions()
	local rw = room.w * ts
	local rh = room.h * ts

	-- Modal window = outer box around the body: body OBJECT node -> contents
	-- ROW -> panel COLUMN -> outline ROW. Fall back to the whole room.
	local dx, dy, dw, dh = 0, 0, rw, rh
	local host = nil
	if G.OVERLAY_MENU.find_node_by_id then
		host = G.OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	end
	local outer = host and host.parent and host.parent.parent and host.parent.parent.parent
	local t = outer and outer.VT
	if t and t.w and t.h and t.w > 0 and t.h > 0 then
		dx, dy = t.x * ts, t.y * ts
		dw, dh = t.w * ts, t.h * ts
	end

	local prev_shader = love.graphics.getShader and love.graphics.getShader()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()
	-- Dim the table behind the modal; the art sits on top in the modal frame.
	love.graphics.setColor(0, 0, 0, 0.45)
	love.graphics.rectangle("fill", 0, 0, rw, rh)
	love.graphics.setColor(1, 1, 1, 1)
	-- Aspect-preserving "cover" fit: uniform scale so the art is never
	-- stretched, cropped to stay inside the modal window.
	local scale = math.max(dw / iw, dh / ih)
	local img_w, img_h = iw * scale, ih * scale
	local ix = dx + (dw - img_w) * 0.5
	local iy = dy + (dh - img_h) * 0.5
	local psx, psy, psw, psh = nil, nil, nil, nil
	if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor then
		local x1, y1 = love.graphics.transformPoint(dx, dy)
		local x2, y2 = love.graphics.transformPoint(dx + dw, dy + dh)
		psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(
			math.min(x1, x2), math.min(y1, y2),
			math.abs(x2 - x1), math.abs(y2 - y1))
	end
	love.graphics.draw(atlas.image, ix, iy, 0, scale, scale)
	if love.graphics.setScissor then
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	end
	love.graphics.pop()
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	elseif love.graphics.setShader then
		love.graphics.setShader()
	end
	if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
end

local TRANSFORM_DISSOLVE_TIME = 0.7
local TRANSFORM_MATERIALIZE_TIME = 0.6

local BURN_DISSOLVE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.MUTED_GREY }
local BURN_MATERIALIZE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.WHITE }

local function apply_black_market_face(card, item)
	local front = deck.front(item.letter, "black")
	if front and card.apply_face then
		deck.tag_card(card, item.letter, "black")
		card:apply_face(front, false)
	end
	item.color = "black"
end

local function finish_transform_fx()
	local item = transform_item
	transform_item = nil
	if not item then return end
	local card = item.market_card
	if card then
		card.dissolve = 0
		card.dissolve_wipe = 0
	end
	item.color = "black"
	play_sfx("card_slide1", 1.05, 0.9)
	if G.OVERLAY_MENU then
		refresh_overlay()
	end
end

local function start_transform_fx(item)
	local card = item.market_card
	if not card then
		item.color = "black"
		refresh_overlay()
		return
	end

	transform_item = item
	card.states.visible = true
	card.dissolve = 0
	card.dissolve_wipe = 0
	card.dissolve_colours = BURN_DISSOLVE_COLOURS

	play_sfx("whoosh2", math.random() * 0.2 + 0.9, 0.5)
	play_sfx("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.9, 0.5)

	-- Phase 1: red card burns away like crumpling paper (fibrous noise dissolve).
	DissolveFX.run(card, {
		mode = "out",
		duration = TRANSFORM_DISSOLVE_TIME,
		wipe = 0,
		pulse = true,
		colours = BURN_DISSOLVE_COLOURS,
		fade = { delay = 0.7 * TRANSFORM_DISSOLVE_TIME, duration = 0.3 * TRANSFORM_DISSOLVE_TIME },
		on_finish = function()
			apply_black_market_face(card, item)
			card.dissolve = 1
			card.dissolve_wipe = 0
			card.dissolve_colours = BURN_MATERIALIZE_COLOURS
			-- Phase 2: black card re-forms from the same burnt-paper dissolve, reversed.
			DissolveFX.run(card, {
				mode = "in",
				duration = TRANSFORM_MATERIALIZE_TIME,
				wipe = 0,
				pulse = true,
				colours = BURN_MATERIALIZE_COLOURS,
				particle = { timer = 0.025, scale = 0.25, speed = 3, lifespan = 0.7 },
				on_finish = finish_transform_fx,
			})
		end,
	})
end

local function start_remove_dissolve(item)
	local card = item.market_card
	if not card then
		trade.sync_offer_cards(offer)
		refresh_overlay()
		return
	end
	session.removing[item] = true
	play_sfx("whoosh2", math.random() * 0.2 + 0.9, 0.5)
	play_sfx("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.9, 0.5)
	DissolveFX.run(card, {
		duration = 0.7,
		colours = { G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD },
		pulse = true,
		remove = true,
		on_finish = function()
			item.market_card = nil
			if session then
				session.removing[item] = nil
			end
			trade.sync_offer_cards(offer)
			if G.OVERLAY_MENU then
				refresh_overlay()
			end
		end,
	})
end

function M.is_transforming()
	return transform_item ~= nil
end

function M.draw_pass()
	if not flyer or not G.ROOM or not love.graphics then return end
	local dt = math.min(0.05, love.timer and love.timer.getDelta() or 0.016)
	flyer.t = flyer.t + dt
	local u = math.min(1, flyer.t / FLY_TIME)
	local eased = 1 - (1 - u) * (1 - u)
	local arc = math.sin(u * math.pi) * 0.8 * (G.TILESIZE or 1) * (G.TILESCALE or 1)
	local x = flyer.landed and flyer.ex or flyer.sx + (flyer.ex - flyer.sx) * eased
	local y = flyer.landed and flyer.ey or flyer.sy + (flyer.ey - flyer.sy) * eased - arc
	flyer.rot = flyer.landed and flyer.rot or (math.pi * 0.08) * math.sin(u * math.pi)

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.push()
	love.graphics.setShader()
	room_translate()
	draw_flyer_card(flyer.item, x, y, flyer.rot, 1)
	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)

	if u >= 1 and not flyer.landed then
		local done = flyer_callback
		flyer.landed = true
		flyer_callback = nil
		flyer = nil
		if done then done() end
	end
end

function M.open()
	standalone = true
	reset_session(trade.roll_offer())
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	open_overlay()
end

function M.open_then_dealer()
	standalone = false
	local alpha = state.get()
	if (alpha and alpha.trade_used_this_hand) or not trade.can_use() then
		continue_run()
		return
	end
	reset_session(trade.roll_offer())
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	open_overlay()
end

function M.on_pick(e)
	if flyer or transform_item then return end
	local ref = e and e.config and e.config.ref_table
	local item = ref and ref.item or ref
	local action = ref and ref.action or "add"
	if not item or not session then return end
	if action == "remove" and (session.removed or session.removing[item]) then return end
	if action == "modifier" and session.modified[item] then return end

	local cost = action == "add" and M.session_add_cost(session) or nil
	local ok, result = trade.apply(item, { action = action, cost = cost, defer_used = true })
	if not ok then
		fail(result)
		return
	end

	if action == "add" then
		if WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.spend_fly then
			WORD_GAME.TokenReward.spend_fly(cost)
		elseif WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.spend_tokens_display then
			WORD_GAME.TableDeck.spend_tokens_display(cost)
		end
		local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
		local card = item.market_card
		local transform = card and card.T
		local start_x = transform and (transform.x + (transform.w or G.CARD_W) * 0.5) * ts
		local start_y = transform and (transform.y + (transform.h or G.CARD_H) * 0.5) * ts
		item.flying = true
		refresh_overlay()
		start_card_fly(item, function()
			item.flying = false
			session.add_cost_bonus = (session.add_cost_bonus or 0) + ADD_COST_STEP
			play_sfx("card_slide1", 1.05, 0.75)
			refresh_overlay()
		end, start_x, start_y)
		return
	end

	play_sfx("card_slide1", 0.9, 0.8)
	if action == "remove" then
		start_remove_dissolve(item)
		return
	elseif action == "modifier" then
		session.modified[item] = true
		start_transform_fx(item)
		return
	end
	refresh_overlay()
end

function M.on_skip_add()
	if flyer or transform_item then return end
	if not session or session.add_done then
		if session and session_complete() then finish_trade() end
		return
	end
	session.add_done = true
	session.added = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	refresh_or_finish()
end

function M.on_skip_remove()
	if flyer or transform_item then return end
	if not session or session.remove_done then
		if session and session_complete() then finish_trade() end
		return
	end
	session.remove_done = true
	session.removed = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	refresh_or_finish()
end

return M
