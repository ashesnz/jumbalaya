--[[
	app/bootstrap/engine_boot.lua - Jumbalaya engine packages (load order matters).
]]

require "app.core.object"
require "bit"
require "app.core.util.pack"
require "app.core.input.router"
require "app.core.util.tween"
require "app.core.scene.node"
require "app.core.scene.animated.init"
require "app.core.graphics.sprite"
require "app.core.graphics.sprite_animator"

require "app.core.util.tables"
require "app.core.util.geometry"
require "app.core.util.random"
require "app.core.util.colour"
require "app.core.graphics.draw"
require "app.core.platform.display"
require "app.core.audio.sound"
require "word_game.ui.number_format"
require "word_game.model.profile_stats"
require "word_game.ui.localize"

require "app.core.ui.panel"
require "app.core.ui.container"
require "app.core.graphics.particles"
require "app.core.graphics.flow_text"
