extends Area2D

signal hit
signal special_moves_changed(count)
signal special_move_started
signal special_move_ended

var speed = 150.0
var screen_size
var bullet_scene = preload("res://bullet.tscn")
var can_shoot = true
var shoot_delay = 0.33
var invincible = false
var invincible_time = 2.0
var sprite
var target_position: Vector2
var is_touching = false
var special_moves = 3
var is_special_firing = false
var active_touches = 0
var can_trigger_special = true

func _ready():
	screen_size = get_viewport_rect().size
	position = Vector2(screen_size.x / 2, screen_size.y - 40)
	sprite = Sprite2D.new()
	sprite.texture = load("res://panda.png")
	add_child(sprite)

func _process(delta):
	var velocity = Vector2.ZERO

	if is_touching and target_position != Vector2.ZERO:
		var direction = target_position - position
		if direction.length() > 5:
			velocity = direction.normalized() * speed
		if can_shoot and is_touching and visible:
			shoot_bullet()
			can_shoot = false
			get_tree().create_timer(shoot_delay).timeout.connect(_on_shoot_ready)
	elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		velocity.x += 1
	elif Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		velocity.y += 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		# Subtle rotation wobble (±10°) based on movement direction
		var target_rotation = clamp(velocity.x * 0.01, -0.17, 0.17)
		sprite.rotation = lerp(sprite.rotation, target_rotation, 10 * delta)
	else:
		# Return to center when not moving
		sprite.rotation = lerp(sprite.rotation, 0.0, 10 * delta)
	
	position += velocity * delta
	position.x = clamp(position.x, 20, screen_size.x - 20)
	position.y = clamp(position.y, 20, screen_size.y - 20)
	
	if Input.is_key_pressed(KEY_SPACE) and can_shoot and visible:
		shoot_bullet()
		can_shoot = false
		get_tree().create_timer(shoot_delay).timeout.connect(_on_shoot_ready)

func _on_shoot_ready():
	can_shoot = true

func _input(event):
	if event is InputEventKey and event.keycode == KEY_X and event.pressed:
		special_move()
	
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches += 1
			if active_touches >= 2 and can_trigger_special:
				special_move()
				can_trigger_special = false
		else:
			active_touches = max(0, active_touches - 1)
			if active_touches < 2:
				can_trigger_special = true
		if event.pressed:
			target_position = get_canvas_transform().affine_inverse() * event.position
			target_position.x = clamp(target_position.x, 20, screen_size.x - 20)
			target_position.y = clamp(target_position.y, 20, screen_size.y - 20)
			is_touching = true
		else:
			is_touching = false
			target_position = Vector2.ZERO
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				target_position = get_global_mouse_position()
				target_position.x = clamp(target_position.x, 20, screen_size.x - 20)
				target_position.y = clamp(target_position.y, 20, screen_size.y - 20)
				is_touching = true
			else:
				is_touching = false
				target_position = Vector2.ZERO
	elif event is InputEventMouseMotion:
		if is_touching:
			target_position = get_global_mouse_position()
			target_position.x = clamp(target_position.x, 20, screen_size.x - 20)
			target_position.y = clamp(target_position.y, 20, screen_size.y - 20)

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.position.y -= 12
	get_parent().add_child(bullet)
	bullet.add_to_group("player_bullets")

func special_move():
	if special_moves > 0 and not is_special_firing:
		is_special_firing = true
		special_moves -= 1
		special_moves_changed.emit(special_moves)
		special_move_started.emit()
		
		fire_special_wave()
		
		for i in range(9):
			await get_tree().create_timer(0.1).timeout
			fire_special_wave()
		
		is_special_firing = false
		special_move_ended.emit()

func fire_special_wave():
	for i in range(5):
		var bullet = bullet_scene.instantiate()
		bullet.position = Vector2(randf_range(20, screen_size.x - 20), screen_size.y - 10)
		get_parent().add_child(bullet)
		bullet.add_to_group("player_bullets")

func reset_special_moves():
	special_moves = 3
	special_moves_changed.emit(special_moves)

func _on_area_entered(area):
	if area.is_in_group("enemies") or area.is_in_group("enemy_bullets"):
		if not invincible:
			hit.emit()

func start_invincible():
	invincible = true
	modulate.a = 0.5
	await get_tree().create_timer(invincible_time).timeout
	invincible = false
	modulate.a = 1.0

func blink_effect():
	invincible = true
	var tween = create_tween()
	for i in range(6):
		tween.tween_property(sprite, "modulate:a", 0.3, 0.15)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.15)
	tween.tween_callback(_on_blink_done)

func _on_blink_done():
	invincible = false
	sprite.modulate.a = 1.0
