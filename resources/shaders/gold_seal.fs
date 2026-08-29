// Jumbalaya - gold shimmer overlay (Balatro voucher-style travelling shine).
// Drawn over the yellow dissolve face with normal alpha. The stripe's alpha
// is the animation — gold-on-gold additive was effectively invisible.
//
// Clock is `time` (G.TIMERS.REAL). Cards do not need to move; Lua is not a
// limiter — the game loop advances REAL every frame.

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
	float clock = time;

	// Diagonal ridge that crosses the card about once per 1.4s.
	float phase = fract(uv.x * SWEEP_X + uv.y * SWEEP_Y - clock * SWEEP_SPEED);
	float beam = pow(1.0 - abs(phase - 0.5) * 2.0, 3.0);

	// Slower Balatro-voucher crawl so the face isn't a single hard stripe.
	float v = clock / 28.0;
	float fac = 0.8 + 0.9 * sin(13. * uv.x + 5.32 * uv.y + v * 12.
		+ cos(v * 5.3 + uv.y * 4.2 - uv.x * 4.));
	float crawl = max(0.0, fac - 1.2);

	float shine = clamp(beam * 0.85 + crawl * 0.25, 0.0, 1.0);
	vec3 highlight = vec3(1.00, 0.96, 0.72);

	return vec4(highlight, pixel.a * shine);
}
