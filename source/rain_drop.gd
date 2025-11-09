extends Sprite2D


var velocity:= Vector2.ZERO
var alpha:= 0.0

func _ready():
	set_process(false)
	rotation = velocity.angle()
func start():
	set_process(true)

func _process(delta):
	position += velocity * delta
	if position.y > Globals.GROUND_Y:
		get_parent().make_splash(position, Globals.game_speed * -200.0) 
		queue_free()


func _on_area_entered(area):
	get_parent().make_splash(position)
	queue_free()
