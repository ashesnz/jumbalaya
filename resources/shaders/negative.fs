// Jumbalaya - negative print.
// Inverts the artwork like a photographic negative with a cool cyan cast,
// leaving the silhouette and its alpha untouched.

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

	// Invert, then nudge toward cold cyan so the result reads intentional
	// rather than like a missing texture.
	vec3 inverted = 1.0 - pix.rgb;
	inverted *= vec3(0.82, 0.94, 1.06);

	return vec4(inverted, pix.a) * colour;
}
