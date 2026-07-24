extends Grabbable

@export var fire: Sprite2D
@export var movement_threshold := 20.0
@export var min_fire_scale := 0.0
@export var max_fire_scale := 0.6
@export var extinguish_amount := 0.003

var target_fire_scale := 0.6

var _last_drag_y_left := 0.0
var _last_drag_y_right := 0.0

var _has_last_left := false
var _has_last_right := false

func _ready() -> void:
	super._ready()

	if fire:
		fire.scale = Vector2.ONE * max_fire_scale
		target_fire_scale = max_fire_scale

func _on_grabbed(is_left: bool) -> void:
	super._on_grabbed(is_left)
	
	if is_left:
		_has_last_left = false
	else:
		_has_last_right = false

func _on_dragged(hand_pos: Vector2, is_left: bool) -> void:
	if globals.is_playing_minigame_anim:
		return

	var last_y := _last_drag_y_left if is_left else _last_drag_y_right
	var has_last := _has_last_left if is_left else _has_last_right


	if has_last and fire:
		var dy = abs(hand_pos.y - last_y)

		if dy > movement_threshold and fire.scale.x > 0:
			fire.scale -= Vector2.ONE * extinguish_amount

	if is_left:
		_last_drag_y_left = hand_pos.y
		_has_last_left = true
	else:
		_last_drag_y_right = hand_pos.y
		_has_last_right = true
