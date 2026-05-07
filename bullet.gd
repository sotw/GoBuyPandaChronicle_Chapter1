extends Node2D

var speed = 300.0
var is_enemy_bullet = false
var sprite
var collision_radius = 8.0

func _ready():
	sprite = Sprite2D.new()
	sprite.texture = load("res://bill.png")
	add_child(sprite)

func _process(delta):
	position.y -= speed * delta
	if position.y < -10:
		queue_free()
	
	if not is_enemy_bullet:
		check_enemy_collisions()

func check_enemy_collisions():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.position.distance_to(position) < collision_radius + 15:
			var explosion = load("res://explosion.tscn").instantiate()
			explosion.position = enemy.position
			get_parent().add_child(explosion)
			match enemy.type:
				0: get_parent().add_score(10)
				1: get_parent().add_score(25)
				2: get_parent().add_score(50)
			enemy.queue_free()
			queue_free()
			return