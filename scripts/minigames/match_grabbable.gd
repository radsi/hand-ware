extends Grabbable
class_name MatchStick

signal match_lit
signal candle_touched(candle)

@onready var fire: Sprite2D = $fire
@onready var matchbox = get_parent()

var lit := false
var grabbed_now := false

var move_timer := 0.0
var last_position := Vector2.ZERO

var fire_timer := 0.0
var fire_frame := 0

@onready var fire_sprites = [
	preload("res://mini games sprites/smoke/fire1.png"),
	preload("res://mini games sprites/smoke/fire2.png"),
	preload("res://mini games sprites/smoke/fire3.png")
]

func _ready():
	super._ready()

	fire.hide()
	last_position = global_position

func _on_grabbed(is_left: bool) -> void:
	super._on_grabbed(is_left)

	grabbed_now = true

	z_index = 9

func _on_released(_is_left: bool) -> void:
	super._on_released(_is_left)

	grabbed_now = false
	move_timer = 0

func _process(delta):

	if lit:
		_animate_fire(delta)
		_check_candles()

	elif grabbed_now:
		_check_slide(delta)

	last_position = global_position

func _animate_fire(delta):

	fire_timer += delta

	if fire_timer >= 0.5:
		fire_timer = 0

		fire_frame += 1

		if fire_frame >= fire_sprites.size():
			fire_frame = 0

		fire.texture = fire_sprites[fire_frame]

func _check_slide(delta):

	var local_pos = matchbox.to_local(global_position)
	var size = matchbox.texture.get_size()

	var rect = Rect2(-size * 0.5, size)

	if rect.has_point(local_pos) and global_position != last_position:

		move_timer += delta

		if move_timer >= 0.7:
			light()

	else:
		move_timer = 0

func light():

	if lit:
		return

	lit = true
	fire.show()

	$"../../slide".play()

	match_lit.emit()

func _check_candles():
	for candle in get_tree().get_nodes_in_group("candles"):
		if fire.global_position.distance_to(candle.fire.global_position) < 80:
			candle_touched.emit(candle)

func reset():

	lit = false
	grabbed_now = false
	
	z_index = -1

	fire.hide()

	fire_frame = 0
	fire_timer = 0

	fire.texture = fire_sprites[0]

	move_timer = 0
