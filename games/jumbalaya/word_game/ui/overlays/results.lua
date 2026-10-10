--[[ word_game/ui/overlays/results.lua - Win, game over, and score summary overlays ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local game = require("word_game.ui.util.game_runtime").game

local NumberFormat = require("jumbalaya-engine.util.number_format")
local Easing = require "word_game.ui.effects.easing"
local Components = require "word_game.ui.widgets.components"
local Colour = require("jumbalaya-engine.util.colour")
local Tables = require("jumbalaya-engine.util.tables")

local localize = require("word_game.ui.util.localize").localize
local Panel = require("jumbalaya-engine.panels.api")
local Spatial = require("jumbalaya-engine.scene.animated.init")
local Press = require("word_game.ui.widgets.press")
function build_win()
	local show_win_cta = false
	local eased_green = Tables.deep_clone(game().C.GREEN)
	eased_green[4] = 0
	Easing.value{ref_table = eased_green, ref_value = 4, mod = 0.5, not_blockable = true}
	local t = build_generic_options({ padding = 0, bg_colour = eased_green , colour = game().C.BLACK, outline_colour = game().C.FINISH, no_back = true, no_esc = true, contents = {
		Panel.row({align = "cm"}, {
			Panel.object({object = FlowText({string = {localize('hdr_you_win')}, colours = {game().C.FINISH},shadow = true, float = true, spacing = 10, rotate = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}),
		}),
		Panel.row({align = "cm", padding = 0.15}, {
			Panel.column({align = "cm"}, {
		Panel.row({align = "cm", padding = 0.08}, {
			build_round_scores_row('hand'),
		}),
		Panel.row({align = "cm"}, {
			Panel.column({align = "cm", padding = 0.08}, {
				build_round_scores_row('cards_discarded', game().C.RED),
				build_round_scores_row('seed', game().C.WHITE),
				Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = game().C.BLUE, textSize = 0.3, width = 2.3, height = 0.4,}),
			}),
			Panel.column({align = "tr", padding = 0.08}, {
				build_round_scores_row('furthest_set', game().C.FILTER),
				build_round_scores_row('furthest_round', game().C.FILTER),
				Panel.row({align = "cm", minh = 0.4, minw = 0.1}, {}),
				not show_win_cta and Components.button({id = 'from_game_won', onClick = 'notify_then_start_run', label = {localize('ui_start_new_run')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide', snap_to = true}}) or nil,
				not show_win_cta and Panel.row({align = "cm", minh = 0.2, minw = 0.1}, {}) or nil,
				not show_win_cta and Components.button({onClick = 'return_to_menu', label = {localize('ui_main_menu')}, width = 2.5, maxw = 2.5, height = 1, focus_args = {nav = 'wide'}}) or nil,
			})
		}),
	})
	})
	}}) 
	t.nodes[1] = Panel.row({align = "cm", padding = 0.1}, {
			Panel.column({align = "cm", padding = 2}, {
				Panel.object({padding = 0, id = 'mascot_spot', object = Spatial(0,0,game().CARD_W*1.1, game().CARD_H*1.1)}),
			}),
			Panel.column({align = "cm", padding = 0.1}, {t.nodes[1]})})
	--t.nodes[1].config.mid = true
	t.config.id = 'you_win_UI'
	return t
end


function build_exit_CTA()

	local t = build_generic_options({ back_label = 'Quit Game', back_func = 'quit' , colour = game().C.BLACK, back_colour = game().C.RED, padding = 0, contents = {
		Panel.column({align = "tm", padding = 0.15}, {
			Panel.row({align = "cm", padding = 0}, {
				Panel.object({object = FlowText({string = {localize('hdr_demo_thanks_1')}, colours = {game().C.WHITE},shadow = true, float = true, scale = 0.9})}),
			}),
			Panel.row({align = "cm", padding = 0}, {
				Panel.object({object = FlowText({string = {localize('hdr_demo_thanks_2')}, colours = {game().C.WHITE},shadow = true, bump = true, rotate = true, pop_in = 0.2, scale = 1.4})}),
			}),
			Panel.row({align = "tm", padding = 0.12, emboss = 0.1, colour = game().C.L_BLACK, r = 0.1}, {
				simple_text_container('opt_demo_thanks_message',{colour = game().C.UI.TEXT_LIGHT, scale = 0.55, shadow = true}),
				Panel.row({align = "cm", padding = 0.2}, {
				}),
			}),
		})
	}})
	t.nodes[2] = t.nodes[1]
	t.nodes[1] = Panel.column({align = "cm", padding = 2}, {
		Panel.object({padding = 0, id = 'mascot_spot', object = Spatial(0,0,game().CARD_W*1.1, game().CARD_H*1.1)}),
	})   
	--t.nodes[1].config.mid = true
	return t
end


function build_game_over()
	local show_lose_cta = false

	local eased_red = Tables.deep_clone(game().C.RED)
	eased_red[4] = 0
	Easing.value{ref_table = eased_red, ref_value = 4, mod = 0.8, not_blockable = true}
	local t = build_generic_options({ bg_colour = eased_red ,no_back = true, padding = 0, contents = {
		Panel.row({align = "cm"}, {
			Panel.object({object = FlowText({string = {localize('hdr_game_over')}, colours = {game().C.RED},shadow = true, float = true, scale = 1.5, pop_in = 0.4, maxw = 6.5})}),
		}),
		Panel.row({align = "cm", padding = 0.15}, {
			Panel.column({align = "cm"}, {
				Panel.row({align = "cm", padding = 0.05, colour = game().C.BLACK, emboss = 0.05, r = 0.1}, {
					Panel.row({align = "cm", padding = 0.08}, {
						build_round_scores_row('hand'),
					}),
					Panel.row({align = "cm"}, {
						Panel.column({align = "cm", padding = 0.08}, {
							build_round_scores_row('cards_discarded', game().C.RED),
							build_round_scores_row('seed', game().C.WHITE),
							Components.button({onClick = 'copy_run_seed', label = {localize('ui_copy')}, colour = game().C.BLUE, textSize = 0.3, width = 2.3, height = 0.4, focus_args = {nav = 'wide'}}),
						}),
						Panel.column({align = "tr", padding = 0.08}, {
							build_round_scores_row('furthest_set', game().C.FILTER),
							build_round_scores_row('furthest_round', game().C.FILTER),
						})
					})
				}),
				Panel.row({align = "cm", padding = 0.1}, {
					Panel.row({id = 'from_game_over', align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = game().C.RED, on_press = Press.named("notify_then_start_run"), shadow = true, focus_args = {nav = 'wide', snap_to = true}}, {
						Panel.row({align = "cm", padding = 0, no_fill = true, maxw = 4.8}, {
							Panel.label({text = localize('ui_start_new_run'), scale = 0.5, colour = game().C.UI.TEXT_LIGHT})
						})
					}),
					Panel.row({align = "cm", minw = 5, padding = 0.1, r = 0.1, hover = true, colour = game().C.RED, on_press = Press.named("return_to_menu"), shadow = true, focus_args = {nav = 'wide'}}, {
						Panel.row({align = "cm", padding = 0, no_fill = true, maxw = 4.8}, {
							Panel.label({text = localize('ui_main_menu'), scale = 0.5, colour = game().C.UI.TEXT_LIGHT})
						})
					})
				})
			}),
		})
}})
	t.nodes[1] = Panel.row({align = "cm", padding = 0.1}, {
		Panel.column({align = "cm", padding = 2}, {
			Panel.row({align = "cm"}, {
				Panel.object({padding = 0, id = 'mascot_spot', object = Spatial(0,0,game().CARD_W*1.1, game().CARD_H*1.1)}),
			}),
		}),
		Panel.column({align = "cm", padding = 0.1}, {t.nodes[1]})})

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
			Panel.object({object = FlowText({string = {NumberFormat.number_format((game and game.word_round and game.word_round.set) or 0)}, colours = {text_colour or game().C.FILTER},shadow = true, float = true, scale = 0.45})}),
		}
	end
	if score == 'furthest_round' then 
		label_w = 1.9
		check_high_score = true
		label = localize('term_round')
		score_tab = {
			Panel.object({object = FlowText({string = {NumberFormat.number_format(game and game.round or 0)}, colours = {text_colour or game().C.FILTER},shadow = true, float = true, scale = 0.45})}),
		}
	end
	if score == 'seed' then 
		label_w = 1.9
		score_w = 1.9
		label = localize('term_seed')
		score_tab = {
			Panel.object({object = FlowText({string = {game and game.seed_streams and game.seed_streams.seed or ""}, colours = {text_colour or game().C.WHITE},shadow = true, float = true, scale = 0.45})}),
		}
	end

	local label_scale = 0.5

	if score == 'hand' then
		check_high_score = true
		local chip_sprite = Sprite(0,0,0.3,0.3,game().TEXTURE_ATLASES.ui_1, {x=0, y=0})
		chip_sprite.states.drag.can = false
		score_tab = {
			Panel.column({align = "cm"}, {
				Panel.object({w=0.3,h=0.3 , object = chip_sprite})
			}),
			Panel.column({align = "cm"}, {
				Panel.object({object = FlowText({string = {NumberFormat.number_format(game.round_scores[score].amt)}, colours = {text_colour or game().C.RED},shadow = true, float = true, scale = math.min(0.6, NumberFormat.score_number_scale(1.2, game.round_scores[score].amt))})}),
			}),
		}
	elseif game and game.round_scores[score] and not score_tab[1] then 
		score_tab = {
			Panel.object({object = FlowText({string = {NumberFormat.number_format(game.round_scores[score].amt)}, colours = {text_colour or game().C.FILTER},shadow = true, float = true, scale = NumberFormat.score_number_scale(0.6, game.round_scores[score].amt)})}),
		}
	end
	return Panel.row({align = "cm", padding = 0.05, r = 0.1, colour = Colour.shade(game().C.MUTED_GREY, 0.1), emboss = 0.05, func = check_high_score and 'high_score_alert' or nil, id = score}, {
		Panel.column({align = "cm", padding = 0.02, minw = label_w, maxw = label_w}, {
				Panel.label({text = label, scale = label_scale, colour = game().C.UI.TEXT_LIGHT, shadow = true}),
		}),
		Panel.column({align = "cr"}, {
			Panel.column({align = "cm", minh = h, r = 0.1, minw = score_w, colour = (score == 'seed' and game and game.seeded) and game().C.RED or game().C.BLACK, emboss = 0.05}, {
				Panel.column({align = "cm", padding = 0.05, r = 0.1, minw = score_w}, score_tab),
			})
		}),
	})
end

