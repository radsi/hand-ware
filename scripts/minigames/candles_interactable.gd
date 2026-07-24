extends Node2D

signal candle_lit

@onready var fire = $fire

var lit := false
var fire_timer := 0.0
var fire_frame := 0

var fire_sprites = [
	preload("res://mini games sprites/smoke/fire1.png"),
	preload("res://mini games sprites/smoke/fire2.png"),
	preload("res://mini games sprites/smoke/fire3.png")
]


func _ready():
	add_to_group("candles")
	fire.hide()


func light():

	if lit:
		return

	lit = true
	fire.show()

	candle_lit.emit()


func _process(delta):

	if lit:
		fire_timer += delta

		if fire_timer >= 0.5:
			fire_timer = 0
			fire_frame = (fire_frame + 1) % fire_sprites.size()
			fire.texture = fire_sprites[fire_frame]


func reset():

	lit = false

	fire.hide()

	fire_frame = 0
	fire_timer = 0
	fire.texture = fire_sprites[0]
