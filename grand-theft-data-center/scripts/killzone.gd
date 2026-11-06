extends Area2D

func _ready() -> void:
	for connection in body_entered.get_connections():
		if connection["callable"] == Callable(self, "_on_body_entered"):
			body_entered.disconnect(_on_body_entered)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("Hit body: ", body.name)
	if body.is_in_group("player") and body.has_method("die"):
		body.die()
