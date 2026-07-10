class_name DungeonGenerator
extends RefCounted

## Generates a dungeon as a grid of "#" (wall) and "." (floor) —
## the same shape of data as the old hand-typed MAP.
##
## Algorithm (rooms + corridors):
##   1. Try to place a number of random rectangular rooms, keeping
##      only ones that don't touch a room we already placed.
##   2. Walk the room list in order, carving an L-shaped corridor
##      from each room's center to the previous room's center.
##   3. Everything not carved stays wall.


static func generate(width: int, height: int, room_attempts: int, rng: RandomNumberGenerator) -> Dictionary:
	var rooms: Array[Rect2i] = []
	for i in room_attempts:
		var w := rng.randi_range(3, 7)
		var h := rng.randi_range(3, 7)
		var x := rng.randi_range(1, width - w - 1)
		var y := rng.randi_range(1, height - h - 1)
		var room := Rect2i(x, y, w, h)
		# grow(1) demands a one-cell wall ring, so rooms never merge.
		var overlaps := false
		for other in rooms:
			if room.grow(1).intersects(other):
				overlaps = true
				break
		if not overlaps:
			rooms.append(room)

	# Carve rooms into a set of floor cells.
	var floor_cells := {}
	for room in rooms:
		for cy in range(room.position.y, room.end.y):
			for cx in range(room.position.x, room.end.x):
				floor_cells[Vector2i(cx, cy)] = true

	# Corridors: horizontal leg then vertical, or the other way
	# around, chosen by coin flip so bends vary.
	for i in range(1, rooms.size()):
		var a := rooms[i - 1].get_center()
		var b := rooms[i].get_center()
		if rng.randf() < 0.5:
			_carve_h(floor_cells, a.x, b.x, a.y)
			_carve_v(floor_cells, a.y, b.y, b.x)
		else:
			_carve_v(floor_cells, a.y, b.y, a.x)
			_carve_h(floor_cells, a.x, b.x, b.y)

	# Render the set out to rows of "#" and ".".
	var map: Array[String] = []
	for cy in height:
		var row := ""
		for cx in width:
			row += "." if floor_cells.has(Vector2i(cx, cy)) else "#"
		map.append(row)

	return {"map": map, "rooms": rooms}


static func _carve_h(cells: Dictionary, x1: int, x2: int, y: int) -> void:
	for x in range(mini(x1, x2), maxi(x1, x2) + 1):
		cells[Vector2i(x, y)] = true


static func _carve_v(cells: Dictionary, y1: int, y2: int, x: int) -> void:
	for y in range(mini(y1, y2), maxi(y1, y2) + 1):
		cells[Vector2i(x, y)] = true
