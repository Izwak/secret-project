extends Node3D

@export var movePoints: Array[Node3D]
@export var speed := 5.0
@export var delay := 1.0

@onready var movable := $Moveable
@onready var timer := $Timer

var targetIndex := 1
var velocity := Vector3.ZERO


func _physics_process(delta: float) -> void:
	
	if movePoints.size() <= 2:
		return
	if timer.time_left > 0:
		return
	
	var difference: Vector3 = movePoints[targetIndex].global_position - movable.global_position
	velocity = difference.normalized() * speed
	
	if difference.length() < speed * delta:
		movable.global_position = movePoints[targetIndex].global_position
		timer.start(delay)
	else:
		movable.global_translate(velocity * delta)

func _on_timer_timeout() -> void:
	if targetIndex < movePoints.size() - 1:
		targetIndex += 1
	else:
		targetIndex = 0
