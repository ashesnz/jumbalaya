// Jumbalaya - "spice tin" foil.
// Brushed-metal bands at a slight diagonal, warmed toward the palette gold,
// with a cursor-tracked highlight like light catching a tin lid.

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

	// Brushed grain: tight horizontal striations over a slow diagonal wave.
	float brush = sin((uv.x * 3.0 + uv.y) * 90.0 + time * 0.8);
	float wave = sin((uv.x + uv.y * 1.4) * 9.0 - time * 1.1) * 0.5 + 0.5;

	vec3 warm = vec3(1.00, 0.87, 0.55);   // turmeric
	vec3 cool = vec3(0.82, 0.92, 0.95);   // tin flash
	float blend = clamp(0.5 + 0.45 * brush * 0.15 + (wave - 0.5), 0.0, 1.0);
	vec3 metal = mix(cool, warm, blend);

	// Cursor highlight: a soft pool of light that follows the pointer.
	vec2 md = (screen_coords - mouse_screen_pos) / max(screen_scale, 1.0);
	float pool = exp(-dot(md, md) * 2.2) * hovering;

	vec3 rgb = pix.rgb * mix(vec3(1.0), metal, 0.62)
		+ metal * (wave * 0.18 + pool * 0.35);

	return vec4(rgb, pix.a) * colour;
}
