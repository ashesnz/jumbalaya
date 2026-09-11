--[[ word_game/model/run/register.lua - Register run teardown participants ]]

local RunScope = require("word_game.model.run.scope")
local Busy = require("word_game.model.run.busy")

local function call(name, fn)
	if fn then
		RunScope.on_teardown(name, fn)
	end
end

return function(domain, ui)
	domain = domain or {}
	ui = ui or {}
	call("BusyFlags", Busy.clear)
	call("TradeUI", ui.TradeUI and ui.TradeUI.teardown_run)
	call("PlacementWord", domain.PlacementWord and domain.PlacementWord.clear)
	call("BonusStack", domain.BonusStack and domain.BonusStack.clear)
	call("BonusStackUI", ui.BonusStackUI and ui.BonusStackUI.clear)
	call("BossWordAnnounce", ui.BossWordAnnounce and ui.BossWordAnnounce.clear)
	call("Confetti", ui.Confetti and ui.Confetti.clear)
	call("PlayHoldRedraw", ui.PlayHoldRedraw and ui.PlayHoldRedraw.reset)
	call("HandClearFocus", ui.HandClearFocus and ui.HandClearFocus.reset)
	call("FirstPlayTutorial", ui.FirstPlayTutorial and ui.FirstPlayTutorial.reset)
	call("StageLabel", ui.StageLabel and ui.StageLabel.reset)
	call("ScoreBanner", function()
		if ui.ScoreBanner and ui.ScoreBanner.reset then
			ui.ScoreBanner.reset(0)
		end
		if ui.ScoreBanner and ui.ScoreBanner.reset_jumble_score then
			ui.ScoreBanner.reset_jumble_score()
		end
	end)
	call("TimelineTimer", function()
		if domain.Round and domain.Round.reset_timeline then
			domain.Round.reset_timeline()
		end
	end)
	call("TokenReward", ui.TokenReward and ui.TokenReward.reset)
	call("FloatUpText", ui.FloatUpText and ui.FloatUpText.clear)
	call("HandShuffleAnim", ui.HandShuffleAnim and ui.HandShuffleAnim.reset)
	call("PlacementRecallAnim", ui.HandPlacementRecallAnim and ui.HandPlacementRecallAnim.reset)
	call("VoucherDiscard", domain.VoucherDiscard and domain.VoucherDiscard.reset)
	call("TableDeck", ui.TableDeck and ui.TableDeck.reset)
	call("TableControls", ui.TableControls and ui.TableControls.destroy)
	call("PerkStamp", ui.PerkStamp and ui.PerkStamp.clear_runtime)
	call("Sidebar", ui.Sidebar and ui.Sidebar.destroy)
end
