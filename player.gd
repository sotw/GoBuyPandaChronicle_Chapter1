extends Area2D

signal hit

var speed = 150.0
var screen_size
var bullet_scene = preload("res://bullet.tscn")
var can_shoot = true
var shoot_delay = 0.33
var invincible = false
var invincible_time = 2.0
var sprite

func _ready():
	screen_size = get_viewport_rect().size
	sprite = Sprite2D.new()
	sprite.texture = load("res://panda.png")
	add_child(sprite)

func _process(delta):
	var velocity = Vector2.ZERO
	
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		velocity.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		velocity.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		velocity.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		velocity.y += 1
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	position += velocity * delta
	position.x = clamp(position.x, 20, screen_size.x - 20)
	position.y = clamp(position.y, 20, screen_size.y - 20)
	
	if Input.is_key_pressed(KEY_SPACE) and can_shoot:
		shoot_bullet()
		can_shoot = false
		await get_tree().create_timer(shoot_delay).timeout
		can_shoot = true

func shoot_bullet():
	var bullet = bullet_scene.instantiate()
	bullet.position = position
	bullet.position.y -= 12
	get_parent().add_child(bullet)
	bullet.add_to_group("player_bullets")

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
	var tween = create_tween()
	for i in range(6):
		tween.tween_property(self, "modulate:a", 0.3, 0.15)
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
	invincible = true
	tween.tween_callback(_on_blink_done)

func _on_blink_done():
	invincible = false