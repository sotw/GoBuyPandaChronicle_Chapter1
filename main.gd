extends Node2D

enum GameState { TITLE, PLAYING, GAMEOVER }

var game_state = GameState.TITLE
var score = 0
var lives = 3
var spawn_timer = 0.0
var spawn_delay = 1.5
var game_time = 0.0

var player_scene = preload("res://player.tscn")
var enemy_scene = preload("res://enemy.tscn")
var explosion_scene = preload("res://explosion.tscn")
var player
var special_background: AnimatedSprite2D
var screen_size
var gif_size = Vector2(240, 135)

var star_layers: Array = []
var star_texture: Texture2D
var rotating_star_positions: Array = []
var parallax_initialized = false

# --- Initialization ---

func _ready():
	screen_size = get_viewport_rect().size
	$CanvasLayer/HUD.visible = false
	$CanvasLayer/GameOver.visible = false
	
	special_background = $SpecialBackground
	
	# Load WebP frames and create SpriteFrames at runtime
	var frames = SpriteFrames.new()
	
	var frame_dir = "res://gif_frames_webp/"
	var frame_num = 0
	while true:
		var frame_path = frame_dir + "%03d.webp" % frame_num
		var frame_texture = load(frame_path)
		if not frame_texture:
			break
		if frame_num == 0 and not frames.has_animation("default"):
			frames.add_animation("default")
		frames.add_frame("default", frame_texture)
		frame_num += 1
		if frame_num > 100:
			break
	
	if frames.get_frame_count("default") > 0:
		special_background.sprite_frames = frames
		special_background.speed_scale = 1.0
		var first_frame = frames.get_frame_texture("default", 0)
		if first_frame:
			gif_size = first_frame.get_size()
	
	# Scale based on screen height, keep original ratio
	var scale_by_height = screen_size.y / gif_size.y
	
	special_background.position = screen_size / 2
	special_background.scale = Vector2(scale_by_height, scale_by_height)
	
	# Connect Button signals safely
	$CanvasLayer/Title.pressed.connect(_on_title_pressed)
	$CanvasLayer/GameOver.pressed.connect(_on_gameover_pressed)

func create_star_texture():
	var image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	var center = 2.0
	
	for x in range(4):
		for y in range(4):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			if dist < 2.0:
				var alpha = 1.0 - (dist / 2.0)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	star_texture = ImageTexture.create_from_image(image)

func setup_parallax_layers():
	var stars_node = $Stars
	stars_node.visible = true
	
	var layer_configs = [
		{"speed": 5.0, "count": 20, "size": 0.3, "color": Color(0.5, 0.5, 0.6, 0.5)},
		{"speed": 10.0, "count": 25, "size": 0.5, "color": Color(0.7, 0.7, 0.8, 0.7)},
		{"speed": 20.0, "count": 15, "size": 0.8, "color": Color(1, 1, 1, 0.9)},
		{"speed": 35.0, "count": 8, "size": 1.2, "color": Color(1, 1, 1, 1.0)}
	]
	
	for config in layer_configs:
		var layer_node = Node2D.new()
		layer_node.set_meta("speed", config.speed)
		stars_node.add_child(layer_node)
		
		var stars: Array = []
		for i in range(config.count):
			var sprite = Sprite2D.new()
			sprite.texture = star_texture
			sprite.scale = Vector2(config.size, config.size)
			sprite.modulate = config.color
			sprite.position = Vector2(randf() * screen_size.x, randf() * screen_size.y)
			layer_node.add_child(sprite)
			stars.append(sprite)
		
		star_layers.append({"node": layer_node, "stars": stars, "speed": config.speed})
	
	# Create rotating starfield (Mode 7 style center rotation)
	var rotating_node = Node2D.new()
	rotating_node.name = "RotatingStars"
	stars_node.add_child(rotating_node)
	
	for i in range(12):
		var sprite = Sprite2D.new()
		sprite.texture = star_texture
		sprite.scale = Vector2(0.6, 0.6)
		sprite.modulate = Color(0.8, 0.85, 1.0, 0.6)
		
		var angle = (i * TAU) / 12.0
		var radius = 80.0
		sprite.position = Vector2(screen_size.x / 2 + cos(angle) * radius, screen_size.y / 2 + sin(angle) * radius)
		
		rotating_node.add_child(sprite)
		rotating_star_positions.append({"sprite": sprite, "angle": angle, "radius": radius})

	# Add nebula clouds (semi-transparent colored gradients)
	create_nebula_clouds()

func create_nebula_clouds():
	var stars_node = $Stars
	
	var nebula_node = Node2D.new()
	nebula_node.name = "Nebula"
	nebula_node.set_meta("speed", 8.0)
	stars_node.add_child(nebula_node)
	
	# Create nebula texture (soft gradient circle)
	var nebula_tex = create_nebula_texture()
	
	# Create 3 soft nebula clouds
	for i in range(3):
		var nebula = Sprite2D.new()
		nebula.texture = nebula_tex
		nebula.scale = Vector2(3.0, 2.5)
		nebula.modulate = Color(0.4, 0.15, 0.5, 0.25)
		nebula.position = Vector2(randf() * screen_size.x, randf() * screen_size.y)
		nebula_node.add_child(nebula)
	
	star_layers.append({"node": nebula_node, "nebula": true, "speed": 8.0})

