--[[ word_game/ui/trade/init.lua - The Card Marketplace overlay ]]

local widgets = require("word_game.ui.widgets")
local trade = require("word_game.model.trade")
local state = require("word_game.model.state")
local deck = require("word_game.model.cards.deck")
local DissolveFX = require("app.effects.dissolve_fx")
local Layout = require("word_game.ui.layout")
local LetterPalette = require("word_game.config.letter_card_palette")
local trade_layout = require("word_game.ui.trade.layout")
local trade_fly = require("word_game.ui.trade.fly")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}
local unpack_nodes = table.unpack or unpack
local offer
local session
local standalone = false
local transform_item
local ADD_COST_STEP = 10
-- Marketplace cards render slightly smaller than table cards so the modal
-- contents fit comfortably inside the play-area-sized window.
local MARKET_CARD_SCALE = 0.82

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

function M.can_afford_action(action, session_state)
	local balance = state.tokens()
	if action == "add" then
		return balance >= M.session_add_cost(session_state)
	end
	if action == "remove" then
		return balance >= trade.ACTION_COSTS.remove
	end
	if action == "modifier" then
		return balance >= trade.ACTION_COSTS.modifier
	end
	return false
end

function M.is_action_disabled(action, item, session_state)
	if action == "add" then
		return not M.can_afford_action("add", session_state)
	end
	if action == "remove" then
		return not trade.item_in_deck(item) or not M.can_afford_action("remove", session_state)
	end
	if action == "modifier" then
		local already_modified = item.card and deck.is_modified(item.card)
		local modified_this_session = session_state
			and session_state.modified
			and session_state.modified[item]
		return not trade.item_in_deck(item)
			or modified_this_session
			or already_modified
			or not M.can_afford_action("modifier", session_state)
	end
	return true
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
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W * MARKET_CARD_SCALE, minh = G.CARD_H * MARKET_CARD_SCALE }, nodes = {} }
	end
	-- A card whose deck copy was removed this session stays gone: empty slot.
	if item.removed or (item.mode == "remove" and not trade.item_in_deck(item)) then
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W * MARKET_CARD_SCALE, minh = G.CARD_H * MARKET_CARD_SCALE }, nodes = {} }
	end
	local w, h = G.CARD_W * MARKET_CARD_SCALE, G.CARD_H * MARKET_CARD_SCALE
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
		align = "cm", padding = 0.12, r = 0.18, minw = G.CARD_W * MARKET_CARD_SCALE + 0.45, minh = 0.62,
		hover = not disabled, button = disabled and nil or "alpha_trade_pick", ref_table = ref, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or colour or G.C.UI.BUTTON,
	        hover_colour = G.C.UI.BUTTON_HOVER, shadow = true, emboss = 0.1, no_jiggle = true,
	    }, nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.05 }, nodes = action_button_label_nodes(label, cost) },
	}}
end

	local function modifier_description_node(item, placeholder)
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
				-- Placeholder keeps the same invisible ink (alpha 0) so the
				-- text still measures identically and the modal width never
				-- changes when a card is removed.
				colour = placeholder and G.C.CLEAR or (G.C.BLACK or { 0, 0, 0, 1 }),
				shadow = false,
			}},
		}}
	end
	-- Parchment chip so the black text stays readable on the artwork. The
	-- placeholder variant is fully transparent but reserves the same footprint
	-- so the modal keeps its size when a card is removed.
	return { n = G.UI.COLUMN, config = {
		align = "cm",
		padding = 0.08,
		minw = G.CARD_W * MARKET_CARD_SCALE + 0.35,
		minh = math.max(0.5, #lines * 0.28) + 0.12,
		r = 0.14,
		colour = placeholder and G.C.CLEAR or { 0.97, 0.93, 0.84, 1 },
		shadow = not placeholder and true or nil,
	}, nodes = line_nodes }
end

local function deck_count_node(item, placeholder)
	if not item or not item.letter then return nil end
	local count = deck.count_letters_in_deck(item.letter)
	local text = tostring(count) .. " in deck"
	return { n = G.UI.COLUMN, config = {
		align = "cm",
		padding = 0.08,
		minw = G.CARD_W * MARKET_CARD_SCALE + 0.35,
		minh = math.max(0.5, 0.28) + 0.12,
		r = 0.14,
		colour = placeholder and G.C.CLEAR or { 0.97, 0.93, 0.84, 1 },
		shadow = not placeholder and true or nil,
	}, nodes = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = text,
				scale = MODIFIER_TEXT_SCALE,
				font = alpha_button_font(),
				colour = placeholder and G.C.CLEAR or (G.C.BLACK or { 0, 0, 0, 1 }),
				shadow = false,
			}},
		}},
	}}
end

