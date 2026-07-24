extends HANDS

@onready var button = $"../button/buttonHead"
@onready var joystick = $"../joystick/JoystickHead"
@onready var ship = $"../game/playerShip"
@onready var bullets_container = $"../bullets"
@onready var bullet = preload("res://prefabs/arcade/player_bullet.tscn")

var bullet_interval := 0.25
var bullet_timer := 1.0

var button_is_pressed := false


func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	super._process(delta)

	if _hand_over_object(button) and (dragging_left or dragging_right):
		_press_arcade_button(delta)
	else:
		_release_arcade_button()

	if _hand_over_object(joystick, 25) and not button_is_pressed:
		_move_joystick()
	else:
		joystick.rotation = 0

	_move_ship(delta)


func _hand_over_object(object: Node2D, margin: float = 0.0) -> bool:
	if object == null:
		return false

	if hand_left != null and hand_left.visible and dragging_left:
		if _is_over_object(hand_left.global_position, object, margin):
			return true

	if hand_right != null and hand_right.visible and dragging_right:
		if _is_over_object(hand_right.global_position, object, margin):
			return true

	return false

func _is_over_object(pos: Vector2, object: Node2D, margin: float = 0.0) -> bool:
	if object == null or object.texture == null:
		return false

	var size = object.texture.get_size() * object.scale
	size += Vector2.ONE * margin * 2

	var rect = Rect2(
		object.global_position - size * 0.5,
		size
	)

	return rect.has_point(pos)

func _move_joystick() -> void:
	var hand_pos: Vector2

	if dragging_left:
		hand_pos = hand_left.global_position
	else:
		hand_pos = hand_right.global_position

	if hand_pos.x < joystick.global_position.x:
		joystick.rotation = 100
	else:
		joystick.rotation = -100


func _move_ship(delta: float) -> void:
	ship.global_position.x += -joystick.rotation * (globals.game_speed / 100.0) * delta
	ship.global_position.x = clamp(ship.global_position.x, 214, 880)


func _press_arcade_button(delta: float) -> void:
	button_is_pressed = true
	button.position.y = 12

	bullet_timer += delta

	if bullet_timer >= bullet_interval:
		bullet_timer = 0

		var new_bullet = bullet.instantiate()
		new_bullet.global_position = Vector2(
			ship.global_position.x,
			ship.global_position.y - 35
		)

		bullets_container.add_child(new_bullet)


func _release_arcade_button() -> void:
	button_is_pressed = false
	button.position.y = 6
	bullet_timer = 1
