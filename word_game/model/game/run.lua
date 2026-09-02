--[[
	model/run.lua - Starting a match (init_game_object, start_run, board).
]]

local Layout = require "word_game.ui.layout"
local Scheduler = require "app.effects.scheduler"
local RunScope = require "word_game.model.run_scope"

--- Tear down run-scoped UI and caches (delegates to RunScope).
function Game:teardown_run_ui()
	RunScope.teardown()
end

--- Reset G.ARGS fields that mirror per-run gameplay state for HUD/runtime glue.
function Game:reset_run_args()
	RunScope.reset_args()
end

function Game:start_gameplay_board()
    G.INPUT.locks.load = nil

    if G.debug_panel and G.debug_panel.is_open and G.debug_panel:is_open() then
        G.debug_panel:close()
    end

    G.GAME.round = 1
    G.GAME.round_resets.ante = G.GAME.round_resets.ante or 1

    G.STATE = G.STATES.TABLE_BOARD
    G.STATE_COMPLETE = true
    if WORD_GAME and WORD_GAME.Round then
        WORD_GAME.Round.init_run()
    end
    local opening_deal = require "word_game.model.play.opening_deal"
    opening_deal.deal()

    if G.FUNCS.ensure_table_board_sidebar then
        G.FUNCS.ensure_table_board_sidebar()
    end
    if WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.sync_deck_count_display then
        WORD_GAME.Deck.sync_deck_count_display()
    end
   	if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.ensure then
        WORD_GAME.PlayerHost.ensure()
    end
   	if WORD_GAME and WORD_GAME.AllyHost and WORD_GAME.AllyHost.ensure then
        WORD_GAME.AllyHost.ensure()
    end
   	if WORD_GAME and WORD_GAME.GuestHost and WORD_GAME.GuestHost.ensure then
        WORD_GAME.GuestHost.ensure()
    end

    -- Layout after HUD / hand controls / hosts exist so hand + placement anchors match.
    Layout.request_refresh()

    if G.TIMELINE then
        Scheduler.add{
            mode = "delayed",
            delay = 0,
            blocking = false,
            func = function()
                if G.STATE == G.STATES.TABLE_BOARD and G.STAGE == G.STAGES.RUN then
                    Layout.request_refresh()
                end
                return true
            end,
        }
    end
end

function Game:init_game_object()
    return {
        won = false,
        round_scores = {
            furthest_set = {label = 'Set', amt = 0},
            furthest_round = {label = 'Round', amt = 0},
            new_collection = {label = 'New Discoveries', amt = 0},
            cards_played = {label = 'Cards Played', amt = 0},
            cards_discarded = {label = 'Cards Discarded', amt = 0},
            times_rerolled = {label = 'Times Rerolled', amt = 0},
        },
        tile_usage = {},
        modifiers = {},
        starting_params = require("word_game.config.run_params").get(),
        round = 0,
        seed_streams = {},
        starting_deck_size = 12,
        points = 0,
        current_round = {
            current_hand = {
                points = 0,
                mult = 0,
            },
        },
        round_resets = {
            ante = 1,
        },
    }
end

