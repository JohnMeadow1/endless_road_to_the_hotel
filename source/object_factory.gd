extends Node

var pickups_count := 0
var obstacles_count := 0
var flying_obstacles_count := 0


func _ready():
	obstacles_count = %Obstacle.get_child_count()
	pickups_count = %Pickup.get_child_count()
	flying_obstacles_count = %FlyingObstacle.get_child_count()

func get_pickup():
	return %Pickup.get_child(randi()%pickups_count).duplicate()

func get_obstacle():
	return %Obstacle.get_child(randi()%obstacles_count).duplicate()

func get_flying_obstacle():
	return %FlyingObstacle.get_child(randi()%flying_obstacles_count).duplicate()
