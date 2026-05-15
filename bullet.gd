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
	if not is_inside_tree() or is_queued_for_deletion():
		return

	var parent = get_parent()
	if not parent or not is_instance_valid(parent):
		return

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if position.distance_to(enemy.position) < collision_radius + 15:
			enemy.hp -= 1
			if not is_queued_for_deletion():
				queue_free()
			if enemy.hp <= 0:
				var explosion = load("res://explosion.tscn").instantiate()
				explosion.position = enemy.position
				parent.add_child(explosion)
				match enemy.type:
					0: parent.add_score(10)
					1: parent.add_score(25)
					2: parent.add_score(50)
				if not enemy.is_queued_for_deletion():
					enemy.queue_free()
			else:
				enemy.flash_effect()
			return