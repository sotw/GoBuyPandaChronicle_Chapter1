extends Node2D

func _ready():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)