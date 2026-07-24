extends Node

@onready var gallery_locked_sprite = preload("res://sprites/gallery item locked.png")
@onready var bg1 = $Bg
@onready var bg2 = $Bg2
@onready var button_back = $buttonback
@onready var button_left = $left
@onready var button_right = $right
@onready var achievments_button = $achievments
@onready var buttons = []

var item_under_mouse: Sprite2D = null
var page = 1
var max_page = 1
var current_button = 1

var prev_dpad_left := false
var prev_dpad_right := false
var prev_dpad_up := false
var prev_dpad_down := false

var prev_axis_x := 0.0
var prev_axis_y := 0.0
var prev_button_a := false
var prev_button_b := false

var konami_sequence = ["up", "up", "down", "down", "left", "right", "left", "right", "b", "a"]
var konami_progress = 0

func _ready():
	bg1.global_position.y = globals.current_menu_bg_pos[0]
	bg2.global_position.y = globals.current_menu_bg_pos[1]
	max_page = get_tree().get_nodes_in_group("pages").size()
	$AnimationPlayer.play("arrow_green")
	$AnimationPlayer2.play("arrow_back")
	_refresh_buttons()
	_refresh_gallery()

func _process(delta): 
	_handle_dpad_input()
	_handle_joystick_input()
	_scroll_background()
	_highlight_items()

func _input(event):
	var input_name = null

	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_UP: input_name = "up"
			JOY_BUTTON_DPAD_DOWN: input_name = "down"
			JOY_BUTTON_DPAD_LEFT: input_name = "left"
			JOY_BUTTON_DPAD_RIGHT: input_name = "right"
			JOY_BUTTON_B: input_name = "b"
			JOY_BUTTON_A: input_name = "a"

	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5 and prev_axis_y > -0.5:
				input_name = "up"
			elif event.axis_value > 0.5 and prev_axis_y < 0.5:
				input_name = "down"
		elif event.axis == JOY_AXIS_LEFT_X:
			if event.axis_value < -0.5 and prev_axis_x > -0.5:
				input_name = "left"
			elif event.axis_value > 0.5 and prev_axis_x < 0.5:
				input_name = "right"

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP: input_name = "up"
			KEY_DOWN: input_name = "down"
			KEY_LEFT: input_name = "left"
			KEY_RIGHT: input_name = "right"
			KEY_A: input_name = "a"
			KEY_B: input_name = "b"

	if input_name:
		if input_name == konami_sequence[konami_progress]:
			konami_progress += 1
			if konami_progress >= konami_sequence.size():
				konami_progress = 0
				_on_unlockall_pressed()
		else:
			konami_progress = 0

	if event is InputEventJoypadButton and event.pressed and konami_progress < 4:
		if event.button_index == JOY_BUTTON_B:
			get_tree().change_scene_to_file("res://scenes/menu.tscn")
		elif event.button_index == JOY_BUTTON_A:
			if current_button == 0:
				get_tree().change_scene_to_file("res://scenes/menu.tscn")
			elif current_button == 13:
				_on_left_pressed()
			elif current_button == 14:
				get_tree().change_scene_to_file("res://scenes/achievments.tscn")
			elif current_button == 15:
				_on_right_pressed()
			elif item_under_mouse:
				if item_under_mouse.name.contains("checkbox"):
					if item_under_mouse.get_child(0).visible == false:
						item_under_mouse.get_child(1).hide()
						item_under_mouse.get_child(0).show()
						var minigame = item_under_mouse.get_parent().get_child(0).name
						if minigame == "samurai": minigame = "samurai long"
						globals.all_used_scenes.append("res://scenes/minigames/"+minigame+".tscn")
					else:
						if globals.all_used_scenes.size() == 2: return
						item_under_mouse.get_child(1).hide()
						item_under_mouse.get_child(0).show()
						var minigame = item_under_mouse.get_parent().get_child(0).name
						if minigame == "samurai": minigame = "samurai long"
						globals.all_used_scenes.erase("res://scenes/minigames/"+minigame+".tscn")
					globals._play_pop()
					_refresh_gallery()
					return
				var icon = item_under_mouse.get_child(0)
				if icon and item_under_mouse.get_meta("unlocked"):
					globals.start_single_minigame(icon.name)
		elif event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			_on_left_pressed()
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			_on_right_pressed()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not globals.using_gamepad and item_under_mouse:
		if item_under_mouse.name.contains("checkbox"):
			if item_under_mouse.get_child(0).visible == false:
				item_under_mouse.get_child(1).hide()
				item_under_mouse.get_child(0).show()
				var minigame = item_under_mouse.get_parent().get_child(0).name
				if minigame == "samurai": minigame = "samurai long"
				globals.all_used_scenes.append("res://scenes/minigames/"+minigame+".tscn")
			else:
				if globals.all_used_scenes.size() == 2: return
				item_under_mouse.get_child(1).hide()
				item_under_mouse.get_child(0).show()
				var minigame = item_under_mouse.get_parent().get_child(0).name
				if minigame == "samurai": minigame = "samurai long"
				globals.all_used_scenes.erase("res://scenes/minigames/"+minigame+".tscn")
			globals._play_pop()
			_refresh_gallery()
			return
		var icon = item_under_mouse.get_child(0)
		if icon and item_under_mouse.get_meta("unlocked"):
			globals.start_single_minigame(icon.name)


