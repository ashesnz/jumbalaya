--[[ app/core/graphics/particles.lua - CPU particle emitter (ParticleEmitter) ]]

ParticleEmitter = AnimNode:derive("ParticleEmitter")
Particles = ParticleEmitter

require("jumbalaya-engine.graphics.particles_init")(ParticleEmitter)
require("jumbalaya-engine.graphics.particles_sim")(ParticleEmitter)
require("jumbalaya-engine.graphics.particles_render")(ParticleEmitter)

return ParticleEmitter
