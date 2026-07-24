extends Node2D

@onready var enemies = $enemies
@onready var bullets = $bullets

var frame_interval = 0.5
var current_frame = 7
var timer = 0.0

var active_enemies: Array = []
var dead_enemies_count = 1

var enemies_tweens = {}
var enemies_original_positions = {}
var can_restart = false

func _ready() -> void:
	_set_enemies()

func _process(delta: float) -> void:
	if globals.is_single_minigame and can_restart and enemies_tweens.size() == 0:
		can_restart = false
		globals.is_playing_minigame_anim = false
		globals.time_left = globals.game_time
		enemies_tweens.clear()
		_set_enemies()
	
	timer += delta
	if timer < frame_interval:
		return
	timer = 0.0

	current_frame = 8 if current_frame == 7 else 7

	for enemy: Sprite2D in active_enemies:
		if enemy.visible:
			enemy.frame = current_frame

func _kill_enemy(enemy: Sprite2D) -> void:
	active_enemies.erase(enemy)
	dead_enemies_count += 1
	if globals.is_single_minigame and dead_enemies_count == 20:
		globals._unlock_minigame("Jail")
		globals._unlock_hands("striped")
	if dead_enemies_count % 4 == 1:
		globals.minigame_completed = true
		
		for _enemy: Sprite2D in active_enemies:
			if globals.is_single_minigame: globals.is_playing_minigame_anim = true
			var tween := get_tree().create_tween()
			enemies_tweens[tween.get_instance_id()] = tween
			tween.tween_property(_enemy, "position:y", -20, globals.game_speed / 150)
			tween.finished.connect(func():
				enemies_tweens.erase(tween.get_instance_id())
				can_restart = true
			)
	enemy.frame = 23
	$boom.play()
	await get_tree().create_timer(0.3).timeout
	enemy.frame = 30
	enemy.hide()

func _enemy_is_dead(enemy: Sprite2D) -> bool:
	return not active_enemies.has(enemy)

func _set_enemies() -> void:
	var children = enemies.get_children()
	children.shuffle()

	for i in range(children.size()):
		var child = children[i]
		if i < 47:
			child.hide()
		else:
			active_enemies.append(child)
			child.show()
