// Jumbalaya - "paper crumble" dissolve.
// The card breaks apart like a wet letter-tile: coarse fibrous noise decides
// which patches survive, and a warm ember rim burns along the tear line.
// burn_colour_1 tints the surviving surface near the rim, burn_colour_2 the
// crumbling edge itself.

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

float value_noise(vec2 p)
{
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

vec4 effect(vec4 colour, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 pix = Texel(tex, texture_coords);
	vec2 uv = (texture_details.xy + texture_coords * texture_details.zw) / image_details;

	// Fibrous two-octave noise, stable per tile thanks to atlas UV space.
	float grain = value_noise(uv * 46.0) * 0.68 + value_noise(uv * 118.0) * 0.32;
	// Slight drift so the crumble creeps rather than sitting frozen.
	grain += 0.04 * sin(uv.y * 21.0 + time * 0.7);

	float t = clamp(dissolve, 0.0, 1.0);

	if (shadow) {
		// Shadow pass: flat dark silhouette that crumbles on the same pattern.
		float coverage = smoothstep(t - 0.10, t + 0.02, grain);
		return vec4(0.0, 0.0, 0.0, pix.a * coverage * 0.22) * colour;
	}

	// Surviving surface and the burning rim just inside the tear line.
	float keep = smoothstep(t - 0.035, t + 0.045, grain);
	float rim = smoothstep(t - 0.17, t - 0.03, grain) * (1.0 - smoothstep(t - 0.03, t + 0.02, grain));

	// Soft cursor sheen while the card is alive.
	vec2 md = (screen_coords - mouse_screen_pos) / max(screen_scale, 1.0);
	float sheen = exp(-dot(md, md) * 1.6) * hovering * 0.10 * keep;

	vec3 rgb = mix(burn_colour_2.rgb, pix.rgb, keep);
	rgb = mix(rgb, burn_colour_1.rgb, rim * 0.75);
	rgb += sheen;

	float alpha = pix.a * max(keep, rim * 0.55);
	return vec4(rgb, alpha) * colour;
}
