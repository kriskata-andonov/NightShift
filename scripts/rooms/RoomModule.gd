class_name RoomModule
extends Node3D

# Size of the room in 12x12m grid units
@export var grid_size: Vector2i = Vector2i(1, 1)

# Returns available sockets based on Marker3D nodes under the "Sockets" node.
# Expected naming format: "Socket_X_Y_DIR"
# X, Y: Cell offset (e.g. 0_0)
# DIR: N, S, E, W
func get_sockets() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var sockets_node = get_node_or_null("Sockets")
	if not sockets_node:
		return result
		
	for child in sockets_node.get_children():
		if child is Marker3D:
			var parts = child.name.split("_")
			if parts.size() >= 4:
				var cell_x = int(parts[1])
				var cell_y = int(parts[2])
				var dir_str = parts[3]
				var dir = Vector2i.ZERO
				
				if dir_str == "N": dir = Vector2i(0, -1)
				elif dir_str == "S": dir = Vector2i(0, 1)
				elif dir_str == "E": dir = Vector2i(1, 0)
				elif dir_str == "W": dir = Vector2i(-1, 0)
				
				result.append({
					"node": child,
					"cell": Vector2i(cell_x, cell_y),
					"dir": dir,
					"local_pos": child.position
				})
	return result
