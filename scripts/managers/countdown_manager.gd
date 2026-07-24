extends Node

var colors = ["F75270", "EF9595", "F7CAC9"]
var start_count := 4

@onready var mouse_left_click_sprite = preload("res://sprites/left click.png")
@onready var mouse_right_click_sprite = preload("res://sprites/right click.png")
@onready var joystick_left_sprite = preload("res://sprites/left joystick.png")
@onready var joystick_right_sprite = preload("res://sprites/right joystick.png")
@onready var mouse = $mouse
@onready var hand_left = $OpenHand
@onready var hand_right = $OpenHand2

var count := start_count
var timer = 0
var index = 0

func _ready():
	
	if globals.using_gamepad:
		mouse_left_click_sprite = load("res://sprites/left joystick.png")
		mouse_right_click_sprite = load("res://sprites/right joystick.png")
	
	mouse.texture = mouse_left_click_sprite
	
	$ColorRect2.color.a = 1
	var tween = create_tween()
	tween.tween_property($ColorRect2, "color:a", 0.0, 1.0)
	await get_tree().create_timer(1.0).timeout
	$AudioStreamPlayer2D.play()
	_start_countdown()

func _start_countdown():
	if count <= 1:
		globals.start_roll_from_menu()
		return
	count -= 1
	$Label.add_theme_font_size_override("font_size", 204 + (start_count - count) * 30)
	$Label.text = str(count)
	$AudioStreamPlayer2D.play()
	$ColorRect.color = Color(colors[(start_count - count - 1)])
	
	await get_tree().create_timer(1.0).timeout
	_start_countdown()

func _process(delta: float) -> void:
	timer += delta
	
	if timer >= 0.75:
		timer = 0
		if index == 0:
			index = 1
			mouse.texture = mouse_right_click_sprite
			hand_right.global_position.y = 750
			hand_left.global_position.y = 800
		else:
			index = 0
			mouse.texture = mouse_left_click_sprite
			hand_left.global_position.y = 750
			hand_right.global_position.y = 800
