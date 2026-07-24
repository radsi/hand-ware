extends Grabbable

var _original_pos: Vector2
var _original_rotation: float

signal brush_dragged(pos: Vector2)
signal brush_released

@onready var tip: Node2D = $Tip

func _ready() -> void:
	super._ready()

	_original_pos = global_position
	_original_rotation = rotation_degrees


func _on_grabbed(is_left: bool) -> void:
	rotation_degrees = -40

	if not is_left:
		flip_h = true
		rotation_degrees = 40


func _on_released(_is_left: bool) -> void:
	globals.is_playing_minigame_anim = true
	flip_h = false

	if get_child_count() > 0 and get_child(0) is Sprite2D:
		get_child(0).flip_h = false

	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(self, "global_position", _original_pos, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "rotation_degrees", _original_rotation, 0.2)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func():
		brush_released.emit()
		globals.is_playing_minigame_anim = false
		)

func _on_dragged(_hand_pos: Vector2, _is_left: bool) -> void:
	brush_dragged.emit(tip.global_position)
