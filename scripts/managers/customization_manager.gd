extends Node

@onready var hands = $Current
@onready var gallery_locked_sprite = preload("res://sprites/gallery item locked.png")
var item_under_mouse: Sprite2D = null
var max_page = 1
var page = 1
var buttons = []
var current_button = 0

@onready var bg1 = $Bg
@onready var bg2 = $Bg2

var prev_dpad_left := false
var prev_dpad_right := false
var prev_dpad_up := false
var prev_dpad_down := false
var prev_axis_x := 0.0
var prev_axis_y := 0.0
var prev_button_a := false
var prev_button_b := false

func _ready() -> void:
	max_page = get_tree().get_nodes_in_group("pages").size()
	$AnimationPlayer.play("arrow_green")
	$AnimationPlayer2.play("arrow_back")
	_refresh_buttons()
	for page_node in get_tree().get_nodes_in_group("pages"):
		for item in page_node.get_children():
			if item.get_child_count() > 0 and globals.all_unlocked_hands.has(item.name):
				item.set_meta("unlocked", true)
			else:
				if item.get_child_count() > 0:
					item.get_child(0).hide()
					item.get_child(1).hide()
				item.set_meta("unlocked", false)
				item.texture = gallery_locked_sprite

func _process(delta: float) -> void:
	_scroll_background()
	_highlight_items()
	_handle_gamepad_navigation()

func _on_marker_color_changed(value: int, id: StringName) -> void:
	match str(id): 
		"R": globals.hands_color.r = value / 255.0 
		"G": globals.hands_color.g = value / 255.0 
		"B": globals.hands_color.b = value / 255.0 
	hands.modulate = globals.hands_color

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_B:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
			return
		elif event.button_index == JOY_BUTTON_A:
			if current_button == 0:
				get_tree().change_scene_to_file("res://scenes/menu.tscn")
			elif current_button == 7:
				_on_left_pressed()
			elif current_button == 8:
				_on_right_pressed()
			elif item_under_mouse:
				_select_mouse_item()
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_on_left_pressed()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_on_right_pressed()
				

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and item_under_mouse != null:
		_select_mouse_item()

func _clamp_visible_button(direction: int) -> void:
	if buttons.size() == 0:
		return
	
	current_button = clamp(current_button, 0, buttons.size() - 1)
	var start_index = current_button
	var tries = 0
	
	while tries < buttons.size():
		if buttons[current_button].visible:
			break
		
		current_button += direction
		if current_button >= buttons.size():
			current_button = 0
		elif current_button < 0:
			current_button = buttons.size() - 1
		
		tries += 1
		
		if current_button == start_index:
			break

func _handle_gamepad_navigation():
	# D-Pad
	var dpad_left = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)
	var dpad_right = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)
	var dpad_up = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
	var dpad_down = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)

	if dpad_left and not prev_dpad_left and (current_button != 1 and current_button != 2 and current_button != 3):
		current_button = clamp(current_button - 1, 0, buttons.size() - 1)
	elif dpad_right and not prev_dpad_right and (current_button != 1 and current_button != 2 and current_button != 3):
		current_button = clamp(current_button + 1, 0, buttons.size() - 1)
	elif dpad_up and not prev_dpad_up:
		current_button -= 1
		_clamp_visible_button(-1)
	elif dpad_down and not prev_dpad_down:
		current_button += 1
		_clamp_visible_button(1)

	prev_dpad_left = dpad_left
	prev_dpad_right = dpad_right
	prev_dpad_up = dpad_up
	prev_dpad_down = dpad_down

	# Joystick
	var x_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	if x_axis < -0.5 and prev_axis_x >= -0.5 and (current_button != 1 and current_button != 2 and current_button != 3):
		current_button = clamp(current_button - 1, 0, buttons.size() - 1)
	elif x_axis > 0.5 and prev_axis_x <= 0.5 and (current_button != 1 and current_button != 2 and current_button != 3):
		current_button = clamp(current_button + 1, 0, buttons.size() - 1)

	if y_axis < -0.5 and prev_axis_y >= -0.5:
		current_button -= 1
		_clamp_visible_button(-1)
	elif y_axis > 0.5 and prev_axis_y <= 0.5:
		current_button += 1
		_clamp_visible_button(1)

	prev_axis_x = x_axis
	prev_axis_y = y_axis

	current_button = clamp(current_button, 0, buttons.size() - 1)

func _refresh_buttons():
	buttons.clear()
	buttons.append($buttonback)
	buttons.append($sliders/SliderR/Marker)
	buttons.append($sliders/SliderG/Marker)
	buttons.append($sliders/SliderB/Marker)
	for item in get_node("page"+str(page)).get_children():
		buttons.append(item)
	buttons.append($left)
	buttons.append($right)

