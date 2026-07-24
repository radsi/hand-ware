class_name HANDS
extends Node2D

const HAND_MOVE_SPEED := 700.0
const HAND_MIN_Y := 0.0
const HAND_MAX_Y := 1000.0
const SLOW_FACTOR := 0.1
const SIDE_FACTOR := 0.5
const LOOSE_GRIP_FACTOR := 0.3
const DEFAULT_GRAB_OFFSET := Vector2(30, 30)

@onready var hand_left: Node2D = $Hand1
@onready var hand_right: Node2D = $Hand2
@onready var minigame_manager: Node = get_parent()

var dragging_left := false
var dragging_right := false
var durability_left: float = globals.hands_max_durability
var durability_right: float = globals.hands_max_durability
@export var grappling := false

var last_pos_left := Vector2.ZERO
var last_pos_right := Vector2.ZERO

var block_left_hand_movement := false
var block_right_hand_movement := false

var loose_grip := 0
var one_hand := -1

var _defeated := false

@export var grab_offset: Vector2 = DEFAULT_GRAB_OFFSET

signal hand_hit_solid(hand: Node2D, solid: Node, is_left: bool)

var _touching_solid_left: Node = null
var _touching_solid_right: Node = null

var attached_left: Node = null
var attached_right: Node = null

func _ready() -> void:
	add_to_group("player_hands")
	_setup_difficulty()

	hand_left.modulate = Color.WHITE
	hand_right.modulate = Color.WHITE
	modulate = globals.hands_color

	_refresh_hand_texture(hand_left, false)
	_refresh_hand_texture(hand_right, false)

	last_pos_left = hand_left.global_position
	last_pos_right = hand_right.global_position

	if minigame_manager and minigame_manager.has_method("_hands_ready"):
		minigame_manager._hands_ready(self)


func _setup_difficulty() -> void:
	if globals.difficult_tier == 2:
		loose_grip = randi() % 21

	if globals.difficult_tier == 4:
		one_hand = randi() % 2
		if one_hand == 0:
			hand_left.hide()
		else:
			hand_right.hide()

func _input(event: InputEvent) -> void:

	if event is InputEventJoypadButton:
		if hand_left != null and event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_set_dragging(true, event.pressed)
		if hand_right != null and event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_set_dragging(false, event.pressed)

	elif event is InputEventMouseButton:
		if hand_left != null and event.button_index == MOUSE_BUTTON_LEFT:
			_set_dragging(true, event.pressed)
		if hand_right != null and event.button_index == MOUSE_BUTTON_RIGHT:
			_set_dragging(false, event.pressed)

	if minigame_manager and minigame_manager.has_method("_hands_input"):
		minigame_manager._hands_input(self, event)


func _set_dragging(is_left: bool, pressed: bool) -> void:
	var durability = durability_left if is_left else durability_right
	if pressed and durability <= 0:
		return

	if is_left:
		dragging_left = pressed
		_refresh_hand_texture(hand_left, dragging_left)
	else:
		dragging_right = pressed
		_refresh_hand_texture(hand_right, dragging_right)


func _refresh_hand_texture(hand: Node2D, is_dragging: bool) -> void:
	if hand == null:
		return
	var closed = is_dragging != grappling
	hand.texture = globals.closehand_texture if closed else globals.openhand_texture

