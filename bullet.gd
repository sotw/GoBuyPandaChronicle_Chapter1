extends Area2D

var speed = 300.0
var is_enemy_bullet = false

func _process(delta):
	position.y -= speed * delta
	if position.y < -10:
		queue_free()