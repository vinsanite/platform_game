extends Node

# Score variable
var score = 0
var highscore = 0
var permanant_buff = false

func _ready():
	# Initial check to update highscore if score is loaded from a saved game
	check_highscore()

# Function to reset the score
func reset_score():
	score = 0

func check_highscore():
	if score > highscore:
		highscore = score

func perma_buff():
	permanant_buff = true
