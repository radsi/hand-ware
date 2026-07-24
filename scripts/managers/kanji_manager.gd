extends Node

var posible_kanjis = ["う", "ロ", "ミ", "二", "ウ", "ア", "ド", "人", "ら", "ん", "ム", "⭐"]

@onready var subvp = $SubViewportContainer/SubViewport
@onready var label: Label = $SubViewportContainer/SubViewport/Label
@onready var brush: Sprite2D = $bottle/Brush
@onready var ink_deco = $ink

var kanji_image: Image
var draw_image: Image
var draw_tex: ImageTexture

var brush_size := 12
var can_calculate := false
var wrong_pixels: Array = []
var wrong_pixels_dict := {}

var can_add_kanji := true

var setting_kanji := false

func _ready() -> void:
	globals.is_playing_minigame_anim = true

	brush.brush_dragged.connect(_on_brush_dragged)
	brush.brush_released.connect(_on_brush_released)

	label.text = posible_kanjis.pick_random()

	if globals.using_gamepad:
		brush_size = 16

	_setup_kanji()

func _on_brush_dragged(pos: Vector2) -> void:
	_draw_at(pos)
	can_calculate = true


func _on_brush_released() -> void:
	if not can_calculate or setting_kanji:
		return

	can_calculate = false

	var accuracy = calculate_accuracy()
	print(accuracy)

	if accuracy < 80:
		return

	setting_kanji = true

	for item in wrong_pixels:
		var pos = item["pos"]
		draw_image.set_pixelv(pos, Color(0,0,0,0))

	wrong_pixels.clear()
	wrong_pixels_dict.clear()

	draw_tex.update(draw_image)

	ink_deco.show()
	globals.minigame_completed = true
	label.hide()
	$pencil.play()
	
	globals.game_score += 1

	if globals.is_single_minigame:
		if can_add_kanji:
			can_add_kanji = false

		if globals.game_score >= 8:
			globals._unlock_minigame("Candle")

		globals.is_playing_minigame_anim = true
		globals.time_left = globals.game_time

		await get_tree().create_timer(2).timeout

		label.text = posible_kanjis.pick_random()
		label.show()
		globals.is_playing_minigame_anim = false
		ink_deco.hide()
		can_add_kanji = true

		await _setup_kanji()

func _setup_kanji() -> void:
	subvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	kanji_image = subvp.get_texture().get_image()

	draw_image = Image.create(
		kanji_image.get_width(),
		kanji_image.get_height(),
		false,
		Image.FORMAT_RGBA8
	)

	draw_image.fill(Color(1,1,1,0))

	if draw_tex == null:
		draw_tex = ImageTexture.create_from_image(draw_image)

		var sprite = Sprite2D.new()
		sprite.texture = draw_tex
		sprite.centered = false
		sprite.position = Vector2.ZERO
		add_child(sprite)
	else:
		draw_tex.update(draw_image)
	
	setting_kanji = false


func _draw_at(pos: Vector2) -> void:
	var radius_sq = brush_size * brush_size

	for x in range(-brush_size, brush_size + 1):
		for y in range(-brush_size, brush_size + 1):
			if x * x + y * y <= radius_sq:
				var px = int(pos.x) + x
				var py = int(pos.y) + y

				if px >= 0 and py >= 0 and px < draw_image.get_width() and py < draw_image.get_height():
					draw_image.set_pixel(px, py, Color.BLACK)

					var kc = kanji_image.get_pixel(px, py)

					var kanji_pixel = kc.a > 0.1 and kc.get_luminance() > 0.9

					if not kanji_pixel:
						wrong_pixels.append({
							"pos": Vector2(px, py)
						})

	draw_tex.update(draw_image)


func calculate_accuracy() -> float:
	if not kanji_image or not draw_image:
		return 0.0

	var w = kanji_image.get_width()
	var h = kanji_image.get_height()

	var total_pixels := 0
	var correct_pixels := 0

	for x in range(w):
		for y in range(h):
			var kc = kanji_image.get_pixel(x, y)
			var dc = draw_image.get_pixel(x, y)

			if kc.a < 0.1:
				continue

			var kanji_pixel = kc.a > 0.1 and kc.get_luminance() > 0.9
			var drawn_pixel = dc.a > 0.1 and dc.get_luminance() < 0.5

			if kanji_pixel:
				total_pixels += 1

				if drawn_pixel:
					correct_pixels += 1

	if total_pixels == 0:
		return 0.0

	return float(correct_pixels) / float(total_pixels) * 100.0
