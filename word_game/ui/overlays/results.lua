--[[ word_game/ui/overlays/results.lua - Win, game over, and score summary overlays ]]

local Easing = require "app.effects.easing"
local Components = require "word_game.ui.widgets.components"

function build_win()
  local show_win_cta = false
  local eased_green = deep_clone(G.C.GREEN)
  eased_green[4] = 0
  Easing.value{ref_table = eased_green, ref_value = 4, mod = 0.5, not_blockable = true}
  local t = build_generic_options({ padding = 0, bg_colour = eased_green , colour = G.C.BLACK, outline_colour = G.C.FINISH, no_back = true, no_esc = true, contents = {
    {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.OBJECT, config={object = FlowText({string = {localize('hdr_you_win')}, colours = {G.C.FINISH},shadow = true, float = true, spacing = 10, rotate = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}},
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.15}, nodes={
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
    {n=G.UI.ROW, config={align = "cm", padding = 0.08}, nodes={
      build_round_scores_row('hand'),
    }},
    {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.08}, nodes={
        build_round_scores_row('cards_played', G.C.BLUE),
        build_round_scores_row('cards_discarded', G.C.RED),
        build_round_scores_row('cards_purchased', G.C.MONEY),
        build_round_scores_row('times_rerolled', G.C.GREEN),
        build_round_scores_row('new_collection', G.C.WHITE),
        build_round_scores_row('seed', G.C.WHITE),
        Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = G.C.BLUE, textSize = 0.3, width = 2.3, height = 0.4,}),
      }},
      {n=G.UI.COLUMN, config={align = "tr", padding = 0.08}, nodes={
        build_round_scores_row('furthest_set', G.C.FILTER),
        build_round_scores_row('furthest_round', G.C.FILTER),
        {n=G.UI.ROW, config={align = "cm", minh = 0.4, minw = 0.1}, nodes={}},
        not show_win_cta and Components.button({id = 'from_game_won', onClick = 'notify_then_start_run', label = {localize('ui_start_new_run')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide', snap_to = true}}) or nil,
        not show_win_cta and {n=G.UI.ROW, config={align = "cm", minh = 0.2, minw = 0.1}, nodes={}} or nil,
        not show_win_cta and Components.button({onClick = 'return_to_menu', label = {localize('ui_main_menu')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide'}}) or nil,
      }}
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.08}, nodes={
      Components.button({onClick = 'close_overlay', label = {localize('ui_endless')}, width = 6.5, maxw = 5, height = 1.2, textSize = 0.7, shadow = true, colour = G.C.BLUE, focus_args = {nav = 'wide', button = 'x',set_button_pip = true}}),
    }},
  }}
  }}
  }}) 
  t.nodes[1] = {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 2}, nodes={
        {n=G.UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,G.CARD_W*1.1, G.CARD_H*1.1)}},
      }},
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.1}, nodes={t.nodes[1]}
    }}
  }
  --t.nodes[1].config.mid = true
  t.config.id = 'you_win_UI'
  return t
end


function build_exit_CTA()

  local t = build_generic_options({ back_label = 'Quit Game', back_func = 'quit' , colour = G.C.BLACK, back_colour = G.C.RED, padding = 0, contents = {
    {n=G.UI.COLUMN, config={align = "tm", padding = 0.15}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = {localize('hdr_demo_thanks_1')}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.9})}},
      }},
      {n=G.UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = {localize('hdr_demo_thanks_2')}, colours = {G.C.WHITE},shadow = true, bump = true, rotate = true, pop_in = 0.2, scale = 1.4})}},
      }},
      {n=G.UI.ROW, config={align = "tm", padding = 0.12, emboss = 0.1, colour = G.C.L_BLACK, r = 0.1}, nodes={
        simple_text_container('opt_demo_thanks_message',{colour = G.C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}),
        {n=G.UI.ROW, config={align = "cm", padding = 0.2}, nodes={
        }},
      }},
    }}
  }})
  t.nodes[2] = t.nodes[1]
  t.nodes[1] = {n=G.UI.COLUMN, config={align = "cm", padding = 2}, nodes={
    {n=G.UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,G.CARD_W*1.1, G.CARD_H*1.1)}},
  }}   
  --t.nodes[1].config.mid = true
  return t
end


