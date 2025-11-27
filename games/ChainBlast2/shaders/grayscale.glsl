const float factor = 1;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
    float lum = color_src.r * 0.299 + color_src.g * 0.587 + color_src.b * 0.114;
    vec4 result = vec4(lum, lum, lum, color_src.a);
	return mix(color_src, result, factor);
}