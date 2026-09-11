--[[ word_game/ui/overlays/results.lua - Win, game over, and score summary overlays ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Easing = require "word_game.ui.effects.easing"
local Components = require "word_game.ui.widgets.components"
local game_access = require("word_game.model.game_access")

function build_win()
  local show_win_cta = false
  local eased_green = deep_clone(runtime().C.GREEN)
  eased_green[4] = 0
  Easing.value{ref_table = eased_green, ref_value = 4, mod = 0.5, not_blockable = true}
  local t = build_generic_options({ padding = 0, bg_colour = eased_green , colour = runtime().C.BLACK, outline_colour = runtime().C.FINISH, no_back = true, no_esc = true, contents = {
    {n=runtime().UI.ROW, config={align = "cm"}, nodes={
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {localize('hdr_you_win')}, colours = {runtime().C.FINISH},shadow = true, float = true, spacing = 10, rotate = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}},
    }},
    {n=runtime().UI.ROW, config={align = "cm", padding = 0.15}, nodes={
      {n=runtime().UI.COLUMN, config={align = "cm"}, nodes={
    {n=runtime().UI.ROW, config={align = "cm", padding = 0.08}, nodes={
      build_round_scores_row('hand'),
    }},
    {n=runtime().UI.ROW, config={align = "cm"}, nodes={
      {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.08}, nodes={
        build_round_scores_row('cards_discarded', runtime().C.RED),
        build_round_scores_row('seed', runtime().C.WHITE),
        Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = runtime().C.BLUE, textSize = 0.3, width = 2.3, height = 0.4,}),
      }},
      {n=runtime().UI.COLUMN, config={align = "tr", padding = 0.08}, nodes={
        build_round_scores_row('furthest_set', runtime().C.FILTER),
        build_round_scores_row('furthest_round', runtime().C.FILTER),
        {n=runtime().UI.ROW, config={align = "cm", minh = 0.4, minw = 0.1}, nodes={}},
        not show_win_cta and Components.button({id = 'from_game_won', onClick = 'notify_then_start_run', label = {localize('ui_start_new_run')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide', snap_to = true}}) or nil,
        not show_win_cta and {n=runtime().UI.ROW, config={align = "cm", minh = 0.2, minw = 0.1}, nodes={}} or nil,
        not show_win_cta and Components.button({onClick = 'return_to_menu', label = {localize('ui_main_menu')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide'}}) or nil,
      }}
    }},
  }}
  }}
  }}) 
  t.nodes[1] = {n=runtime().UI.ROW, config={align = "cm", padding = 0.1}, nodes={
      {n=runtime().UI.COLUMN, config={align = "cm", padding = 2}, nodes={
        {n=runtime().UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,runtime().CARD_W*1.1, runtime().CARD_H*1.1)}},
      }},
      {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.1}, nodes={t.nodes[1]}
    }}
  }
  --t.nodes[1].config.mid = true
  t.config.id = 'you_win_UI'
  return t
end


function build_exit_CTA()

  local t = build_generic_options({ back_label = 'Quit Game', back_func = 'quit' , colour = runtime().C.BLACK, back_colour = runtime().C.RED, padding = 0, contents = {
    {n=runtime().UI.COLUMN, config={align = "tm", padding = 0.15}, nodes={
      {n=runtime().UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=runtime().UI.OBJECT, config={object = FlowText({string = {localize('hdr_demo_thanks_1')}, colours = {runtime().C.WHITE},shadow = true, float = true, scale = 0.9})}},
      }},
      {n=runtime().UI.ROW, config={align = "cm", padding = 0}, nodes={
        {n=runtime().UI.OBJECT, config={object = FlowText({string = {localize('hdr_demo_thanks_2')}, colours = {runtime().C.WHITE},shadow = true, bump = true, rotate = true, pop_in = 0.2, scale = 1.4})}},
      }},
      {n=runtime().UI.ROW, config={align = "tm", padding = 0.12, emboss = 0.1, colour = runtime().C.L_BLACK, r = 0.1}, nodes={
        simple_text_container('opt_demo_thanks_message',{colour = runtime().C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}),
        {n=runtime().UI.ROW, config={align = "cm", padding = 0.2}, nodes={
        }},
      }},
    }}
  }})
  t.nodes[2] = t.nodes[1]
  t.nodes[1] = {n=runtime().UI.COLUMN, config={align = "cm", padding = 2}, nodes={
    {n=runtime().UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,runtime().CARD_W*1.1, runtime().CARD_H*1.1)}},
  }}   
  --t.nodes[1].config.mid = true
  return t
end


