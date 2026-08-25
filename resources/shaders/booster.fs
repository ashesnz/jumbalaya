// Jumbalaya - booster pack glint.
// Twinkling tile-sparkle field over the pack face, plus a slow violet
// wash that deepens toward the edges like sealed foil under a shop lamp.

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

float hash21(vec2 p)
{
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 27.19);
	return fract(p.x * p.y);
}

vec4 effect(vec4 colour, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pix = Texel(tex, texture_coords);
	vec2 uv = (texture_details.xy + texture_coords * texture_details.zw) / image_details;

	// Twinkle lattice: each cell wakes for a blink on its own schedule.
	vec2 cell = floor(uv * 26.0);
	vec2 frac = fract(uv * 26.0);
	float seed = hash21(cell);
	float blink = step(0.965, seed)
		* smoothstep(0.35, 0.5, sin(time * 6.0 + seed * 90.0) * 0.5 + 0.5);
	float star = blink
		* smoothstep(0.32, 0.0, length(frac - vec2(hash21(cell + 3.7), hash21(cell + 9.1))));

	// Violet rim wash, strongest at the card border.
	float border = smoothstep(0.18, 0.5, max(abs(uv.x - 0.5), abs(uv.y - 0.5)));
	vec3 wash = vec3(0.48, 0.39, 0.86) * (border * 0.30 + 0.06);

	vec3 rgb = pix.rgb + wash + star * 0.8;

	return vec4(rgb, pix.a) * colour;
}
