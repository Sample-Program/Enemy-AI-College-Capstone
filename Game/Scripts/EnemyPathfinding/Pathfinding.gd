"""
The basic pathfinding that utilizes an A* pathfinding algorithm utilizing the
built in Navigation2D and AStar2D classes. In the future the AStar2D class
will be changed to a manual implementation. The pathfinding algorithm is 
already manual, and not utilizing any external assistance outside of 
utilizing AStar2D.

///////////////////////////////////////////////////////////////////////////////
 ||||  |||  |||||||  ||||||||  ||  ||||||| |||||||
 ||||| |||  ||   ||     ||     ||  ||      ||||||
 ||| |||||  ||   ||     ||     ||  ||      ||
 |||   |||  |||||||     ||     ||  ||||||| |||||||
//////////////////////////////////////////////////////////////////////////////

Most of this file was scrapped for the Navigation Mesh, implemented through
Godot's built in features. Some methods are still used, but most are not.
Maintenance on this file did not continue through to the 2nd semester besides
extremely minor changes to allow seamless integration with the Navigation Mesh.
"""

extends Node2D
class_name Pathfinding #Autocompletion assist

# Fields
@onready var grass_layer: TileMapLayer = $"/root/NavMeshTesting/NavigationRegion2D/Grass"
@onready var wall_layer: TileMapLayer = $"/root/NavMeshTesting/NavigationRegion2D/Grass/Structures"
var astar: AStar2D = AStar2D.new()

var used_rect: Rect2i
var wall_tiles: Array[Vector2i] = []  # Store wall positions

"""
	Generate the navigation map on ready, when everything has loaded in enough to be referenced.
"""
func _ready():
	# Error checking :pray:?
	if not grass_layer:
		push_error("Pathfinding: TileMapLayer not found.")

"""
	This is called for each entity to essentially give them awareness of the map around them, it builds
	specific points that they can walk on (in case specific entities can walk though/over other tiles
	another entity cannot). It builds the A* grid that is accessed to build a path towards any 
	specified point of interest (often the player.)
	@param: the TileMapLayer that the player can walk on
"""
func create_navigation_map(layer: TileMapLayer):
	# Build navigation graph
	grass_layer = layer
	
	# cell info
	used_rect = grass_layer.get_used_rect()
	
	#get wall tiles
	wall_tiles = []
	for tile in wall_layer.get_used_cells():
		if wall_layer.get_cell_tile_data(tile) != null:
			wall_tiles.append(tile)
	
	# Include ALL grass tiles, even those with walls
	var all_grass_tiles = []
	for tile in grass_layer.get_used_cells():
		if grass_layer.get_cell_tile_data(tile) != null:
			all_grass_tiles.append(tile)
	
	# Add all grass tiles to A*
	add_traversable_tiles(all_grass_tiles)
	
	# Connect tiles with 'wall-aware' logic
	connect_tiles_with_wall_avoidance(all_grass_tiles)
	
"""
	Add all traversable tiles to the A* grid
	@param: The (walkable) tiles to add to the A* grid
"""
func add_traversable_tiles(tiles: Array):
	for tile in tiles:
		var id = get_id_for_point(tile)
		astar.add_point(id, tile)
		
"""
	Uses the helper methods to establish a 'wall-awareness' feature to the pathfinding. It connects all
	tiles around the 'center' tile but only after making sure there are no walls. This had to be 
	introduced when no longer removing the grass tiles that walls sit on.
	@param: The tiles the user can walk on that need to be checked and connected
"""
func connect_tiles_with_wall_avoidance(tiles: Array):
	for tile in tiles:
		var id = get_id_for_point(tile)
		
		# Check all directions
		var directions = [
			Vector2i(1, 0),    # Right
			Vector2i(-1, 0),   # Left
			Vector2i(0, 1),    # Down
			Vector2i(0, -1),   # Up
			Vector2i(1, 1),    # Down-Right
			Vector2i(1, -1),   # Up-Right
			Vector2i(-1, 1),   # Down-Left
			Vector2i(-1, -1)   # Up-Left
		]
		# search through all directions
		for direction in directions:
			# get neighboring tile
			var neighbor = tile + direction
			var neighbor_id = get_id_for_point(neighbor)
			
			# Only connect if neighbor exists in A*
			if not astar.has_point(neighbor_id):
				continue
			
			# For diagonal movements, check if both orthogonal paths are clear
			if abs(direction.x) == 1 and abs(direction.y) == 1:
				# Check the two "corner" tiles
				var horiz_neighbor = Vector2i(tile.x + direction.x, tile.y)
				var vert_neighbor = Vector2i(tile.x, tile.y + direction.y)
				
				# Don't allow diagonal if either corner tile has a wall
				if wall_tiles.has(horiz_neighbor) or wall_tiles.has(vert_neighbor):
					continue
			
			# Check if this connection would cut through a wall
			if not is_wall_between(tile, neighbor):
				astar.connect_points(id, neighbor_id, true)
	
