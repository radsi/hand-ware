extends Node

@onready var fire := $bonfire/fire
@onready var burn_audio := $AudioStreamPlayer2D
@onready var complete_audio := $AudioStreamPlayer2D2

@onready var fire_sprites := [
	preload("res://mini games sprites/fire/fire1.png"),
	preload("res://mini games sprites/fire/fire2.png"),
	preload("res://mini games sprites/fire/fire3.png")
]

var frame := 0
var frame_timer := 0.0
var restarting := false


func _ready() -> void:
	globals.is_playing_minigame_anim = true


func _process(delta: float) -> void:
	frame_timer += delta
	if frame_timer >= 0.5:
		frame_timer = 0.0
		frame = (frame + 1) % fire_sprites.size()
		fire.texture = fire_sprites[frame]

	if !globals.minigame_completed and fire.scale.x <= 0.1:
		complete()


func complete() -> void:
	globals.game_score += 1
	globals.minigame_completed = true
	complete_audio.play()

	if globals.is_single_minigame and !restarting:
		restart()


func restart() -> void:
	restarting = true
	globals.is_playing_minigame_anim = true

	await get_tree().create_timer(1).timeout

	burn_audio.stop()

	fire.scale = Vector2(0.5, 0.5)
	frame = 0
	frame_timer = 0.0
	fire.texture = fire_sprites[0]

	globals.time_left = globals.game_time
	globals.minigame_completed = false
	globals.is_playing_minigame_anim = false

	restarting = false
