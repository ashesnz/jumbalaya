--[[ app/core/graphics/particles.lua - CPU particle emitter (ParticleEmitter) ]]

local Spatial = require("jumbalaya-engine.scene.animated.init")
local ParticleEmitter = Spatial:derive("ParticleEmitter")

require("jumbalaya-engine.graphics.particles_init")(ParticleEmitter)
require("jumbalaya-engine.graphics.particles_sim")(ParticleEmitter)
require("jumbalaya-engine.graphics.particles_render")(ParticleEmitter)

return ParticleEmitter
