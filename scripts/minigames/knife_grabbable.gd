extends Grabbable

var _original_pos: Vector2
var _original_rotation: float

func _ready() -> void:
	super._ready()

	_original_pos = global_position
	_original_rotation = rotation_degrees

func _on_grabbed(_is_left: bool) -> void:
	rotation_degrees = -140

	if not _is_left:
		flip_h = true

		if get_child_count() > 0 and get_child(0) is Sprite2D:
			get_child(0).flip_h = true

		rotation_degrees = 140

func _on_released(_is_left: bool) -> void:
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

	tween.finished.connect(_on_knife_reset_done)


func _on_knife_reset_done() -> void:
	if get_child_count() > 0 and get_child(0) is CanvasItem:
		get_child(0).modulate.a = 1
