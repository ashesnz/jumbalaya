--[[ word_game/ui/perks/stamp/definition.lua - perk/stamp data copies and resolution ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local perk_cfg = require("word_game.config.perks")
require("word_game.ui.perks.shared.voucher_sprite")

local perk_model = facade.perks_registry()
local run_state = facade.run_state()
local game_access = require("word_game.model.game_access")

local M = {}

function M.perk_popup_definition(entry)
	local w = (runtime().CARD_W or 1) * 0.9
	local h = w / (perk_cfg.VOUCHER_ASPECT or 2.3)
	local sprite = PerkVoucherSprite(0, 0, w, h, entry)
	return build_generic_options({
		contents = {
			{ n = runtime().UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
				{ n = runtime().UI.OBJECT, config = { object = sprite, w = w, h = h } },
			}},
			{ n = runtime().UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = runtime().UI.TEXT, config = {
					text = entry.name or "Perk",
					scale = 0.42,
					colour = runtime().C.GOLD,
					shadow = true,
				}},
			}},
			{ n = runtime().UI.ROW, config = { align = "cm", padding = 0.06, maxw = 4.8 }, nodes = {
				{ n = runtime().UI.TEXT, config = {
					text = entry.desc or "",
					scale = 0.28,
					colour = runtime().C.UI.TEXT_LIGHT,
					shadow = true,
				}},
			}},
		},
	})
end

function M.copy_perk(entry)
	return {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
		token_cost = entry.token_cost,
	}
end

function M.copy_stamp(entry)
	return {
		id = entry.id,
		pos = { x = entry.pos.x, y = entry.pos.y },
	}
end

function M.roll_stamp_sprite()
	local sprites = perk_cfg.STAMP_SPRITES
	if not sprites or #sprites == 0 then return nil end
	return M.copy_stamp(sprites[math.random(1, #sprites)])
end

function M.resolve_stamp_sprite(sprite_entry)
	if sprite_entry then return M.copy_stamp(sprite_entry) end
	local sprites = perk_cfg.STAMP_SPRITES
	if sprites and #sprites > 0 then
		local rs = run_state.get()
		if rs and #(rs.perks or {}) == 0 then
			return M.copy_stamp(sprites[1])
		end
	end
	return M.roll_stamp_sprite()
end

function M.resolve_stamp_perk(perk_entry)
	if perk_entry then return M.copy_perk(perk_entry) end
	local game = game_access.get()
	if game and game.pending_stamp_perk then
		local pending = M.copy_perk(game.pending_stamp_perk)
		game_access.patch({ pending_stamp_perk = nil })
		return pending
	end
	return perk_model.roll_stamp_perk()
end

return M
