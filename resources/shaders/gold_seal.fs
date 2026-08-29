// Jumbalaya - gold shimmer overlay (Balatro voucher/foil travelling shine).
// Drawn additively over the yellow dissolve face. Highlight only — no fill.
//
// Balatro gold seals use the voucher shader: card-local UV plus a clock
// (send_to_shader.r) so bands actually travel across the sprite. Atlas
// texture_coords barely change on one cell, so they cannot drive a sweep.

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

// Must stay in sync with tests/unit/test_bonus_card_gold_shader.lua
#define SWEEP_X 0.85
#define SWEEP_Y 0.45
#define SWEEP_SPEED 0.70

vec2 card_uv(vec2 texture_coords)
{
	vec2 img = max(image_details, vec2(1.0));
	vec2 cell = max(texture_details.ba, vec2(1.0));
	return (texture_coords * img - texture_details.xy * cell) / cell;
}

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pixel = Texel(texture, texture_coords);
	if (pixel.a <= 0.001) {
		return vec4(0.0);
	}

	vec2 uv = card_uv(texture_coords);
	float clock = gold_seal.r;

	// Sharp diagonal ridge that crosses the card about once per 1.4s.
	float phase = fract(uv.x * SWEEP_X + uv.y * SWEEP_Y - clock * SWEEP_SPEED);
	float beam = pow(1.0 - abs(phase - 0.5) * 2.0, 6.0);

	// Balatro voucher-style gold crawl, keyed to the same card UV.
	float v = clock / 28.0;
	float fac = 0.8 + 0.9 * sin(13. * uv.x + 5.32 * uv.y + v * 12.
		+ cos(v * 5.3 + uv.y * 4.2 - uv.x * 4.));
	float fac2 = 0.5 + 0.5 * sin(10. * uv.x + 2.32 * uv.y + v * 5.
		- cos(v * 2.3 + uv.x * 8.2));
	float crawl = max(0.0, max(fac, fac2) - 1.15);

	vec3 gold = vec3(1.00, 0.90, 0.35);
	vec3 rgb = gold * (beam * 1.25 + crawl * 0.35) * pixel.a;

	return vec4(rgb, pixel.a);
}
