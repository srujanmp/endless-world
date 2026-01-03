# Global.gd (autoload)
extends Node

var selected_topic: String = "programming"
var score: int = 0
var high_score: int = 0
var level: int = 1

func reset_score():
	score = 0
	level = 1

func reset_score_only():
	score = 0

func add_score(amount: int):
	score += amount
	if score > high_score:
		high_score = score

func next_level():
	level += 1