func create_nebula_texture() -> Texture2D:
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(Vector2(center, center))
			if dist < center:
				var alpha = pow(1.0 - (dist / center), 2.0) * 0.5
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

# --- Input Handling ---

func _on_title_pressed():
	if game_state == GameState.TITLE:
		start_game()

func _on_gameover_pressed():
	if game_state == GameState.GAMEOVER:
		restart_game()

func _input(event):
	# 1. Handle Menu Navigation (Standard UI)
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		if game_state == GameState.TITLE:
			start_game()
		elif game_state == GameState.GAMEOVER:
			restart_game()
	
	# 2. Handle Multi-Touch Logic
	if event is InputEventScreenTouch:
		if game_state == GameState.PLAYING and is_instance_valid(player):
			# INDEX 0: The first finger on screen (Movement)
			if event.index == 0:
				var world_pos = get_canvas_transform().affine_inverse() * event.position
				player.target_position = world_pos
			
			# INDEX 1+: Any additional finger (Special Move)
			elif event.index >= 1 and event.pressed:
				# Trigger special move only if the player has the method
				if player.has_method("use_special_move"):
					player.use_special_move()

	elif event is InputEventScreenDrag:
		# Dragging only updates movement if it's the primary finger
		if game_state == GameState.PLAYING and is_instance_valid(player):
			if event.index == 0:
				var world_pos = get_canvas_transform().affine_inverse() * event.position
				player.target_position = world_pos

# --- Game Loop ---

func _process(delta):
	# Initialize parallax on first frame (for HTML5 export compatibility)
	if not parallax_initialized:
		screen_size = get_viewport_rect().size
		create_star_texture()
		setup_parallax_layers()
		parallax_initialized = true
	
	# Update screen size in case of resize
	screen_size = get_viewport_rect().size
	
	# Update special background scale on resize (based on height, keep ratio)
	if special_background and is_instance_valid(special_background):
		special_background.position = screen_size / 2
		if gif_size.y > 0:
			var scale_by_height = screen_size.y / gif_size.y
			special_background.scale = Vector2(scale_by_height, scale_by_height)
	
	# Parallax scrolling
	update_parallax(delta)
	
	match game_state:
		GameState.PLAYING:
			game_time += delta
			spawn_timer += delta
			if spawn_timer >= spawn_delay:
				spawn_enemy()
				spawn_timer = 0
				spawn_delay = max(0.3, 1.5 - (game_time / 25.0))

func update_parallax(delta):
	var stars_node = $Stars
	if not stars_node:
		return
	
	# Scroll each star layer
	for layer_data in star_layers:
		var node = layer_data.get("node")
		if node and is_instance_valid(node):
			var speed = layer_data.get("speed", 10.0)
			
			if layer_data.get("nebula", false):
				for child in node.get_children():
					child.position.y += speed * delta
					if child.position.y > screen_size.y:
						var nebula_height = 64.0  # Approximate nebula height
						child.position.y = -nebula_height
						child.position.x = randf() * screen_size.x
			else:
				var stars = layer_data.get("stars", [])
				for star in stars:
					if is_instance_valid(star):
						star.position.y += speed * delta
						if star.position.y > screen_size.y + 10:
							star.position.y = -10
							star.position.x = randf() * screen_size.x
	
	# Rotate starfield
	var rotating_node = stars_node.get_node_or_null("RotatingStars")
	if rotating_node and is_instance_valid(rotating_node):
		rotating_node.rotation += 0.15 * delta
	
	# Also animate rotating stars in a circular pattern
	for star_data in rotating_star_positions:
		var sprite = star_data.get("sprite")
		if is_instance_valid(sprite):
			star_data.angle += 0.2 * delta
			var radius = star_data.radius
			sprite.position = Vector2(
				screen_size.x / 2 + cos(star_data.angle) * radius,
				screen_size.y / 2 + sin(star_data.angle) * radius
			)

# --- Game State Methods ---

func start_game():
	game_state = GameState.PLAYING
	score = 0
	lives = 3
	spawn_timer = 0.0
	spawn_delay = 1.5
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
	player.special_moves_changed.connect(_on_special_moves_changed)
	player.special_move_started.connect(_on_special_move_started)
	player.special_move_ended.connect(_on_special_move_ended)
	player.reset_special_moves()
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
	$CanvasLayer/GameOver/FinalScore.text = "SPENT: " + str(score) + "$"

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
		player.reset_special_moves()
	else:
		var explosion = explosion_scene.instantiate()
		explosion.position = player.position
		add_child(explosion)
		game_over()

func _on_special_moves_changed(count):
	$CanvasLayer/HUD.update_special_moves(count)

func _on_special_move_started():
	if special_background:
		special_background.visible = true
		if special_background is AnimatedSprite2D:
			special_background.play()
	$Stars.visible = false

func _on_special_move_ended():
	if special_background:
		special_background.visible = false
		if special_background is AnimatedSprite2D:
			special_background.stop()
	$Stars.visible = true
