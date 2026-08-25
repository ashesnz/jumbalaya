--[[
	model/cards/definitions.lua - Letter card definitions and shared centers.

	P_CARDS is the 52 letter faces: `red_A`–`red_Z` and `black_A`–`black_Z`.
	Sprites live on AlphaDeck.png (13×4 grid, 71×95 px cells at 1x).
	Letter body (`letter_base`), tutorial companion card (`companion_pads`), Alpha Deck, and editions live in P_CENTERS.
]]

-- Returns true when `key` starts with any of the given Lua patterns.
local function matches_any_prefix(key, prefixes)
	for _, prefix in ipairs(prefixes) do
		if string.find(key, prefix) then return true end
	end
	return false
end

function Game:load_card_definitions()
    -- Sprite sheet is 13 columns × 4 rows. Columns are just atlas x;
    -- rows are red A–M, black N–Z, red N–Z, black A–M. Keys are letter+color.
    self.P_CARDS = {}
    for i = 1, 26 do
        local letter = string.char(64 + i)
        local col = (i - 1) % 13
        local first = i <= 13
        self.P_CARDS["red_"..letter] = {
            name = "Red "..letter,
            letter = letter,
            color = "red",
            value = letter,
            pos = {x = col, y = first and 0 or 2},
        }
        self.P_CARDS["black_"..letter] = {
            name = "Black "..letter,
            letter = letter,
            color = "black",
            value = letter,
            pos = {x = col, y = first and 3 or 1},
        }
    end
    self.P_CARDS.empty = {name = "Empty", pos = {x = 0, y = 0}}

    self.companion_locked = {unlocked = false, max = 1, name = "Locked", pos = {x=8,y=9}, set = "Companion", cost_mult = 1.0,config = {}}
    self.perk_locked = {unlocked = false, max = 1, name = "Locked", pos = {x=8,y=3}, set = "Perk", cost_mult = 1.0,config = {}}
    self.letter_locked = {unlocked = false, max = 1, name = "Locked", pos = {x=4,y=2}, set = "Charm", cost_mult = 1.0,config = {}}
    self.companion_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=9,y=9}, set = "Companion", cost_mult = 1.0,config = {}}
    self.charm_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=6,y=2}, set = "Charm", cost_mult = 1.0,config = {}}
    self.orbit_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=7,y=2}, set = "Orbit", cost_mult = 1.0,config = {}}
    self.phantom_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=5,y=2}, set = "Phantom", cost_mult = 1.0,config = {}}
    self.perk_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=8,y=2}, set = "Perk", cost_mult = 1.0,config = {}}
    self.booster_undiscovered = {unlocked = false, max = 1, name = "Locked", pos = {x=0,y=5}, set = "Bundle", cost_mult = 1.0,config = {}}

    self.P_CENTERS = {
        letter_base={max = 500, freq = 1, line = 'base', name = "Letter", pos = {x=0,y=0}, atlas = "cards_1", set = "Default", label = 'Letter', effect = "Base", cost_mult = 1.0, config = {}},

        -- Tutorial companion card (not in shop/collection pools)
        companion_pads={order = 0, unlocked = true, discovered = true, skip_pool = true, rarity = 1, cost = 0, name = "Pads", pos = {x=0,y=9}, set = "Companion", effect = "", config = {talk_pos = {x=1,y=9}}},

        --Backs
        deck_alpha=              {name = "Alpha Deck",         stake = 1, unlocked = true,order = 1, pos =   {x=0,y=0}, set = "Back", config = {discards = 1}, discovered = true},

        --editions
        finish_base =       {order = 1,  unlocked = true, discovered = false, name = "Base", pos = {x=0,y=0}, atlas = 'Companion', set = "Finish", config = {}},
        finish_foil =       {order = 2,  unlocked = true, discovered = false, name = "Foil", pos = {x=0,y=0}, atlas = 'Companion', set = "Finish", config = {extra = 50}},
        finish_holo =       {order = 3,  unlocked = true, discovered = false, name = "Holographic", pos = {x=0,y=0}, atlas = 'Companion', set = "Finish", config = {extra = 10}},
        finish_polychrome = {order = 4,  unlocked = true, discovered = false, name = "Polychrome", pos = {x=0,y=0}, atlas = 'Companion', set = "Finish", config = {extra = 1.5}},
        finish_negative =   {order = 5,  unlocked = true, discovered = false, name = "Negative", pos = {x=0,y=0}, atlas = 'Companion', set = "Finish", config = {extra = 1}},

        --Extras       
        soul={pos = {x=0,y=1}},
        undiscovered_joker={pos = {x=5,y=3}},
        undiscovered_tarot={pos = {x=6,y=3}},
    }

    -- Pools actually consumed by the game: Back (deck select/collection/stats),
    -- Finish (card popups), Companion (kept for the tutorial center's set routing).
    self.P_CENTER_POOLS = {
        Default = {},
        Finish = {},
        Companion = {},
        Back = {},
    }

    self.P_LOCKED = {}

    self:queue_progress_write()


    -------------------------------------
    local TESTHELPER_unlocks = false and not _RELEASE_MODE
    -------------------------------------
    local profile_id = (G.SETTINGS and G.SETTINGS.profile) or (self.SETTINGS and self.SETTINGS.profile) or 1
    if not love.filesystem.getInfo(profile_id..'') then love.filesystem.createDirectory( profile_id..'' ) end
    if not love.filesystem.getInfo(profile_id..'/'..'meta.acs') then love.filesystem.append( profile_id..'/'..'meta.acs', 'return {}') end

    local meta = unpack_source(read_save_payload(profile_id..'/'..'meta.acs') or 'return {}')
    meta.unlocked = meta.unlocked or {}
    meta.discovered = meta.discovered or {}
    meta.alerted = meta.alerted or {}
    
    -- Centre id prefixes eligible for persistent unlock/discovery badges.
    local UNLOCKABLE_PREFIXES = { '^companion_', '^perk_', '^deck_' }
    local DISCOVERABLE_PREFIXES = { '^companion_', '^deck_', '^finish_', '^letter_', '^orbit_', '^perk_' }

    for k, v in pairs(self.P_CENTERS) do
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then v.unlocked = true; v.discovered = true;v.alerted = true end --REMOVE THIS
            if not v.unlocked and matches_any_prefix(k, UNLOCKABLE_PREFIXES) and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked and matches_any_prefix(k, UNLOCKABLE_PREFIXES) then self.P_LOCKED[#self.P_LOCKED+1] = v end
            if not v.discovered and matches_any_prefix(k, DISCOVERABLE_PREFIXES) and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] or v.set == 'Back' or v.start_alerted then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end

    table.sort(self.P_LOCKED, function (a, b) return not a.order or not b.order or a.order < b.order end)

    for k, v in pairs(self.P_CENTERS) do
        v.key = k
        if v.set == 'Companion' and not v.skip_pool then table.insert(self.P_CENTER_POOLS['Companion'], v) end
        if not v.wip then
            if v.set and self.P_CENTER_POOLS[v.set] and v.set ~= 'Companion' and not v.skip_pool and not v.omit then table.insert(self.P_CENTER_POOLS[v.set], v) end
        end
    end

    table.sort(self.P_CENTER_POOLS["Companion"], function (a, b) return a.order < b.order end)
    table.sort(self.P_CENTER_POOLS["Back"], function (a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
    table.sort(self.P_CENTER_POOLS["Finish"], function (a, b) return a.order < b.order end)
end
