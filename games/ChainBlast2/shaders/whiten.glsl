const float shade = 1;
const float factor = 1;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
	return vec4(
        mix(color_src.r, shade, factor),
        mix(color_src.g, shade, factor),
        mix(color_src.b, shade, factor),
        color_src.a
    );
}