// Jumbalaya - "tricolour" polychrome.
// Three slow bands - plum, gold, teal - slide across the face and tint it;
// where two bands meet, a bright seam sweeps through like a card fanned
// under a lamp.

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

vec4 effect(vec4 colour, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pix = Texel(tex, texture_coords);
	vec2 uv = (texture_details.xy + texture_coords * texture_details.zw) / image_details;

	float travel = uv.y * 3.0 + time * 0.35;

	vec3 plum = vec3(0.72, 0.42, 0.86);
	vec3 gold = vec3(1.00, 0.80, 0.38);
	vec3 teal = vec3(0.30, 0.85, 0.78);

	// Three overlapping smooth bands 1/3 of the face apart.
	float b1 = exp(-pow(fract(travel)        - 0.5, 2.0) * 18.0);
	float b2 = exp(-pow(fract(travel + 0.33) - 0.5, 2.0) * 18.0);
	float b3 = exp(-pow(fract(travel + 0.66) - 0.5, 2.0) * 18.0);

	vec3 tint = plum * b1 + gold * b2 + teal * b3;

	// Seam sparkle: brightest right between two bands.
	float seam = abs(b1 - b2) + abs(b2 - b3) + abs(b3 - b1);
	float spark = clamp(1.2 - seam, 0.0, 1.0) * 0.22;

	vec3 rgb = pix.rgb * (1.0 - 0.28) + tint * 0.42 + vec3(spark);

	return vec4(rgb, pix.a) * colour;
}
