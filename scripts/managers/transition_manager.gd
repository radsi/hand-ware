extends Node

@onready var text = $CanvasGroup/message
@onready var score = $CanvasGroup/message2
@onready var hands = $CanvasGroup/hands
@onready var decorations_list = [$decorations1, $decorations2, $decorations3, $decorations4]
@onready var decorations = decorations_list[randf_range(0, decorations_list.size())]
@onready var bg1 = $Bg
@onready var bg2 = $Bg2
var timer = 0

var original_positions := {}

var colors = ["#F8FAB4", "#91ADC8", "#D9E9CF", "#A376A2"]
var bg_colors = ["#8FA31E", "#003161", "#D1D3D4"]
var messages_bad = ["Too bad!", "You can do better", "Oh...", "Uhmm..."]
var messages_good = ["Nice!", "Very good!", "Good work!", "GG EZ", "Wario Ware"]

func _ready() -> void:
	score.text = "Score: " + str(globals.game_score)
	hands.modulate = globals.hands_color
	var color = Color(bg_colors[randf_range(0, bg_colors.size())])
	bg1.modulate = color
	bg2.modulate = color
	text.rotation_degrees = 6
	hands.rotation_degrees = -6
	decorations.visible = true
	hands.texture = globals.winhand_texture
	for deco: Sprite2D in decorations.get_children():
		original_positions[deco] = deco.global_position
		deco.modulate = Color(colors[randf_range(0, colors.size())])
		_apply_random_transform(deco)
	
	if not globals.roll_started:
		text.text = "Game over"
		hands.flip_v = true
		bg1.modulate = Color("#231942")
		bg2.modulate = Color("#231942")
		$over.play()
		return
	
	if globals.has_lost_life:
		globals.has_lost_life = false
		globals.deaths += 1
		if globals.deaths >= 10:
			globals._unlock_minigame("Valve")
		if globals.deaths >= 20:
			globals._unlock_minigame("Samurai")
		text.text = messages_bad[randf_range(0, messages_bad.size())]
		hands.flip_v = true
		$bad.play()
	else:
		text.text = messages_good[randf_range(0, messages_good.size())]
		$good.play()
	
	await get_tree().create_timer(2).timeout
	
	if globals.incresing_speed:
		hands.flip_v = false
		decorations.visible = false
		original_positions.clear()
		decorations = decorations_list[randf_range(0, decorations_list.size())]
		for deco: Sprite2D in decorations.get_children():
			original_positions[deco] = deco.global_position
			deco.modulate = Color(colors[randf_range(0, colors.size())])
		decorations.visible = true

		text.text = "Go go go!"
		hands.texture = globals.gohand_texture
		$speed.play()
		await get_tree().create_timer(2).timeout
	
	_next_minigame()

func _next_minigame():
	globals.is_on_transition = false
	globals.incresing_speed = false
	get_tree().change_scene_to_file(globals.last_scene)

func _process(delta: float) -> void:
	
	bg1.global_position.y += 5
	bg2.global_position.y += 5
	
	if bg1.global_position.y > 2156:
		bg1.global_position.y = -2156
	if bg2.global_position.y > 2156:
		bg2.global_position.y = -2156
	
	timer += delta
	
	if timer >= 0.5:
		timer = 0
		for deco: Sprite2D in decorations.get_children():
			_apply_random_transform(deco)
		text.rotation_degrees *= -1
		hands.rotation_degrees *= -1

func _apply_random_transform(deco: Sprite2D) -> void:
	var base_pos = original_positions[deco]
	deco.global_position = base_pos + Vector2(
		randf_range(-20, 20),
		randf_range(-20, 20)
	)
	deco.rotation_degrees = randf_range(0, 360)
	var new_scale = randf_range(0.5, 1.25)
	deco.scale = Vector2(new_scale, new_scale)
