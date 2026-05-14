extends Node2D

func _ready():
	# Create single explosion sprite
	var sprite = Sprite2D.new()
	sprite.texture = load("res://bill.png")
	sprite.modulate = Color(1, 0.5, 0, 1)  # Orange
	sprite.scale = Vector2(0.5, 0.5)
	sprite.position = Vector2.ZERO
	sprite.name = "ExplosionSprite"
	add_child(sprite)
	
	# Animate scale up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(2.5, 2.5), 0.4)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(_on_explosion_done)

func _on_explosion_done():
	# Ensure cleanup
	queue_free()