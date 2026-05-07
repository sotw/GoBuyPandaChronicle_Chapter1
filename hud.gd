extends Control

@onready var score_label = $ScoreLabel
@onready var lives_label = $LivesLabel

func update_score(new_score):
	score_label.text = "SCORE: " + str(new_score)

func update_lives(new_lives):
	lives_label.text = "LIVES: " + str(new_lives)