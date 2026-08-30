--[[ word_game/ui/card_ui.lua - hover UI, click, set_selected, per-frame update ]]

---@class (partial) Card : EaseNode
--- Clears cached ability tooltip UI so it gets rebuilt next time it's shown.
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

    return generate_card_ui(self.config.center, nil, loc_vars, 'Locked')
end

--- Builds the full ability-description tooltip content for this card,
--- choosing the right "card_type" (Locked/Undiscovered/Default/Enhanced/
--- debuffed/etc.) and localization variables based on current state.
--- @return table ui_definition passed to `generate_card_ui`
function Card:build_card_tooltip()
    local card_type, hide_desc = self.ability.set or "None", nil
    local loc_vars = nil
    local main_start, main_end = nil,nil
    
    if not self.bypass_lock and self.config.center.unlocked ~= false and
    (self.ability.set == 'Companion' or self.ability.set == 'Finish' or self.ability.usable or self.ability.set == 'Perk') and
    not self.config.center.discovered then
        card_type = 'Undiscovered'
    end
    if self.config.center.unlocked == false and not self.bypass_lock then
        card_type = "Locked"
    elseif card_type == 'Undiscovered' and not self.bypass_discovery_ui then
        hide_desc = true
        hide_desc = true
    elseif self.debuff then
        loc_vars = { no_name = self.ability.set == 'Default' or self.ability.set == 'Enhanced', debuffed = true, playing_card = not not self.base.colour, value = self.base.value, color_name = (self.base.color == 'red') and 'Red' or 'Black', colour = self.base.colour }
    elseif card_type == 'Default' or card_type == 'Enhanced' then
        local points = self.base.letter_index
        loc_vars = { no_name = true, playing_card = not not self.base.colour, value = self.base.value, color_name = (self.base.color == 'red') and 'Red' or 'Black', colour = self.base.colour,
                    letter_points = points and points > 0 and points or nil,
                    letter_bonus = (self.ability.bonus + (self.ability.perma_bonus or 0)) > 0 and (self.ability.bonus + (self.ability.perma_bonus or 0)) or nil,
                }
    elseif self.ability.set == 'Companion' then
        -- Shop/collection companions were removed from P_CENTERS.
    end
    local badges = {}
    if (card_type ~= 'Locked' and card_type ~= 'Undiscovered' and card_type ~= 'Default') or self.debuff then
        badges.card_type = card_type
    end
    if self.ability.set == 'Companion' and self.bypass_discovery_ui then
        badges.force_rarity = true
    end
    if self.edition then
        if self.edition.type == 'negative' and self.ability.usable then
            badges[#badges + 1] = 'negative_consumable'
        else
            badges[#badges + 1] = (self.edition.type == 'holo' and 'holographic' or self.edition.type)
        end
    end
    if self.seal then badges[#badges + 1] = string.lower(self.seal)..'_seal' end
    if self.pinned then badges[#badges + 1] = 'pinned_left' end

    return generate_card_ui(self.config.center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
end

-- ============ Stat getters ============
-- Small getters used by sorting/scoring code, most of which just apply the
-- `debuff` short-circuit (return 0/nil while debuffed) on top of raw
-- `self.ability`/`self.base` fields. `get_nominal` is the one with real
-- logic worth explaining below; the rest are largely self-describing by name.

--- Sort key combining letter, color, and a per-instance tiebreaker
--- (`unique_val`) so sorts are stable even between identical letters.
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
        local popup_direction = (self.children.buy_button or (self.area and self.area.config.view_deck) or (self.area and self.area.config.type == 'shop')) and 'cl' or 
                                (self.T.y < G.CARD_H*0.8) and 'bm' or
                                'tm'
        return {
            major = self.children.focused_ui or self,
            parent = self,
            xy_bond = 'Strong',
            r_bond = 'Weak',
            wh_bond = 'Weak',
            offset = {
                x = popup_direction ~= 'cl' and 0 or
                    focused_ui and -0.05 or
                    (self.ability.usable and 0.0) or
                    (self.ability.set == 'Perk' and 0.0) or
                    -0.05,
                y = focused_ui and (
                            popup_direction == 'tm' and (self.area and self.area == G.hand and -0.08 or-0.15) or
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
    if self.children.alert and not self.config.center.alerted then
        self.config.center.alerted = true
        G:queue_progress_write()
    end
end

function Card:hover()
    local is_letter = self.ability and (self.ability.set == 'Default' or self.ability.set == 'Enhanced')

    if not is_letter then
        self:pulse(0.05, 0.03)
        play_sfx('hover_card', math.random()*0.2 + 0.9, 0.35)
    end

    -- The gamepad-focused card gets a persistent highlight frame.
    if self.states.focus.is and not self.children.focused_ui then
        self.children.focused_ui = G.DEFINITIONS.card_focus_ui(self)
    end

    if self.facing ~= 'front' or self.no_ui or G.debug_tooltip_toggle then return end
    self:mark_alert_seen()

    -- Letter cards are placed by dragging; no hover popup for them.
    if is_letter then return end

    if not self.states.drag.is or G.INPUT.HID.touch then
        if not self.children.h_popup then
            self.tooltip_info = self:build_card_tooltip()
            self.config.h_popup = G.DEFINITIONS.card_h_popup(self)
            self.config.h_popup_config = self:align_h_popup()
        end
        SceneNode.hover(self)
    end
end


function Card:stop_hover()
    SceneNode.stop_hover(self)
end


function Card:stop_drag()
    SceneNode.stop_drag(self)
    if self.area == G.hand
        and WORD_GAME and WORD_GAME.TableDiscard
        and WORD_GAME.TableDiscard.try_discard(self) then
        return
    end
    if G.placement_table then
        G.placement_table:try_snap_card(self)
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
    if is_playing and G.STATE == G.STATES.TABLE_BOARD then
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
    if self.area and self.area == G.deck and self.area.cards[1] == self then
        if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.uses_table_draw() then
            WORD_GAME.TableDeck.show_info()
        end
    end
end
