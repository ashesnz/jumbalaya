extern number time;

#define PIXEL_SIZE_FAC 700.
#define LEAF_COUNT 22

float hash21(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float leaf_mask(vec2 p, vec2 size)
{
    vec2 q = p / size;
    q.x *= 1.6;
    float body = length(q) - 1.0;
    float tip = length(q - vec2(0.0, 0.85)) - 0.35;
    return min(body, tip);
}

vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    number pixel_size = length(love_ScreenSize.xy) / PIXEL_SIZE_FAC;
    vec2 uv = (floor(screen_coords.xy * (1. / pixel_size)) * pixel_size - 0.5 * love_ScreenSize.xy) / length(love_ScreenSize.xy);

    vec3 top = vec3(0.52, 0.66, 0.48);
    vec3 mid = vec3(0.44, 0.58, 0.41);
    vec3 bot = vec3(0.36, 0.50, 0.35);
    number grad = clamp(uv.y * 0.45 + 0.52, 0.0, 1.0);
    vec3 bg = mix(bot, mix(mid, top, grad), grad);
    bg += vec3(0.04, 0.05, 0.03) * sin(uv.x * 3.5 + time * 0.15) * sin(uv.y * 2.8 - time * 0.1) * 0.5;
    bg *= 1.0 - 0.06 * pow(length(uv * 1.1), 2.0);

    vec3 col = bg;
    number t = time;

    for (int i = 0; i < LEAF_COUNT; i++) {
        number fi = number(i);
        vec2 seed = vec2(fi * 1.73, fi * 2.41);
        number lane = hash21(seed);
        number depth = hash21(seed + 4.7);
        number speed = 0.05 + depth * 0.04;
        number phase = hash21(seed + 9.3) * 6.28318;
        number x = (lane - 0.5) * 1.75;
        // Positive uv.y is downward on screen — increase y over time to fall.
        number y = fract(fi * 0.11 + t * speed + hash21(seed + 1.9)) * 1.55 - 0.78;
        number sway = sin(t * (0.7 + depth * 0.4) + phase) * (0.025 + depth * 0.015);
        vec2 center = vec2(x + sway, y);

        number rot = t * (0.55 + depth * 0.3) + phase;
        number c = cos(rot);
        number s = sin(rot);
        vec2 p = uv - center;
        vec2 rp = vec2(c * p.x - s * p.y, s * p.x + c * p.y);

        number scale = 0.005 + depth * 0.006;
        vec2 size = vec2(scale * 0.7, scale * 1.1);
        number d = leaf_mask(rp, size);
        number leaf = smoothstep(0.006, 0.0, d);

        number warm = hash21(seed + 6.1);
        vec3 leaf_col = mix(vec3(0.48, 0.64, 0.28), vec3(0.78, 0.58, 0.22), warm);
        col = mix(col, leaf_col, leaf * (0.22 + depth * 0.14));
    }

    return vec4(col, 1.0);
}
