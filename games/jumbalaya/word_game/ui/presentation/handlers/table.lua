--[[ word_game/ui/presentation/handlers/table.lua - Table controls, motion, and voucher hooks ]]

local M = {}

function M.register(Presentation, ctx)
	local ui = ctx.ui

	Presentation.on("card_motion_move", function(opts)
		local CardMotion = require("word_game.ui.effects.card_motion")
		CardMotion.move(opts)
		return true
	end)

	Presentation.on("voucher_discard_ui_reset", function()
		if ui.VoucherDiscard and ui.VoucherDiscard.reset then
			ui.VoucherDiscard.reset()
		end
	end)

	Presentation.on("voucher_discard_recorded", function(from_left, to_left)
		local vd = ui.VoucherDiscard
		if not vd then return end
		if vd.roll_discards_left then
			vd.roll_discards_left(from_left, to_left)
		end
		if vd.sync_sidebar_ui then
			vd.sync_sidebar_ui()
		end
	end)

	Presentation.on("voucher_discard_ui_sync", function()
		if ui.VoucherDiscard and ui.VoucherDiscard.sync_sidebar_ui then
			ui.VoucherDiscard.sync_sidebar_ui()
		end
	end)
end

return M
