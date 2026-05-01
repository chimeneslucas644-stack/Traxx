extends CharacterBody3D

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var body: Node3D = $body
@onready var camera_pivot: Node3D = $CameraPivot


@export_group("Movement")
@export var speed_player: float = 4.0

@export_group("Camera")
@export var CameraSensitivity: float = 0.005

@export_group("Smooths")
@export var smooth_camera: float = 8.0
@export var smooth_velocity: float = 16.0
@export var smooth_aniamtion: float = 6.0
@export var smooth_body_rotate: float = 8.0

var camera_axis_x: float = 0.0
var camera_axis_y: float = 0.0

var blend_param_move: String = "parameters/move/blend_position"
var blend_value_move: float = 0.0
var target_value_move: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camera_axis_x -= event.relative.y * CameraSensitivity
		camera_axis_y -= event.relative.x * CameraSensitivity
		camera_axis_x = clamp(camera_axis_x, deg_to_rad(-90), deg_to_rad(60))
		
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	var input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var forward = camera_pivot.global_transform.basis.z
	var right = camera_pivot.global_transform.basis.x
	var direction = (forward * input.y + right * input.x)
	direction.y = 0
	direction = direction.normalized()
	
	var target_velocity = direction * speed_player
	
	velocity.x = move_toward(velocity.x, target_velocity.x, smooth_velocity * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, smooth_velocity * delta)
	
	# Rotaciona o corpo do player para a direcao em que estou adando
	if direction.length() > 0.01:
		var target_angle = atan2(direction.x, direction.z)
		body.rotation.y = lerp_angle(body.rotation.y, target_angle, smooth_body_rotate * delta)

	# Aplica a suavizacao da rotaca da camera
	camera_pivot.rotation.x = lerp_angle(camera_pivot.rotation.x, camera_axis_x, smooth_camera * delta)
	camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, camera_axis_y, smooth_camera * delta)
	
	var is_sprinting := Input.is_action_pressed("sprint")
	if input:
		if is_sprinting:
			target_value_move = 2.0
			speed_player = 4.0
		else:
			target_value_move = 1.0
			speed_player = 2.0
	else:
		target_value_move = 0.0
	
	move_and_slide()

	apply_animations(delta)

func apply_animations(delta):
	animation_tree.set(blend_param_move, blend_value_move)
	blend_value_move = lerp(blend_value_move, target_value_move, smooth_aniamtion * delta)
