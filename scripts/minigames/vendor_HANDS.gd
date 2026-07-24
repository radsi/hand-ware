extends HANDS

@onready var keypad = $"../Vendor/Keypad"
@onready var beep = $"../beep"
@onready var manager = $".."

var was_dragging_left := false
var was_dragging_right := false
var was_fingerhand_left := false
var was_fingerhand_right := false

func _ready():
	super._ready()

	last_pos_left = hand_left.global_position
	last_pos_right = hand_right.global_position

func _process(delta):
	was_dragging_left = dragging_left
	was_dragging_right = dragging_right
	was_fingerhand_left = hand_left.texture == globals.fingerhand_texture
	was_fingerhand_right = hand_right.texture == globals.fingerhand_texture

	super._process(delta)

	if dragging_left:
		if HANDS.is_point_over_sprite(keypad, hand_left.global_position + Vector2(10, -30)):
			hand_left.texture = globals.fingerhand_texture
		else:
			hand_left.texture = globals.closehand_texture

	if dragging_right:
		if HANDS.is_point_over_sprite(keypad, hand_right.global_position + Vector2(10, -30)):
			hand_right.texture = globals.fingerhand_texture
		else:
			hand_right.texture = globals.closehand_texture

func _get_finger_tip(hand: Node2D) -> Node2D:
	if hand.get_child_count() > 0:
		return hand.find_child("finger tip")
	return null

func _get_closest_keypad_child(finger_tip: Node2D) -> Node2D:
	if keypad == null or finger_tip == null:
		return null

	var closest_child = null
	var min_dist := INF

	for child in keypad.get_children():
		if child is Node2D:
			var dist = finger_tip.global_position.distance_to(child.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_child = child

	return closest_child

func _input(event):
	super._input(event)
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if was_dragging_left and was_fingerhand_left:
				var tip = _get_finger_tip(hand_left)
				var nearest = _get_closest_keypad_child(tip)
				if nearest:
					manager.hand_input += str(nearest.name)
					beep.play()

		if event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			if was_dragging_right and was_fingerhand_right:
				var tip = _get_finger_tip(hand_right)
				var nearest = _get_closest_keypad_child(tip)
				if nearest:
					manager.hand_input += str(nearest.name)
					beep.play()

	if event is InputEventJoypadButton and globals.using_gamepad:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER and not event.pressed:
			if was_dragging_left and was_fingerhand_left:
				var tip = _get_finger_tip(hand_left)
				var nearest = _get_closest_keypad_child(tip)
				if nearest:
					manager.hand_input += str(nearest.name)
					beep.play()

		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER and not event.pressed:
			if was_dragging_right and was_fingerhand_right:
				var tip = _get_finger_tip(hand_right)
				var nearest = _get_closest_keypad_child(tip)
				if nearest:
					manager.hand_input += str(nearest.name)
					beep.play()
