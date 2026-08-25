// Jumbalaya - "juice stain" holographic.
// Iridescent film like light on a juice-glass rim: hue drifts across the
// card diagonally over time, strongest on bright artwork, with a slow
// breathing intensity.

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

	// Diagonal phase across the face, drifting slowly with time.
	float phase = uv.x * 1.7 + uv.y * 2.3 + sin(time * 0.45) * 0.8;
	vec3 rainbow = 0.5 + 0.5 * cos(6.28318 * (phase + vec3(0.00, 0.33, 0.67)));

	// Film sits mainly on bright pixels; dark ink stays readable.
	float lum = dot(pix.rgb, vec3(0.299, 0.587, 0.114));
	float mask = smoothstep(0.15, 0.85, lum);

	float breathe = 0.38 + 0.16 * sin(time * 0.9);

	vec3 rgb = pix.rgb * (1.0 - breathe * mask * 0.55)
		+ rainbow * breathe * mask;

	return vec4(rgb, pix.a) * colour;
}
