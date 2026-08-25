// Jumbalaya - debuffed wash.
// Cools and greys the artwork, with a faint uneasy flicker so it reads
// as "something is wrong with this tile".

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

	float lum = dot(pix.rgb, vec3(0.299, 0.587, 0.114));
	vec3 slate = vec3(lum) * vec3(0.72, 0.80, 0.88);

	// Uneasy flicker: barely visible, felt more than seen.
	float flicker = 0.94 + 0.06 * sin(time * 17.0 + sin(time * 7.3));

	vec3 rgb = mix(pix.rgb, slate, 0.68) * flicker;

	return vec4(rgb, pix.a) * colour;
}
