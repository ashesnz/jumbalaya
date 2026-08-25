--[[ word_game/ui/card_tooltip.lua - Letter-card tooltip UI generation ]]

local perk = require("word_game.model.perk")

function get_type_colour(_c, card)
	if (_c.unlocked == false and not (card and card.bypass_lock)) then
		return G.C.BLACK
	end
	if _c.set == "Finish" then
		return G.C.DARK_FINISH
	end
	return G.C.SECONDARY_SET[_c.set] or { 0, 1, 1, 1 }
end

function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
	local first_pass = nil
	if not full_UI_table then
		first_pass = true
		full_UI_table = {
			main = {},
			info = {},
			type = {},
			name = nil,
			badges = badges or {},
		}
	end

	local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
	if full_UI_table.name then
		full_UI_table.info[#full_UI_table.info + 1] = {}
		desc_nodes = full_UI_table.info[#full_UI_table.info]
	end

	if not full_UI_table.name then
		if specific_vars and specific_vars.no_name then
			full_UI_table.name = true
		elseif card_type == "Locked" then
			full_UI_table.name = localize { type = "name", set = "Other", key = "locked", nodes = {} }
		elseif card_type == "Undiscovered" then
			full_UI_table.name = localize {
				type = "name",
				set = "Other",
				key = "undiscovered_" .. string.lower(_c.set),
				name_nodes = {},
			}
		elseif specific_vars and (card_type == "Default" or card_type == "Enhanced") then
			if specific_vars.playing_card then
				full_UI_table.name = {}
				localize {
					type = "other",
					key = "playing_card",
					set = "Other",
					nodes = full_UI_table.name,
					vars = {
						specific_vars.color_name or "Black",
						specific_vars.value,
						colours = { specific_vars.colour },
					},
				}
				full_UI_table.name = full_UI_table.name[1]
			end
		else
			full_UI_table.name = localize { type = "name", set = _c.set, key = _c.key, nodes = full_UI_table.name }
		end
		full_UI_table.card_type = card_type or _c.set
	end

	if main_start then
		desc_nodes[#desc_nodes + 1] = main_start
	end

	if card_type == "Locked" then
		localize { type = "unlocks", key = _c.key, set = _c.set, nodes = desc_nodes, vars = {} }
	elseif hide_desc then
		localize { type = "other", key = "undiscovered_" .. string.lower(_c.set), set = _c.set, nodes = desc_nodes }
	elseif specific_vars and specific_vars.debuffed then
		localize {
			type = "other",
			key = specific_vars.playing_card and "playing_card" or "default",
			nodes = desc_nodes,
		}
	elseif _c.set == "Default" and specific_vars then
		if specific_vars.letter_points then
			localize { type = "other", key = "card_points", nodes = desc_nodes, vars = { specific_vars.letter_points } }
		end
		if specific_vars.letter_bonus then
			localize { type = "other", key = "card_extra_points", nodes = desc_nodes, vars = { specific_vars.letter_bonus } }
		end
	elseif _c.set == "Enhanced" then
		if specific_vars and specific_vars.letter_points then
			localize { type = "other", key = "card_points", nodes = desc_nodes, vars = { specific_vars.letter_points } }
		end
		localize { type = "descriptions", key = _c.key, set = _c.set, nodes = desc_nodes, vars = specific_vars or {} }
	elseif _c.set == "Perk" then
		local loc_vars = perk.description_vars(_c, G.PROFILES and G.PROFILES[G.SETTINGS.profile]) or {}
		localize { type = "descriptions", key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars }
	elseif _c.set == "Finish" then
		localize { type = "descriptions", key = _c.key, set = _c.set, nodes = desc_nodes, vars = { _c.config.extra } }
	end

	if main_end then
		desc_nodes[#desc_nodes + 1] = main_end
	end

	if first_pass and not (_c.set == "Finish") and badges then
		for _, v in ipairs(badges) do
			if v == "foil" then
				full_UI_table.info[#full_UI_table.info + 1] = { name = localize { type = "name_text", set = "Finish", key = "finish_foil" } }
			elseif v == "holographic" then
				full_UI_table.info[#full_UI_table.info + 1] = { name = localize { type = "name_text", set = "Finish", key = "finish_holo" } }
			elseif v == "polychrome" then
				full_UI_table.info[#full_UI_table.info + 1] = { name = localize { type = "name_text", set = "Finish", key = "finish_polychrome" } }
			elseif v == "negative" then
				full_UI_table.info[#full_UI_table.info + 1] = { name = localize { type = "name_text", set = "Finish", key = "finish_negative" } }
			end
		end
	end

	return full_UI_table
end

return {
	get_type_colour = get_type_colour,
	generate_card_ui = generate_card_ui,
}
