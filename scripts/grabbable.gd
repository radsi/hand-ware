extends Sprite2D
class_name Grabbable

@export var offset_x: float = 30.0
@export var offset_y: float = 30.0
@export var rotation_on_grab: float = 0.0
@export var flip_H_on_right_hand: bool = false
@export var flip_V_on_right_hand: bool = false
@export var grab_sound: AudioStreamPlayer2D

signal grabbed(is_left: bool)
signal released(is_left: bool)
signal dragged(hand_pos: Vector2, is_left: bool)

func _ready() -> void:
	grabbed.connect(_on_grabbed)
	released.connect(_on_released)
	dragged.connect(_on_dragged)

func _on_grabbed(_is_left: bool) -> void:
	if grab_sound != null: grab_sound.play()
	
	if _is_left:
		if rotation_on_grab != 0: global_rotation_degrees = rotation_on_grab - 90
		if flip_H_on_right_hand:
			flip_h = false
		if flip_V_on_right_hand:
			flip_v = true
	else:
		if rotation_on_grab != 0: global_rotation_degrees = -rotation_on_grab + 90*3
		if flip_H_on_right_hand:
			flip_h = true
		if flip_V_on_right_hand:
			flip_v = false
	
	pass

func _on_released(_is_left: bool) -> void:
	pass

func _on_dragged(_hand_pos: Vector2, _is_left: bool) -> void:
	pass
