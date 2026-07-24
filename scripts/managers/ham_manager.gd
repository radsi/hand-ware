extends Node

@onready var knife: Sprite2D = $HamKnife
@onready var ham: Sprite2D = $Ham
@onready var cut: AudioStreamPlayer2D = $cut
@onready var ham_plate: Sprite2D = $HamPlate

var attached_left: Sprite2D = null
var attached_right: Sprite2D = null

var original_top_pos: Vector2
var last_knife_pos: Vector2

var rotation_timer := 0.0

var score_added := false

var restarting := false

func _ready() -> void:
	last_knife_pos = knife.global_position

func _hands_process(hands: HANDS, delta: float) -> void:
	if globals.minigame_completed:
		cut.stop()
		rotation_timer += delta

		if rotation_timer >= 0.5:
			ham_plate.rotation_degrees *= -1
			rotation_timer = 0.0

		if globals.is_single_minigame and not restarting:
			restart_minigame()

		return

	var knife_pos = knife.global_position

	if knife_pos.x >= 689 and not globals.minigame_completed:
		globals.minigame_completed = true
		rotation_timer = 0.0

		if not score_added:
			globals.game_score += 1
			score_added = true

		ham_plate.show()
		ham.hide()
		knife.hide()
		return

	knife_pos.y = clamp(knife_pos.y, 463.0, 610.0)

	if attached_left != null or attached_right != null:
		var dy = knife_pos.y - last_knife_pos.y
		if dy != 0:
			if not cut.playing:
				cut.play()
			knife_pos.x += 1.5

	knife.global_position = knife_pos
	last_knife_pos = knife_pos

	update_attached_hand(hands, hands.hand_left, true)
	update_attached_hand(hands, hands.hand_right, false)


func update_attached_hand(hands: HANDS, hand: Node2D, is_left: bool) -> void:
	if not hands.dragging_left and attached_left != null:
		detach_hand(hands.hand_left, true)
	if not hands.dragging_right and attached_right != null:
		detach_hand(hands.hand_right, false)

	if hand == null or hand.visible == false or not hand.is_inside_tree():
		return

	var attached = attached_left if is_left else attached_right
	if attached != null:
		if attached.is_inside_tree():
			attached.global_position = Vector2(attached.global_position.x, hand.global_position.y - 80)
			hand.texture = globals.closehand_texture
		else:
			detach_hand(hand, is_left)

	if hands.dragging_left and attached_left == null:
		attach_hand_to_knife(hands.hand_left, true)
	elif hands.dragging_right and attached_right == null:
		attach_hand_to_knife(hands.hand_right, false)


func restart_minigame() -> void:
	restarting = true

	globals.is_playing_minigame_anim = true

	rotation_timer = 0.0
	score_added = false

	attached_left = null
	attached_right = null

	knife.global_position = Vector2(500.0, 463.0)
	last_knife_pos = knife.global_position
	
	await get_tree().create_timer(1).timeout

	ham_plate.hide()
	ham.show()
	knife.show()

	globals.time_left = globals.game_time

	globals.minigame_completed = false
	globals.is_playing_minigame_anim = false

	restarting = false

func attach_hand_to_knife(hand: Node2D, is_left: bool) -> void:
	if knife == null or knife.texture == null or not knife.visible:
		return

	if HANDS.is_point_over_sprite(knife, hand.global_position):
		if is_left:
			attached_left = knife
		else:
			attached_right = knife
		hand.texture = globals.closehand_texture


func detach_hand(hand: Node2D, is_left: bool) -> void:
	if is_left:
		attached_left = null
	else:
		attached_right = null
	if hand != null and hand.is_inside_tree():
		hand.texture = globals.openhand_texture
