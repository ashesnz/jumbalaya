// Jumbalaya - perk gilding.
// Warm gold wash with a slow pulse, like a tile glaze catching the sun.
// Also used for gold seal accents.

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

	vec3 gold = vec3(1.00, 0.83, 0.42);

	// Slow pulse plus a gentle diagonal shimmer band.
	float pulse = 0.5 + 0.5 * sin(time * 1.15);
	float shimmer = 0.5 + 0.5 * sin((uv.x + uv.y) * 12.0 - time * 1.4);

	float mix_amt = 0.30 + 0.14 * pulse;
	vec3 rgb = mix(pix.rgb, pix.rgb * gold * 1.25, mix_amt);
	rgb += gold * shimmer * 0.10;

	return vec4(rgb, pix.a) * colour;
}
