extends Grabbable

@export var impact: AudioStreamPlayer2D

var anchored_rotation := 0.0


func _ready() -> void:
	super._ready()



func _on_grabbed(is_left: bool) -> void:

	if is_left:
		anchored_rotation = 15.0
	else:
		anchored_rotation = -15.0

	rotation_degrees = anchored_rotation



func _on_dragged(_hand_pos: Vector2, _is_left: bool) -> void:

	rotation_degrees = anchored_rotation



func _on_released(_is_left: bool) -> void:

	rotation_degrees = anchored_rotation



func _on_area_2d_body_entered(_body: Node2D) -> void:

	if impact:
		impact.play()
