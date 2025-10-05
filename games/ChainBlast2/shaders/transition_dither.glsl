extern int t; // How many pixels will be colored in, 0 to (native res X + native res Y)
extern bool fadein; // true = fading in, false = fading out

const vec4 black = vec4(0, 0, 0, 1);
const vec4 trans = vec4(0, 0, 0, 0);
const int size = 170;
const float[16] bayer_map = float[](0, 12, 3, 15, 8, 4, 11, 7, 2, 14, 1, 13, 10, 6, 9, 5);
//const float[16] bayer_map = float[](0, 12, 2, 14, 8, 4, 10, 6, 2, 14, 0, 12, 10, 6, 8, 4);

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
    float val = screen_coords.x + screen_coords.y;
    float intensity = clamp((-val + t) / size, 0, 1);

    vec2 bayer_offset = floor(mod(screen_coords, 4));
    int bayer_index = int(bayer_offset.y * 4 + bayer_offset.x);
    float bayer_threshold = bayer_map[bayer_index] / 16;

    if (fadein) {
        return intensity > bayer_threshold ? black : trans;
    } else {
        return intensity > bayer_threshold ? trans : black;
    }
}