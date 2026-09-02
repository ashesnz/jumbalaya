--[[ word_game/model/run_scope_register.lua - Register run teardown participants. ]]

local RunScope = require("word_game.model.run_scope")

local function hook(name, mod, method)
	if mod and mod[method] then
		RunScope.on_teardown(name, mod[method])
	end
end

local function call(name, fn)
	if fn then
		RunScope.on_teardown(name, fn)
	end
end

return function(word_game)
	local placement_word = require("word_game.model.placement_word")

	call("TradeUI", word_game.TradeUI and word_game.TradeUI.teardown_run)
	call("PlacementWord", placement_word.clear)
	call("BossWordStack", word_game.BossWordStack and word_game.BossWordStack.clear)
	call("BossWordAnnounce", word_game.BossWordAnnounce and word_game.BossWordAnnounce.clear)
	call("Confetti", word_game.Confetti and word_game.Confetti.clear)
	call("PlayHoldRedraw", word_game.PlayHoldRedraw and word_game.PlayHoldRedraw.reset)
	call("HandClearFocus", word_game.HandClearFocus and word_game.HandClearFocus.reset)
	call("StageLabel", word_game.StageLabel and word_game.StageLabel.reset)
	call("ScoreBanner", function()
		if word_game.ScoreBanner and word_game.ScoreBanner.reset then
			word_game.ScoreBanner.reset(0)
		end
		if word_game.ScoreBanner and word_game.ScoreBanner.reset_jumble_score then
			word_game.ScoreBanner.reset_jumble_score()
		end
	end)
	call("TimelineTimer", function()
		if word_game.TimelineTimer and word_game.TimelineTimer.reset then
			word_game.TimelineTimer.reset(60.0)
		end
	end)
	call("TokenReward", word_game.TokenReward and word_game.TokenReward.reset)
	call("FloatUpText", word_game.FloatUpText and word_game.FloatUpText.clear)
	call("HandShuffleAnim", word_game.HandShuffleAnim and word_game.HandShuffleAnim.reset)
	call("PlacementRecallAnim", word_game.HandPlacementRecallAnim and word_game.HandPlacementRecallAnim.reset)
	call("TableDiscard", word_game.TableDiscard and word_game.TableDiscard.reset)
	call("TableDeck", word_game.TableDeck and word_game.TableDeck.reset)
	call("HandShuffle", word_game.HandShuffle and word_game.HandShuffle.destroy)
	call("PerkStamp", word_game.PerkStamp and word_game.PerkStamp.clear_runtime)
	call("Sidebar", word_game.Sidebar and word_game.Sidebar.destroy)
	call("PlayerHost", function()
		if word_game.PlayerHost and word_game.PlayerHost.clear_spotlight then
			word_game.PlayerHost.clear_spotlight()
		end
		if word_game.PlayerHost and word_game.PlayerHost.reset_stage3_cinematic_state then
			word_game.PlayerHost.reset_stage3_cinematic_state()
		end
		if word_game.PlayerHost and word_game.PlayerHost.reset_marco_cinematic_state then
			word_game.PlayerHost.reset_marco_cinematic_state()
		end
	end)
end
