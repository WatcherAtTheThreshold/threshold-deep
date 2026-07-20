class_name DungeonGenerator
extends RefCounted

## Generates a dungeon as a grid of characters — the same shape of
## data as the old hand-typed MAP:
##   "#"  stone wall
##   "W"  wooden wall (breakable: two hits open it into floor)
##   "."  stone floor
##   ","  wooden floor (may collapse into a hole behind the player)
##
## Algorithm (rooms + corridors):
##   1. Try to place a number of random rectangular rooms, keeping
##      only ones that don't touch a room we already placed.
##   2. Walk the room list in order, carving an L-shaped corridor
##      from each room's center to the previous room's center.
##   3. Everything not carved stays wall.
##   4. Some rooms get a patch of wooden flooring; some walls that
##      separate two walkable cells turn wooden (secret shortcuts).

const WOOD_WALL_CHANCE := 0.12
const WOOD_FLOOR_ROOM_CHANCE := 0.35
const DIRS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


static func generate(width: int, height: int, room_attempts: int, rng: RandomNumberGenerator, with_secret := false) -> Dictionary:
	var rooms: Array[Rect2i] = []
	for i in room_attempts:
		# The second room placed is always arena-sized, so boss floors
		# never stage their fight in a closet.
		var big := rooms.size() == 1
		var w := rng.randi_range(6, 8) if big else rng.randi_range(3, 7)
		var h := rng.randi_range(6, 8) if big else rng.randi_range(3, 7)
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

	# Wooden floor patches: a sub-rectangle of planks in some rooms.
	var wood_floor := {}
	for room in rooms:
		if rng.randf() < WOOD_FLOOR_ROOM_CHANCE:
			var pw := rng.randi_range(2, room.size.x)
			var ph := rng.randi_range(2, room.size.y)
			var px := room.position.x + rng.randi_range(0, room.size.x - pw)
			var py := room.position.y + rng.randi_range(0, room.size.y - ph)
			for cy in range(py, py + ph):
				for cx in range(px, px + pw):
					wood_floor[Vector2i(cx, cy)] = true

	# Every room keeps a stone anchor at its centre — proven ground
	# for pedestals, plates, and hatches, so nothing ever has to
	# convert wood to stone after the solvability proof runs.
	for room in rooms:
		wood_floor.erase(room.get_center())
		wood_floor.erase(room.get_center() + Vector2i(1, 0))

	# Wooden walls: only where a wall separates two walkable cells,
	# so breaking one always opens a real shortcut.
	var wood_wall := {}
	for cy in range(1, height - 1):
		for cx in range(1, width - 1):
			var c := Vector2i(cx, cy)
			if floor_cells.has(c):
				continue
			var ns: bool = floor_cells.has(c + Vector2i.UP) \
					and floor_cells.has(c + Vector2i.DOWN)
			var ew: bool = floor_cells.has(c + Vector2i.LEFT) \
					and floor_cells.has(c + Vector2i.RIGHT)
			if (ns or ew) and rng.randf() < WOOD_WALL_CHANCE:
				wood_wall[c] = true

	# Collapse solvability (docs/level-gen-fix.md): in the worst case —
	# every wooden floor cell already a hole, breakable walls treated
	# as passable — the dungeon must stay fully connected from spawn.
	# Demote wooden cells to stone until it is; then no sequence of
	# collapses can ever trap the player.
	var demoted: Array[Vector2i] = []
	var spawn := rooms[0].get_center()
	if wood_floor.has(spawn):
		wood_floor.erase(spawn)
		demoted.append(spawn)
	while true:
		var passable := {}
		for c: Vector2i in floor_cells:
			if not wood_floor.has(c):
				passable[c] = true
		for c: Vector2i in wood_wall:
			passable[c] = true
		var reachable := _flood(spawn, passable)
		var stranded := {}
		for c: Vector2i in floor_cells:
			if not wood_floor.has(c) and not reachable.has(c):
				stranded[c] = true
		if stranded.is_empty():
			break
		var bridge := _pick_bridge(wood_floor, reachable, stranded)
		if bridge == Vector2i(-1, -1):
			break  # cannot happen: the carved floor graph is connected
		wood_floor.erase(bridge)
		demoted.append(bridge)

	# The commoner secret (docs/roadmap.md): a small sealed chamber
	# grafted outside walkable space — there from the start, found
	# by a buried trigger, opened by sliding one wall cell. The
	# solvability proof ignores sealed space, so this runs after it.
	var secret_room: Array[Vector2i] = []
	var secret_door := Vector2i(-1, -1)
	var secret_plank := Vector2i(-1, -1)
	if with_secret and wood_floor.size() > 0:
		var floors: Array[Vector2i] = []
		for c: Vector2i in floor_cells:
			floors.append(c)
		for attempt in 300:
			var f: Vector2i = floors[rng.randi_range(0, floors.size() - 1)]
			var d: Vector2i = DIRS[rng.randi_range(0, 3)]
			var door := f + d
			var base := door + d
			var perp := Vector2i(d.y, d.x)
			var cells: Array[Vector2i] = [
				base, base + perp, base + d, base + d + perp]
			if floor_cells.has(door) or wood_wall.has(door):
				continue
			var ok := true
			for c in cells:
				if c.x < 1 or c.y < 1 or c.x > width - 2 \
						or c.y > height - 2 \
						or floor_cells.has(c) or wood_wall.has(c):
					ok = false
					break
			if not ok:
				continue
			# Sealed means sealed: no chamber cell may share an edge
			# with walkable space — the door wall is the only seam.
			for c in cells:
				for dd in DIRS:
					if floor_cells.has(c + dd):
						ok = false
			if not ok:
				continue
			for c in cells:
				floor_cells[c] = true
			secret_room = cells
			secret_door = door
			# The trigger hides under one wooden plank somewhere on
			# the floor; breaking it reveals stone, not void.
			var woods: Array[Vector2i] = []
			for c: Vector2i in wood_floor:
				woods.append(c)
			secret_plank = woods[rng.randi_range(0, woods.size() - 1)]
			break

	# Render the sets out to rows of characters.
	var map: Array[String] = []
	for cy in height:
		var row := ""
		for cx in width:
			var c := Vector2i(cx, cy)
			if floor_cells.has(c):
				row += "," if wood_floor.has(c) else "."
			elif wood_wall.has(c):
				row += "W"
			else:
				row += "#"
		map.append(row)

	return {"map": map, "rooms": rooms, "demoted": demoted,
			"secret_room": secret_room, "secret_door": secret_door,
			"secret_plank": secret_plank}


