extends Node2D


# --- State ---
var started := false
var is_game_over := false
var score: float = 0.0

var player_ducking := false
var current_zoom: float = Globals.INITIAL_ZOOM

# --- Nodes ---
var bg_far: Sprite2D
var bg_mid: Sprite2D
var bg_near: Sprite2D

var player_vel_y: float = 0.0

var sidekicks := [] # each: { sprite: Sprite2D, delay:int, is_ducking:bool, is_jumping:bool, jump_vel:float, x_offset:float }
var action_queue := [] # each: { type:String, time_ms:int, processed_by:Array }




@onready var camera_2d = %Camera2D
@onready var parallax_1 = %Parallax2D1
@onready var parallax_2 = %Parallax2D2
@onready var parallax_3 = %Parallax2D3
@onready var boss = %Boss
@onready var player = %Player
@onready var obstacle_container = %Obstacles
@onready var spawn_timer = %SpawnTimer

@onready var overlay = %Overlay
@onready var ui_layer = %UILayer
@onready var score_label = %ScoreLabel
@onready var start_label = %StartLabel
@onready var factory = $Factory
@onready var rain_timer = %RainTimer
@onready var sidekicks_container = %Sidekicks
@onready var pickup_timer = %PickupTimer


func _ready() -> void:
	# Camera
	camera_2d.zoom = Vector2(Globals.INITIAL_ZOOM, Globals.INITIAL_ZOOM)

	player.position = Vector2(Globals.PLAYER_INITIAL_X, Globals.GROUND_Y)

	# Sidekicks
	#var sidekick_tex_paths := ["res://assets/commie.png", "res://assets/clover.png", "res://assets/pumpkin.png"]
	#var sidekick_duck_tex_paths := ["res://assets/commie.png", "res://assets/clover.png", "res://assets/pumpkin.png"]
	var sidekick_offsets := [-60.0, -90.0]
	var sidekick_delays := [150, 300]
	var i := 0
	for sidekick in sidekicks_container.get_children():
		sidekick.position = Vector2(Globals.PLAYER_INITIAL_X + sidekick_offsets[i], Globals.GROUND_Y)
		sidekicks.append({
			"sprite": sidekick,
			"delay": sidekick_delays[i],
			"is_ducking": false,
			"is_jumping": false,
			"jump_vel": 0.0,
			"x_offset": sidekick_offsets[i],
			#"duck_paths": [sidekick_duck_tex_paths[min(i, sidekick_duck_tex_paths.size()-1)],
							#sidekick_duck_tex_paths[min(i, sidekick_duck_tex_paths.size()-1)].replace(".png", ".jpg")] 
		})
		i += 1

	# Boss
	boss.position = Vector2(Globals.BOSS_INITIAL_X, Globals.GROUND_Y)

	#set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		_on_start_pressed()
		if started and not is_game_over:
			_jump()
	if event.is_action_pressed("ui_down"):
		_duck()
	if event.is_action_released("ui_down"):
		_stand_up()

func _on_start_pressed() -> void:
	if not started and not is_game_over:
		started = true
		start_label.queue_free()
		spawn_timer.start()
		rain_timer.start()
		pickup_timer.start()

func _jump() -> void:
	if is_game_over or player_ducking:
		return
	player.scale.y = 0.1
	if abs(player.position.y - Globals.GROUND_Y) < 0.5:
		player_vel_y = Globals.PLAYER_JUMP_VELOCITY
		action_queue.append({"type":"jump", "time_ms": Time.get_ticks_msec(), "processed_by": []})

func _duck() -> void:
	if is_game_over:
		return
	if player_ducking:
		return
	if abs(player.position.y - Globals.GROUND_Y) < 0.5:
		player_ducking = true
		player.scale.y = 0.04
		action_queue.append({"type":"duck", "time_ms": Time.get_ticks_msec(), "processed_by": []})

func _stand_up() -> void:
	if is_game_over:
		return
	if not player_ducking:
		return
	player.scale.y = 0.1
	player_ducking = false
	action_queue.append({"type":"standup", "time_ms": Time.get_ticks_msec(), "processed_by": []})