function build_game_over()
  local show_lose_cta = false

  local eased_red = deep_clone(runtime().C.RED)
  eased_red[4] = 0
  Easing.value{ref_table = eased_red, ref_value = 4, mod = 0.8, not_blockable = true}
  local t = build_generic_options({ bg_colour = eased_red ,no_back = true, padding = 0, contents = {
    {n=runtime().UI.ROW, config={align = "cm"}, nodes={
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {localize('hdr_game_over')}, colours = {runtime().C.RED},shadow = true, float = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}},
    }},
    {n=runtime().UI.ROW, config={align = "cm", padding = 0.15}, nodes={
      {n=runtime().UI.COLUMN, config={align = "cm"}, nodes={
        {n=runtime().UI.ROW, config={align = "cm", padding = 0.05, colour = runtime().C.BLACK, emboss = 0.05, r = 0.1}, nodes={
          {n=runtime().UI.ROW, config={align = "cm", padding = 0.08}, nodes={
            build_round_scores_row('hand'),
          }},
          {n=runtime().UI.ROW, config={align = "cm"}, nodes={
            {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.08}, nodes={
              build_round_scores_row('cards_discarded', runtime().C.RED),
              build_round_scores_row('seed', runtime().C.WHITE),
              Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = runtime().C.BLUE, textSize = 0.3, width = 2.3, height = 0.4, focus_args = {nav = 'wide'}}),
            }},
            {n=runtime().UI.COLUMN, config={align = "tr", padding = 0.08}, nodes={
              build_round_scores_row('furthest_set', runtime().C.FILTER),
              build_round_scores_row('furthest_round', runtime().C.FILTER),
            }}
          }}
        }},
        {n=runtime().UI.ROW, config={align = "cm", padding = 0.1}, nodes={
          {n=runtime().UI.ROW, config={id = 'from_game_over', align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = runtime().C.RED, button = "notify_then_start_run", shadow = true, focus_args = {nav = 'wide', snap_to = true}}, nodes={
            {n=runtime().UI.ROW, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
              {n=runtime().UI.TEXT, config={text = localize('ui_start_new_run'), scale = 0.5, colour = runtime().C.UI.TEXT_LIGHT}}
            }}
          }},
          {n=runtime().UI.ROW, config={align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = runtime().C.RED, button = "return_to_menu", shadow = true, focus_args = {nav = 'wide'}}, nodes={
            {n=runtime().UI.ROW, config={align = "cm", padding = 0, no_fill = true, maxw = 4.8}, nodes={
              {n=runtime().UI.TEXT, config={text = localize('ui_main_menu'), scale = 0.5, colour = runtime().C.UI.TEXT_LIGHT}}
            }}
          }}
        }}
      }},
    }}
}})
  t.nodes[1] = {n=runtime().UI.ROW, config={align = "cm", padding = 0.1}, nodes={
    {n=runtime().UI.COLUMN, config={align = "cm", padding = 2}, nodes={
      {n=runtime().UI.ROW, config={align = "cm"}, nodes={
        {n=runtime().UI.OBJECT, config={padding = 0, id = 'mascot_spot', object = EaseNode(0,0,runtime().CARD_W*1.1, runtime().CARD_H*1.1)}},
      }},
    }},
    {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.1}, nodes={t.nodes[1]}}}
}

  --t.nodes[1].config.mid = true
  return t
end


function build_round_scores_row(score, text_colour)
  local game = game_access.get()
  local label = game and game.round_scores[score] and localize('hdr_score_'..score) or ''
  local check_high_score = false
  local score_tab = {}
  local label_w, score_w, h = ({hand=true})[score] and 3.5 or 2.9, ({hand=true})[score] and 3.5 or 1, 0.5

  if score == 'furthest_set' then
    label_w = 1.9
    check_high_score = true
    label = 'Set'
    score_tab = {
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {number_format((game and game.word_round and game.word_round.set) or 0)}, colours = {text_colour or runtime().C.FILTER},shadow = true, float = true, scale = 0.45})}},
    }
  end
  if score == 'furthest_round' then 
    label_w = 1.9
    check_high_score = true
    label = localize('term_round')
    score_tab = {
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {number_format(game and game.round or 0)}, colours = {text_colour or runtime().C.FILTER},shadow = true, float = true, scale = 0.45})}},
    }
  end
  if score == 'seed' then 
    label_w = 1.9
    score_w = 1.9
    label = localize('term_seed')
    score_tab = {
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {game and game.seed_streams and game.seed_streams.seed or ""}, colours = {text_colour or runtime().C.WHITE},shadow = true, float = true, scale = 0.45})}},
    }
  end

  local label_scale = 0.5

  if score == 'hand' then
    check_high_score = true
    local chip_sprite = Sprite(0,0,0.3,0.3,runtime().TEXTURE_ATLASES.ui_1, {x=0, y=0})
    chip_sprite.states.drag.can = false
    score_tab = {
      {n=runtime().UI.COLUMN, config={align = "cm"}, nodes={
        {n=runtime().UI.OBJECT, config={w=0.3,h=0.3 , object = chip_sprite}}
      }},
      {n=runtime().UI.COLUMN, config={align = "cm"}, nodes={
        {n=runtime().UI.OBJECT, config={object = FlowText({string = {number_format(game.round_scores[score].amt)}, colours = {text_colour or runtime().C.RED},shadow = true, float = true, scale = math.min(0.6, score_number_scale(1.2, game.round_scores[score].amt))})}},
      }},
    }
  elseif game and game.round_scores[score] and not score_tab[1] then 
    score_tab = {
      {n=runtime().UI.OBJECT, config={object = FlowText({string = {number_format(game.round_scores[score].amt)}, colours = {text_colour or runtime().C.FILTER},shadow = true, float = true, scale = score_number_scale(0.6, game.round_scores[score].amt)})}},
    }
  end
  return {n=runtime().UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = shade(runtime().C.MUTED_GREY, 0.1), emboss = 0.05, func = check_high_score and 'high_score_alert' or nil, id = score}, nodes={
    {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.02, minw = label_w, maxw = label_w}, nodes={
        {n=runtime().UI.TEXT, config={text = label, scale = label_scale, colour = runtime().C.UI.TEXT_LIGHT, shadow = true}},
    }},
    {n=runtime().UI.COLUMN, config={align = "cr"}, nodes={
      {n=runtime().UI.COLUMN, config={align = "cm", minh = h, r = 0.1, minw = score_w, colour = (score == 'seed' and game and game.seeded) and runtime().C.RED or runtime().C.BLACK, emboss = 0.05}, nodes={
        {n=runtime().UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = score_w}, nodes=score_tab},
      }}
    }},
  }}
end

