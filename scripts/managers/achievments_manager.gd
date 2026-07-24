extends Node

@onready var bg1 = $Bg
@onready var bg2 = $Bg2
@onready var button_back = $buttonback
@onready var scroll_container = $MarginContainer/VBoxContainer/ScrollContainer
@onready var scroll_elements = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var gallery_item_sprite = preload("res://sprites/gallery item.png")

func _ready():
	bg1.global_position.y = globals.current_menu_bg_pos[0]
	bg2.global_position.y = globals.current_menu_bg_pos[1]
	$AnimationPlayer2.play("arrow_back")
	
	for element in scroll_elements.get_children():
		if globals.all_unlocked_scenes.has("res://scenes/minigames/" + element.name + ".tscn"):
			element.get_child(0).modulate = Color.LIME_GREEN
			if element.name == "boss": element.get_child(1).modulate = Color(1,1,1)
			else: 
				element.get_child(1).texture = gallery_item_sprite
				element.get_child(1).get_child(0).show()
		if globals.all_unlocked_hands.has(element.name):
			element.get_child(0).modulate = Color.LIME_GREEN
			element.get_child(1).modulate = Color(1,1,1)
			element.get_child(2).modulate = Color(1,1,1)

func _process(delta: float) -> void:
	_scroll_background()
	
	var dpad_up = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
	var dpad_down = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)
	
	if dpad_up:
		scroll_container.scroll_vertical -= 300 * delta
	elif dpad_down:
		scroll_container.scroll_vertical += 300 * delta
	
		
	var y_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if y_axis < -0.5:
		scroll_container.scroll_vertical -= 300 * delta
	elif y_axis > 0.5:
		scroll_container.scroll_vertical += 300 * delta

func _scroll_background():
	bg1.global_position.y += 5
	bg2.global_position.y += 5
	globals.current_menu_bg_pos[0] = bg1.global_position.y
	globals.current_menu_bg_pos[1] = bg2.global_position.y
	if bg1.global_position.y > 2156:
		bg1.global_position.y = -2156
	if bg2.global_position.y > 2156:
		bg2.global_position.y = -2156


func _on_buttonback_pressed():
	globals._play_pop()
	get_tree().change_scene_to_file("res://scenes/gallery.tscn")
	
func _on_buttonback_mouse_entered() -> void: $buttonback.scale = Vector2(1.15,1.15)
func _on_buttonback_mouse_exited() -> void: $buttonback.scale = Vector2(1,1) 
