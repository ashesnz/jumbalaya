--[[ word_game/ui/trade/definition.lua - Marketplace UIBox node builders ]]

local trade = require("word_game.model.trade")
local deck = require("word_game.model.cards.deck")

local M = {}

-- Marketplace cards render slightly smaller than table cards so the modal
-- contents fit comfortably inside the play-area-sized window.
M.MARKET_CARD_SCALE = 0.82

local BUTTON_LABEL_SCALE = 0.38
local MODIFIER_TEXT_SCALE = 0.30
local MODIFIER_LINE_CHARS = 38
local TOKEN_COIN_W = 0.24

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
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W * M.MARKET_CARD_SCALE, minh = G.CARD_H * M.MARKET_CARD_SCALE }, nodes = {} }
	end
	-- A card whose deck copy was removed this session stays gone: empty slot.
	if item.removed or (item.mode == "remove" and not trade.item_in_deck(item)) then
		return { n = G.UI.ROW, config = { align = "cm", minw = G.CARD_W * M.MARKET_CARD_SCALE, minh = G.CARD_H * M.MARKET_CARD_SCALE }, nodes = {} }
	end
	local w, h = G.CARD_W * M.MARKET_CARD_SCALE, G.CARD_H * M.MARKET_CARD_SCALE
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
		align = "cm", padding = 0.12, r = 0.18, minw = G.CARD_W * M.MARKET_CARD_SCALE + 0.45, minh = 0.62,
		hover = not disabled, button = disabled and nil or "trade_pick", ref_table = ref, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or colour or G.C.UI.BUTTON,
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
		minw = G.CARD_W * M.MARKET_CARD_SCALE + 0.35,
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
		minw = G.CARD_W * M.MARKET_CARD_SCALE + 0.35,
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

local function action_column(item, mode, done, session_state, host)
	local add_cost = host.session_add_cost(session_state)
	local add_disabled = host.is_action_disabled("add", item, session_state)
	local modify_disabled = host.is_action_disabled("modifier", item, session_state)
	local remove_disabled = host.is_action_disabled("remove", item, session_state)
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
	return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.28, minw = G.CARD_W * M.MARKET_CARD_SCALE + 0.7 }, nodes = column_nodes }
end

local function card_row(items, mode, done, session_state, host)
	local cards = {}
	for _, item in ipairs(items or {}) do
		cards[#cards + 1] = action_column(item, mode, done, session_state, host)
		cards[#cards + 1] = { n = G.UI.COLUMN, config = { minw = 0.5 }, nodes = {} }
	end
	if #cards > 0 then
		cards[#cards] = nil
	end
	return { n = G.UI.ROW, config = {
		align = "cm",
		padding = 0.12,
		minh = 3.4 * G.CARD_H * M.MARKET_CARD_SCALE,
		minw = 3.8 * G.CARD_W * M.MARKET_CARD_SCALE,
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

function M.marketplace_content_nodes(ctx)
	local offer = ctx.get_offer()
	local session = ctx.get_session()
	trade.sync_offer_cards(offer)
	local add = offer.add or offer
	local nodes = {
		-- Red cross close button, top right of the modal.
		{ n = G.UI.ROW, config = { align = "cr", minw = 3.8 * G.CARD_W * M.MARKET_CARD_SCALE }, nodes = {
			{ n = G.UI.COLUMN, config = {
				align = "cm", minw = 0.72, minh = 0.72, r = 0.16, padding = 0.1,
				hover = true, colour = G.C.RED, hover_colour = G.C.UI.BUTTON_HOVER,
				button = "trade_skip_add", shadow = true, emboss = 0.12, no_jiggle = true,
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
		card_row(add.letters, "market", session.add_done, session, ctx.host),
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
			nodes[#nodes + 1] = card_row(remove.letters, "remove", session.remove_done, session, ctx.host)
			nodes[#nodes + 1] = status_or_skip(
				session.remove_done,
				session.removed == "skipped" and "Remove skipped" or "Card removed",
				"trade_skip_remove"
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

function M.marketplace_body_definition(ctx)
	return {
		n = G.UI.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = M.marketplace_content_nodes(ctx),
	}
end

function M.build_overlay_definition(ctx)
	return build_generic_options({
		minw = 12,
		minh = ctx.modal_minh(),
		padding = 0.35,
		bg_colour = G.C.CLEAR,
		outline_colour = G.C.CLEAR,
		colour = G.C.CLEAR,
		contents = {
			{ n = G.UI.OBJECT, config = {
				id = "trade_marketplace_body",
				object = LayoutView{
					definition = M.marketplace_body_definition(ctx),
					config = { offset = { x = 0, y = 0 }, align = "cm" },
				},
			}},
		},
		no_back = true,
	})
end

return M
