extends Sprite2D

@onready var animation = %Animation


func telegraph(kind: String, speed:= 1.0) -> void:
	animation.speed_scale = speed
	if kind == "kick":
		animation.play("kick")
	else:
		animation.play("punch")
