--[[
	model/run.lua - Starting a match (init_game_object, start_run, board).
]]

local live_game = require("word_game.model.live_game")

local LayoutRequest = require("word_game.model.layout.request")
local Presentation = require("word_game.model.presentation")
local Scheduler = require "app.effects.timeline_scheduler"
local RunScope = require "word_game.model.run.scope"
local RunMode = require "word_game.model.run.mode"
local game_access = require "word_game.model.game_access"

--- Tear down run-scoped UI and caches (delegates to RunScope).
function Game:teardown_run_ui()
	RunScope.teardown()
end

--- Reset self.ARGS fields that mirror per-run gameplay state for HUD/runtime glue.
function Game:reset_run_args()
	RunScope.reset_args()
end

function Game:start_gameplay_board()
    self.INPUT.locks.load = nil

    if self.debug_panel and self.debug_panel.is_open and self.debug_panel:is_open() then
        self.debug_panel:close()
    end

    game_access.patch({ round = 1 })

    self.STATE = self.STATES.TABLE_BOARD
    self.STATE_COMPLETE = true
    if WORD_GAME and WORD_GAME.Round then
        WORD_GAME.Round.init_run()
    end
    local opening_deal = require "word_game.model.jumble_play.opening_deal"
    opening_deal.deal()

    Presentation.emit("sidebar_ensure")
    if WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.sync_deck_count_display then
        WORD_GAME.Deck.sync_deck_count_display()
    end
    -- Layout after HUD / hand controls exist so hand + placement anchors match.
    LayoutRequest.refresh()

    if self.TIMELINE then
        Scheduler.add{
            mode = "delayed",
            delay = 0,
            blocking = false,
            func = function()
                if self.STATE == self.STATES.TABLE_BOARD and self.STAGE == self.STAGES.RUN then
                    LayoutRequest.refresh()
                end
                return true
            end,
        }
        Presentation.emit("run_board_ready")
    end
end

