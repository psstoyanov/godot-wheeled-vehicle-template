extends RigidBody2D

@export_group("Vehicle controls")
## Set the grip of the vehicle.
@export_range(0.0, 1.0) var grip = 1.0
## Air resistance
@export var air_resistance = 0.1

## How fast the wheel steers toward its target angle (degrees per second).
@export var steering_speed: int = 3
## Enable steering auto-centering to return towards center position.
@export var steering_auto_center: bool = true
## How fast the wheel returns towards center postion(degrees per second).
@export var steering_speed_decay: float = 0.1

## Debug lines for the wheel forces
@export var debug_draw_forces: bool = false

@onready var right: Vector2
@onready var wheel_group: String = str(get_instance_id()) + "-wheels" # unique name for the wheel group


func _ready():
	# add wheels to group with unique name
	var wheels = get_node("Wheels").get_children()
	for wheel in wheels:
		wheel.add_to_group(wheel_group)

	# tire setup
	get_tree().set_group(wheel_group, "vehicle", self)
	get_tree().set_group(wheel_group, "grip", grip)
	get_tree().set_group(wheel_group, "debug_draw_forces", debug_draw_forces)
	get_tree().set_group(wheel_group, "steering_speed", steering_speed)
	get_tree().set_group(wheel_group, "steering_auto_center", steering_auto_center)

func _physics_process(delta) -> void:
	right = global_transform.x.normalized()

	# acceleration input
	var drive_input = 0
	if Input.is_action_pressed("accelerate"):
		drive_input = 1
	if Input.is_action_pressed("decelerate"):
		drive_input = -1
	get_tree().call_group(wheel_group, "drive", drive_input)
	
	# steering input
	var steering_input = 0.0
	if Input.is_action_pressed("steer_right"):
		steering_input += 1.0
	if Input.is_action_pressed("steer_left"):
		steering_input -= 1.0

	steering_input /= 0.01 * steering_speed_decay * linear_velocity.length() + 1.0
	get_tree().call_group(wheel_group, "steer", steering_input, delta)
	
	# lateral tire forces
	get_tree().call_group(wheel_group, "apply_lateral_forces", delta)
	
	# "air resistance"
	var vel = 0.005 * linear_velocity
	apply_central_impulse(-air_resistance * vel)
	# air resistance *should* scale quadratically with velssssocity but whatever
	# var velSquared = vel.length_squared() * vel.normalized()
	# apply_central_impulse(-air_resistance * velSquared)
