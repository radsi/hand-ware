extends Sprite2D
class_name BreakableWall

@export var breakable := false
@export var is_boss := false
@export var hits_required := 6
@export var shake_duration := 0.5
@export var shake_strength := 8.0

@export var hit_sound: AudioStreamPlayer2D
@export var break_sound: AudioStreamPlayer2D

signal wall_broken(wall: BreakableWall)
signal wall_hit(wall: BreakableWall, hits_left: int)

var hits_taken := 0
var _original_position: Vector2
var _shake_tween: Tween

func _ready() -> void:
	_original_position = position
	add_to_group("solids")

	var hands := get_tree().get_first_node_in_group("player_hands")
	if hands:
		hands.hand_hit_solid.connect(_on_hand_hit_solid)


func _on_hand_hit_solid(_hand: Node2D, solid: Node, _is_left: bool) -> void:
	if solid != self or !breakable:
		return

	hits_taken += 1

	if hit_sound:
		hit_sound.play()

	_shake()

	wall_hit.emit(self, hits_required - hits_taken)

	if is_boss and hits_taken == 3:
		breakable = false

	if hits_taken >= hits_required:
		_break()


func _shake() -> void:
	if _shake_tween:
		_shake_tween.kill()

	_shake_tween = create_tween()
	_shake_tween.tween_method(
		func(v): material.set_shader_parameter("shake_amount", v),
		shake_strength,
		0.0,
		shake_duration
	)


func _break() -> void:
	breakable = false
	remove_from_group("solids")

	if break_sound:
		break_sound.play()

	hide()
	wall_broken.emit(self)


func reset() -> void:
	if _shake_tween:
		_shake_tween.kill()

	hits_taken = 0
	breakable = false

	position = _original_position
	show()

	if !is_in_group("solids"):
		add_to_group("solids")

	if material:
		material.set_shader_parameter("shake_amount", 0.0)
