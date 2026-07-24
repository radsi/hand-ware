extends Node

@onready var text = $Vendor/Label
@onready var coin = $Coin
@onready var slot = $Vendor/slot
@onready var wrong = $wrong
@onready var correct = $correct
@onready var items = $Vendor/items
var current_item
var original_item_pos
var can_play_correct = true
var can_play_insert = true

var original_hand_pos = {}
var original_coin_pos

var letters = ["A", "B", "C", "D"]

@export var hand_input = ""

func _ready() -> void:
	set_item()
	original_hand_pos[0] = $CanvasGroup/Hand1.global_position
	original_hand_pos[1] = $CanvasGroup/Hand2.global_position
	original_coin_pos = coin.global_position

func _process(delta: float) -> void:
	print(hand_input)
	if hand_input.length() > 1:
		if hand_input != text.text or coin.visible != false:
			blink_text()
		else:
			if can_play_correct: 
				can_play_correct = false
				correct.play()
				hand_input = ""
				globals.minigame_completed = true
				current_item.global_position = Vector2(540, 540)
				current_item.z_index = 2
			
			if globals.is_single_minigame:
				globals.is_playing_minigame_anim = true
				globals.time_left = globals.game_time
				await get_tree().create_timer(1).timeout
				current_item.z_index = 0
				current_item.hide()
				current_item.global_position = original_item_pos
				can_play_correct = true
				can_play_insert = true
				globals.is_playing_minigame_anim = false
				$CanvasGroup/Hand1.global_position = original_hand_pos[0]
				$CanvasGroup/Hand2.global_position = original_hand_pos[1]
				coin.show()
				coin.global_position = original_coin_pos
				
				set_item()
	
	if coin == null: 
		return
	if slot.global_position.distance_to(coin.global_position) < 24 and can_play_insert:
		can_play_insert = false
		coin.hide()
		$insert.play()

func set_item():
	var number = randi() % 10
	var letter = letters.pick_random()
	text.text = str(number) + letter
				
	current_item = items.get_child(randi() % items.get_children().size())
	current_item.show()
	original_item_pos = current_item.global_position

func blink_text() -> void:
	wrong.play()
	globals.is_playing_minigame_anim = true
	text.hide()
	await get_tree().create_timer(0.1).timeout
	text.show()
	await get_tree().create_timer(0.1).timeout
	text.hide()
	await get_tree().create_timer(0.1).timeout
	text.show()
	globals.is_playing_minigame_anim = false
	hand_input = ""
