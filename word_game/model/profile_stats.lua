--[[
	word_game/model/profile_stats.lua - gameplay progress, profile stats, and input locks.

	Companion/deck/consumable usage, high scores, discovery tallies, and STOP_USE
	all write G.PROFILES / G.GAME then save settings.
]]
local Scheduler = require "app.effects.scheduler"


function alert_no_space(card, area)
  G.INPUT.locks.no_space = true
  spawn_attention({
      scale = 0.9, text = localize('term_no_space_ex'), hold = 0.9, align = 'cm',
      cover = area, cover_padding = 0.1, cover_colour = with_alpha(G.C.BLACK, 0.7)
  })
  card:pulse(0.3, 0.2)
  for i = 1, #area.cards do
    area.cards[i]:pulse(0.15)
  end
  Scheduler.add{mode = 'delayed', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
    play_sfx('tarot2', 0.76, 0.4);return true end}
    play_sfx('tarot2', 1, 0.4)

    Scheduler.add{mode = 'delayed', delay = 0.5*G.SETTINGS.GAMESPEED, blockable = false, blocking = false,
    func = function()
      G.INPUT.locks.no_space = nil
    return true end}
end

function find_joker(name, non_debuff)
  -- Legacy probe over the old companion/consumable trays; both stay empty in the
  -- letter-deck game, so this can only ever report 'not found'.
  return {}
end

function send_score(_score)
  return _score
end

function send_name()
end

function check_and_set_high_score(score, amt)
  if not amt or type(amt) ~= 'number' then return end
  if G.GAME.round_scores[score] and math.floor(amt) > G.GAME.round_scores[score].amt then
    G.GAME.round_scores[score].amt = math.floor(amt)
  end
  if  G.GAME.seeded  then return end
  if score == 'hand' and G.SETTINGS.COMP and ((not G.SETTINGS.COMP.score) or (G.SETTINGS.COMP.score < math.floor(amt))) then 
    G.SETTINGS.COMP.score = amt
    send_score(math.floor(amt))
  end
  if G.PROFILES[G.SETTINGS.profile].high_scores[score] and math.floor(amt) > G.PROFILES[G.SETTINGS.profile].high_scores[score].amt then
    if G.GAME.round_scores[score] then G.GAME.round_scores[score].high_score = true end
    G.PROFILES[G.SETTINGS.profile].high_scores[score].amt = math.floor(amt)
    G:queue_settings_write()
  end
end



function set_deck_usage()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.center and G.GAME.selected_back.effect.center.key then
    local deck_key = G.GAME.selected_back.effect.center.key
    if G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] then
      G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].count = G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].count + 1
    else
      G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.center.order, wins = {}, losses = {}}
    end
    G:queue_settings_write()
  end
end

function set_deck_win()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.center and G.GAME.selected_back.effect.center.key then
    local deck_key = G.GAME.selected_back.effect.center.key
    if not G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] then G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.center.order, wins = {}, losses = {}} end
    if G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] then
      G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].wins[G.GAME.stake] = (G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].wins[G.GAME.stake] or 0) + 1
      for i = 1, G.GAME.stake do
        G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].wins[i] = (G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].wins[i] or 1)
      end
    end
    set_challenge_unlock()
    G:queue_settings_write()
  end
end

function set_challenge_unlock()
  if G.PROFILES[G.SETTINGS.profile].all_unlocked then return end
  if G.PROFILES[G.SETTINGS.profile].challenges_unlocked then
    local _ch_comp, _ch_tot = 0,#G.CHALLENGES
    for k, v in ipairs(G.CHALLENGES) do
      if v.id and G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id or ''] then
        _ch_comp = _ch_comp + 1
      end
    end
    G.PROFILES[G.SETTINGS.profile].challenges_unlocked = math.min(_ch_tot, _ch_comp+5)
  else
    local deck_wins = 0
    for k, v in pairs(G.PROFILES[G.SETTINGS.profile].deck_usage) do
      if v.wins and v.wins[1] then
        deck_wins = deck_wins + 1
      end
    end
    if deck_wins >= G.CHALLENGE_WINS and not G.PROFILES[G.SETTINGS.profile].challenges_unlocked then
      G.PROFILES[G.SETTINGS.profile].challenges_unlocked = 5
      notify_alert('ui_challenge', "Back")
    end
  end
end

function get_deck_win_stake(_deck_key)
  if not _deck_key then 
    local _w, _w_low = 0, nil
    local deck_count = 0
    for _, deck in pairs(G.PROFILES[G.SETTINGS.profile].deck_usage) do 
      deck_count = deck_count + 1
      for k, v in pairs(deck.wins) do
        _w = math.max(k, _w)
      end
      _w_low = _w_low and (math.min(_w_low, _w)) or _w
    end
    return _w, ((deck_count >= #G.P_CENTER_POOLS.Back) and _w_low or 0)
  end
  if G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key] and
     G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key].wins then 
    local _w = 0
    for k, v in pairs(G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key].wins) do
      _w = math.max(k, _w)
    end
    return _w
  end
  return 0