local function action_column(item, mode, done, session_state)
	local add_cost = M.session_add_cost(session_state)
	local add_disabled = M.is_action_disabled("add", item, session_state)
	local modify_disabled = M.is_action_disabled("modifier", item, session_state)
	local remove_disabled = M.is_action_disabled("remove", item, session_state)
	local column_nodes = {}
	local deck_count = deck_count_node(item)
	if deck_count then
		column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = { deck_count } }
	elseif item.letter then
		column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = { deck_count_node(item, true) } }
	end
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.03 }, nodes = { face_node(item) } }
	-- No card left to describe: keep an invisible placeholder so the modal
	-- window keeps its size.
	local desc = nil
	if not item.removed and (item.mode ~= "remove" or trade.item_in_deck(item)) then
		desc = modifier_description_node(item)
	elseif item.letter then
		desc = modifier_description_node(item, true)
	end
	if desc then
		column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.0 }, nodes = { desc } }
	end
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "add", add_cost, G.C.BLUE, add_disabled),
	}}
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "remove", 20, G.C.RED, remove_disabled),
	}}
	column_nodes[#column_nodes + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "modifier", 30, G.C.GOLD, modify_disabled),
	}}
	return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.28, minw = G.CARD_W * MARKET_CARD_SCALE + 0.7 }, nodes = column_nodes }
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
		minh = 3.4 * G.CARD_H * MARKET_CARD_SCALE,
		minw = 3.8 * G.CARD_W * MARKET_CARD_SCALE,
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
local rebuild_overlay
local finish_trade

--- Vertical offset (tiles) centreing the modal on the play-area felt so its
--- top edge lines up just above the timer and its bottom just below the hand,
--- then nudged up 20px.
local modal_offset_y = trade_layout.modal_offset_y
local modal_minh = trade_layout.modal_minh
local room_translate = trade_layout.room_translate

open_overlay = function()
	G.SETTINGS.paused = true
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.reset then
		WORD_GAME.PlayHoldRedraw.reset()
	end
	G.FUNCS.show_overlay({
		definition = M.definition(),
		config = { no_esc = true, offset = { x = 0, y = modal_offset_y() }, no_jiggle = true },
	})
end