func _process(delta: float) -> void:
	if hand_left == null or hand_right == null:
		return

	last_pos_left = hand_left.global_position
	last_pos_right = hand_right.global_position

	var screen_half = get_viewport().get_visible_rect().size.x / 2.0

	var move_left := Vector2.ZERO
	var move_right := Vector2.ZERO
	if globals.using_gamepad:
		move_left = Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
		move_right = Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))

	if not block_left_hand_movement:
		_apply_stick_movement(hand_left, move_left, delta, screen_half, true)
	if not block_right_hand_movement:
		_apply_stick_movement(hand_right, move_right, delta, screen_half, false)

	if get_viewport() == null:
		return
	var pointer_pos = get_viewport().get_mouse_position()

	if not block_left_hand_movement:
		process_hand(hand_left, dragging_left, true, delta, hand_left.global_position if globals.using_gamepad else pointer_pos, screen_half)
	if not block_right_hand_movement:
		process_hand(hand_right, dragging_right, false, delta, hand_right.global_position if globals.using_gamepad else pointer_pos, screen_half)

	_process_grabbables()

	if minigame_manager and minigame_manager.has_method("_hands_process"):
		minigame_manager._hands_process(self, delta)


func _apply_stick_movement(hand: Node2D, move: Vector2, delta: float, screen_half: float, is_left: bool) -> void:
	if move.length() <= 0.1:
		return

	var dragging = dragging_left if is_left else dragging_right
	var near_own_side = (hand.global_position.x <= screen_half) if is_left else (hand.global_position.x >= screen_half)
	var loose_hit = (is_left and loose_grip == 10) or (not is_left and loose_grip == 20)

	var factor = 1.0 if near_own_side else SIDE_FACTOR
	if (globals.using_gamepad and not dragging) or loose_hit:
		factor = LOOSE_GRIP_FACTOR

	var target_pos = hand.global_position + move * HAND_MOVE_SPEED * delta
	target_pos.y = clamp(target_pos.y, HAND_MIN_Y, HAND_MAX_Y)
	var lerped_pos = hand.global_position.lerp(target_pos, factor)
	hand.global_position = _clip_by_solids(hand, lerped_pos, is_left)


func process_hand(hand: Node2D, dragging: bool, is_left: bool, delta: float, pointer_pos: Vector2, screen_half: float) -> void:
	if hand == null:
		return

	var durability = durability_left if is_left else durability_right
	var factor = SLOW_FACTOR

	var near_own_side = (is_left and pointer_pos.x <= screen_half) or (not is_left and pointer_pos.x >= screen_half)
	var loose_hit = (is_left and loose_grip == 10) or (not is_left and loose_grip == 20)
	if near_own_side or loose_hit:
		factor = SIDE_FACTOR

	if dragging and durability > 0:
		if not globals.using_gamepad:
			var lerped_pos = hand.global_position.lerp(pointer_pos, factor)
			hand.global_position = _clip_by_solids(hand, lerped_pos, is_left)
		durability -= globals.hands_drain_rate * delta
	else:
		durability += globals.hands_drain_rate / 3.0 * delta

	durability = clamp(durability, 0, globals.hands_max_durability)
	var ratio = clamp(durability / globals.hands_max_durability, 0.0, 1.0)
	var fade_color = Color.RED if globals.hands_color == Color.WHITE else Color.BLACK
	hand.modulate = Color.WHITE.lerp(fade_color, 1.0 - ratio)

	if not _defeated and (durability_left <= 0 or durability_right <= 0):
		_handle_defeat(hand)

	if globals.difficult_tier == 3:
		var shared_ratio = durability / globals.hands_max_durability
		hand_left.modulate = Color(1, shared_ratio, shared_ratio)
		hand_right.modulate = Color(1, shared_ratio, shared_ratio)
		durability_left = durability
		durability_right = durability
		if durability_left <= 0:
			dragging_left = false
		if durability_right <= 0:
			dragging_right = false
		return

	if is_left:
		durability_left = durability
		if durability_left <= 0:
			dragging_left = false
	else:
		durability_right = durability
		if durability_right <= 0:
			dragging_right = false


func _handle_defeat(hand: Node2D) -> void:
	_defeated = true

	if globals.is_single_minigame:
		globals._game_over()
	else:
		if not globals.has_lost_life:
			globals.life -= 1
		globals.has_lost_life = true
		globals._start_roll()

	hand.queue_free()

