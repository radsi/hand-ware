extends Node

@onready var dirty_objects = $BlackTshirt/Dirty
@onready var scrub_sound: AudioStreamPlayer2D = $"AudioStreamPlayer2D"

var transparency_step: float = 0.025
var old_transparency := {}

var last_pos_left := Vector2.ZERO
var last_pos_right := Vector2.ZERO


func _hands_ready(hands: HANDS) -> void:
	await get_tree().process_frame

	last_pos_left = hands.hand_left.global_position
	last_pos_right = hands.hand_right.global_position

	for obj in dirty_objects.get_children():
		if obj is Sprite2D:
			old_transparency[obj] = obj.modulate.a

func _hands_process(hands: HANDS, delta: float) -> void:
	if globals.is_playing_minigame_anim:
		return

	var changed := false

	if hands.hand_left != null:
		changed = increase_transparency_under_hand(
			hands.hand_left,
			last_pos_left
		) or changed

	if hands.hand_right != null:
		changed = increase_transparency_under_hand(
			hands.hand_right,
			last_pos_right
		) or changed


	if hands.hand_left != null:
		last_pos_left = hands.hand_left.global_position

	if hands.hand_right != null:
		last_pos_right = hands.hand_right.global_position


	if changed and not scrub_sound.playing:
		scrub_sound.play()

func increase_transparency_under_hand(hand: Node2D, last_point: Vector2) -> bool:
	if hand == null or not hand.visible:
		return false

	var point := hand.global_position
	if hand.get_child_count() > 0:
		point = hand.get_child(0).global_position

	if point.distance_to(last_point) < 0.05:
		return false


	var any_changed := false


	for obj in dirty_objects.get_children():

		if not obj is Sprite2D:
			continue

		if obj.texture == null:
			continue


		if HANDS.is_point_over_sprite(obj, point):

			var c: Color = obj.modulate
			var new_alpha = clamp(c.a - transparency_step, 0.0, 1.0)

			if new_alpha < c.a:
				c.a = new_alpha
				obj.modulate = c

				old_transparency[obj] = new_alpha
				any_changed = true

	return any_changed