local function marketplace_content_nodes()
	trade.sync_offer_cards(offer)
	local add = offer.add or offer
	local nodes = {
		-- Red cross close button, top right of the modal.
		{ n = G.UI.ROW, config = { align = "cr", minw = 3.8 * G.CARD_W * MARKET_CARD_SCALE }, nodes = {
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
		{ n = G.UI.ROW, config = { minh = 40 / (G.TILESIZE or 64) }, nodes = {} },
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
			nodes[#nodes + 1] = card_row(remove.letters, "remove", session.remove_done, session)
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
-- after_add_purchase: the add-cost bonus rises once the in-flight card lands,
-- so project the next add price when deciding whether to auto-close.
function M.cannot_afford_anything(opts)
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
		end
	end
	local min_cost = M.session_add_cost(session)
	if opts and opts.after_add_purchase then
		min_cost = min_cost + ADD_COST_STEP
	end
	if any_in_deck then
		min_cost = math.min(min_cost, trade.ACTION_COSTS.remove)
		if modify_available then
			min_cost = math.min(min_cost, trade.ACTION_COSTS.modifier)
		end
	end
	return balance < min_cost
end

local cannot_afford_anything = M.cannot_afford_anything

-- Rebuilds the modal body without any affordability gating, so in-flight
-- animations can play out before the session is torn down.
rebuild_overlay = function()
	if not G.OVERLAY_MENU then
		open_overlay()
		return
	end
	local host = G.OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	if not host or not host.config then
		open_overlay()
		return
	end
	-- Remember the body's current height so the rebuilt body can never be
	-- shorter — the modal must not change size when a card is removed.
	local prev_body_h = nil
	if host.config.object and host.config.object.VT and host.config.object.VT.h then
		prev_body_h = host.config.object.VT.h
	end
	if host.config.object and host.config.object.remove then
		host.config.object:remove()
	end
	local body_def = marketplace_body_definition()
	if prev_body_h and body_def.config then
		body_def.config.minh = math.max(body_def.config.minh or 0, prev_body_h)
	end
	host.config.object = LayoutView{
		definition = body_def,
		config = { offset = { x = 0, y = 0 }, align = "cm", parent = host },
	}
	G.OVERLAY_MENU:recalculate()
end

refresh_overlay = function()
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	rebuild_overlay()
end

function M.definition()
	if not offer then
		reset_session(trade.roll_offer())
	elseif not session then
		reset_session(offer)
	end

	return build_generic_options({
		minw = 12,
		minh = modal_minh(),
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
	trade_fly.clear()
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

finish_trade = function()
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

-- True when the balance right after the last purchase was already below the
-- cheapest remaining action. Locked in at pick time so a token reward that
-- lands mid-animation cannot keep the marketplace open afterwards.
local function broke_after_last_action()
	return session and session.broke_after_action or false
end

local function refresh_or_finish()
	if session_complete() then
		finish_trade()
		return
	end
	refresh_overlay()
end

local function fail(text)
	word_feedback.show_screen_centered(tostring(text), G.C.RED, 1.4)
end

function M.is_flying()
	return trade_fly.is_flying()
end

function M.is_open()
	return offer ~= nil
end

--- Advance the marketplace card fly animation. Called from the post_input
--- updater so progress continues while G.SETTINGS.paused freezes game dt.
function M.step_card_fly(dt)
	return trade_fly.step_card_fly(dt)
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
	-- Aspect-preserving "cover" fill, cropped with a Quad (no scissor needed):
	-- uniform scale fills the whole modal boundary and the source rectangle is
	-- cropped symmetrically so nothing spills outside the modal.
	local scale = math.max(dw / iw, dh / ih)
	local crop_w = math.min(iw, dw / scale)
	local crop_h = math.min(ih, dh / scale)
	local qx = (iw - crop_w) * 0.5
	local qy = (ih - crop_h) * 0.5
	local quad = love.graphics.newQuad(qx, qy, crop_w, crop_h, iw, ih)
	love.graphics.draw(atlas.image, quad, dx, dy, 0, scale, scale)
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

local function apply_modified_market_face(card, item)
	local color = LetterPalette.MODIFIED_FACE_COLOR
	local front = deck.front(item.letter, color)
	if front and card.apply_face then
		deck.tag_card(card, item.letter, color)
		card:apply_face(front, false)
	end
	item.color = color
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
	item.color = LetterPalette.MODIFIED_FACE_COLOR
	play_sfx("card_slide1", 1.05, 0.9)
	if broke_after_last_action() then
		finish_trade()
		return
	end
	if G.OVERLAY_MENU then
		refresh_overlay()
	end
end

local function start_transform_fx(item)
	local card = item.market_card
	if not card then
		item.color = LetterPalette.MODIFIED_FACE_COLOR
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
			apply_modified_market_face(card, item)
			card.dissolve = 1
			card.dissolve_wipe = 0
			card.dissolve_colours = BURN_MATERIALIZE_COLOURS
			-- Phase 2: modified card re-forms from the same burnt-paper dissolve, reversed.
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
	item.removed = true
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
			-- Another copy of this letter is still in the pack: clear the
			-- removed flag so sync rebinds the slot to it and it shows
			-- in place of the dissolved copy.
			if deck.find_deck_card(item.letter) then
				item.removed = false
			end
			trade.sync_offer_cards(offer)
			if item.card then
				item.color = deck.color_from_card(item.card)
			end
			if broke_after_last_action() then
				finish_trade()
				return
			end
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
	trade_fly.draw_pass()
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
	if trade_fly.is_flying() or transform_item then return end
	local ref = e and e.config and e.config.ref_table
	local item = ref and ref.item or ref
	local action = ref and ref.action or "add"
	if not item or not session then return end
	if action == "remove" and (session.removed or session.removing[item]) then return end
	if action == "modifier" and session.modified[item] then return end
	if not M.can_afford_action(action, session) then
		fail("Not enough tokens")
		return
	end

	local cost = action == "add" and M.session_add_cost(session) or nil
	local ok, result = trade.apply(item, { action = action, cost = cost, defer_used = true })
	if not ok then
		fail(result)
		return
	end
	-- Record whether this purchase drained us below every remaining action
	-- BEFORE the animation runs; the check at landing can be skewed by token
	-- rewards that land in the meantime. For adds, project the post-landing
	-- add-cost escalation so we do not keep the modal open when the next add
	-- would already be unaffordable.
	local broke_opts = action == "add" and { after_add_purchase = true } or nil
	session.broke_after_action = cannot_afford_anything(broke_opts)

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
		-- Rebuild without the affordability check: if this purchase broke
		-- us, the modal must stay open until the card finishes flying.
		rebuild_overlay()
		trade_fly.start_card_fly(item, function()
			if not session then return end
			item.flying = false
			session.add_cost_bonus = (session.add_cost_bonus or 0) + ADD_COST_STEP
			play_sfx("card_slide1", 1.05, 0.75)
			-- Now that the animation is done, close when nothing was
			-- affordable after the purchase (or still isn't).
			if broke_after_last_action() then
				finish_trade()
				return
			end
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
	if trade_fly.is_flying() or transform_item then return end
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
	if trade_fly.is_flying() or transform_item then return end
	if not session or session.remove_done then
		if session and session_complete() then finish_trade() end
		return
	end
	session.remove_done = true
	session.removed = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	refresh_or_finish()
end

function M.teardown_run()
	offer = nil
	session = nil
	standalone = false
	trade_fly.clear()
	transform_item = nil
end

return M
