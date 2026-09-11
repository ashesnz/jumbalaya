// Jumbalaya - "scale shed" transformation.
// Two-phase directional wipe used when a marketplace card is modified:
//   phase 1 (progress 0 -> 0.5): the red card burns away from the bottom
//   edge upward, leaving a ragged gold ember rim along the retreat line.
//   phase 2 (progress 0.5 -> 1): the black version of the card materialises
//   from the top edge downward behind the same travelling rim.

uniform Image alt_texture;
uniform vec2 origin_a;   // normalised top-left of the source (red) quad
uniform vec2 origin_b;   // normalised top-left of the target (black) quad
uniform vec2 quad_size;  // normalised size of one card face in the atlas
uniform float progress;  // 0..1 across both phases
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

	// Card-face space: x/y in 0..1, y = 0 at the top edge, 1 at the bottom.
	vec2 uv = clamp((texture_coords - origin_a) / quad_size, 0.0, 1.0);

	float u = clamp(progress, 0.0, 1.0);
	// Ragged, slowly flickering frontier so the wipe reads organic.
	float rag = (hash21(vec2(floor(uv.x * 24.0), 7.0)) - 0.5) * 0.07
		+ (hash21(vec2(floor(uv.x * 24.0), floor(time * 7.0))) - 0.5) * 0.03;

	vec3 rgb;
	float alpha;

	if (u < 0.5) {
		// Phase 1: red card sheds away bottom -> top.
		float edge = (1.0 - u * 2.0) + rag;
		float gone = step(edge, uv.y);
		float rim = smoothstep(edge - 0.07, edge, uv.y) * (1.0 - gone);
		rgb = mix(red_pix.rgb, vec3(1.0, 0.78, 0.30), rim * 0.85);
		alpha = (1.0 - gone) * (1.0 - 0.25 * rim);
	} else {
		// Phase 2: black card grows back top -> bottom.
		float edge = ((u - 0.5) * 2.0) + rag;
		float shown = step(uv.y, edge);
		float rim = (1.0 - smoothstep(edge - 0.07, edge, uv.y)) * shown;
		rgb = mix(black_pix.rgb, vec3(1.0, 0.82, 0.35), rim * 0.7);
		alpha = shown;
	}

	return vec4(rgb, alpha * red_pix.a) * colour;
}