func _handle_dpad_input():
	var dpad_left = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT)
	var dpad_right = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT)
	var dpad_up = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
	var dpad_down = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)

	# Horizontal
	if dpad_left and not prev_dpad_left:
		current_button = clamp(current_button - 1, 0, buttons.size() - 1)
		_clamp_visible_button(-1)
	elif dpad_right and not prev_dpad_right:
		current_button = clamp(current_button + 1, 0, buttons.size() - 1)
		_clamp_visible_button(1)

	# Vertical
	elif dpad_up and not prev_dpad_up:
		current_button -= 3
		_clamp_visible_button(-3)
	elif dpad_down and not prev_dpad_down:
		current_button += 3
		_clamp_visible_button(3)

	current_button = clamp(current_button, 0, buttons.size() - 1)
	prev_dpad_left = dpad_left
	prev_dpad_right = dpad_right
	prev_dpad_up = dpad_up
	prev_dpad_down = dpad_down

func _handle_joystick_input():
	var x_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y_axis = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)

	# Horizontal
	if x_axis < -0.5 and prev_axis_x >= -0.5:
		current_button = clamp(current_button - 1, 0, buttons.size() - 1)
		_clamp_visible_button(-1)
	elif x_axis > 0.5 and prev_axis_x <= 0.5:
		current_button = clamp(current_button + 1, 0, buttons.size() - 1)
		_clamp_visible_button(1)
		
	# Vertical
	elif y_axis < -0.5 and prev_axis_y >= -0.5:
		current_button -= 3
		_clamp_visible_button(-3)
	elif y_axis > 0.5 and prev_axis_y <= 0.5:
		current_button += 3
		_clamp_visible_button(3)

	current_button = clamp(current_button, 0, buttons.size() - 1)

	prev_axis_x = x_axis
	prev_axis_y = y_axis

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


func _scroll_background():
	bg1.global_position.y += 5
	bg2.global_position.y += 5
	globals.current_menu_bg_pos[0] = bg1.global_position.y
	globals.current_menu_bg_pos[1] = bg2.global_position.y
	if bg1.global_position.y > 2156:
		bg1.global_position.y = -2156
	if bg2.global_position.y > 2156:
		bg2.global_position.y = -2156

func _highlight_items():
	if globals.using_gamepad:
		for i in range(buttons.size()):
			var btn = buttons[i]
			if i == current_button:
				if btn.visible == false:
					current_button -= 1
					return
				if get_tree().get_nodes_in_group("uibutton").has(btn): btn.scale = Vector2(1.15, 1.15)
				elif btn.name.contains("checkbox"): btn.scale = Vector2(0.35, 0.35)
				else: btn.scale = Vector2(1.75, 1.75)
			else:
				if get_tree().get_nodes_in_group("uibutton").has(btn): btn.scale = Vector2(1, 1)
				elif btn.name.contains("checkbox"): btn.scale = Vector2(0.3, 0.3)
				else: btn.scale = Vector2(1.5, 1.5)
		return
		
	var mouse_pos = get_viewport().get_mouse_position()
	item_under_mouse = null
	for item in get_node("page" + str(page)).get_children():
		var scale_target = Vector2(1.5, 1.5)
		if is_mouse_over_item(item.get_child(1), mouse_pos):
			item.get_child(1).scale = Vector2(0.35, 0.35)
			scale_target = Vector2(1.75, 1.75)
			item_under_mouse = item.get_child(1)
		elif is_mouse_over_item(item, mouse_pos):
			scale_target = Vector2(1.75, 1.75)
			item.get_child(1).scale = Vector2(0.3, 0.3)
			if item.get_meta("unlocked"):
				item.get_child(1).show()
				item_under_mouse = item
		else:
			item.get_child(1).hide()
		item.scale = scale_target