end

function set_deck_loss()
  if G.GAME.selected_back and G.GAME.selected_back.effect and G.GAME.selected_back.effect.center and G.GAME.selected_back.effect.center.key then
    local deck_key = G.GAME.selected_back.effect.center.key
    if not G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] then G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] = {count = 1, order = G.GAME.selected_back.effect.center.order, wins = {}, losses = {}} end
    if G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key] then
      G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].losses[G.GAME.stake] = (G.PROFILES[G.SETTINGS.profile].deck_usage[deck_key].losses[G.GAME.stake] or 0) + 1
    end
    G:queue_settings_write()
  end
end

function set_usable_usage(card)
    if card.config.center_key and card.ability.usable then
      if G.PROFILES[G.SETTINGS.profile].usable_usage[card.config.center_key] then
        G.PROFILES[G.SETTINGS.profile].usable_usage[card.config.center_key].count = G.PROFILES[G.SETTINGS.profile].usable_usage[card.config.center_key].count + 1
      else
        G.PROFILES[G.SETTINGS.profile].usable_usage[card.config.center_key] = {count = 1, order = card.config.center.order}
      end
      if G.GAME.usable_usage[card.config.center_key] then
        G.GAME.usable_usage[card.config.center_key].count = G.GAME.usable_usage[card.config.center_key].count + 1
      else
        G.GAME.usable_usage[card.config.center_key] = {count = 1, order = card.config.center.order, set = card.ability.set}
      end
      G.GAME.usable_usage_total = G.GAME.usable_usage_total or {orbit = 0, phantom = 0, all = 0}
      if card.config.center.set == 'Orbit' then
        G.GAME.usable_usage_total.orbit = G.GAME.usable_usage_total.orbit + 1
      elseif card.config.center.set == 'Phantom' then
        G.GAME.usable_usage_total.phantom = G.GAME.usable_usage_total.phantom + 1
      end

      G.GAME.usable_usage_total.all = G.GAME.usable_usage_total.all + 1

      if not card.config.center.discovered then
        discover_card(card)
      end

    end
    G:queue_settings_write()
end

function set_voucher_usage(card)
  if card.config.center_key and card.ability.set == 'Perk' then
    if G.PROFILES[G.SETTINGS.profile].bonus_usage[card.config.center_key] then
      G.PROFILES[G.SETTINGS.profile].bonus_usage[card.config.center_key].count = G.PROFILES[G.SETTINGS.profile].bonus_usage[card.config.center_key].count + 1
    else
      G.PROFILES[G.SETTINGS.profile].bonus_usage[card.config.center_key] = {count = 1, order = card.config.center.order}
    end
  end
  G:queue_settings_write()
end

function set_hand_usage(hand)
  local hand_label = hand
  hand = hand:gsub("%s+", "")
  if G.PROFILES[G.SETTINGS.profile].hand_usage[hand] then
    G.PROFILES[G.SETTINGS.profile].hand_usage[hand].count = G.PROFILES[G.SETTINGS.profile].hand_usage[hand].count + 1
  else
    G.PROFILES[G.SETTINGS.profile].hand_usage[hand] = {count = 1, order = hand_label}
  end
  if G.GAME.hand_usage[hand] then
    G.GAME.hand_usage[hand].count = G.GAME.hand_usage[hand].count + 1
  else
    G.GAME.hand_usage[hand] = {count = 1, order = hand_label}
  end
  G:queue_settings_write()
end

function set_profile_progress()
  G.PROGRESS = G.PROGRESS or {
    joker_stickers = {tally = 0, of = 0},
    deck_stakes = {tally = 0, of = 0},
    challenges = {tally = 0, of = 0},
  }
  for _, v in pairs(G.PROGRESS) do
    if type(v) == 'table' then
      v.tally = 0
      v.of = 0
    end
  end

  for _, v in pairs(G.P_CENTERS) do
    if v.set == 'Back' and not v.omit then
      G.PROGRESS.deck_stakes.of = G.PROGRESS.deck_stakes.of + #(G.P_CENTER_POOLS.Stake or {})
      G.PROGRESS.deck_stakes.tally = G.PROGRESS.deck_stakes.tally + get_deck_win_stake(v.key)
    end
  end

  for _, v in pairs(G.CHALLENGES) do
    G.PROGRESS.challenges.of = G.PROGRESS.challenges.of + 1
    if G.PROFILES[G.SETTINGS.profile].challenge_progress.completed[v.id] then
      G.PROGRESS.challenges.tally = G.PROGRESS.challenges.tally + 1
    end
  end

  G.PROFILES[G.SETTINGS.profile].progress.joker_stickers = deep_clone(G.PROGRESS.joker_stickers)
  G.PROFILES[G.SETTINGS.profile].progress.deck_stakes = deep_clone(G.PROGRESS.deck_stakes)
  G.PROFILES[G.SETTINGS.profile].progress.challenges = deep_clone(G.PROGRESS.challenges)
