extends Node


@onready var grabbables = $Grabbables
@onready var bricks_Sfx = [$brick1, $brick2]

const RETURN_TIME := 0.2
const GRAB_MARGIN := 20.0
const STARTER_HAND_OFFSET := Vector2(45, 0)

var attached_left: Sprite2D
var attached_right: Sprite2D

var last_attached_left: Sprite2D
var last_attached_right: Sprite2D


var returning_left := false
var returning_right := false


var prev_dragging_left := false
var prev_dragging_right := false



func _hands_ready(hands: HANDS) -> void:
	var starter = $Grabbables/StarterBrick

	if starter == null:
		push_error("No existe StarterBrick")
		return


	attached_left = starter
	last_attached_left = starter

	attached_right = starter
	last_attached_right = starter


	_snap_hand(hands.hand_left, starter)
	_snap_hand(hands.hand_right, starter)



func _hands_process(hands: HANDS, _delta: float) -> void:

	if hands.hand_left == null or hands.hand_right == null:
		return


	_process_hand(hands, true)
	_process_hand(hands, false)


	prev_dragging_left = hands.dragging_left
	prev_dragging_right = hands.dragging_right

func _process_hand(hands:HANDS, is_left:bool):

	var hand = hands.hand_left if is_left else hands.hand_right
	var dragging = hands.dragging_left if is_left else hands.dragging_right

	if hand == null:
		return

	if hand.global_position.y >= 1100:
		hands._handle_defeat(hand)
		return

	var attached = attached_left if is_left else attached_right
	var returning = returning_left if is_left else returning_right


	if dragging:
		hand.texture = globals.openhand_texture
		return

	if returning:
		return

	if attached != null and attached.is_inside_tree():
		hand.texture = globals.closehand_texture
		hand.global_position.y = attached.global_position.y



func _hands_input(hands:HANDS,event:InputEvent):

	if not _is_release(event):
		return


	var left_release := false
	var right_release := false


	if event is InputEventMouseButton:

		left_release = event.button_index == MOUSE_BUTTON_LEFT
		right_release = event.button_index == MOUSE_BUTTON_RIGHT


	elif event is InputEventJoypadButton:

		left_release = event.button_index == JOY_BUTTON_LEFT_SHOULDER
		right_release = event.button_index == JOY_BUTTON_RIGHT_SHOULDER



	if left_release and prev_dragging_left:

		_release_hand(hands,true)


	if right_release and prev_dragging_right:

		_release_hand(hands,false)



func _release_hand(hands:HANDS,is_left:bool):

	var hand = hands.hand_left if is_left else hands.hand_right

	if hand == null:
		return


	var brick = get_grabable_under_hand(hand)


	if brick:

		attach_hand(hands,is_left,brick)

	else:

		return_hand(hands,is_left)



func attach_hand(hands:HANDS,is_left:bool,brick:Sprite2D):

	if is_left:

		attached_left = brick
		last_attached_left = brick

	else:

		attached_right = brick
		last_attached_right = brick


	var hand = hands.hand_left if is_left else hands.hand_right

	_snap_hand(hand,brick)


	_play_brick()



func return_hand(hands:HANDS,is_left:bool):

	var hand = hands.hand_left if is_left else hands.hand_right

	var brick = last_attached_left if is_left else last_attached_right


	if hand == null or brick == null:
		return


	if not brick.is_inside_tree():
		return



	if is_left:
		returning_left=true
	else:
		returning_right=true



	var target = brick.global_position


	var tween = create_tween()

	tween.tween_property(
		hand,
		"global_position",
		target,
		RETURN_TIME
	)


	tween.finished.connect(
		func():

			_snap_hand(hand,brick)

			if is_left:
				attached_left = brick
				returning_left=false
			else:
				attached_right = brick
				returning_right=false
	)



func _snap_hand(hand: Node2D, brick: Sprite2D):

	if hand == null or brick == null:
		return


	var offset := Vector2.ZERO

	if brick.name == "StarterBrick":

		if hand.name == "Hand1":
			offset = Vector2(-45, 0)

		else:
			offset = Vector2(45, 0)


	hand.global_position = brick.global_position + offset
	hand.texture = globals.closehand_texture



func get_grabable_under_hand(hand:Node2D)->Sprite2D:

	if hand == null:
		return null


	for g in grabbables.get_children():

		if not g is Sprite2D:
			continue

		if g.texture == null:
			continue


		var size = g.texture.get_size() * g.global_scale

		var rect = Rect2(
			g.global_position-size*0.5,
			size
		)


		if rect.has_point(hand.global_position):
			return g


		if hand.global_position.distance_to(g.global_position) <= size.length()*0.5 + GRAB_MARGIN:
			return g


	return null



func _is_release(event:InputEvent)->bool:

	if event is InputEventMouseButton:
		return not event.pressed


	if event is InputEventJoypadButton:
		return not event.pressed


	return false

func _play_brick():
	bricks_Sfx.pick_random().play()

func _exit_tree():

	attached_left=null
	attached_right=null
	last_attached_left=null
	last_attached_right=null
