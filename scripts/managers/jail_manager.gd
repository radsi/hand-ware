extends Node

@onready var walls: Array[BreakableWall] = [
	$jail/Line,
	$jail/Line2,
	$jail/Line3,
	$jail/Line4,
]

func _ready() -> void:
	_pick_random_breakable_wall()


func _pick_random_breakable_wall() -> void:
	for wall in walls:
		wall.breakable = false
		if not wall.wall_broken.is_connected(_on_wall_broken):
			wall.wall_broken.connect(_on_wall_broken)

	walls.pick_random().breakable = true


func _on_wall_broken(wall: Node) -> void:
	globals.game_score += 1
	if globals.is_single_minigame:
		globals.is_playing_minigame_anim = true
		await get_tree().create_timer(1.5).timeout
		globals.is_playing_minigame_anim = false
		globals.time_left = globals.game_time
		for w in walls:
			w.reset()
		_pick_random_breakable_wall()
		$CanvasGroup/Hand1.position = Vector2(-50, 100)
		$CanvasGroup/Hand2.position = Vector2(50, 100)
