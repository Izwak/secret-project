extends RigidBody3D

@export var maxSpeed := 7.0
@export var accelForce := 20.0
@export var deccelForce := 20.0
@export var jumpForce := 325.0
@export var fallForce := 10.0
@export var camMaxDistance := 5.0

var mouseSensitivity := .3
var twistInput := .0
var pitchInput := .0
var camDistance := .0


var targetVel := Vector3.ZERO
var parent : Node3D

@export var resawnNode: Node3D

@onready var twitstPivot = $TwistPivot
@onready var pitchPivot = $TwistPivot/PitchPivot
@onready var playerMesh = $PlayerMesh
@onready var groundCheck: ShapeCast3D = $GroundCheckCast
@onready var velLabel = $"../CanvasLayer/Vel Label"
@onready var speedLabel = $"../CanvasLayer/Speed Label"
var level

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	level = get_parent()
	parent = level


func _process(delta: float) -> void:
	CameraHandler(delta);
	
	if transform.origin.y < -10:
		Respawn()


func _physics_process(delta: float) -> void:
	MovementHandler(delta)
	
	GroundHandler()


func _unhandled_input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion && Input.get_mouse_mode:
		twistInput = -event.relative.x * mouseSensitivity
		pitchInput = -event.relative.y * mouseSensitivity


func MovementHandler(delta: float):
	
	# Get input direction
	var inputDir := Vector3.ZERO
	inputDir.x = Input.get_axis("move_left", "move_right")
	inputDir.z = Input.get_axis("move_forward", "move_backward")
	inputDir = inputDir.normalized()
	
	var horizontalVel = Vector3(linear_velocity.x, 0, linear_velocity.z)
	
	# Accelerate player
	if inputDir != Vector3.ZERO:
		var desiredVel = horizontalVel + (twitstPivot.basis * inputDir * accelForce / mass) * delta
		
		# Already at or above max don’t accelerate further
		if desiredVel.length() > maxSpeed:
			var newSpeed
			if horizontalVel.length() < maxSpeed:
				newSpeed = maxSpeed
			else: 
				newSpeed = horizontalVel.length()
			var finalVel = desiredVel.normalized() * newSpeed
			var finalAccel = (finalVel - horizontalVel) / delta
			apply_central_force(finalAccel * mass)
		# Accelerate player
		else:
			apply_central_force(twitstPivot.basis * inputDir * accelForce)
		
		# Turn Player to face direction moving
		var targetRotation = Transform3D().looking_at(twitstPivot.basis * inputDir, Vector3.UP).basis.get_euler()
		playerMesh.rotation.y = lerp_angle(playerMesh.rotation.y, targetRotation.y, 0.1)
	# Deccelerate player
	elif horizontalVel.length() > .2:
		apply_central_force(horizontalVel.normalized() * -deccelForce)
	# Bring player to stop if slow enough
	else:
		linear_velocity = Vector3(0, linear_velocity.y, 0)
	
	if linear_velocity.y < 0:
		apply_central_force(Vector3.DOWN * fallForce)
	
	
	# Jump
	if Input.is_action_just_pressed("move_jump"):
		Jump()
	
	velLabel.text = "Vel: " + str(linear_velocity)
	speedLabel.text = "Speed: " + str(Vector3(linear_velocity.x, 0, linear_velocity.z).length())


func GroundHandler():
	if !groundCheck.is_colliding():
		if parent != level:
			DetachParent()
		return
	var ground := groundCheck.get_collider(0)
	
	#print("Ground: " + ground.name)
	
	if ground.is_in_group("Movable") && parent != ground:
		SetNewParent(ground)

func SetNewParent(newParent):
	parent = newParent	
	get_parent().remove_child(self)
	
	parent.add_child(self)
	transform.origin -= parent.global_position
	print("Parent: " + parent.name)

func DetachParent():
	transform.origin += parent.global_position
	parent = level
	get_parent().remove_child(self)
	parent.add_child(self)

func Jump() -> void:
	if groundCheck.is_colliding():
		apply_central_force(Vector3.UP * jumpForce)	


func CameraHandler(delta: float):
	# Mouse visibility controls
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		twitstPivot.rotate_y(twistInput * delta)
		pitchPivot.rotate_x(pitchInput * delta)
		pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(80))
	
	twistInput = 0
	pitchInput = 0


func Respawn():
	transform = resawnNode.transform
	linear_velocity = Vector3.ZERO
