shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(1.0, 100.0) = 4.0;
uniform float pixel_grid_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float brightness : hint_range(0.5, 1.5) = 1.1;
uniform float contrast : hint_range(0.5, 1.5) = 1.1;
uniform float saturation : hint_range(0.5, 1.5) = 1.1;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.3;

uniform float barrel_distortion : hint_range(0.0, 0.5) = 0.03;
uniform float chromatic_aberration : hint_range(0.0, 0.01) = 0.003;
uniform float scanline_wobble : hint_range(0.0, 1.0) = 0.1;
uniform float scanline_speed : hint_range(0.0, 10.0) = 2.0;
uniform float color_bleed : hint_range(0.0, 0.1) = 0.02;

vec2 apply_barrel_distortion(vec2 uv, float distortion) {
	vec2 centered = uv - 0.5;
	float dist_from_center = length(centered);
	vec2 distorted = centered * (1.0 + dist_from_center * dist_from_center * distortion);
	return distorted + 0.5;
}

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
	vec2 base_uv = SCREEN_UV;
	
	vec2 distorted_uv = apply_barrel_distortion(base_uv, barrel_distortion);
	
	distorted_uv = clamp(distorted_uv, 0.0, 1.0);
	
	vec2 uv_r = distorted_uv + vec2(chromatic_aberration, 0.0);
	vec2 uv_g = distorted_uv;
	vec2 uv_b = distorted_uv - vec2(chromatic_aberration, 0.0);
	
	float r = texture(screen_texture, uv_r).r;
	float g = texture(screen_texture, uv_g).g;
	float b = texture(screen_texture, uv_b).b;
	
	vec3 color = vec3(r, g, b);
	
	float bleed_offset = color_bleed;
	float r_bleed = texture(screen_texture, clamp(vec2(distorted_uv.x + bleed_offset, distorted_uv.y), 0.0, 1.0)).r;
	float b_bleed = texture(screen_texture, clamp(vec2(distorted_uv.x - bleed_offset, distorted_uv.y), 0.0, 1.0)).b;
	color.r = mix(color.r, r_bleed, 0.5);
	color.b = mix(color.b, b_bleed, 0.5);
	
	vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
	
	float time_offset = TIME * scanline_speed;
	float wobble = scanline_wobble * sin(time_offset * 0.5);
	float scanline = sin((distorted_uv.y + wobble * 0.01) * scanline_count * 6.28318) * 0.5 + 0.5;
	scanline = mix(1.0, scanline, scanline_intensity);
	color *= scanline;
	
	float grid_x = sin(distorted_uv.x / pixel_size.x * 3.14159) * 0.5 + 0.5;
	float grid_y = sin(distorted_uv.y / pixel_size.y * 3.14159) * 0.5 + 0.5;
	float grid = mix(1.0, grid_x * grid_y, pixel_grid_intensity);
	color *= grid;
	
	color = apply_lcd_subpixel(color, distorted_uv, pixel_size);
	
	color = adjust_color(color);
	
	vec2 center = distorted_uv - 0.5;
	float vignette = 1.0 - dot(center, center) * vignette_intensity;
	color *= vignette;
	
	COLOR = vec4(color, 1.0);
}