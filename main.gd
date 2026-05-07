extends Node2D

enum GameState { TITLE, PLAYING, GAMEOVER }

var game_state = GameState.TITLE
var score = 0
var lives = 3
var spawn_timer = 0.0
var spawn_delay = 2.0
var game_time = 0.0

var player_scene = preload("res://player.tscn")
var enemy_scene = preload("res://enemy.tscn")
var explosion_scene = preload("res://explosion.tscn")
var player
var screen_size

func _ready():
	screen_size = get_viewport_rect().size
	$CanvasLayer/HUD.visible = false
	$CanvasLayer/GameOver.visible = false
	setup_touch_input()

func setup_touch_input():
	var touch_control = Control.new()
	touch_control.set_name("TouchInputHandler")
	touch_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	touch_control.mouse_filter = Control.MOUSE_FILTER_STOP
	touch_control.gui_input.connect(_on_touch_input)
	add_child(touch_control)

func _on_touch_input(event):
	if event is InputEventScreenTouch:
		print("Touch detected: ", event.pressed)
		if event.pressed:
			if game_state == GameState.TITLE:
				start_game()
			elif game_state == GameState.GAMEOVER:
				restart_game()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("Mouse click detected")
			if game_state == GameState.TITLE:
				start_game()
			elif game_state == GameState.GAMEOVER:
				restart_game()

func _on_touch_area_input(event):
	if event is InputEventScreenTouch and event.pressed:
		if game_state == GameState.TITLE:
			start_game()
		elif game_state == GameState.GAMEOVER:
			restart_game()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if game_state == GameState.TITLE:
				start_game()
			elif game_state == GameState.GAMEOVER:
				restart_game()

func _process(delta):
	match game_state:
		GameState.PLAYING:
			game_time += delta
			spawn_timer += delta
			if spawn_timer >= spawn_delay:
				spawn_enemy()
				spawn_timer = 0
				spawn_delay = max(0.5, 2.0 - (game_time / 30.0))

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):
		if game_state == GameState.TITLE:
			start_game()
		elif game_state == GameState.GAMEOVER:
			restart_game()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseMotion:
		if player and player.is_touching:
			var world_pos = get_canvas_transform().affine_inverse() * event.position
			player.target_position = world_pos

func start_game():
	game_state = GameState.PLAYING
	score = 0
	lives = 3
	spawn_timer = 0.0
	spawn_delay = 2.0
	game_time = 0.0
	
	$CanvasLayer/Title.visible = false
	$CanvasLayer/HUD.visible = true
	$CanvasLayer/GameOver.visible = false
	
	player = player_scene.instantiate()
	player.position = Vector2(screen_size.x / 2, screen_size.y - 40)
	player.add_to_group("player")
	player.hit.connect(_on_player_hit)
	add_child(player)

func restart_game():
	for node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("player_bullets"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("enemy_bullets"):
		node.queue_free()
	if player:
		player.queue_free()
	start_game()

func add_score(points):
	score += points
	$CanvasLayer/HUD.update_score(score)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	var rand_x = randf_range(30, screen_size.x - 30)
	enemy.position = Vector2(rand_x, -20)
	
	var type_rng = randf()
	if type_rng < 0.6:
		enemy.set_type(0)
	elif type_rng < 0.85:
		enemy.set_type(1)
	else:
		enemy.set_type(2)
	
	enemy.add_to_group("enemies")
	add_child(enemy)

func _on_enemy_hit(enemy_pos, bullet, enemy_type):
	var explosion = explosion_scene.instantiate()
	explosion.position = enemy_pos
	add_child(explosion)
	match enemy_type:
		0: score += 10
		1: score += 25
		2: score += 50
	bullet.queue_free()
	$CanvasLayer/HUD.update_score(score)

func _on_player_hit():
	lives -= 1
	$CanvasLayer/HUD.update_lives(lives)
	if lives > 0:
		player.blink_effect()
	else:
		var explosion = explosion_scene.instantiate()
		explosion.position = player.position
		add_child(explosion)
		game_over()

func game_over():
	game_state = GameState.GAMEOVER
	if player:
		player.queue_free()
	$CanvasLayer/GameOver.visible = true
	$CanvasLayer/GameOver/FinalScore.text = "SCORE: " + str(score)