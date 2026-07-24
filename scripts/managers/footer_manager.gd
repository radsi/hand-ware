extends Node

var timer_colors = ["#ABCDCB", "#EBE59B", "#E78775", "#C84361"]
@onready var timer_color = $TimerColor
@onready var heart_hand = $HeartHand
@onready var footer_timer = $FooterTimer
@onready var footer_sprite_1 = preload("res://sprites/footer-timer.png")
@onready var footer_sprite_2 = preload("res://sprites/footer-timer-2.png")
var current_footer_sprite = 1
var initial_scale := Vector2.ONE

var timer := 0.0

func _ready() -> void:
	globals.is_playing_minigame_anim = false
	$".".get_child(2).text = str(globals.life)
	if globals.is_single_minigame:
		$".".get_child(2).text = "1"
		if globals.is_long and globals.is_single_minigame: self.visible = false
	
	initial_scale = timer_color.scale
	heart_hand.rotation_degrees = 5

func _process(delta: float) -> void:
	timer += delta

	var max_time := globals.game_time_long if globals.is_long else globals.game_time
	var t = clamp(globals.time_left / max_time, 0.0, 1.0)

	var idx := int(floor((1.0 - t) * (timer_colors.size() - 1)))
	timer_color.color = Color(timer_colors[idx])

	timer_color.scale.x = initial_scale.x * t
	
	if timer >= 1:
		timer = 0
		heart_hand.rotation_degrees *= -1
		if current_footer_sprite == 1: 
			footer_timer.texture = footer_sprite_2
			current_footer_sprite = 2
		else: 
			footer_timer.texture = footer_sprite_1
			current_footer_sprite = 1
