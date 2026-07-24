extends Grabbable

@onready var shine: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	super._ready()
	
	shine.play()

func _on_grabbed(_is_left: bool) -> void:
	super._on_grabbed(_is_left)
	
	shine.hide()
