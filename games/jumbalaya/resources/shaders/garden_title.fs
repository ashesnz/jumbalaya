extern number time;

#define PIXEL_SIZE_FAC 900.

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    number pixel_size = length(love_ScreenSize.xy) / PIXEL_SIZE_FAC;
    vec2 uv = (floor(screen_coords.xy * (1. / pixel_size)) * pixel_size - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);

    vec4 base = Texel(texture, texture_coords) * colour;

    // Soft drifting sunlight patches through the garden canopy.
    number t = time * 0.35;
    number dapple_a = sin((uv.x * 8.0 + t) * 1.7 + sin(uv.y * 5.0 - t * 0.6) * 2.0);
    number dapple_b = sin((uv.y * 6.5 - t * 0.8) * 1.3 + cos(uv.x * 7.0 + t * 0.4) * 1.5);
    number dapple = clamp(0.5 + 0.5 * dapple_a * dapple_b, 0.0, 1.0);
    dapple = pow(dapple, 2.4) * 0.18;

    // Gentle breeze: subtle vertical colour shift on the grass.
    number breeze = sin(uv.x * 14.0 + t * 1.1) * sin(uv.y * 9.0 - t * 0.7) * 0.04;

    vec3 warm = vec3(1.08, 1.04, 0.92);
    vec3 cool = vec3(0.92, 1.02, 0.94);
    vec3 tint = mix(cool, warm, dapple + breeze + 0.5);
    vec3 lit = base.rgb * tint + vec3(dapple * 0.12, dapple * 0.16, dapple * 0.06);

    return vec4(lit, base.a);
}
