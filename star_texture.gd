extends Node

func create_star_texture(size: int, color: Color) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			if dist < radius:
				var alpha = 1.0 - (dist / radius)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	
	return ImageTexture.create_from_image(image)

func create_dot_texture(size: int = 2) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	var radius = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			if dist < radius:
				var alpha = 1.0 - (dist / radius)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

func create_glow_texture(size: int = 8) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			var alpha = max(0, 1.0 - (dist / center))
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)