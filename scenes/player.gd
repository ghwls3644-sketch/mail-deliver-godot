extends CharacterBody3D

const SPEED = 5.0
const GRAVITY = -9.8

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var input = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		input += Vector3(1, 0, -1)
	if Input.is_action_pressed("ui_down"):
		input += Vector3(-1, 0, 1)
	if Input.is_action_pressed("ui_left"):
		input += Vector3(-1, 0, -1)
	if Input.is_action_pressed("ui_right"):
		input += Vector3(1, 0, 1)

	if input.length() > 0:
		input = input.normalized()
		velocity.x = input.x * SPEED
		velocity.z = input.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()
