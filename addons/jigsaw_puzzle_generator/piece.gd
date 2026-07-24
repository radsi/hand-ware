extends Sprite2D
class_name Piece

enum STYLE {STRAIGHT, INSET, OUTSET}
enum SIDE {TOP, RIGHT, BOTTOM, LEFT}

var image:Texture2D
var region:Rect2
var sides:Dictionary
var mask:Texture2D

var dragging:bool = false
var mouse_inside = false
var offset_value:Vector2

var group:Array[Piece]
var top_neighbor:Piece = null
var right_neighbor:Piece = null
var bottom_neighbor:Piece = null
var left_neighbor:Piece = null
var target_node = null

var locked = false

func _ready() -> void:
	region_enabled = true
	var shader =  load("res://addons/jigsaw_puzzle_generator/piece.tres")
	
	material = shader.duplicate(false)
	material.set("shader_parameter/mask_texture", mask)
	set_rect_uvs()
	$Area2D/all.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y))
	$left/left.shape.set_size(Vector2(region_rect.size.x/4, region_rect.size.y))
	$right/right.shape.set_size(Vector2(region_rect.size.x/4, region_rect.size.y))
	$top/top.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y/4))
	$bottom/bottom.shape.set_size(Vector2(region_rect.size.x, region_rect.size.y/4))
	$left/left.position = Vector2(-region_rect.size.x/4 + -region_rect.size.x/8, 0)
	$right/right.position = Vector2(region_rect.size.x/4 + region_rect.size.x/8, 0)
	$top/top.position = Vector2(0, -region_rect.size.y/4 + -region_rect.size.y/8)
	$bottom/bottom.position = Vector2(0, region_rect.size.y/4 + region_rect.size.y/8)

func set_rect_uvs():
	var texture_size = texture.get_size()
	var uv_pos = region_rect.position / texture_size
	var uv_size = region_rect.size / texture_size
	var region_uv_data = Vector4(uv_pos.x, uv_pos.y, uv_size.x, uv_size.y)
	material.set("shader_parameter/region_rect_uv_data", region_uv_data)
			
func _process(delta: float) -> void:
	pass
		
func _on_area_2d_mouse_entered() -> void:
	mouse_inside = true
func _on_area_2d_mouse_exited() -> void:
	mouse_inside = false

func next_to_neighbor(check_whole_piece:bool) -> Piece:
	var overlapping:Array[Area2D] = $Area2D.get_overlapping_areas()
	var overlapping_left:Array[Area2D] = $left.get_overlapping_areas()
	var overlapping_top:Array[Area2D] = $top.get_overlapping_areas()
	var overlapping_right:Array[Area2D] = $right.get_overlapping_areas()
	var overlapping_bottom:Array[Area2D] = $bottom.get_overlapping_areas()
	
	if check_whole_piece:
		for area in overlapping:
			var owner = area.get_parent()
		
			if owner == top_neighbor: return top_neighbor
			if owner == right_neighbor: return right_neighbor
			if owner == bottom_neighbor: return bottom_neighbor
			if owner == left_neighbor: return left_neighbor
		return null
			
	for area in overlapping_left:
		if area.get_parent() == left_neighbor:	return left_neighbor
	for area in overlapping_top:
		if area.get_parent() == top_neighbor:	return top_neighbor
	for area in overlapping_right:
		if area.get_parent() == right_neighbor:	return right_neighbor
	for area in overlapping_bottom:
		if area.get_parent() == bottom_neighbor:	return bottom_neighbor
	return null
