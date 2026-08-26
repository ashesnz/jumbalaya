// Jumbalaya - "reptilian scales" transformation.
// A wave of diamond-shaped scales rises up the card from the bottom edge.
// Each scale grows out of its cell centre and, as it expands, flips the
// artwork underneath from the red variant to the black variant. A warm gold
// rim glints along each scale's leading edge while it is still growing.

uniform Image alt_texture;
uniform vec2 origin_a;   // normalised top-left of the source (red) quad
uniform vec2 origin_b;   // normalised top-left of the target (black) quad
uniform vec2 quad_size;  // normalised size of one card face in the atlas
uniform float progress;  // 0..1 sweep of the rising wave
uniform float time;

float hash21(vec2 p)
{
	p = fract(p * vec2(233.34, 851.73));
	p += dot(p, p + 27.19);
	return fract(p.x * p.y);
}

vec4 effect(vec4 colour, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 red_pix = Texel(tex, texture_coords);
	vec4 black_pix = Texel(alt_texture, origin_b + (texture_coords - origin_a));

	vec2 uv = clamp((texture_coords - origin_a) / quad_size, 0.0, 1.0);

	// Diamond grid laid over the card face.
	float cols = 6.0;
	float rows = 8.0;
	vec2 gp = vec2(uv.x * cols, uv.y * rows);
	vec2 cell = floor(gp);
	vec2 f = fract(gp);
	// Diamond metric: 0 at the scale centre, 1 at the cell corners.
	float d = (abs(f.x - 0.5) + abs(f.y - 0.5)) * 2.0;

	// The wave starts at the bottom edge and climbs; per-cell hash jitters so
	// neighbouring scales do not flip in lockstep.
	float h = hash21(cell);
	float rise = 1.0 - cell.y / rows;
	float t = progress * 1.35 - 0.175;
	float threshold = rise * 0.8 + h * 0.2;

	// Each scale grows from its centre once the wave passes its threshold.
	float grow = clamp((t - threshold) / 0.22, 0.0, 1.0);
	float radius = sqrt(grow); // ease-out growth of the inscribed diamond

	float inside = 1.0 - smoothstep(radius - 0.10, radius + 0.03, d);

	// Glinting rim on scales that are mid-growth.
	float rim = smoothstep(radius - 0.32, radius - 0.02, d)
		* (1.0 - smoothstep(radius - 0.02, radius + 0.06, d))
		* step(0.001, grow) * (1.0 - step(0.999, grow));

	vec3 rgb = mix(red_pix.rgb, black_pix.rgb, inside);
	rgb += rim * vec3(1.0, 0.82, 0.35) * 0.30 * (0.75 + 0.25 * sin(time * 9.0 + h * 12.0));

	return vec4(rgb, red_pix.a) * colour;
}