func _highlight_items():
	item_under_mouse = null
	if globals.using_gamepad:
		for i in range(buttons.size()):
			var btn = buttons[i]
			if i == current_button:
				if get_tree().get_nodes_in_group("uibutton").has(btn): btn.scale = Vector2(1.15, 1.15)
				elif btn.name == "Marker": btn.scale = Vector2(1.25, 1.25)
				else: btn.scale = Vector2(1.75, 1.75)
				if btn is not Button: item_under_mouse = btn
			else:
				if get_tree().get_nodes_in_group("uibutton").has(btn): btn.scale = Vector2(1, 1)
				elif btn.name == "Marker": btn.scale = Vector2(1.111, 1.0)
				else: btn.scale = Vector2(1.5, 1.5)
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	for item in get_node("page"+str(page)).get_children():
		if is_mouse_over_item(item, mouse_pos):
			item.scale = Vector2(1.75, 1.75)
			if item.get_meta("unlocked"): item_under_mouse = item
		else:
			item.scale = Vector2(1.5, 1.5)

func _select_current_item():
	if current_button >= buttons.size():
		return
	var selected = buttons[current_button]
	if selected.get_meta("unlocked"):
		hands.get_child(0).texture = selected.get_child(0).texture
		hands.get_child(1).texture = selected.get_child(1).texture
		globals.openhand_texture = hands.get_child(0).texture
		globals.closehand_texture = hands.get_child(1).texture
		_apply_skin_textures(selected.get_child(0).texture.get_path().get_file())
		globals._play_pop()

func _select_mouse_item():
	if item_under_mouse and item_under_mouse.get_meta("unlocked"):
		hands.get_child(0).texture = item_under_mouse.get_child(0).texture
		hands.get_child(1).texture = item_under_mouse.get_child(1).texture
		globals.openhand_texture = hands.get_child(0).texture
		globals.closehand_texture = hands.get_child(1).texture
		_apply_skin_textures(item_under_mouse.get_child(0).texture.get_path().get_file())
		globals._play_pop()

func _apply_skin_textures(texture_name: String):
	if texture_name.contains("_"):
		var skin = texture_name.split("_")[1]
		globals.fingerhand_texture = load("res://hand sprites/finger hand_" + skin)
		globals.winhand_texture = load("res://hand sprites/win hands_" + skin)
		globals.gohand_texture = load("res://hand sprites/up hand_" + skin)
		globals.skin = skin.replace(".png", "")
	else:
		globals.fingerhand_texture = load("res://hand sprites/finger hand.png")
		globals.winhand_texture = load("res://hand sprites/win hands.png")
		globals.gohand_texture = load("res://hand sprites/up hand.png")
		globals.skin = ""

func is_mouse_over_item(item: Sprite2D, mouse_pos: Vector2) -> bool:
	if item.texture == null: return false
	var local_pos = item.to_local(mouse_pos)
	var size = item.texture.get_size()
	return Rect2(-size * 0.5, size).has_point(local_pos)

func _scroll_background():
	bg1.global_position.y += 5
	bg2.global_position.y += 5
	if bg1.global_position.y > 2156: bg1.global_position.y = -2156
	if bg2.global_position.y > 2156: bg2.global_position.y = -2156
	globals.current_menu_bg_pos[0] = bg1.global_position.y
	globals.current_menu_bg_pos[1] = bg2.global_position.y

func _on_left_pressed() -> void:
	if page == 1: return
	get_node("page"+str(page)).visible = false
	page -= 1
	get_node("page"+str(page)).visible = true
	if page == 1: $left.hide()
	$right.visible = true
	globals._play_pop()
	_refresh_buttons()

func _on_right_pressed() -> void:
	if page == max_page:
		current_button -= 1
		return
	get_node("page"+str(page)).visible = false
	page += 1
	get_node("page"+str(page)).visible = true
	if page == max_page: $right.hide()
	$left.visible = true
	globals._play_pop()
	_refresh_buttons()

func _on_buttonback_pressed() -> void:
	globals._play_pop()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_buttonback_mouse_entered() -> void:
	if $buttonback != null:
		$buttonback.scale = Vector2(1.15,1.15)

func _on_buttonback_mouse_exited() -> void:
	if $buttonback != null:
		$buttonback.scale = Vector2(1,1)

func _on_left_mouse_entered() -> void: $left.scale = Vector2(1.15,1.15) 
func _on_left_mouse_exited() -> void: $left.scale = Vector2(1,1) 
func _on_right_mouse_entered() -> void: $right.scale = Vector2(1.15,1.15)
func _on_right_mouse_exited() -> void: $right.scale = Vector2(1,1)
