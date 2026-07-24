extends HANDS

@export var snap_radius: float = 40.0

@onready var pieces_pos: Node = $"../pieces_pos"


func _find_grabbable_under(hand: Node2D) -> Node:
	for node in get_tree().get_nodes_in_group("grabbable"):
		if node == attached_left or node == attached_right:
			continue
		if not (node is Node2D) or not node.visible:
			continue
		if "locked" in node and node.locked:
			continue
		if not ("mouse_inside" in node):
			continue
		if node.mouse_inside:
			return node
	return null


func _release_grabbable(obj: Node, hand: Node2D, is_left: bool) -> void:
	_try_snap_to_slot(obj)
	super._release_grabbable(obj, hand, is_left)


func _try_snap_to_slot(piece: Node) -> void:
	if pieces_pos == null:
		return
	if not ("target_node" in piece) or not ("locked" in piece):
		return
	if piece.locked:
		return

	var slots = pieces_pos.get_children()
	if piece.target_node < 0 or piece.target_node >= slots.size():
		return

	var target_slot: Node2D = slots[piece.target_node]
	var dist = piece.global_position.distance_to(target_slot.global_position)

	if dist <= snap_radius:
		piece.global_position = target_slot.global_position
		piece.locked = true
		if piece.has_method("_on_snapped"):
			piece._on_snapped()
