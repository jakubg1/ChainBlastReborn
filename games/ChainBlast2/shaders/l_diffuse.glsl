extern Image lightmap;
extern vec2 lightmap_size; // Assumption: The lightmap must cover the whole screen.
extern Image normal;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
	vec4 color_src = Texel(tex, texture_coords);
    vec4 color_light = Texel(lightmap, screen_coords / lightmap_size);
	//vec4 color_light = vec4(0.707, 0.5, 0.707, 1);
	vec4 color_normal = Texel(normal, texture_coords);
	// Calculate brightness based on the light power at that pixel.
	float brightness = color_light.g;
	// Check the difference in angles between the light direction and the normalmap.
	float angle = 1 - acos(dot(normalize(color_light.rb * 2 - 1), normalize(color_normal.rb - 0.5))) / 3.1415;
	// The resulting angle is in the range 0..1.
	// <= 0.5: darken (down to 0x), > 0.5: brighten (up to 2x).
	// This is further multiplied by the normalmap strength.
	float normal_strength = length(color_normal.rb - 0.5) * 2;
	float multiplier = (angle - 0.5) * normal_strength * 2 + 1;
	// For brightness <= 0.5, the multiplier is naturally applied.
	// For brightness > 0.5 however, we still want to brighten even if the multiplication would result in zero
	// (so for brightness = 1, final brightness is also 1 even if multiplier = 0).
	brightness = brightness * multiplier + max((brightness - 0.5) * 2, 0);
	// Return final pixel value.
	if (brightness <= 0.5) {
		// brightness <= 0.5: Darken by how far it is from 0.5.
		return vec4(color_src.rgb * brightness * 2, color_src.a);
	} else {
		// brightness > 0.5: Brighten by how far it is from 0.5.
		return vec4(mix(color_src.rgb, vec3(1, 1, 1), brightness * 2 - 1), color_src.a);
	}
}