function build_game_over()
  local show_lose_cta = false


  local eased_red = deep_clone(G.GAME.round_resets.ante <= G.GAME.win_ante and G.C.RED or G.C.BLUE)
  eased_red[4] = 0
  Easing.value{ref_table = eased_red, ref_value = 4, mod = 0.8, not_blockable = true}
  local t = build_generic_options({ bg_colour = eased_red ,no_back = true, padding = 0, contents = {
    {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.OBJECT, config={object = FlowText({string = {localize('hdr_game_over')}, colours = {G.C.RED},shadow = true, float = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}},
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.15}, nodes={
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.ROW, config={align = "cm", padding = 0.05, colour = G.C.BLACK, emboss = 0.05, r = 0.1}, nodes={
          {n=G.UI.ROW, config={align = "cm", padding = 0.08}, nodes={
            build_round_scores_row('hand'),
          }},
          {n=G.UI.ROW, config={align = "cm"}, nodes={
            {n=G.UI.COLUMN, config={align = "cm", padding = 0.08}, nodes={
              build_round_scores_row('cards_played', G.C.BLUE),
              build_round_scores_row('cards_discarded', G.C.RED),
              build_round_scores_row('cards_purchased', G.C.MONEY),
              build_round_scores_row('times_rerolled', G.C.GREEN),
              build_round_scores_row('new_collection', G.C.WHITE),
              build_round_scores_row('seed', G.C.WHITE),
              Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = G.C.BLUE, textSize = 0.3, width = 2.3, height = 0.4, focus_args = {nav = 'wide'}}),
            }},
            {n=G.UI.COLUMN, config={align = "tr", padding = 0.08}, nodes={
              build_round_scores_row('furthest_set', G.C.FILTER),
              build_round_scores_row('furthest_round', G.C.FILTER),
              build_round_scores_row('defeated_by'),
            }}
          }}
        }},
        {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
          {n=G.UI.ROW, config={id = 'from_game_over', align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = G.C.RED, button = "notify_then_start_run", shadow = true, focus_args = {nav = 'wide', snap_to = true}}, nodes={
            {n=G.UI.ROW, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
              {n=G.UI.TEXT, config={text = localize('ui_start_new_run'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
            }}
          }},
          {n=G.UI.ROW, config={align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = G.C.RED, button = "return_to_menu", shadow = true, focus_args = {nav = 'wide'}}, nodes={
            {n=G.UI.ROW, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
              {n=G.UI.TEXT, config={text = localize('ui_main_menu'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT}}
            }}
          }}
        }}
      }},
    }}
}})
  t.nodes[1] = {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
    {n=G.UI.COLUMN, config={align = "cm", padding = 2}, nodes={
      {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,G.CARD_W*1.1, G.CARD_H*1.1)}},
      }},
    }},
    {n=G.UI.COLUMN, config={align = "cm", padding = 0.1}, nodes={t.nodes[1]}}}
}

  --t.nodes[1].config.mid = true
  return t
end


function build_round_scores_row(score, text_colour)
  local label = G.GAME.round_scores[score] and localize('hdr_score_'..score) or ''
  local check_high_score = false
  local score_tab = {}
  local label_w, score_w, h = ({hand=true})[score] and 3.5 or 2.9, ({hand=true})[score] and 3.5 or 1, 0.5

  if score == 'furthest_set' then
    label_w = 1.9
    check_high_score = true
    label = 'Set'
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.GAME.round_resets.ante)}, colours = {text_colour or G.C.FILTER},shadow = true, float = true, scale = 0.45})}},
    }
  end
  if score == 'furthest_round' then 
    label_w = 1.9
    check_high_score = true
    label = localize('term_round')
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.GAME.round)}, colours = {text_colour or G.C.FILTER},shadow = true, float = true, scale = 0.45})}},
    }
  end
  if score == 'seed' then 
    label_w = 1.9
    score_w = 1.9
    label = localize('term_seed')
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {G.GAME.seed_streams.seed}, colours = {text_colour or G.C.WHITE},shadow = true, float = true, scale = 0.45})}},
    }
  end
  if score == 'defeated_by' then
    label = localize('term_defeated_by')
    score_tab = {
      {n=G.UI.ROW, config={align = "cm", minh = 0.6}, nodes={
        {n=G.UI.TEXT, config={text = (G.GAME.word_round and G.GAME.word_round.hand_name) or '', colours = {G.C.WHITE}, shadow = true, scale = 0.45}}
      }},
    }
  end

  local label_scale = 0.5

  if score == 'hand' then
    check_high_score = true
    local chip_sprite = Sprite(0,0,0.3,0.3,G.TEXTURE_ATLASES.ui_1, {x=0, y=0})
    chip_sprite.states.drag.can = false
    score_tab = {
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={w=0.3,h=0.3 , object = chip_sprite}}
      }},
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.GAME.round_scores[score].amt)}, colours = {text_colour or G.C.RED},shadow = true, float = true, scale = math.min(0.6, score_number_scale(1.2, G.GAME.round_scores[score].amt))})}},
      }},
    }
  elseif G.GAME.round_scores[score] and not score_tab[1] then 
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.GAME.round_scores[score].amt)}, colours = {text_colour or G.C.FILTER},shadow = true, float = true, scale = score_number_scale(0.6, G.GAME.round_scores[score].amt)})}},
    }
  end
  return {n=G.UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = shade(G.C.MUTED_GREY, 0.1), emboss = 0.05, func = check_high_score and 'high_score_alert' or nil, id = score}, nodes={
    {n=score=='defeated_by' and G.UI.ROW or G.UI.COLUMN, config={align = "cm", padding = 0.02, minw = label_w, maxw = label_w}, nodes={
        {n=G.UI.TEXT, config={text = label, scale = label_scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
    }},
    {n=score=='defeated_by' and G.UI.ROW or G.UI.COLUMN, config={align = "cr"}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", minh = h, r = 0.1, minw = score=='defeated_by' and label_w or score_w, colour = (score == 'seed' and G.GAME.seeded) and G.C.RED or G.C.BLACK, emboss = 0.05}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = score_w}, nodes=score_tab},
      }}
    }},
  }}
end