"""
	Check if there's a wall between two tiles that would block movement. This was needed because
	some checks without this would assume that two tiles with the center tile between them
	would be unwalkable, for some reason.
	@param tile_a: The first tile to check
	@param tile_b: The second tile to check
"""
func is_wall_between(tile_a: Vector2i, tile_b: Vector2i) -> bool:
	# If either tile has a wall on it, don't connect
	if wall_tiles.has(tile_a) or wall_tiles.has(tile_b):
		return true
	
	# Check for diagonal wall corner cases
	var dx = tile_b.x - tile_a.x
	var dy = tile_b.y - tile_a.y
	
	# Only check for diagonal corner cutting
	if abs(dx) == 1 and abs(dy) == 1:
		# For diagonal movement, check the two corner tiles
		var corner1 = Vector2i(tile_a.x + dx, tile_a.y)
		var corner2 = Vector2i(tile_a.x, tile_a.y + dy)
	
		# Block if BOTH corners have walls (tight corner)
		if wall_tiles.has(corner1) and wall_tiles.has(corner2):
			return true
	
	# (For up/down/left/right), allow it even between walls
	# This fixes the "can't walk between walls" issue -_-
	return false
	
"""
	Get the world position adjusted away from walls. This prevents being lodged in walls, causing pathfinding
	to break. This essentially makes the enemy grab a point near, but not directly on top (or next to) walls.
	@param world_pos: The initial position
	@param search_radius: The radius in which we can consider the new positon to be at
"""
func get_position_away_from_walls(world_pos: Vector2, search_radius: int = 2) -> Vector2:
	var tile_pos = grass_layer.local_to_map(grass_layer.to_local(world_pos))
	
	# If current position is on a wall, find nearest non-wall position
	if wall_tiles.has(tile_pos):
		for radius in range(1, search_radius + 1):
			for dx in range(-radius, radius + 1):
				for dy in range(-radius, radius + 1):
					var check_tile = tile_pos + Vector2i(dx, dy)
					if not wall_tiles.has(check_tile) and astar.has_point(get_id_for_point(check_tile)):
						return grass_layer.to_global(grass_layer.map_to_local(check_tile))
	
	return world_pos
				
				
"""
	This function connects all of the traversable tiles in a 3 x 3 grid (9 tiles total).
	It checks each tile around each tile in the tiles array and adds each potentially traversable
	tile into the astar array.
	@param: The tiles to connect in the 3 x 3 grid
"""
func connect_traversable_tiles(tiles: Array):
	# Connect vertices from the 'center' tile
	for tile in tiles:
		# get the tile id for use
		var id = get_id_for_point(tile)
		# look in a 3x3 range (9 tiles total)
		for x in range(3):
			for y in range(3):
				# grab the target tile
				var target = tile + Vector2i(x - 1, y - 1)
				# make sure we are not connecting the tile to itself (skip iteration if so)
				if tile == target:
					continue
				# if its not itself, get its id
				var target_id = get_id_for_point(target)
				# add it to A* grid if its not ain it
				if not astar.has_point(target_id):
					continue
				# connect the points when done
				astar.connect_points(id, target_id, true)

"""
	This function generates an id for a specific point. It recieves a specified point and gets the
	location from its x and y position on the tiled map and returns its value which will now be that
	specific point's unique id.
	@param: The point to get the id of
"""
func get_id_for_point(point: Vector2i) -> int:
	# Generate a unique ID for the position (tile)
	var x = point.x - used_rect.position.x
	var y = point.y - used_rect.position.y
	return x + y * used_rect.size.x

"""
	This function gets a new path from the start and end vectors. It ensures the tile exists within
	the possible array of tiles (which is generated through add_traversable_tiles). Once it has
	computed a path of world-space points (that the entity can use to walk to) it returns the
	"path_world" which is an array of Vector2s (the world-space points that the entity walks to)
	@param start: The vector (2d point) that is the start of the path
	@param end: The vector (2d point) that is the end of the path
"""
func get_new_path(start: Vector2, end: Vector2) -> Array[Vector2]:
	# Convert the "world-space" positions into tile coordinates
	var start_tile: Vector2i = grass_layer.local_to_map(grass_layer.to_local(start))
	var end_tile: Vector2i = grass_layer.local_to_map(grass_layer.to_local(end))
	# Look up the specified tiles's id for use with A* grid 
	var start_id = get_id_for_point(start_tile)
	var end_id = get_id_for_point(end_tile)
	# Validate the points exist within the A* graph
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return []
	# Obtain the path using the A* algorithm ( f(n) = g(n) + h(n) )
	var path_map = astar.get_point_path(start_id, end_id)
	# Convert the tile coordinates back into world coordinates for the entity
	var path_world: Array[Vector2] = []
	# for each point in our path
	for point in path_map:
		# get the world point via map_to_local (converts tile to coordinates)
		var world_point = grass_layer.to_global(grass_layer.map_to_local(point))
		path_world.append(world_point) # add the coordinates to the path
	# Return the final world-space path for the entity
	return path_world

"""
	Helper method that is used to combat collision with other entities (such as the training dummy
	or other enemies). It checks for any obstacles in its nearby tiles and treats them as
	temporarily unavailable tiles. This mainly used for pathfinding around other enemies that are
	chasing the player.
	@param start: The vector (2d point) that is the start of the path
	@param end: The vector (2d point) that is the end of the path
"""
func avoid_entities(start: Vector2, end: Vector2, obstacles: Array[Vector2i]) -> Array[Vector2]:	
	## Temporarily remove tiles occupied by obstacles
	var disabled = []

	## Disable obstacle tiles
	#for obs_tile in obstacles:
		#var obs_id = get_id_for_point(obs_tile)
		#if astar.has_point(obs_id):
			#astar.set_point_disabled(obs_id, true)
			#disabled.append(obs_id)

	## rebuild path without points
	var path = get_new_path(start, end)

	### Restore the removed points
	#for id in disabled:
		#astar.set_point_disabled(id, false)

	## return the path with the points removed
	return path
