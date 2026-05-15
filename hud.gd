extends Control

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel
@onready var special_moves_container = $SpecialMovesContainer

func update_score(new_score):
	score_label.text = "SPENT: " + str(new_score) + "$"

func update_lives(new_lives):
	lives_label.text = "LIVES: " + str(new_lives)

func update_special_moves(count):
	for i in range(3):
		var icon = special_moves_container.get_child(i)
		if i < count:
			icon.visible = true
		else:
			icon.visible = false