end

function discover_card(card)
  if G.GAME.seeded or G.GAME.challenge then return end
  card = card or {}
  if card.discovered or card.wip then return end
  card.discovered = true
  sync_discover_counts()
  Scheduler.add{
    func = function()
      G:queue_progress_write()
      return true
    end,
  }
end

function sync_discover_counts()
  G.DISCOVER_TALLIES = G.DISCOVER_TALLIES or {
      companions = {tally = 0, of = 0},
      usables = {tally = 0, of = 0},
      orbits = {tally = 0, of = 0},
      phantoms = {tally = 0, of = 0},
      perks = {tally = 0, of = 0},
      editions = {tally = 0, of = 0},
      backs = {tally = 0, of = 0},
      total = {tally = 0, of = 0},
    }
  for _, v in pairs(G.DISCOVER_TALLIES) do
      v.tally = 0
      v.of = 0
  end
  
  for _, v in pairs(G.P_CENTERS) do
    if not v.omit then 
      if v.set and ((v.set == 'Companion') or v.usable or (v.set == 'Finish') or (v.set == 'Perk') or (v.set == 'Back')) then
        G.DISCOVER_TALLIES.total.of = G.DISCOVER_TALLIES.total.of+1
        if v.discovered then 
          G.DISCOVER_TALLIES.total.tally = G.DISCOVER_TALLIES.total.tally+1
        end
      end
      if v.set and v.set == 'Companion' then
        G.DISCOVER_TALLIES.companions.of = G.DISCOVER_TALLIES.companions.of+1
        if v.discovered then 
            G.DISCOVER_TALLIES.companions.tally = G.DISCOVER_TALLIES.companions.tally+1
        end
      end
      if v.set and v.set == 'Back' then
        G.DISCOVER_TALLIES.backs.of = G.DISCOVER_TALLIES.backs.of+1
        if v.unlocked then 
            G.DISCOVER_TALLIES.backs.tally = G.DISCOVER_TALLIES.backs.tally+1
        end
      end
      if v.set and v.usable then
        G.DISCOVER_TALLIES.usables.of = G.DISCOVER_TALLIES.usables.of+1
        if v.discovered then 
            G.DISCOVER_TALLIES.usables.tally = G.DISCOVER_TALLIES.usables.tally+1
        end
        if v.set == 'Orbit' then
          G.DISCOVER_TALLIES.orbits.of = G.DISCOVER_TALLIES.orbits.of+1
          if v.discovered then 
              G.DISCOVER_TALLIES.orbits.tally = G.DISCOVER_TALLIES.orbits.tally+1
          end
        elseif v.set == 'Phantom' then
          G.DISCOVER_TALLIES.phantoms.of = G.DISCOVER_TALLIES.phantoms.of+1
          if v.discovered then 
              G.DISCOVER_TALLIES.phantoms.tally = G.DISCOVER_TALLIES.phantoms.tally+1
          end
        end
      end
      if v.set and v.set == 'Perk' then
        G.DISCOVER_TALLIES.perks.of = G.DISCOVER_TALLIES.perks.of+1
        if v.discovered then 
            G.DISCOVER_TALLIES.perks.tally = G.DISCOVER_TALLIES.perks.tally+1
        end
      end
      if v.set and v.set == 'Finish' then
        G.DISCOVER_TALLIES.editions.of = G.DISCOVER_TALLIES.editions.of+1
        if v.discovered then 
            G.DISCOVER_TALLIES.editions.tally = G.DISCOVER_TALLIES.editions.tally+1
        end
      end
    end
  end
  G.PROFILES[G.SETTINGS.profile].high_scores.collection.amt = G.DISCOVER_TALLIES.total.tally
  G.PROFILES[G.SETTINGS.profile].high_scores.collection.tot = G.DISCOVER_TALLIES.total.of
  G.PROFILES[G.SETTINGS.profile].progress.discovered = deep_clone(G.DISCOVER_TALLIES.total)

end

function stop_use()
  G.GAME.STOP_USE = (G.GAME.STOP_USE or 0) + 1
  dec_stop_use(6)
end

function dec_stop_use(_depth)
  if _depth > 0 then 
  Scheduler.add{
    blocking = false,
    persistent = true,
    func = (function()
    dec_stop_use(_depth - 1)
  return true end)}
  else
    Scheduler.add{
      blocking = false,
      persistent = true,
      func = (function()
      G.GAME.STOP_USE = math.max(G.GAME.STOP_USE - 1, 0)
    return true end)}
  end
end

function inc_career_stat(stat, mod)
  if G.GAME.seeded or G.GAME.challenge then return end
  if not G.PROFILES[G.SETTINGS.profile].career_stats[stat] then G.PROFILES[G.SETTINGS.profile].career_stats[stat] = 0 end
  G.PROFILES[G.SETTINGS.profile].career_stats[stat] = G.PROFILES[G.SETTINGS.profile].career_stats[stat] + (mod or 0)
  G:queue_settings_write()
end
