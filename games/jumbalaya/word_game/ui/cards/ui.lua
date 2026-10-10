--[[ word_game/ui/card_ui.lua - hover UI, click, set_selected, per-frame update ]]

---@class (partial) Card : Spatial
--- Clears cached ability tooltip UI so it gets rebuilt next time it's shown.
local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
function Card:remove_UI()
		self.tooltip_info = nil
		self.config.h_popup = nil
		self.config.h_popup_config = nil
		self.no_ui = true
end

-- ============ UI generation ============

--- Builds the tooltip content shown for a locked (not-yet-unlocked) card.
--- @param hidden boolean|nil if true, hides even the "locked" hint text
--- @return table ui_definition passed to `generate_card_ui`
function Card:build_unlock_table(hidden)
		local loc_vars = {no_name = true, not_hidden = not hidden}

		return generate_card_ui(nil, nil, loc_vars, 'Locked')
end

--- Letter tooltip: points and modifier bonus only (no discovery/lock/companion).
--- @return table ui_definition passed to `generate_card_ui`
function Card:build_card_tooltip()
		local loc_vars = nil
		if self.debuff then
				loc_vars = { no_name = true, debuffed = true, has_letter_face = not not self.base.colour, value = self.base.value, color_name = (self.base.color == 'red') and 'Red' or 'Black', colour = self.base.colour }
		else
				local points = self.base.letter_index
				loc_vars = { no_name = true, has_letter_face = not not self.base.colour, value = self.base.value, color_name = (self.base.color == 'red') and 'Red' or 'Black', colour = self.base.colour,
										letter_points = points and points > 0 and points or nil,
										letter_bonus = (self.ability.bonus + (self.ability.perma_bonus or 0)) > 0 and (self.ability.bonus + (self.ability.perma_bonus or 0)) or nil,
								}
		end

		return generate_card_ui({ set = "Default" }, nil, loc_vars, "Default", {}, nil, nil, nil)
end

-- ============ Stat getters ============
-- Small getters used by sorting/scoring code, most of which just apply the
-- `debuff` short-circuit (return 0/nil while debuffed) on top of raw
-- `self.ability`/`self.base` fields. `get_nominal` is the one with real
-- logic worth explaining below; the rest are largely self-describing by name.

--- Sort key combining letter, color, and a per-instance tiebreaker
--- (`sort_id`) so sorts are stable even between identical letters.
--- Passing `mod = 'color'` weights color above letter.


-- Which face a flip lands on, keyed by its animation direction.
local FLIP_TARGET = {f2b = 'back', b2f = 'front'}

function Card:update(dt)
		-- A flip resolves the moment the width collapses through zero: swap faces,
		-- then un-pinch so it swings back open showing the new side.
		local landed_face = FLIP_TARGET[self.flipping]
		if landed_face and self.VT.w <= 0 then
				self.sprite_facing = landed_face
				self.pinch.x = false
		end

		if not self.states.focus.is and self.children.focused_ui then
				self.children.focused_ui:remove()
				self.children.focused_ui = nil
		end

		self:update_alert()
end


function Card:align_h_popup()
				local focused_ui = self.children.focused_ui and true or false
				local popup_direction = (self.children.buy_button or (self.area and self.area.config.view_deck)) and 'cl' or 
																(self.T.y < game().CARD_H*0.8) and 'bm' or
																'tm'
				return {
						major = self.children.focused_ui or self,
						parent = self,
						bond = 'Strong',
						offset = {
								x = popup_direction ~= 'cl' and 0 or
										focused_ui and -0.05 or
										(self.ability.set == 'Perk' and 0.0) or
										-0.05,
								y = focused_ui and (
														popup_direction == 'tm' and (self.area and self.area == game().dealt_letters and -0.08 or-0.15) or
														popup_direction == 'bm' and 0.12 or
														0
												) or
										popup_direction == 'tm' and -0.13 or
										popup_direction == 'bm' and 0.1 or
										0
						},  
						type = popup_direction,
				}
end


--- First hover on an undiscovered card clears its "new item" badge and
--- queues a progress write so the dismissal persists.
function Card:mark_alert_seen()
		if self.children.alert then
			self.children.alert:remove()
			self.children.alert = nil
		end
end

function Card:hover()
		local is_letter = self.ability and (self.ability.set == 'Default' or self.ability.set == 'Enhanced')

		if not is_letter then
				self:pulse(0.05, 0.03)
				play_sfx('hover_card', math.random()*0.2 + 0.9, 0.35)
		end

		-- Hand letter cards skip the focus chrome; placement uses drag, not focus rings.
		if self.states.focus.is and not self.children.focused_ui
				and not (is_letter and self.area == game().dealt_letters) then
				self.children.focused_ui = game().DEFINITIONS.card_focus_ui(self)
		end

		if self.facing ~= 'front' or self.no_ui or game().debug_tooltip_toggle then return end
		self:mark_alert_seen()

		-- Letter cards are placed by dragging; no hover popup for them.
		if is_letter then return end

		if not self.states.drag.is or game().INPUT.HID.touch then
				if not self.children.h_popup then
						self.tooltip_info = self:build_card_tooltip()
						self.config.h_popup = game().DEFINITIONS.card_h_popup(self)
						self.config.h_popup_config = self:align_h_popup()
				end
				SceneNode.hover(self)
		end
end


function Card:stop_hover()
		SceneNode.stop_hover(self)
end


local function hand_cards(hand)
		if hand and hand.cards and #hand.cards > 0 then
				return hand.cards
		end
		local board = WORD_GAME_UI.TableBoard
		local view = board and board.table_board_view and board.table_board_view()
		return view and view:pile_cards("hand") or {}
end

local function is_hand_letter(card)
		local hand = game().dealt_letters
		if not hand or not card then return false end
		if card.area == hand or card.pile_id == "hand" then return true end
		for _, c in ipairs(hand_cards(hand)) do
				if c == card then return true end
		end
		return false
end

function Card:drag()
		local hand = game().dealt_letters
		if hand and is_hand_letter(self) and hand.add_selection then
				if hand.selected[1] ~= self then
						for _, c in ipairs(hand_cards(hand)) do
								if c ~= self and c.selected then
										c:set_selected(false)
								end
						end
						hand:clear_selection()
						hand:add_selection(self, true)
				end
		end
		Spatial.drag(self)
end


function Card:stop_drag()
		SceneNode.stop_drag(self)
		if self.area == game().dealt_letters
				and WORD_GAME_UI.DiscardBin
				and WORD_GAME_UI.DiscardBin.try_discard(self) then
				return
		end
		if game().pattern_row then
				local effects = game().pattern_row:try_snap_card(self)
				if effects and effects.hand_shuffle_sync then
						facade.presentation().emit("hand_shuffle_sync")
				end
		end
end


function Card:release(dragged)
		if dragged:is_kind(Card) and self.area then
				self.area:release(dragged)
		end
end


function Card:set_selected(selected)
		self.selected = selected
end


function Card:click() 
		local is_playing = self.ability and (self.ability.set == 'Default' or self.ability.set == 'Enhanced')
		if is_playing and game().STATE == game().STATES.TABLE_BOARD then
				-- Letter cards are placed by dragging; a click must not raise/select them.
				return
		end
		if self.area and self.area:can_select(self) then
				if self.selected ~= true then
						self.area:add_selection(self)
				else
						self.area:remove_selection(self)
						play_sfx('card_slide1', nil, 0.3)
				end
		end
		if self.area and self.area == game().draw_pile and self.area.cards[1] == self then
				if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
						WORD_GAME_UI.TableDeck.show_info()
				end
		end
end
