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

# --- Initialization ---

func _ready():
	screen_size = get_viewport_rect().size
	$CanvasLayer/HUD.visible = false
	$CanvasLayer/GameOver.visible = false
	
	# Connect Button signals safely
	$CanvasLayer/Title.pressed.connect(_on_title_pressed)
	$CanvasLayer/GameOver.pressed.connect(_on_gameover_pressed)

# --- Input Handling ---

func _on_title_pressed():
	if game_state == GameState.TITLE:
		start_game()

func _on_gameover_pressed():
	if game_state == GameState.GAMEOVER:
		restart_game()

func _input(event):
	# 1. Handle Menu Navigation (Taps/Buttons)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if game_state == GameState.TITLE:
			start_game()
		elif game_state == GameState.GAMEOVER:
			restart_game()
	
	# 2. Handle Player Movement (Touch and Drag)
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		if game_state == GameState.PLAYING and is_instance_valid(player):
			# Map the touch screen position to the game world position
			var world_pos = get_canvas_transform().affine_inverse() * event.position
			player.target_position = world_pos

# --- Game Loop ---

func _process(delta):
	match game_state:
		GameState.PLAYING:
			game_time += delta
			spawn_timer += delta
			if spawn_timer >= spawn_delay:
				spawn_enemy()
				spawn_timer = 0
				# Difficulty curve: speed up spawns over time
				spawn_delay = max(0.5, 2.0 - (game_time / 30.0))

# --- Game State Methods ---

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
	$CanvasLayer/HUD.update_score(score)
	$CanvasLayer/HUD.update_lives(lives)
	
	player = player_scene.instantiate()
	player.position = Vector2(screen_size.x / 2, screen_size.y - 80)
	# Set target_position immediately so player doesn't fly to (0,0)
	player.target_position = player.position 
	player.add_to_group("player")
	player.hit.connect(_on_player_hit)
	add_child(player)

func restart_game():
	# Clean up enemies and bullets
	for group in ["enemies", "player_bullets", "enemy_bullets"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()
			
	if is_instance_valid(player):
		player.queue_free()
	
	start_game()

func game_over():
	game_state = GameState.GAMEOVER
	if is_instance_valid(player):
		player.queue_free()
	$CanvasLayer/GameOver.visible = true
	$CanvasLayer/GameOver/FinalScore.text = "SCORE: " + str(score)

# --- Combat & Scoring ---

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
	
	if is_instance_valid(bullet):
		bullet.queue_free()
	$CanvasLayer/HUD.update_score(score)

func _on_player_hit():
	lives -= 1
	$CanvasLayer/HUD.update_lives(lives)
	if lives > 0:
		if player.has_method("blink_effect"):
			player.blink_effect()
	else:
		var explosion = explosion_scene.instantiate()
		explosion.position = player.position
		add_child(explosion)
		game_over()
