extern int x; // pixel X position of light source on the texture
extern int y; // pixel Y position of light source on the texture
extern float strength; // light strength, 0 - nothing burger, 0.5 - natural lighting (matches source texture), 1 - entirely white at source
extern float range; // distance from source at which the strength will be halved

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
    float dist = distance(screen_coords, vec2(x, y));
    vec2 offset = normalize(screen_coords - vec2(x, y));
    // Falloff is applied: the strength is halved every `range` pixels.
    float result = strength * 1 / pow(2, dist / range);

    // Result: R - X light direction, G - light strength, B - Y light direction
	return vec4(
        0.5 + offset.x / 2,
        result,
        0.5 + offset.y / 2,
        1
    );
}