func _refresh_gallery():
	for en in globals.all_unlocked_scenes:
		print(en)
	for page_node in get_tree().get_nodes_in_group("pages"):
		for item in page_node.get_children():
			var item_icon = null
			if item.get_child_count() > 0:
				item_icon = item.get_child(0)
			if not item_icon:
				if item is Sprite2D:
					item.texture = gallery_locked_sprite
				item.set_meta("unlocked", false)
				continue
			var unlocked = false
			var icon_name = item_icon.name.replace(" long", "")
			for minigame in globals.all_unlocked_scenes:
				if minigame.split("/")[-1].contains(icon_name):
					unlocked = true
					break
			item_icon.visible = unlocked
			if not unlocked and item is Sprite2D:
				item.texture = gallery_locked_sprite
			item.set_meta("unlocked", unlocked)
			if icon_name == "climb": icon_name = "climb long"
			if not globals.all_used_scenes.has("res://scenes/minigames/" + icon_name + ".tscn"):
				item.get_child(1).get_child(1).show()
				item.get_child(1).get_child(0).hide()

func _refresh_buttons():
	buttons.clear()
	buttons.append(button_back)
	for item in get_node("page" + str(page)).get_children():
		buttons.append(item)
		buttons.append(item.get_child(1))
	buttons.append(button_left)
	buttons.append(achievments_button)
	buttons.append(button_right)

func is_mouse_over_item(item: Sprite2D, mouse_pos: Vector2) -> bool:
	if item.texture == null:
		return false
	var local_pos = item.to_local(mouse_pos)
	var size = item.texture.get_size()
	return Rect2(-size * 0.5, size).has_point(local_pos)

func _on_buttonback_pressed():
	globals._play_pop()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_left_pressed():
	if page == 1:
		return
	get_node("page" + str(page)).visible = false
	page -= 1
	get_node("page" + str(page)).visible = true
	if page == 1:
		button_left.hide()
	button_right.show()
	globals._play_pop()
	_refresh_buttons()

func _on_right_pressed():
	if page == max_page:
		current_button -= 1
		return
	get_node("page" + str(page)).visible = false
	page += 1
	get_node("page" + str(page)).visible = true
	if page == max_page:
		button_right.hide()
	button_left.show()
	globals._play_pop()
	_refresh_buttons()

func _on_unlockall_pressed():
	globals._play_pop()
	for hand in ["camo", "eyes", "fire", "caution", "real", "striped", "dalmata", "hearts"]:
		globals._unlock_hands(hand, false)
	for game in ["Soccer", "Arcade", "Bonfire", "Candle", "Clean", "Jail", "Kanji", "PingPong", "Rope", "Soccer", "Toast", "Vendor", "Ham", "Puzzle", "Valve", "Samurai", "Boss"]:
		globals._unlock_minigame(game, false)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_buttonback_2_mouse_entered() -> void: button_back.scale = Vector2(1.15,1.15) 
func _on_buttonback_mouse_exited() -> void: button_back.scale = Vector2(1,1) 
func _on_left_mouse_entered() -> void: button_left.scale = Vector2(1.15,1.15) 
func _on_left_mouse_exited() -> void: button_left.scale = Vector2(1,1) 
func _on_right_mouse_entered() -> void: button_right.scale = Vector2(1.15,1.15)
func _on_right_mouse_exited() -> void: button_right.scale = Vector2(1,1)
func _on_achievments_pressed() -> void:
	globals._play_pop()
	get_tree().change_scene_to_file("res://scenes/achievments.tscn")
func _on_achievments_mouse_entered() -> void: achievments_button.scale = Vector2(1.15,1.15)
func _on_achievments_mouse_exited() -> void: achievments_button.scale = Vector2(1,1)
