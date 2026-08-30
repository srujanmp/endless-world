extends Area2D

signal collected

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		Global.add_score(-2)
		emit_signal("collected")
		queue_free()
