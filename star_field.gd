extends Node2D

@export var star_count: int = 30
@export var star_size_min: float = 1.0
@export var star_size_max: float = 2.0
@export var star_color: Color = Color.WHITE
@export var star_color_secondary: Color = Color(0.7, 0.7, 0.8)

var stars: Array = []
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	generate_stars()

func _draw():
	for star in stars:
		draw_circle(star.position, star.size, star.color)

func generate_stars():
	stars.clear()
	for i in range(star_count):
		var star = {
			"position": Vector2(randf() * screen_size.x, randf() * screen_size.y),
			"size": randf_range(star_size_min, star_size_max),
			"color": star_color if randf() > 0.3 else star_color_secondary
		}
		stars.append(star)

func _process(delta):
	queue_redraw()