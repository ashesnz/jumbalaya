#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
	#define MY_HIGHP_OR_MEDIUMP highp
#else
	#define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP vec2 tex_size;
extern MY_HIGHP_OR_MEDIUMP number radius;
extern MY_HIGHP_OR_MEDIUMP number intensity;
extern MY_HIGHP_OR_MEDIUMP vec4 outline_colour;

float max_alpha(Image texture, vec2 uv, vec2 texel, float rad)
{
	float m = 0.0;
	for (int i = 0; i < 16; i++) {
		float ang = float(i) * 0.3926991;
		vec2 off = vec2(cos(ang), sin(ang)) * texel * rad;
		m = max(m, Texel(texture, uv + off).a);
	}
	return m;
}

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
	float a = Texel(texture, texture_coords).a;
	vec2 texel = 1.0 / tex_size;
	float around = max_alpha(texture, texture_coords, texel, radius);

	// Outer glow: empty pixels hugging the bin.
	float outer = (1.0 - step(0.18, a)) * smoothstep(0.12, 0.55, around);
	// Inner rim: paint yellow on the bin's own edge pixels.
	float inner = step(0.18, a) * (1.0 - smoothstep(0.12, 0.85, max_alpha(texture, texture_coords, texel, 2.2)));

	float glow = max(outer, inner);
	if (glow < 0.02) {
		return vec4(0.0);
	}

	return vec4(outline_colour.rgb, outline_colour.a * glow * intensity);
}

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
	return transform_projection * vertex_position;
}
#endif
