shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(1.0, 100.0) = 2.0;
uniform float pixel_grid_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float brightness : hint_range(0.5, 1.5) = 1.1;
uniform float contrast : hint_range(0.5, 1.5) = 1.1;
uniform float saturation : hint_range(0.5, 1.5) = 1.1;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;

vec3 apply_lcd_subpixel(vec3 color, vec2 uv, vec2 pixel_size) {
	float subpixel_x = mod(uv.x / pixel_size.x, 3.0);
	
	vec3 subpixel_color = color;
	
	if (subpixel_x < 1.0) {
		subpixel_color.r *= 1.2;
		subpixel_color.gb *= 0.7;
	} else if (subpixel_x < 2.0) {
		subpixel_color.g *= 1.2;
		subpixel_color.rb *= 0.7;
	} else {
		subpixel_color.b *= 1.2;
		subpixel_color.rg *= 0.7;
	}
	
	return subpixel_color;
}

vec3 adjust_color(vec3 color) {
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 adjusted = mix(vec3(gray), color, saturation);
	adjusted = (adjusted - 0.5) * contrast + 0.5;
	adjusted *= brightness;
	return clamp(adjusted, 0.0, 1.0);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	vec3 final_color = color.rgb;
	
	vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	
	float scanline = sin(SCREEN_UV.y * scanline_count * 6.28318) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	final_color *= scanline;
	
	float grid_x = sin(SCREEN_UV.x / pixel_size.x * 3.14159) * 0.5 + 0.5;
	float grid_y = sin(SCREEN_UV.y / pixel_size.y * 3.14159) * 0.5 + 0.5;
	float grid = mix(1.0, grid_x * grid_y, pixel_grid_intensity);
	final_color *= grid;
	
	final_color = apply_lcd_subpixel(final_color, SCREEN_UV, pixel_size);
	
	final_color = adjust_color(final_color);
	
	vec2 center = SCREEN_UV - 0.5;
	float vignette = 1.0 - dot(center, center) * vignette_intensity;
	final_color *= vignette;
	
	COLOR = vec4(final_color, color.a);
}