static func _flood(start: Vector2i, passable: Dictionary) -> Dictionary:
	var reached := {}
	var queue: Array[Vector2i] = [start]
	reached[start] = true
	while queue.size() > 0:
		var c: Vector2i = queue.pop_back()
		for d in DIRS:
			var n := c + d
			if passable.has(n) and not reached.has(n):
				reached[n] = true
				queue.append(n)
	return reached


static func _pick_bridge(wood_floor: Dictionary, reachable: Dictionary, stranded: Dictionary) -> Vector2i:
	# Prefer a wooden cell touching both sides of the cut; otherwise
	# any wooden cell on the reachable frontier (walks wooden chains
	# one cell per pass).
	var frontier := Vector2i(-1, -1)
	for c: Vector2i in wood_floor:
		var touches_reachable := false
		var touches_stranded := false
		for d in DIRS:
			var n: Vector2i = c + d
			if reachable.has(n):
				touches_reachable = true
			if stranded.has(n):
				touches_stranded = true
		if touches_reachable and touches_stranded:
			return c
		if touches_reachable and frontier == Vector2i(-1, -1):
			frontier = c
	return frontier


static func _carve_h(cells: Dictionary, x1: int, x2: int, y: int) -> void:
	for x in range(mini(x1, x2), maxi(x1, x2) + 1):
		cells[Vector2i(x, y)] = true


static func _carve_v(cells: Dictionary, y1: int, y2: int, x: int) -> void:
	for y in range(mini(y1, y2), maxi(y1, y2) + 1):
		cells[Vector2i(x, y)] = true
