extends Node2D

@onready var valve = $"Valve"

var old_mouse_pos := Vector2.ZERO

func _ready() -> void:
	$AnimationPlayer.play("smoke")

func _hands_ready(hands: HANDS) -> void:
	old_mouse_pos = get_local_mouse_position()


func _hands_process(hands: HANDS, delta: float) -> void:
	if valve.rotation_degrees >= 1500 and not globals.minigame_completed:
		globals.minigame_completed = true
		$"AnimationPlayer".stop()
		$"smoke1".hide()
		$"smoke2".hide()
		$"smoke3".hide()

		if globals.is_single_minigame:
			globals.is_playing_minigame_anim = true
			globals.time_left = globals.game_time
			await get_tree().create_timer(2).timeout
			globals.minigame_completed = false
			globals.is_playing_minigame_anim = false
			$"smoke1".show()
			$"smoke2".show()
			$"smoke3".show()
			$"AnimationPlayer".play("smoke")
			valve.rotation_degrees = 0
		return

	var current_mouse_pos = get_local_mouse_position()

	if HANDS.is_point_over_sprite(valve, hands.hand_left.global_position) and hands.dragging_left and hands.hand_left.visible:
		if (hands.hand_left.global_position.x != hands.last_pos_left.x and globals.using_gamepad) or (current_mouse_pos.x != old_mouse_pos.x and not globals.using_gamepad):
			valve.rotate(0.1)
			if not $"valve".is_playing():
				$"valve".play()

	if HANDS.is_point_over_sprite(valve, hands.hand_right.global_position) and hands.dragging_right and hands.hand_right.visible:
		if (hands.hand_right.global_position.x != hands.last_pos_right.x and globals.using_gamepad) or (current_mouse_pos.x != old_mouse_pos.x and not globals.using_gamepad):
			valve.rotate(0.1)
			if not $"valve".is_playing():
				$"valve".play()

	old_mouse_pos = current_mouse_pos
