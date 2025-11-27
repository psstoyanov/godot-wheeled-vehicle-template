extends Sprite2D

@onready var vehicle: RigidBody2D # set by Vehicle.gd, until then just some temporary rigidbody so that the script doesn't shit itself

# steering variables
@export var is_steering = false # wether a wheel responds to steering input
@export var max_angle = 0.0 # maximum angle the wheel can steer to
var steering_speed = 0.0 # how fast the wheel steers, set by Vehicle.gd
var center_steering = true # see explanation in Vehicle.gd

@export var power = 0.0 # how much a wheel responds to drive input
@export var grip = 0.0 # grip of the tire, set by Vehicle.gd

@onready var forward: Vector2
@onready var right: Vector2
@onready var player_to_wheel = Vector2(0, 0)

@onready var last_position: Vector2
@onready var wheel_velocity: Vector2
@export var debug_draw: bool = true
@onready var myDebugLineLinear: Line2D
@onready var myDebugLineLateral: Line2D

func _ready() -> void:
	myDebugLineLinear = Line2D.new()
	myDebugLineLateral = Line2D.new()
	add_child(myDebugLineLinear)
	add_child(myDebugLineLateral)
	myDebugLineLinear.default_color = Color.PURPLE
	myDebugLineLateral.default_color = Color.BLUE
	if debug_draw:
		myDebugLineLinear.width = 5
		myDebugLineLateral.width = 5
	else:
		myDebugLineLinear.width = 0
		myDebugLineLateral.width = 0

func _physics_process(_delta) -> void:
	# Update wheel forward and right directions in world space
	forward = - global_transform.y.normalized()
	right = global_transform.x.normalized()

	# Get world offset for the wheel
	player_to_wheel = global_position - vehicle.global_position
	# The wheel velocity in world space
	wheel_velocity = vehicle.linear_velocity + vehicle.angular_velocity * Vector2(-player_to_wheel.y, player_to_wheel.x)
	
	last_position = global_position

func steer(steering_input, delta):
	if (is_steering):
		var desired_angle = clamp(steering_input * max_angle,
			- max_angle, max_angle)
		if steering_input == 0 and not center_steering:
			desired_angle = rotation_degrees
		var new_angle = lerp(rotation_degrees, desired_angle,
			steering_speed * delta)
		rotation_degrees = new_angle

func drive(drive_input):
	vehicle.apply_impulse(drive_input * power * forward, player_to_wheel)
	if debug_draw:
		var force_vec = (drive_input * power * forward) * 20.0
		# End point in local wheel space
		var local_end = to_local(global_position + force_vec)

		myDebugLineLinear.points = PackedVector2Array([
			Vector2.ZERO, # start at wheel origin
			local_end # direction of force
		])


func apply_lateral_forces(delta):
	# Use the dot product to calculate the lateral wheel speed
	var lateral_speed = wheel_velocity.dot(right)
	var lateral_impulse = - right * lateral_speed * grip * delta

	if debug_draw:
		var force_vec = lateral_impulse * 20.0

		# End point in *local* wheel space
		var local_end = to_local(global_position + force_vec)

		myDebugLineLateral.points = PackedVector2Array([
			Vector2.ZERO, # start at wheel origin
			local_end # direction of force
		])
	vehicle.apply_impulse(lateral_impulse, player_to_wheel)
