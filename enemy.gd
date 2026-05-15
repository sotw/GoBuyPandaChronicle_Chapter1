extends Area2D

enum Type { BASIC, SWEEPER, CHASER }
var type = Type.BASIC
var speed = 120.0
var hp = 1
var max_hp = 1
var screen_size
var start_x
var time_elapsed = 0.0

func _ready():
	screen_size = get_viewport_rect().size
	start_x = position.x
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.texture = load("res://receipt.png")

func _process(delta):
	time_elapsed += delta
	
	# Get existing sprite from scene
	var sprite = get_node_or_null("Sprite2D")
	
	match type:
		Type.BASIC:
			position.y += speed * delta
			if sprite:
				sprite.rotation = sin(time_elapsed * 5) * 0.1
		Type.SWEEPER:
			position.y += speed * delta
			position.x = start_x + sin(time_elapsed * 3) * 40
			if sprite:
				sprite.rotation = sin(time_elapsed * 4) * 0.17
		Type.CHASER:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var direction = (player.position - position).normalized()
				position += direction * (speed * 0.5) * delta
				if sprite:
					sprite.rotation = direction.angle() + PI/2
	
	# Very subtle pulse (almost invisible)
	if sprite:
		var pulse = 1.0 + sin(time_elapsed * 6) * 0.02
		sprite.scale = Vector2(pulse, pulse)
	
	if position.y > screen_size.y + 20:
		queue_free()
	
	check_collisions()

func check_collisions():
	if not is_inside_tree() or is_queued_for_deletion():
		return

	var parent = get_parent()
	if not parent or not is_instance_valid(parent):
		return

	for bullet in get_tree().get_nodes_in_group("player_bullets"):
		if not is_instance_valid(bullet) or bullet.is_queued_for_deletion():
			continue
		if position.distance_to(bullet.position) < 20:
			hp -= 1
			if not bullet.is_queued_for_deletion():
				bullet.queue_free()
			if hp <= 0:
				parent._on_enemy_hit(position, bullet, type)
				queue_free()
			else:
				flash_effect()
			return

	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and position.distance_to(player.position) < 28:
		if not player.invincible:
			player.hit.emit()
			var explosion = load("res://explosion.tscn").instantiate()
			explosion.position = position
			parent.add_child(explosion)
			queue_free()

func flash_effect():
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tween = create_tween()
		sprite.modulate = Color(2, 2, 2)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func set_type(new_type):
	type = new_type
	match type:
		Type.BASIC:
			speed = 120
			hp = 1
			max_hp = 1
		Type.SWEEPER:
			speed = 90
			hp = 2
			max_hp = 2
		Type.CHASER:
			speed = 100
			hp = 5
			max_hp = 5