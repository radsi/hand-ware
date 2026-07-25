extends Node

@onready var rope = $Rope
@onready var girl_hand = $Rope/GirlHand
@onready var girl_hand_hearts = $Rope/GirlHand/Hearts
@onready var smooch_sfx: AudioStreamPlayer2D = $smooch

var smooch_played = false
var timer = 0
var hearts_original_positions = {}
var rope_original_pos
var grab_margin: float = 20.0
var rope_move_factor: float = 1.2
var sound_played: bool = false
var last_pos_left := Vector2.ZERO
var last_pos_right := Vector2.ZERO

func _ready() -> void:
	rope_original_pos = rope.global_position


func _process(delta: float) -> void:
	timer += delta
	if timer >= 0.5:
		timer = 0
		for heart in girl_hand_hearts.get_children():
			if not hearts_original_positions.has(heart.name): hearts_original_positions[heart.name] = heart.position
			_apply_random_transform(heart)

	if girl_hand.global_position.y >= 180:
		globals.minigame_completed = true
		if not smooch_played:
			smooch_sfx.play()
			smooch_played = true
			if globals.is_single_minigame:
				globals.is_playing_minigame_anim = true
				globals.time_left = globals.game_time
				await get_tree().create_timer(1.5).timeout
				globals.is_playing_minigame_anim = false
				rope.global_position = rope_original_pos
				smooch_played = false
		return
	rope.global_position.y -= globals.game_speed / 100


func _apply_random_transform(deco: Sprite2D) -> void:
	var base_pos = hearts_original_positions[deco.name]
	deco.position = base_pos + Vector2(
		randf_range(-10, 10),
		randf_range(-10, 10)
	)
	deco.rotation_degrees = randf_range(0, 45)
	var new_scale = randf_range(0.25, 0.5)
	deco.scale = Vector2(new_scale, new_scale)


func _hands_ready(hands: HANDS) -> void:
	last_pos_left = hands.hand_left.global_position
	last_pos_right = hands.hand_right.global_position


func _hands_process(hands: HANDS, delta: float) -> void:
	if girl_hand.global_position.y >= 180:
		globals.minigame_completed = true
		return

	if hands.dragging_left and hands.hand_left.visible:
		_handle_hand_move_over_rope(hands.hand_left, last_pos_left)
	elif hands.dragging_right and hands.hand_right.visible:
		_handle_hand_move_over_rope(hands.hand_right, last_pos_right)
	else:
		sound_played = false

	if hands.dragging_left:
		last_pos_left = hands.hand_left.global_position
	if hands.dragging_right:
		last_pos_right = hands.hand_right.global_position

func _handle_hand_move_over_rope(hand: Node2D, prev_pos: Vector2) -> void:
	if rope == null:
		return
	var dy = hand.global_position.y - prev_pos.y
	if dy <= 0:
		return
	rope.global_position.y += dy * rope_move_factor
	if not sound_played:
		get_node("rope" + str(randi() % 2 + 1)).play()
		sound_played = true

func _hands_input(hands: HANDS, event: InputEvent) -> void:
	var pressed_left = (
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
		or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_LEFT_SHOULDER and event.pressed)
	)
	var pressed_right = (
		(event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed)
		or (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_RIGHT_SHOULDER and event.pressed)
	)

	if pressed_left and hands.hand_left.visible and HANDS.is_point_over_sprite(girl_hand, hands.hand_left.global_position):
		_play_smooch()

	if pressed_right and hands.hand_right.visible and HANDS.is_point_over_sprite(girl_hand, hands.hand_right.global_position):
		_play_smooch()


func _play_smooch() -> void:
	if not smooch_sfx.playing:
		smooch_sfx.play()
