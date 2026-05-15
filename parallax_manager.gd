extends Node2D

var star_texture: Texture2D
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	generate_star_texture()

func generate_star_texture():
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var center = 2.0
	
	for x in range(4):
		for y in range(4):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			if dist < 2.0:
				var alpha = 1.0 - (dist / 2.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	star_texture = ImageTexture.create_from_image(image)

func _process(delta):
	screen_size = get_viewport_rect().size