function Game:init_game_object()
    return {
        won = false,
        round_scores = {
            furthest_set = {label = 'Set', amt = 0},
            furthest_round = {label = 'Round', amt = 0},
            cards_discarded = {label = 'Cards Discarded', amt = 0},
        },
        tile_usage = {},
        modifiers = {},
        starting_params = require("word_game.config.gameplay.run_params").get(),
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
    self.STORED_RUN = nil

    local prior = game_access.get()
    local viewed_back = prior and prior.viewed_back
    local selected_back_name = prior and prior.selected_back and prior.selected_back.name

    self:teardown_run_ui()

    self:prep_stage(self.STAGES.RUN, saveTable and saveTable.STATE or self.STATES.TABLE_BOARD)
    
    self.STAGE = self.STAGES.RUN

    self.STATE_COMPLETE = false

    local function deck_center_from_name(name)
        for _, v in pairs(self.LETTERS.centers) do
            if v.name == name then return v end
        end
        return self.LETTERS.centers.deck_alpha
    end

    local selected_back = saveTable and saveTable.BACK.name
        or (viewed_back and viewed_back.name)
        or selected_back_name
        or 'Alpha Deck'
    selected_back = deck_center_from_name(selected_back)
    local game_table = saveTable and saveTable.GAME or self:init_game_object()
    RunScope.begin_run(game_table, { from_save = saveTable ~= nil })
    local run = game_access.get()
    run.modifiers = run.modifiers or {}
    run.selected_back = WORD_GAME.Back.new(selected_back)
    run.selected_back_key = selected_back

    if ease_background_colour and self.C and self.C.GREEN then
        ease_background_colour { new_colour = self.C.GREEN, contrast = 1 }
    end

    self.C.UI_POINTS[1], self.C.UI_POINTS[2], self.C.UI_POINTS[3], self.C.UI_POINTS[4] = self.C.BLUE[1], self.C.BLUE[2], self.C.BLUE[3], self.C.BLUE[4]
    self.C.UI_MULTIPLIER[1], self.C.UI_MULTIPLIER[2], self.C.UI_MULTIPLIER[3], self.C.UI_MULTIPLIER[4] = self.C.RED[1], self.C.RED[2], self.C.RED[3], self.C.RED[4]

    if not saveTable then 
        run.selected_back:apply_to_run()
    end

    if not saveTable then
        if args.seed then run.seeded = true end
        local run_mode = RunMode.resolve_for_new_run(args.run_mode)
        run.run_mode = run_mode
        if args.run_mode then
            RunMode.set_preferred(run_mode)
        end
        local memory_entropy = tonumber(tostring({}):sub(7), 16) or 0
        local runtime_entropy = os.time()
            + math.floor(((love.timer and love.timer.getTime()) or 0) * 1000000)
            + memory_entropy
        math.randomseed(runtime_entropy)
        math.random()
        run.seed_streams.seed = args.seed or random_code(8, runtime_entropy)
    end

    for k, v in pairs(run.seed_streams) do if v == 0 then run.seed_streams[k] = hash_text(k..run.seed_streams.seed) end end
    run.seed_streams.hashed_seed = hash_text(run.seed_streams.seed)

    self:queue_settings_write()
    self.INPUT.locks.load = true
    Scheduler.add{
        persistent = true,
        mode = 'delayed',
        blocking = false,blockable = false,
        delay = 3.5,
        timer = 'TOTAL',
        func = function()
            self.INPUT.locks.load = nil
          return true
        end
      }

    local hand_size_cfg = require("word_game.model.hand_size")
    local hand_size = hand_size_cfg.get()

    if not self.pattern_row then
        self.pattern_row = require("word_game.board").PlacementTable(self)
    end

    local CAI = {
        discard_W = self.CARD_W,
        discard_H = self.CARD_H,
        deck_W = self.CARD_W*1.1,
        deck_H = 0.95*self.CARD_H,
        hand_W = get_hand_area_width(hand_size),
        hand_H = 0.95*self.CARD_H,
        play_W = math.min(5, hand_size)*self.CARD_W + 0.3*self.CARD_W,
        play_H = 0.95*self.CARD_H,
        placement_W = self.pattern_row:area_width(),
        placement_H = self.pattern_row:area_height(),
        usable_W = 2.3*self.CARD_W,
        usable_H = 0.95*self.CARD_H
    }


    self.usables = CardPile(
        0, 0,
        CAI.usable_W,
        CAI.usable_H, 
        {card_limit = run.starting_params.usable_slots, type = 'usable', selection_limit = 1})

    self.pattern_row:create_area(CAI.placement_W, CAI.placement_H)
    self.pattern_row:setup()

    self.recycle_stash = CardPile(
        0, 0,
        CAI.discard_W,CAI.discard_H,
        {card_limit = 500, type = 'discard'})
    self.draw_pile = CardPile(
        0, 0,
        CAI.deck_W,CAI.deck_H, 
        {card_limit = 12, type = 'deck'})
    self.dealt_letters = CardPile(
        0, 0,
        CAI.hand_W,CAI.hand_H,
        {card_limit = run.starting_params.hand_size, type = 'hand', selection_limit = 1})

    self.letter_inventory = {}

	if not saveTable and WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.populate_starting_deck then
		WORD_GAME.Deck.populate_starting_deck()
	end

    Presentation.emit("run_backgrounds")

    Scheduler.delayed{delay = 0.5}

    if not saveTable then
        self.draw_pile:shuffle()
        self.draw_pile:hard_set_T()
    end

    self.draw_pile:relayout()
    self.draw_pile:hard_set_cards()

    Presentation.emit("sidebar_ensure")
    apply_run_layout()
    if self.usables then
        self.usables.states.visible = false
    end

    if saveTable then
        restore_card_areas(saveTable)
        self.STATE = saveTable.STATE or self.STATES.TABLE_BOARD
        self.STATE_COMPLETE = true
        LayoutRequest.refresh()
        Presentation.emit("sidebar_ensure")
        if WORD_GAME and WORD_GAME.Round then
            WORD_GAME.Round.restore_from_save()
        end
        self.INPUT.locks.load = nil
    end

end
