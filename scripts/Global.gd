# Global.gd
extends Node

var score: int = 0
var high_score: int = 0

func add_score(amount: int):
	score += amount
	if score > high_score:
		high_score = score
