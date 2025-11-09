extends Node2D

## --- Constants (ported from the JS version, tuned for Godot) ---
#const GAME_WIDTH: int = 1000
#const GAME_HEIGHT: int = 600
#
#const GROUND_Y: float = GAME_HEIGHT - 30.0

@export var player:Node2D
@export var boss:Node2D
@export var obstacles:Node2D

var splash_particles := [] # each: { x:float,y:float,vx:float,vy:float,life:float,max_life:float,size:float }
var max_splash := 500

func _process(delta):
	# Update splashes
	var keep := []
	for splash in splash_particles:
		splash.x += splash.vx * delta
		splash.y += splash.vy * delta
		splash.vy += 500.0 * delta
		splash.life -= delta * 1000.0
		if splash.life <= 0.0:
			continue
		keep.append(splash)
	splash_particles = keep.duplicate()

	queue_redraw()


func make_splash(in_position:Vector2, extre_x:float = 0.0) -> void:
	var color = Color(1.0,1.0,1.0,0.5)
	for i in randi_range(2,6):
		#var angle_deg := randf_range(-2.10, 1.05)
		var angle_deg := randf_range(-2.10, 0.05)
		var speed := randf_range(230.0, 280.0) 
		%Particles2D.emit_particle(Transform2D(0.0, in_position), Vector2.from_angle(angle_deg) * speed + Vector2(extre_x, 0), color, color, 15)
		
#func make_splash(x: float, y: float, extre_x:float = 0.0) -> void:
	#if splash_particles.size() >= max_splash:
		#return
		#
	#for i in randi_range(2,3):
		#var angle_deg := randf_range(-30.0, 30.0) - 90.0
		#var speed := randf_range(130.0, 180.0)
		#var angle := deg_to_rad(angle_deg)
		#splash_particles.append({
			#"x":x, "y":y,
			#"vx": cos(angle) * speed + extre_x,
			#"vy": sin(angle) * speed,
			#"life": 200.0,
			#"max_life": 200.0,
			#"size": randf_range(2.0, 4.0)
		#})

func _get_sprite_rect(s: Sprite2D) -> Rect2:
	var tex := s.texture
	if tex == null:
		return Rect2(s.global_position - Vector2(16,16), Vector2(32,32))
	var size := tex.get_size() * s.scale
	var pos := s.global_position - size*0.5
	return Rect2(pos, size)

func _rects_intersect(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)

func create_rain_drop():
	var new_drop = Globals.factory.get_rain_drop()
	new_drop.position = Vector2(randf_range(0.0, Globals.GAME_WIDTH + 400.0), -10)
	new_drop.velocity = Vector2(-randf_range(500.0, 700.0), 500.0 + (Globals.game_speed - Globals.INITIAL_GAME_SPEED) * 200.0)
	add_child(new_drop)
	new_drop.start()

func _draw() -> void:
	# Draw splashes
	for splash in splash_particles:
		var alpha: float = splash.life / splash.max_life
		draw_circle(Vector2(splash.x, splash.y), splash.size, Color(0.67, 0.85, 1.0, alpha))
