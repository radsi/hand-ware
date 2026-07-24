extends Node

@onready var _match: MatchStick = $Matches/Match

@onready var candles := [
	$Candle,
	$Candle2,
	$Candle3
]

@onready var candle_sfx = $candle

var lit_candles := 0

var original_match_position: Vector2
var original_match_rotation: float

var finishing := false


func _ready():

	original_match_position = _match.global_position
	original_match_rotation = _match.rotation_degrees

	for candle in candles:
		candle.candle_lit.connect(_on_candle_lit)

	_match.candle_touched.connect(_on_match_touches_candle)

func _on_match_touches_candle(candle):

	if not _match.lit:
		return

	candle.light()

func _on_candle_lit():

	if finishing:
		return

	lit_candles += 1

	candle_sfx.play()

	if lit_candles >= candles.size():
		_complete_minigame()

func _complete_minigame():

	finishing = true

	globals.minigame_completed = true

	if globals.is_single_minigame:

		globals.is_playing_minigame_anim = true

		await get_tree().create_timer(1.5).timeout

		globals.is_playing_minigame_anim = false
		globals.time_left = globals.game_time

		reset()

func reset():

	lit_candles = 0
	finishing = false

	for candle in candles:
		candle.reset()

	_match.reset()

	_match.global_position = original_match_position
	_match.rotation_degrees = original_match_rotation