function Game:start_run(args)
    args = args or {}

    local saveTable = args.savetext or nil
    local function has_invalid_starting_letter(saved_run)
        if not saved_run or not saved_run.cardAreas then return false end
        local allowed = {}
        for _, letter in ipairs(WORD_GAME.Deck.STARTING_LETTERS or {}) do
            allowed[letter] = (allowed[letter] or 0) + 1
        end
        local function inspect(value)
            if type(value) ~= 'table' then return false end
            if value.ability and value.ability.letter then
                local letter = value.ability.letter
                if not allowed[letter] or allowed[letter] == 0 then return true end
                allowed[letter] = allowed[letter] - 1
            end
            for _, child in pairs(value) do
                if inspect(child) then return true end
            end
            return false
        end
        return inspect(saved_run.cardAreas)
    end
    if saveTable and has_invalid_starting_letter(saveTable) then
        saveTable = nil
        delete_saved_run()
    end
    G.STORED_RUN = nil

    local viewed_back = self.GAME and self.GAME.viewed_back
    local selected_back_name = self.GAME and self.GAME.selected_back and self.GAME.selected_back.name

    self:teardown_run_ui()

    self:prep_stage(G.STAGES.RUN, saveTable and saveTable.STATE or G.STATES.TABLE_BOARD)
    
    G.STAGE = G.STAGES.RUN

    G.STATE_COMPLETE = false

    local function deck_center_from_name(name)
        for _, v in pairs(G.P_CENTERS) do
            if v.name == name then return v end
        end
        return G.P_CENTERS.deck_alpha
    end

    local selected_back = saveTable and saveTable.BACK.name
        or (viewed_back and viewed_back.name)
        or selected_back_name
        or 'Alpha Deck'
    selected_back = deck_center_from_name(selected_back)
    local game_table = saveTable and saveTable.GAME or self:init_game_object()
    RunScope.begin_run(game_table, { from_save = saveTable ~= nil })
    self.GAME = G.GAME
    self.GAME.modifiers = self.GAME.modifiers or {}
    self.GAME.selected_back = WORD_GAME.Back.new(selected_back)
    self.GAME.selected_back_key = selected_back

    if ease_background_colour and G.C and G.C.GREEN then
        ease_background_colour { new_colour = G.C.GREEN, contrast = 1 }
    end

    G.C.UI_POINTS[1], G.C.UI_POINTS[2], G.C.UI_POINTS[3], G.C.UI_POINTS[4] = G.C.BLUE[1], G.C.BLUE[2], G.C.BLUE[3], G.C.BLUE[4]
    G.C.UI_MULTIPLIER[1], G.C.UI_MULTIPLIER[2], G.C.UI_MULTIPLIER[3], G.C.UI_MULTIPLIER[4] = G.C.RED[1], G.C.RED[2], G.C.RED[3], G.C.RED[4]

    if not saveTable then 
        self.GAME.selected_back:apply_to_run()
    end

    G.GAME.chips_text = ''

    if not saveTable then
        if args.seed then self.GAME.seeded = true end
        if args.run_mode then self.GAME.run_mode = args.run_mode end
        local memory_entropy = tonumber(tostring({}):sub(7), 16) or 0
        local runtime_entropy = os.time()
            + math.floor(((love.timer and love.timer.getTime()) or 0) * 1000000)
            + memory_entropy
        math.randomseed(runtime_entropy)
        math.random()
        self.GAME.seed_streams.seed = args.seed or random_code(8, runtime_entropy)
    end

    for k, v in pairs(self.GAME.seed_streams) do if v == 0 then self.GAME.seed_streams[k] = hash_text(k..self.GAME.seed_streams.seed) end end
    self.GAME.seed_streams.hashed_seed = hash_text(self.GAME.seed_streams.seed)

    G:queue_settings_write()
    G.INPUT.locks.load = true
    Scheduler.add{
        persistent = true,
        mode = 'delayed',
        blocking = false,blockable = false,
        delay = 3.5,
        timer = 'TOTAL',
        func = function()
            G.INPUT.locks.load = nil
          return true
        end
      }

    if saveTable and saveTable.ACTION then
        -- Replay the queued card-use action from the save, once cards exist.
        Scheduler.add{delay = 0.5, mode = 'delayed', blocking = false, blockable = false, func = function()
            Scheduler.add{func = function()
                Scheduler.add{func = function()
                    for k, v in pairs(G.LIVE.CARD) do
                        if v.sort_id == saveTable.ACTION.card then
                            G.FUNCS.use_card({config = {ref_table = v}}, nil, true)
                        end
                    end
                    return true
                end}
                return true
            end}
            return true
        end}
    end

    local hand_size = self.GAME.starting_params.hand_size

    if not self.placement_table then
        self.placement_table = require("word_game.board").PlacementTable(self)
    end

    local CAI = {
        discard_W = G.CARD_W,
        discard_H = G.CARD_H,
        deck_W = G.CARD_W*1.1,
        deck_H = 0.95*G.CARD_H,
        hand_W = get_hand_area_width(hand_size),
        hand_H = 0.95*G.CARD_H,
        play_W = math.min(5, hand_size)*G.CARD_W + 0.3*G.CARD_W,
        play_H = 0.95*G.CARD_H,
        placement_W = self.placement_table:area_width(),
        placement_H = self.placement_table:area_height(),
        usable_W = 2.3*G.CARD_W,
        usable_H = 0.95*G.CARD_H
    }


    self.usables = CardArea(
        0, 0,
        CAI.usable_W,
        CAI.usable_H, 
        {card_limit = self.GAME.starting_params.usable_slots, type = 'usable', selection_limit = 1})

    self.placement_table:create_area(CAI.placement_W, CAI.placement_H)
    self.placement_table:setup()

    self.discard = CardArea(
        0, 0,
        CAI.discard_W,CAI.discard_H,
        {card_limit = 500, type = 'discard'})
    self.deck = CardArea(
        0, 0,
        CAI.deck_W,CAI.deck_H, 
        {card_limit = 12, type = 'deck'})
    self.hand = CardArea(
        0, 0,
        CAI.hand_W,CAI.hand_H,
        {card_limit = self.GAME.starting_params.hand_size, type = 'hand', selection_limit = 1})

    G.playing_cards = {}

	if not saveTable and WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.populate_starting_deck then
		WORD_GAME.Deck.populate_starting_deck()
	end

    local backgrounds = require "word_game.ui.layout.backgrounds"
    backgrounds.run()
    Layout.request_refresh()

    Scheduler.delayed{delay = 0.5}

    if not saveTable then
        self.deck:shuffle()
        self.deck:hard_set_T()
    end

    self.deck:relayout()
    self.deck:hard_set_cards()

    if WORD_GAME and WORD_GAME.Sidebar then
        WORD_GAME.Sidebar:ensure()
    end
    apply_run_layout()
    if self.usables then
        self.usables.states.visible = false
    end

    if saveTable then
        restore_card_areas(saveTable)
        G.STATE = saveTable.STATE or G.STATES.TABLE_BOARD
        G.STATE_COMPLETE = true
        Layout.request_refresh()
        if G.FUNCS.ensure_table_board_sidebar then
            G.FUNCS.ensure_table_board_sidebar()
        end
        if WORD_GAME and WORD_GAME.PlayerHost then
            WORD_GAME.PlayerHost.ensure()
        end
        if WORD_GAME and WORD_GAME.AllyHost then
            WORD_GAME.AllyHost.ensure()
        end
        if WORD_GAME and WORD_GAME.GuestHost then
            WORD_GAME.GuestHost.ensure()
        end
        if WORD_GAME and WORD_GAME.Round then
            WORD_GAME.Round.restore_from_save()
        end
        G.INPUT.locks.load = nil
    end

end
