extends Area2D

enum Type { BASIC, SWEEPER, CHASER }
var type = Type.BASIC
var speed = 120.0
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
	for bullet in get_tree().get_nodes_in_group("player_bullets"):
		if position.distance_to(bullet.position) < 20:
			get_parent()._on_enemy_hit(position, bullet, type)
			queue_free()
			return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and position.distance_to(player.position) < 28:
		if not player.invincible:
			player.hit.emit()
			var explosion = load("res://explosion.tscn").instantiate()
			explosion.position = position
			get_parent().add_child(explosion)
			queue_free()

func set_type(new_type):
	type = new_type
	match type:
		Type.BASIC:
			speed = 120
		Type.SWEEPER:
			speed = 90
		Type.CHASER:
			speed = 70