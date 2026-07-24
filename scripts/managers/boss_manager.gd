extends Node

var slash_color = Color("e25349ff")

@onready var hands: HANDS = $CanvasGroup

@onready var eye2_sprite = preload("res://mini games sprites/bosses/eye2.png")
@onready var eyes = [$Gas/Eye, $Gas/Eye2]
@onready var boss_sprite = $Gas
var original_positions = []

@onready var valve = $Valve
@onready var valve_tube = $Valve/RedTube
@onready var valve_object = $Valve/Valve
@onready var valve_anim: AnimationPlayer = $Valve/AnimationPlayer
@onready var valve_smokes = [$Valve/smoke1, $Valve/smoke2, $Valve/smoke3, $Valve/smoke4]
@onready var valve_sfx: AudioStreamPlayer2D = $Valve/valve

@onready var vendor = $Vendor
@onready var vendor_label = $Vendor/Label

@onready var wall = $Wall
@onready var knock_sfx: AudioStreamPlayer2D = $knock
@onready var break_sfx: AudioStreamPlayer2D = $break

@onready var slash_sfx = $slash
@onready var explosion_sfx = $explosionsfx
@onready var wrong_sfx = $wrong
@onready var hitboss_sfx = $hitboss

@onready var explosions = $explosions
@onready var explosion = $explosion

@onready var slashes = [$Slash1, $Slash2, $Slash3, $Slash4]
var random_events = []

var doing_attack := false

var boss_hp := 2

var hand_input := ""
var timer: float = 0

var _old_mouse_pos := Vector2.ZERO
var _original_hand_pos := []
var _knockback_active := false

func _ready() -> void:
	globals.minigame_completed = true
	wall.wall_hit.connect(_on_wall_hit)
	wall.wall_broken.connect(_on_wall_broken)
	original_positions = [
		boss_sprite.global_position,
		eyes[0].global_position,
		eyes[1].global_position
	]
	random_events = [Callable(self, "enable_valve"), Callable(self, "enable_vendor")]
	_apply_random_transform()
	do_attacks()

func _on_wall_hit(_wall: BreakableWall, hits_left: int) -> void:
	knock_sfx.play()

	if hits_left == 3:
		if random_events.size() > 0:
			var event = randi() % random_events.size()
			random_events[event].call()
			random_events.remove_at(event)

func _on_wall_broken(_wall: Node) -> void:
	break_sfx.play()

func _process(delta: float) -> void:
	if vendor.visible:
		if hand_input == vendor_label.text:
			disable_vendor()
		elif not vendor_label.text.begins_with(hand_input):
			blink_text()


func _apply_random_transform() -> void:
	if boss_hp <= 0:
		return
	for i in range(eyes.size()):
		var eye = eyes[i]
		var base_pos = original_positions[1 + i]
		eye.global_position = base_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4))
	await get_tree().create_timer(0.1).timeout
	_apply_random_transform()


func blink_text() -> void:
	wrong_sfx.play()
	for i in range(2):
		vendor_label.hide()
		await get_tree().create_timer(0.1).timeout
		vendor_label.show()
		await get_tree().create_timer(0.1).timeout
	hand_input = ""


func do_attacks():
	if boss_hp <= 0:
		return
	await get_tree().create_timer(randf_range(3, 5)).timeout
	var slashes_group = slashes[randi_range(0, slashes.size() - 1)]
	for slash in slashes_group.get_children():
		slash.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(slash, "modulate", slash_color, 1 / (globals.game_speed / 300))
		if slash.name.contains("3"):
			tween.finished.connect(func(): await _on_attack_tween_finished(slashes_group))
	do_attacks()


func _on_attack_tween_finished(slashes_group):
	for slash in slashes_group.get_children():
		for area in slash.get_child(0).get_overlapping_areas():
			if area.name == "Areahand" and not hands.block_left_hand_movement and not hands.block_right_hand_movement:
				die()
	slash_sfx.play()
	doing_attack = true
	await get_tree().create_timer(0.5).timeout
	for slash in slashes_group.get_children():
		slash.modulate = Color(1, 1, 1, 0)
	doing_attack = false


func die():
	if eyes[0].visible == false:
		return
	globals.minigame_completed = false
	explosion.show()
	explosion.play()
	explosion_sfx.play()
	await get_tree().create_timer(1).timeout
	globals.has_lost_life = true
	globals.life -= 1
	globals._start_roll()


func _kill_boss():
	eyes[0].hide()
	eyes[1].hide()
	for slash in slashes: 
		slash.hide()
	globals._unlock_hands("eyes")
	for _explosion: AnimatedSprite2D in explosions.get_children():
		await get_tree().create_timer(0.5).timeout
		explosion_sfx.play()
		_explosion.show()
		_explosion.play()
	await get_tree().create_timer(2).timeout
	globals._start_roll()