func _process(delta: float) -> void:
	if is_game_over or not started:
		queue_redraw() # for rain buildup when paused
		return

	Globals.game_speed = Globals.INITIAL_GAME_SPEED + (score * Globals.GAME_SPEED_INCREMENT)
	# Parallax scroll speeds
	parallax_1.autoscroll.x = Globals.game_speed * -60.0
	parallax_2.autoscroll.x = Globals.game_speed * -120.0
	parallax_3.autoscroll.x = Globals.game_speed * -200.0

	# Scoring & speed
	score += delta * 10.0
	
	score_label.text = "SCORE: %d" % int(score)

	# Zoom & camera slight pan
	current_zoom = min(Globals.MAX_ZOOM, Globals.INITIAL_ZOOM + (score * Globals.ZOOM_INCREMENT))
	camera_2d.zoom = Vector2(current_zoom, current_zoom)
	camera_2d.position.x = lerp(Globals.GAME_WIDTH/2.0, Globals.GAME_WIDTH/2.0 + 125.0, clamp((current_zoom - Globals.INITIAL_ZOOM) / (Globals.MAX_ZOOM - Globals.INITIAL_ZOOM), 0.0, 1.0))
	camera_2d.position.y = lerp(Globals.GAME_HEIGHT/2.0, Globals.GAME_HEIGHT/2.0 + 250.0, clamp((current_zoom - Globals.INITIAL_ZOOM) / (Globals.MAX_ZOOM - Globals.INITIAL_ZOOM), 0.0, 1.0))

	# Move player toward target X
	var progress_ratio: float = clamp(score * Globals.PLAYER_MOVEMENT_SPEED, 0.0, 1.0)
	player.position.x = lerp(Globals.PLAYER_INITIAL_X, Globals.PLAYER_TARGET_X, progress_ratio)

	# Apply jump physics
	player_vel_y += Globals.GRAVITY * delta
	player.position.y += player_vel_y * delta
	if player.position.y >= Globals.GROUND_Y:
		player.position.y = Globals.GROUND_Y
		player_vel_y = 0.0

	
	## Update sidekicks positions and actions
	for i in 2:
		var sk = sidekicks[i]
		var spr: Sprite2D = sidekicks_container.get_child(i)
		spr.position.x = player.position.x + float(sk.x_offset)
		# Jump physics for sidekicks
		if sk.is_jumping:
			sk.jump_vel += Globals.GRAVITY * delta
			spr.position.y += sk.jump_vel * delta
			if spr.position.y >= Globals.GROUND_Y:
				spr.position.y = Globals.GROUND_Y
				sk.is_jumping = false
				sk.jump_vel = 0.0
		# Process action queue with delay
		for a in action_queue:
			if not a.has("processed_by"):
				a.processed_by = []
			var elapsed := Time.get_ticks_msec() - int(a.time_ms)
			if elapsed >= int(sk.delay) and not i in a.processed_by:
				a.processed_by.append(i)
				match String(a.type):
					"jump":
						if not sk.is_jumping:
							sk.is_jumping = true
							sk.jump_vel = Globals.PLAYER_JUMP_VELOCITY
							spr.scale.y = 0.1
					"duck":
						if not sk.is_ducking:
							sk.is_ducking = true
							# attempt change texture
							spr.scale.y = 0.04
					"standup":
						if sk.is_ducking:
							sk.is_ducking = false
							spr.scale.y = 0.1
							# revert to original if available (no stored original, so no-op)

	# Clean old actions
	var new_q := []
	for a in action_queue:
		if Time.get_ticks_msec() - int(a.time_ms) < 1000:
			new_q.append(a)
	action_queue = new_q

	# Boss progression
	var b_ratio: float = clamp(score * Globals.BOSS_MOVEMENT_SPEED, 0.0, 1.0)
	boss.position.x = lerp(Globals.BOSS_INITIAL_X, Globals.BOSS_TARGET_X, b_ratio)

	# Move and cleanup obstacles; check collisions
	for obstacle in obstacle_container.get_children():
		obstacle.position.x -= Globals.game_speed
		if (obstacle.global_position.x + 64.0) < 0.0:
			obstacle.queue_free()
			continue
		#var hb: Rect2 = _get_sprite_rect(obstacle)
		#if _rects_intersect(hb, _get_sprite_rect(player)):
			#_on_game_over()
			#break


func _get_sprite_rect(s: Sprite2D) -> Rect2:
	var tex := s.texture
	if tex == null:
		return Rect2(s.global_position - Vector2(16,16), Vector2(32,32))
	var size := tex.get_size() * s.scale
	var pos := s.global_position - size*0.5
	return Rect2(pos, size)

func _rects_intersect(a: Rect2, b: Rect2) -> bool:
	return a.intersects(b)


func spawn_ground_obstacle() -> void:
	var obstacle = factory.get_obstacle()
	obstacle.position = Vector2(boss.position.x - 80.0, Globals.GROUND_Y)
	obstacle_container.add_child(obstacle)

func spawn_flying_obstacle() -> void:
	var obstacle = factory.get_flying_obstacle()
	obstacle.position = Vector2(boss.position.x - 80.0, Globals.GROUND_Y - 75.0)
	obstacle_container.add_child(obstacle)

func spawn_pickup() -> void:
	var obstacle = factory.get_pickup()
	obstacle.position = Vector2(boss.position.x - 80.0, Globals.GROUND_Y)
	obstacle_container.add_child(obstacle)

func _on_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	spawn_timer.stop()
	pickup_timer.stop()
	rain_timer.stop()
	player_ducking = false
	# simple feedback: tint player red
	player.modulate = Color(1,0.4,0.4)
	# show overlay
	overlay.visible = true
	var final := overlay.get_node("FinalScore") as Label
	if final:
		final.text = "FINAL SCORE: %d" % int(score)

func _on_restart_pressed() -> void:
	# Reload current scene
	get_tree().reload_current_scene()

func _on_spawn_timer_timeout():
	if is_game_over or not started:
		return
	# Decide obstacle type: ground twice as likely as flying
	var spawn_ground := randi() % 3 != 2
	if spawn_ground:
		boss.telegraph("kick")
		await get_tree().create_timer(float(Globals.BOSS_ATTACK_DELAY_MS)/1000.0).timeout
		spawn_ground_obstacle()
	else:
		boss.telegraph("punch")
		await get_tree().create_timer(float(Globals.BOSS_ATTACK_DELAY_MS)/1000.0).timeout
		spawn_flying_obstacle()
		
	# Semi-random next delay scaled by speed
	var next_delay :float= randf_range(1.5, 3.5) / (Globals.game_speed / Globals.INITIAL_GAME_SPEED)
	spawn_timer.wait_time = clamp(next_delay, 0.5, 5.0)
	
func _on_pickup_timer_timeout():
	spawn_pickup()
	var next_delay :float= randf_range(1.5, 3.5) / (Globals.game_speed / Globals.INITIAL_GAME_SPEED)
	pickup_timer.wait_time = clamp(next_delay, 0.5, 5.0)

func _on_player_collider_area_entered(area):
	if "points_value" in area.get_parent():
		score += area.get_parent().points_value
		area.get_parent().queue_free()
	else:
		_on_game_over()
