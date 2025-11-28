extends Sprite2D


@export_group("Wheelcontrols")
##Whetherthewheelrespondstosteerinput
@export var is_steering:bool = false
##Maximumanglethewheelcansteerto
@export var max_angle:float = 0.0
##Howmuch a wheel responds to drive input
@export var power: float = 0.0
## Whether the wheel responds to handbrake input
@export var is_handbrake: bool = false


## How fast the wheel steers, set by Vehicle.gd
var steering_speed: int = 0
## See explanation in Vehicle.gd
var steering_auto_center: bool = true
## Grip of the tire, set by Vehicle.gd
var grip: float = 0.0
## How much strenght is applied via the handbrake, set by Vehicle.gd
var handbrake_strength: float = 2.0
##  Handbrake is active
var handbrake_active: bool = false


@onready var forward: Vector2
@onready var right: Vector2
@onready var player_to_wheel: Vector2
@onready var vehicle: RigidBody2D

@onready var last_position: Vector2
@onready var wheel_velocity: Vector2

## Debug draw of the impulses
var debug_draw_forces: bool = false
@onready var myDebugLineLinear: Line2D
@onready var myDebugLineLateral: Line2D
@onready var myDebugLateralHandbrake: Line2D
@onready var myDebugLineHandbrake: Line2D


func _ready():
	myDebugLineLinear = Line2D.new()
	myDebugLineLateral = Line2D.new()
	myDebugLateralHandbrake = Line2D.new()
	myDebugLineHandbrake = Line2D.new()
	add_child(myDebugLineLinear)
	add_child(myDebugLineLateral)
	add_child(myDebugLateralHandbrake)
	add_child(myDebugLineHandbrake)
	myDebugLineLinear.default_color = Color.PURPLE
	myDebugLineLateral.default_color = Color.BLUE
	myDebugLateralHandbrake.default_color = Color.ORANGE
	myDebugLineHandbrake.default_color = Color.GREEN
	
	if debug_draw_forces:
		# Linear drive force
		myDebugLineLinear.width = 2

		# Lateral force
		myDebugLineLateral.width = 2

		# Handbrake force
		myDebugLateralHandbrake.width = 2
		myDebugLineHandbrake.width = 2

func _physics_process(_delta) -> void:
	# Update wheel forward and right directions in world space
	forward = - global_transform.y.normalized()
	right = global_transform.x.normalized()

	# Get world offset for the wheel
	player_to_wheel = global_position - vehicle.global_position
	# The wheel velocity in world space
	wheel_velocity = vehicle.linear_velocity + vehicle.angular_velocity \
		 * Vector2(-player_to_wheel.y, player_to_wheel.x)
	
	last_position = global_position

func steer(steering_input, delta):
	if (is_steering):
		var desired_angle = clamp(steering_input * max_angle,
			- max_angle, max_angle)
		if steering_input == 0 and not steering_auto_center:
			desired_angle = rotation_degrees
		var new_angle = lerp(rotation_degrees, desired_angle,
			steering_speed * delta)
		rotation_degrees = new_angle

func drive(drive_input):
	vehicle.apply_impulse(drive_input * power * forward, player_to_wheel)
	if debug_draw_forces:
		myDebugLineLinear.points = PackedVector2Array([Vector2.ZERO, \
			to_local(global_position + drive_input \
			* power * forward * 20.0)])


func apply_lateral_forces(delta):
	# Standard lateral friction for all wheels
	var lateral_speed: float = wheel_velocity.dot(right)
	var lateral_impulse = -right * lateral_speed * grip * delta

	if lateral_impulse.length() > 10.0:
		lateral_impulse = lateral_impulse.normalized() * 10.0
	
	# Apply lateral force to the wheels
	vehicle.apply_impulse(lateral_impulse, player_to_wheel)
	
	# Expose handbrake force vectors
	var lateral_brake_impulse := Vector2.ZERO
	var forward_brake := Vector2.ZERO

	# Handbrake logic
	if handbrake_active and is_handbrake:
		# Chassis axes in global space
		var chassis_right = vehicle.global_transform.x.normalized()
		var chassis_forward = -vehicle.global_transform.y.normalized()

		# Project wheel velocity onto chassis
		var lateral_speed_hb : float = wheel_velocity.dot(chassis_right)
		var forward_speed_hb : float = wheel_velocity.dot(chassis_forward)

		# Lateral handbrake force - use the lateral speed to calculate it
		var lateral_brake_strength = min(abs(lateral_speed_hb) * 0.3, 150.0)
		# Ignore the lateral handbrake effect at low values
		if abs(lateral_speed_hb) > 0.1:
			# The key is reversing the sign of the lateral speed.
			# Using directly the `lateral_speed_hb` instead can cause issues
			# with icredibly high forces applied when steering right. 
			lateral_brake_impulse = -signf(lateral_speed_hb) * chassis_right \
				* lateral_brake_strength * handbrake_strength * delta
		 
		# Clamp to ensure there won't be massive spikes.
		var max_lateral_impulse = 5.0
		if lateral_brake_impulse.length() > max_lateral_impulse:
			lateral_brake_impulse = lateral_brake_impulse.normalized() \
				* max_lateral_impulse
		
		# Apply hanbrake lateral force
		vehicle.apply_impulse(lateral_brake_impulse, player_to_wheel)


		# Forward handbrake force
		forward_brake = -chassis_forward * forward_speed_hb * 0.2 * delta

		# Clamp forward force
		var max_forward_brake = abs(forward_speed_hb) * 1.5
		if forward_brake.length() > max_forward_brake:
			forward_brake = forward_brake.normalized() * max_forward_brake

		vehicle.apply_impulse(forward_brake, player_to_wheel)
		
		
	# Debug draw the applied forces
	if debug_draw_forces:
		var lateral_steer_end = to_local(global_position + lateral_impulse * 10)
		var lateral_handbrake_end = to_local(global_position + \
			lateral_brake_impulse * 20.0)
		var forward_brake_local_end = to_local(global_position \
			+ forward_brake * 20.0)
		
		myDebugLineLateral.points = PackedVector2Array([Vector2.ZERO, \
			lateral_steer_end])
		myDebugLateralHandbrake.points = PackedVector2Array([Vector2.ZERO, \
			lateral_handbrake_end])
		myDebugLineHandbrake.points = PackedVector2Array([Vector2.ZERO, \
			forward_brake_local_end])


func set_handbrake_active(active: bool) -> void:
	handbrake_active = active
