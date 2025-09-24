extends RigidBody3D

var maxSpeed := 7.0
var speedForce := 20.0
var deccelForce := 20.0
var jumpForce := 325.0

var mouseSensitivity := .3
var twistInput := .0
var pitchInput := .0

var targetVel := Vector3.ZERO

@onready var twitstPivot = $TwistPivot
@onready var pitchPivot = $TwistPivot/PitchPivot
@onready var playerMesh = $PlayerMesh


func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
    cameraHandler(delta);


func _physics_process(_delta: float) -> void:
    movementHandler()


func movementHandler() -> void:
    
    var inputDir := Vector3.ZERO
    inputDir.x = Input.get_axis("move_left", "move_right")
    inputDir.z = Input.get_axis("move_forward", "move_backward")
    inputDir.normalized()
    
    var horizontalVel = Vector3(linear_velocity.x, 0, linear_velocity.z)
    var targetRotation
    targetRotation = Transform3D().looking_at(twitstPivot.basis * inputDir, Vector3.UP).basis.get_euler()
    
    if inputDir != Vector3.ZERO:
        if horizontalVel.length() < maxSpeed:
            apply_central_force(twitstPivot.basis * inputDir * speedForce)
        playerMesh.rotation.y = lerp_angle(playerMesh.rotation.y, targetRotation.y, 0.1)
    
    elif horizontalVel.length() > 1:
        apply_central_force(horizontalVel.normalized() * -deccelForce)
    
    if Input.is_action_just_pressed("move_jump"):
        apply_central_force(Vector3.UP * jumpForce)	
    
    print("Velocity: " + str(linear_velocity))


func cameraHandler(delta: float) -> void:
    if Input.is_action_just_pressed("ui_cancel"):
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    
    twitstPivot.rotate_y(twistInput * delta)
    pitchPivot.rotate_x(pitchInput * delta)
    pitchPivot.rotation.x = clamp(pitchPivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
    
    twistInput = 0
    pitchInput = 0


func _unhandled_input(event: InputEvent) -> void:
    
    if event is InputEventMouseMotion && Input.get_mouse_mode:
        twistInput = -event.relative.x * mouseSensitivity
        pitchInput = -event.relative.y * mouseSensitivity
