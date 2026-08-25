--[[ word_game/ui/trade.lua - The Card Marketplace overlay ]]

local widgets = require("word_game.ui.widgets")
local trade = require("word_game.model.trade")
local state = require("word_game.model.state")
local deck = require("word_game.model.cards.deck")
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

local function reset_session(rolled)
	offer = rolled
	session = {
		add_done = false,
		remove_done = true,
		added = nil,
		removed = nil,
		add_cost_bonus = 0,
		modified = {},
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
local TOKEN_COIN_SIZE = 0.26

local function token_coin_node()
	if not G or not G.TEXTURE_ATLASES or not G.TEXTURE_ATLASES.stickers then
		return nil
	end
	local sprite = Sprite(0, 0, TOKEN_COIN_SIZE, TOKEN_COIN_SIZE, G.TEXTURE_ATLASES.stickers, { x = 3, y = 1 })
	sprite.states.drag.can = false
	sprite.states.hover.can = false
	sprite.states.collide.can = false
	sprite.states.click.can = false
	return { n = G.UI.OBJECT, config = { object = sprite, w = TOKEN_COIN_SIZE, h = TOKEN_COIN_SIZE } }
end

local function action_button_label_nodes(label, cost)
	local nodes = {
		{ n = G.UI.TEXT, config = {
			text = label .. " " .. tostring(cost),
			scale = BUTTON_LABEL_SCALE,
			font = alpha_button_font(),
			colour = G.C.UI.BUTTON_TEXT,
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
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = action_button_label_nodes(label, cost) },
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
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
			action_button(item, "add", M.session_add_cost(session_state), G.C.BLUE, false),
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
			action_button(item, "remove", 20, G.C.RED, remove_disabled),
		}},
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.14 }, nodes = { face_node(item) } },
	}
	local desc = modifier_description_node(item)
	if desc then
		column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.1 }, nodes = { desc } }
	end
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "modifier", 30, G.C.GOLD, modify_disabled),
	}}
	return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.28, minw = G.CARD_W + 0.7 }, nodes = column_nodes }
end

local function token_balance_node()
	local balance = state.tokens()
	return { n = G.UI.ROW, config = { align = "cm", padding = 0.08, r = 0.16,
		colour = G.C.BLACK or { 0.05, 0.04, 0.03, 1 }, shadow = true }, nodes = {
		{ n = G.UI.TEXT, config = {
			text = "TOKENS: " .. tostring(balance),
			scale = 0.42,
			colour = G.C.GOLD,
			shadow = true,
		}},
	}}
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
		minh = 2.9 * G.CARD_H,
		minw = 3.8 * G.CARD_W,
	}, nodes = cards }
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
		{ n = G.UI.COLUMN, config = {
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
		}},
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
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.12 }, nodes = {
			{ n = G.UI.TEXT, config = { text = "CARD MARKETPLACE", scale = 0.5, colour = G.C.GOLD, shadow = true } },
		}},
		token_balance_node(),
		{ n = G.UI.ROW, config = { minh = 0.08 }, nodes = {} },
		card_row(add.letters, "market", session.add_done, session),
		{ n = G.UI.ROW, config = { minh = 0.1 }, nodes = {} },
		status_or_skip(false, nil, "alpha_trade_skip_add"),
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

refresh_overlay = function()
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
	open_overlay()
end

function M.on_pick(e)
	if flyer then return end
	local ref = e and e.config and e.config.ref_table
	local item = ref and ref.item or ref
	local action = ref and ref.action or "add"
	if not item or not session then return end
	if action == "remove" and session.removed then return end
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
		trade.sync_offer_cards(offer)
	elseif action == "modifier" then
		session.modified[item] = true
	end
	refresh_overlay()
end

function M.on_skip_add()
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
