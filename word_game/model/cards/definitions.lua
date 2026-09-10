--[[
	model/cards/definitions.lua - Letter card definitions and shared centers.

	G.LETTERS.faces holds letter faces (`red_A`–`gold_Z`).
	G.LETTERS.centers holds card bodies (`letter_base`, deck backs, …).
]]

local Registry = require("word_game.model.cards.registry")

-- Returns true when `key` starts with any of the given Lua patterns.
local function matches_any_prefix(key, prefixes)
	for _, prefix in ipairs(prefixes) do
		if string.find(key, prefix) then return true end
	end
	return false
end

function Game:load_card_definitions()
	local letters = Registry.ensure()
	local faces = letters.faces
	local centers = letters.centers
	local pools = letters.center_pools
	local locked = letters.locked

	for k in pairs(faces) do faces[k] = nil end
	for k in pairs(centers) do centers[k] = nil end
	for k in pairs(pools) do pools[k] = nil end
	for i = #locked, 1, -1 do locked[i] = nil end

	for i = 1, 26 do
		local letter = string.char(64 + i)
		local col = (i - 1) % 13
		local row = i <= 13 and 0 or 1
		local pos = { x = col, y = row }
		faces["red_" .. letter] = {
			name = "Red " .. letter,
			letter = letter,
			color = "red",
			value = letter,
			atlas = "letters",
			pos = pos,
		}
		faces["black_" .. letter] = {
			name = "Black " .. letter,
			letter = letter,
			color = "black",
			value = letter,
			atlas = "letters",
			pos = pos,
		}
		faces["modified_" .. letter] = {
			name = "Modified " .. letter,
			letter = letter,
			color = "modified",
			value = letter,
			atlas = "letters",
			pos = pos,
		}
		faces["gold_" .. letter] = {
			name = "Gold " .. letter,
			letter = letter,
			color = "gold",
			value = letter,
			atlas = "letters",
			pos = pos,
		}
	end
	faces.empty = { name = "Empty", pos = { x = 0, y = 0 } }

	self.companion_locked = { unlocked = false, max = 1, name = "Locked", pos = { x = 8, y = 9 }, set = "Companion", cost_mult = 1.0, config = {} }
	self.perk_locked = { unlocked = false, max = 1, name = "Locked", pos = { x = 8, y = 3 }, set = "Perk", cost_mult = 1.0, config = {} }
	self.companion_undiscovered = { unlocked = false, max = 1, name = "Locked", pos = { x = 9, y = 9 }, set = "Companion", cost_mult = 1.0, config = {} }
	self.perk_undiscovered = { unlocked = false, max = 1, name = "Locked", pos = { x = 8, y = 2 }, set = "Perk", cost_mult = 1.0, config = {} }

	centers.letter_base = {
		max = 500,
		freq = 1,
		line = "base",
		name = "Letter",
		pos = { x = 0, y = 0 },
		atlas = "letter_frame",
		set = "Default",
		label = "Letter",
		effect = "Base",
		cost_mult = 1.0,
		config = {},
	}
	centers.deck_alpha = {
		name = "Alpha Deck",
		stake = 1,
		unlocked = true,
		order = 1,
		pos = { x = 0, y = 0 },
		set = "Back",
		config = {},
		discovered = true,
	}

	pools.Default = {}
	pools.Companion = {}
	pools.Back = {}

	self:queue_progress_write()

	-------------------------------------
	local TESTHELPER_unlocks = false and not _RELEASE_MODE
	-------------------------------------
	local profile_id = (G.SETTINGS and G.SETTINGS.profile) or (self.SETTINGS and self.SETTINGS.profile) or 1
	if not love.filesystem.getInfo(profile_id .. "") then love.filesystem.createDirectory(profile_id .. "") end
	if not love.filesystem.getInfo(profile_id .. "/" .. "meta.acs") then love.filesystem.append(profile_id .. "/" .. "meta.acs", "return {}") end

	local meta = unpack_source(read_save_payload(profile_id .. "/" .. "meta.acs") or "return {}")
	meta.unlocked = meta.unlocked or {}
	meta.discovered = meta.discovered or {}
	meta.alerted = meta.alerted or {}

	local UNLOCKABLE_PREFIXES = { "^companion_", "^perk_", "^deck_" }
	local DISCOVERABLE_PREFIXES = { "^companion_", "^deck_", "^letter_", "^perk_" }

	for k, v in pairs(centers) do
		if not v.wip and not v.demo then
			if TESTHELPER_unlocks then v.unlocked = true; v.discovered = true; v.alerted = true end
			if not v.unlocked and matches_any_prefix(k, UNLOCKABLE_PREFIXES) and meta.unlocked[k] then
				v.unlocked = true
			end
			if not v.unlocked and matches_any_prefix(k, UNLOCKABLE_PREFIXES) then locked[#locked + 1] = v end
			if not v.discovered and matches_any_prefix(k, DISCOVERABLE_PREFIXES) and meta.discovered[k] then
				v.discovered = true
			end
			if v.discovered and meta.alerted[k] or v.set == "Back" or v.start_alerted then
				v.alerted = true
			elseif v.discovered then
				v.alerted = false
			end
		end
	end

	table.sort(locked, function(a, b) return not a.order or not b.order or a.order < b.order end)

	for k, v in pairs(centers) do
		v.key = k
		if v.set == "Companion" and not v.skip_pool then table.insert(pools.Companion, v) end
		if not v.wip then
			if v.set and pools[v.set] and v.set ~= "Companion" and not v.skip_pool and not v.omit then
				table.insert(pools[v.set], v)
			end
		end
	end

	table.sort(pools.Companion, function(a, b) return a.order < b.order end)
	table.sort(pools.Back, function(a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
end
