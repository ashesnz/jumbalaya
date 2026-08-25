--[[ app/core/graphics/particles.lua - CPU particle emitter (ParticleEmitter) ]]

ParticleEmitter = AnimNode:derive("ParticleEmitter")
Particles = ParticleEmitter

require("app.core.graphics.particles_init")(ParticleEmitter)
require("app.core.graphics.particles_sim")(ParticleEmitter)
require("app.core.graphics.particles_render")(ParticleEmitter)

return ParticleEmitter
