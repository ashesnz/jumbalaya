--[[ word_game/ui/trade/animate.lua - Marketplace card transform/remove FX ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")
local trade_busy = require("word_game.ui.trade.busy")

local function trade_model()
	return facade.trade()
end

local function deck_model()
	return facade.deck()
end

local function dissolve_fx()
	return facade.dissolve_fx()
end

local M = {}

local ctx
local transform_item

local function transform_dissolve_time()
	return dissolve_fx().CARD_TRANSFORM_DISSOLVE_TIME
end

local function transform_materialize_time()
	return dissolve_fx().CARD_TRANSFORM_MATERIALIZE_TIME
end

local function burn_dissolve_colours()
	return dissolve_fx().card_transform_dissolve_colours()
end

local function burn_materialize_colours()
	return dissolve_fx().card_transform_materialize_colours()
end

function M.init(context)
	ctx = context
end

function M.clear()
	transform_item = nil
	trade_busy.sync()
end

function M.is_transforming()
	return transform_item ~= nil
end

local function apply_modified_market_face(card, item)
	local color = LetterPalette.MODIFIED_FACE_COLOR
	local front = deck_model().front(item.letter, color)
	if front and card.apply_face then
		deck_model().tag_card(card, item.letter, color)
		card:apply_face(front, false)
	end
	item.color = color
end

local function finish_transform_fx()
	local item = transform_item
	transform_item = nil
	trade_busy.sync()
	if not item then return end
	local card = item.market_card
	if card then
		card.dissolve = 0
		card.dissolve_wipe = 0
	end
	item.color = LetterPalette.MODIFIED_FACE_COLOR
	play_sfx("card_slide1", 1.05, 0.9)
	if ctx.broke_after_last_action() then
		ctx.finish_trade()
		return
	end
	if runtime().OVERLAY_MENU then
		ctx.refresh_overlay()
	end
end

function M.start_transform_fx(item)
	local card = item.market_card
	if not card then
		item.color = LetterPalette.MODIFIED_FACE_COLOR
		ctx.refresh_overlay()
		return
	end

	transform_item = item
	trade_busy.sync()
	card.states.visible = true
	card.dissolve = 0
	card.dissolve_wipe = 0
	card.dissolve_colours = burn_dissolve_colours()

	play_sfx("whoosh2", math.random() * 0.2 + 0.9, 0.5)
	play_sfx("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.9, 0.5)

	-- Phase 1: red card burns away like crumpling paper (fibrous noise dissolve).
	local dissolve_time = transform_dissolve_time()
	dissolve_fx().run(card, {
		mode = "out",
		duration = dissolve_time,
		wipe = 0,
		pulse = true,
		colours = burn_dissolve_colours(),
		fade = { delay = 0.7 * dissolve_time, duration = 0.3 * dissolve_time },
		on_finish = function()
			apply_modified_market_face(card, item)
			card.dissolve = 1
			card.dissolve_wipe = 0
			card.dissolve_colours = burn_materialize_colours()
			-- Phase 2: modified card re-forms from the same burnt-paper dissolve, reversed.
			dissolve_fx().run(card, {
				mode = "in",
				duration = transform_materialize_time(),
				wipe = 0,
				pulse = true,
				colours = burn_materialize_colours(),
				particle = { timer = 0.025, scale = 0.25, speed = 3, lifespan = 0.7 },
				on_finish = finish_transform_fx,
			})
		end,
	})
end

function M.start_remove_dissolve(item)
	local card = item.market_card
	if not card then
		trade_model().sync_offer_cards(ctx.get_offer())
		ctx.refresh_overlay()
		return
	end
	local session = ctx.get_session()
	session.removing[item] = true
	item.removed = true
	play_sfx("whoosh2", math.random() * 0.2 + 0.9, 0.5)
	play_sfx("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.9, 0.5)
	dissolve_fx().run(card, {
		duration = 0.7,
		colours = { runtime().C.BLACK, runtime().C.ORANGE, runtime().C.RED, runtime().C.GOLD },
		pulse = true,
		remove = true,
		on_finish = function()
			item.market_card = nil
			local active_session = ctx.get_session()
			if active_session then
				active_session.removing[item] = nil
			end
			-- Another copy of this letter is still in the pack: clear the
			-- removed flag so sync rebinds the slot to it and it shows
			-- in place of the dissolved copy.
			if deck_model().find_deck_card(item.letter) then
				item.removed = false
			end
			trade_model().sync_offer_cards(ctx.get_offer())
			if item.card then
				item.color = deck_model().color_from_card(item.card)
			end
			if ctx.broke_after_last_action() then
				ctx.finish_trade()
				return
			end
			if runtime().OVERLAY_MENU then
				ctx.refresh_overlay()
			end
		end,
	})
end

return M