func enable_valve():
	valve.show()
	var tween = create_tween()
	var tween2 = create_tween()
	tween2.tween_property(valve_object, "global_position", Vector2(540, 630), 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(valve_tube, "global_position", Vector2(540, 1400), 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_valve_moved").bind(false))


func disable_valve():
	timer = 0
	var tween = create_tween()
	var tween2 = create_tween()
	tween2.tween_property(valve_object, "position", Vector2(540, 899), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(valve_tube, "position", Vector2(540, 1669), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_valve_moved").bind(true))


func _on_valve_moved(disable):
	if not disable:
		valve_anim.seek(0)
		valve_anim.play("smoke")
		for i in range(valve_smokes.size()):
			valve_smokes[i].visible = not disable
	else:
		valve_anim.stop()
		valve.hide()
		$Valve/steam.stop()
		if boss_hp > 0:
			wall.breakable = true


func enable_vendor():
	vendor.show()
	var chars = "0123456789ABCD"
	vendor_label.text = ""
	for i in range(5):
		vendor_label.text += chars[randi_range(0, chars.length() - 1)]
	var tween = create_tween()
	tween.tween_property(vendor, "global_position", Vector2(0, -630), 1).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_vendor_moved").bind(false))


func disable_vendor():
	hand_input = ""
	timer = 0
	var tween = create_tween()
	tween.tween_property(vendor, "global_position", Vector2(0, 0), 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "_on_vendor_moved").bind(true))


func _on_vendor_moved(disable):
	if disable:
		vendor.hide()
		if boss_hp > 0:
			wall.breakable = true

func _hands_hit_solid(hands_ref: HANDS, solid: Node, is_left: bool) -> void:
	if doing_attack:
		return

	match solid.name:
		"Gas":
			_hit_boss(hands_ref, is_left)

func _hit_boss(hands_ref: HANDS, is_left: bool) -> void:
	if wall.visible or boss_hp <= 0 or _knockback_active:
		return

	eyes[0].texture = eye2_sprite
	eyes[1].texture = eye2_sprite
	boss_hp -= 1
	hitboss_sfx.play()

	if boss_hp <= 0:
		_kill_boss()

	boss_sprite.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(boss_sprite, "modulate", Color(1, 1, 1, 1), 1)

	_knockback_hands(hands_ref)

func _knockback_hands(hands_ref: HANDS) -> void:
	if _original_hand_pos.is_empty():
		return

	_knockback_active = true
	hands_ref.block_left_hand_movement = true
	hands_ref.block_right_hand_movement = true

	var tween_left = create_tween()
	tween_left.tween_property(hands_ref.hand_left, "global_position", _original_hand_pos[0], 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	var tween_right = create_tween()
	tween_right.tween_property(hands_ref.hand_right, "global_position", _original_hand_pos[1], 1).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween_right.finished.connect(func():
		hands_ref.block_left_hand_movement = false
		hands_ref.block_right_hand_movement = false
		_knockback_active = false
		if boss_hp > 0:
			wall.show()
			wall.reset()
			wall.breakable = true
	)


func _hands_process(hands_ref: HANDS, delta: float) -> void:
	if _original_hand_pos.is_empty():
		_original_hand_pos = [hands_ref.hand_left.global_position, hands_ref.hand_right.global_position]

	_process_valve(hands_ref)


func _process_valve(hands_ref: HANDS) -> void:
	if not valve.visible:
		return

	var viewport := get_viewport()
	if viewport == null:
		return

	var current_mouse_pos = viewport.get_mouse_position()

	var over_valve := (
		(HANDS.is_point_over_sprite(valve_object, hands_ref.hand_right.global_position) and hands_ref.dragging_right and hands_ref.hand_right.visible)
		or (HANDS.is_point_over_sprite(valve_object, hands_ref.hand_left.global_position) and hands_ref.dragging_left and hands_ref.hand_left.visible)
	)

	if over_valve:
		var moved = (
			(hands_ref.hand_right.global_position.x != hands_ref.last_pos_right.x and globals.using_gamepad)
			or (hands_ref.hand_left.global_position.x != hands_ref.last_pos_left.x and globals.using_gamepad)
			or (current_mouse_pos.x != _old_mouse_pos.x and not globals.using_gamepad)
		)
		if moved:
			valve_object.rotate(0.1)
			if valve_sfx and not valve_sfx.is_playing():
				valve_sfx.play()

	if valve_object.rotation_degrees >= 2000:
		disable_valve()

	_old_mouse_pos = current_mouse_pos
