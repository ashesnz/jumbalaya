--[[ word_game/ui/perks/stamp/definition.lua - perk/stamp data copies and resolution ]]

local perk_cfg = require("word_game.config.perks")
local perk_model = require("word_game.model.perks.registry")

local M = {}

function M.perk_popup_definition(entry)
	require("word_game.ui.perk_voucher_sprite")
	local w = (G.CARD_W or 1) * 0.9
	local h = w / (perk_cfg.VOUCHER_ASPECT or 2.3)
	local sprite = PerkVoucherSprite(0, 0, w, h, entry)
	return build_generic_options({
		contents = {
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
				{ n = G.UI.OBJECT, config = { object = sprite, w = w, h = h } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = entry.name or "Perk",
					scale = 0.42,
					colour = G.C.GOLD,
					shadow = true,
				}},
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.06, maxw = 4.8 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = entry.desc or "",
					scale = 0.28,
					colour = G.C.UI.TEXT_LIGHT,
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
	return M.roll_stamp_sprite()
end

function M.resolve_stamp_perk(perk_entry)
	if perk_entry then return M.copy_perk(perk_entry) end
	if G.GAME and G.GAME.pending_stamp_perk then
		local pending = M.copy_perk(G.GAME.pending_stamp_perk)
		G.GAME.pending_stamp_perk = nil
		return pending
	end
	return perk_model.roll_stamp_perk()
end

return M
