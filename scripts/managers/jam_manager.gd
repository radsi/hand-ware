extends Node

@onready var original_toast_sprite = preload("res://mini games sprites/toast.png")
@onready var toast_jam = $Toast/ToastJam
@onready var toast = $Toast
@export var knife_jam: Sprite2D

var _last_knife_pos: Vector2

var bite_count = 0
var burp_played = false
const BURP_WAIT := 0.5

func _process(delta: float) -> void:
	if toast_jam == null:
		return

	if toast_jam.modulate.a >= 0.75 and not globals.is_playing_minigame_anim:
		globals.is_playing_minigame_anim = true
		globals.minigame_completed = true
		if globals.is_single_minigame:
			globals.time_left = globals.game_time
		_handle_bites_async()

func _handle_bites_async() -> void:
	while bite_count < 6:
		await get_tree().create_timer(BURP_WAIT).timeout
		toast_jam.visible = false
		bite_count += 1
		if bite_count < 6:
			$bite.play()
			toast.texture = load("res://mini games sprites/toasts/bite"+str(bite_count)+".png")
	
	if not burp_played: 
		$burp.play()
		globals.minigame_completed = false
	burp_played = true
	await get_tree().create_timer(BURP_WAIT).timeout
	globals.is_playing_minigame_anim = false
	if not globals.is_single_minigame: globals._start_roll()
	toast.visible = false
	
	globals.game_score += 1

	if globals.is_single_minigame:
		bite_count = 0
		burp_played = false
		toast_jam.modulate.a = 0
		toast_jam.visible = true
		toast.texture = original_toast_sprite
		toast.visible = true

func _hands_ready(hands: HANDS) -> void:
	_last_knife_pos = knife_jam.global_position


func _hands_process(hands: HANDS, delta: float) -> void:
	if knife_jam == null or toast == null or toast.get_child_count() == 0:
		return

	if knife_jam.global_position == _last_knife_pos:
		return

	var toast_size = toast.scale * Vector2(toast.texture.get_width(), toast.texture.get_height())
	var toast_rect = Rect2(toast.global_position - toast_size * 0.5, toast_size)

	if toast_rect.has_point(knife_jam.global_position) and knife_jam.modulate.a >= 0.1:
		knife_jam.modulate.a = max(0.0, knife_jam.modulate.a - (globals.game_speed / 1000.0) * 2 * delta)
		var toast_child = toast.get_child(0)
		toast_child.modulate.a = min(1.0, toast_child.modulate.a + (globals.game_speed / 1000.0) * delta)

	_last_knife_pos = knife_jam.global_position