func _find_blocking_solid(pos: Vector2, ignore: Node = null) -> Node:
	for solid in get_tree().get_nodes_in_group("solids"):
		if solid == ignore:
			continue
		if not (solid is Node2D) or not ("texture" in solid) or solid.texture == null or not solid.visible:
			continue
		if is_point_over_sprite(solid, pos):
			return solid
	return null


func _clip_by_solids(hand: Node2D, target_pos: Vector2, is_left: bool) -> Vector2:
	var from := hand.global_position
	var to := target_pos

	var distance := from.distance_to(to)

	if distance <= 0.001:
		_update_solid_contact(hand, is_left, null)
		return to

	var steps := maxi(1, int(ceil(distance / 2.0)))

	var blocking: Node = null
	var last_valid := from

	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var p := from.lerp(to, t)

		blocking = _find_blocking_solid(p)

		if blocking != null:
			_update_solid_contact(hand, is_left, blocking)
			return last_valid

		last_valid = p

	_update_solid_contact(hand, is_left, null)
	return to
	
func _update_solid_contact(hand: Node2D, is_left: bool, solid: Node) -> void:
	var previous = _touching_solid_left if is_left else _touching_solid_right

	if solid != null and solid != previous:
		hand_hit_solid.emit(hand, solid, is_left)
		if solid.has_method("_on_hit"):
			solid._on_hit(hand, is_left)
		if minigame_manager and minigame_manager.has_method("_hands_hit_solid"):
			minigame_manager._hands_hit_solid(self, solid, is_left)

	if is_left:
		_touching_solid_left = solid
	else:
		_touching_solid_right = solid


func _process_grabbables() -> void:
	_update_attached(hand_left, dragging_left, true)
	_update_attached(hand_right, dragging_right, false)


func _update_attached(hand: Node2D, dragging: bool, is_left: bool) -> void:
	if hand == null or not hand.visible or not hand.is_inside_tree():
		return

	var attached = attached_left if is_left else attached_right

	if attached != null and not is_instance_valid(attached):
		_set_attached(is_left, null)
		attached = null

	if attached != null and not dragging:
		_release_grabbable(attached, hand, is_left)
		return

	if attached == null and dragging:
		var found = _find_grabbable_under(hand)
		if found != null:
			_grab_grabbable(found, hand, is_left)
			attached = found

	if attached != null:
		var offset = Vector2(grab_offset.x * (-1 if is_left else 1), grab_offset.y)
		attached.global_position = hand.global_position - offset
		hand.texture = globals.closehand_texture
		if attached.has_method("_on_dragged"):
			attached._on_dragged(hand.global_position, is_left)


func _find_grabbable_under(hand: Node2D) -> Node:
	for node in get_tree().get_nodes_in_group("grabbable"):
		if node == attached_left or node == attached_right:
			continue
		if not (node is Node2D) or not ("texture" in node) or node.texture == null or not node.visible:
			continue
		if is_point_over_sprite(node, hand.global_position):
			return node
	return null


func _grab_grabbable(obj: Node, hand: Node2D, is_left: bool) -> void:
	_set_attached(is_left, obj)
	hand.texture = globals.closehand_texture
	if obj.has_method("_on_grabbed"):
		obj._on_grabbed(is_left)


func _release_grabbable(obj: Node, hand: Node2D, is_left: bool) -> void:
	_set_attached(is_left, null)
	if hand != null and hand.is_inside_tree():
		hand.texture = globals.openhand_texture
	if obj.has_method("_on_released"):
		obj._on_released(is_left)


func _set_attached(is_left: bool, obj: Node) -> void:
	if is_left:
		attached_left = obj
	else:
		attached_right = obj
	
static func is_point_over_sprite(item: Node2D, point: Vector2) -> bool:
	if item == null or not ("texture" in item) or item.texture == null:
		return false
	var local_pos = item.to_local(point)
	var size = item.texture.get_size()
	return Rect2(-size * 0.5, size).has_point(local_pos)
