// Jumbalaya - Balatro-style gold seal shimmer, as an additive overlay.
// The yellow card face is drawn first with dissolve + gold OVERLAY_TINT.
// This pass only emits highlight; black = no change to the face underneath.
//
// Standard sprite uniforms must be declared so sprite_shader.lua can send them
// without aborting before `gold_seal` / `time` are set.
// Balatro gold_seal.fs uses gold_seal.r as the animation clock.

uniform vec2 mouse_screen_pos;
uniform float screen_scale;
uniform float hovering;
uniform float dissolve;
uniform float time;
uniform vec4 texture_details;
uniform vec2 image_details;
uniform vec4 burn_colour_1;
uniform vec4 burn_colour_2;
uniform bool shadow;
uniform vec4 gold_seal;

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords);
	if (pixel.a <= 0.001) {
		return vec4(0.0);
	}

	// Prefer the dedicated gold_seal clock (Balatro); fall back to `time`.
	float clock = gold_seal.r + time;

	float low = min(pixel.r, min(pixel.g, pixel.b));
	float high = max(pixel.r, max(pixel.g, pixel.b));
	float delta = high * 0.5;

	// Balatro gold-seal sparkle (gold_seal.r is the original clock).
	float fac = 0.3
		+ sin((texture_coords.x * 450. + sin(clock * 6.) * 180.) - 700. * clock)
		- sin((texture_coords.x * 190. + texture_coords.y * 30.) + 1080.3 * clock);

	// Extra travelling band so the sweep is obvious on a flat letter frame.
	float cycle = fract(texture_coords.x * 0.90 + texture_coords.y * 0.50 - clock * 0.55);
	float beam = smoothstep(0.18, 0.34, cycle) * smoothstep(0.78, 0.62, cycle);

	float sparkle = max(0.0, fac) * delta * 0.85 + beam * 0.90;
	vec3 gold = vec3(1.00, 0.88, 0.28);
	vec3 rgb = gold * sparkle * pixel.a;

	return vec4(rgb, pixel.a);
}
