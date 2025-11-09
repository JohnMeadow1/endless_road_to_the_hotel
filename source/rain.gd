extends Node2D

## --- Constants (ported from the JS version, tuned for Godot) ---
#const GAME_WIDTH: int = 1000
#const GAME_HEIGHT: int = 600
#
#const GROUND_Y: float = GAME_HEIGHT - 30.0

@export var player:Node2D
@export var boss:Node2D
@export var obstacles:Node2D

var rain_particles := [] # each: { x:float,y:float,speed:float,wind:float,length:float,alpha:float }
var splash_particles := [] # each: { x:float,y:float,vx:float,vy:float,life:float,max_life:float,size:float }
var max_rain := 50
var max_splash := 50
@onready var rain_timer = %RainTimer

func _process(delta):
	# Update rain
	var keep := []
	for rain_drop in rain_particles:
		rain_drop.y += rain_drop.speed * delta
		rain_drop.x -= rain_drop.wind * delta
		if _rain_collides(rain_drop.x, rain_drop.y):
			continue
		if rain_drop.y > Globals.GROUND_Y:
			continue
		keep.append(rain_drop)
	rain_particles = keep.duplicate()

	# Update splashes
	keep.clear()
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

func _rain_collides(x: float, y: float) -> bool:
	# ground
	if y >= Globals.GROUND_Y - 5.0:
		_make_splash(x, Globals.GROUND_Y)
		return true
	# player
	if _get_sprite_rect(player).has_point(Vector2(x,y)):
		_make_splash(x, y)
		return true
	# sidekicks
	#for sk in sidekicks:
		#if _get_sprite_rect(sk.sprite).has_point(Vector2(x,y)):
			#_make_splash(x,y)
			#return true
	# boss
	if _get_sprite_rect(boss).has_point(Vector2(x,y)):
		_make_splash(x,y)
		return true
	# obstacles
	for obstacle in obstacles.get_children():
		if _get_sprite_rect(obstacle).has_point(Vector2(x,y)):
			_make_splash(x,y)
			return true
	return false

func _make_splash(x: float, y: float) -> void:
	if splash_particles.size() >= max_splash:
		return
		
	for i in randi_range(2,3):
		var angle_deg := randf_range(-30.0, 30.0) - 90.0
		var speed := randf_range(30.0, 80.0)
		var angle := deg_to_rad(angle_deg)
		splash_particles.append({
			"x":x, "y":y,
			"vx": cos(angle) * speed,
			"vy": sin(angle) * speed,
			"life": 200.0,
			"max_life": 200.0,
			"size": randf_range(1.0, 2.0)
		})

func _get_sprite_rect(s: Sprite2D) -> Rect2:
	var tex := s.texture
	if tex == null:
		return Rect2(s.global_position - Vector2(16,16), Vector2(32,32))
	var size := tex.get_size() * s.scale
	var pos := s.global_position - size*0.5
	return Rect2(pos, size)

func _rects_intersect(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)

func _on_rain_timer_timeout():
	if rain_particles.size() >= max_rain:
		return
	var x := randf_range(0.0, Globals.GAME_WIDTH + 400.0)
	var y := -10.0
	var speed := randf_range(500.0, 700.0)
	var wind := 500.0 + (Globals.game_speed - Globals.INITIAL_GAME_SPEED) * 200.0
	var speed_mult := (Globals.game_speed - Globals.INITIAL_GAME_SPEED) / Globals.INITIAL_GAME_SPEED
	var len_min := 10.0 + (speed_mult * 30.0)
	var len_max := 25.0 + (speed_mult * 50.0)
	var length := randf_range(len_min, len_max)
	var alpha := randf_range(0.5, 0.8)
	rain_particles.append({"x":x, "y":y, "speed":speed, "wind":wind, "length":length, "alpha":alpha})


func _draw() -> void:
	# Draw rain as lines
	for rain_drop in rain_particles:
		var angle_offset: float = (rain_drop.wind / rain_drop.speed) * rain_drop.length
		draw_line(Vector2(rain_drop.x, rain_drop.y), Vector2(rain_drop.x + angle_offset, rain_drop.y - rain_drop.length), Color(0.53, 0.8, 1.0, rain_drop.alpha), 2.0)
		
	# Draw splashes
	for splash in splash_particles:
		var alpha: float = splash.life / splash.max_life
		draw_circle(Vector2(splash.x, splash.y), splash.size, Color(0.67, 0.85, 1.0, alpha))
