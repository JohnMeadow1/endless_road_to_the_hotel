extends Label

var speed_up := 0.0

func _ready():
	set_process(false)
	speed_up = randf_range(150.0, 400.0)

func _process(delta):
	position.y -= delta * speed_up
	modulate = Color.from_hsv(randf(), 1.0, 1.0)
	

func start():
	$Timer.start(0.8)
	set_process(true)
	
func _on_timer_timeout():
	queue_free()
