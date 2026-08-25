// Jumbalaya - played-out tile.
// Heavily desaturated and darkened: the card has done its job and looks
// retired from the round.

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
	vec3 faded = vec3(lum) * 0.62;

	vec3 rgb = mix(pix.rgb, faded, 0.82);

	return vec4(rgb, pix.a) * colour;
}
