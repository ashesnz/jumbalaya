#if defined(VERTEX) || __VERSION__ > 100 || defined(GL_FRAGMENT_PRECISION_HIGH)
	#define MY_HIGHP_OR_MEDIUMP highp
#else
	#define MY_HIGHP_OR_MEDIUMP mediump
#endif

extern MY_HIGHP_OR_MEDIUMP number time;
extern MY_HIGHP_OR_MEDIUMP number bounce_amount;
extern MY_HIGHP_OR_MEDIUMP number is_mult;

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 tex = Texel(texture, texture_coords);
    if (tex.a < 0.01) {
        return vec4(0.0);
    }

    // Subtle glossy bubble shimmer sweep
    float shimmer_pos = fract((time * 0.6) + (screen_coords.x * 0.004) - (screen_coords.y * 0.004));
    float sheen = smoothstep(0.35, 0.50, shimmer_pos) * (1.0 - smoothstep(0.50, 0.65, shimmer_pos));

    // Throb / bounce flash highlight
    float bounce_flash = bounce_amount * (0.6 + 0.4 * sin(time * 16.0));

    vec3 col = colour.rgb;
    col += vec3(0.4, 0.4, 0.5) * sheen * (0.6 + bounce_amount * 0.8);
    col += vec3(0.3, 0.3, 0.35) * bounce_flash;

    return vec4(col, tex.a * colour.a);
}
