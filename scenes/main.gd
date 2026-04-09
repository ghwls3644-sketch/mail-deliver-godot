extends Node3D

const CAMERA_OFFSET = Vector3(-12, 14, 12)

@onready var camera = $Camera3D
@onready var player = $Player

func _process(delta):
	camera.position = player.position + CAMERA_OFFSET
	camera.look_at(player.position, Vector3.UP)
