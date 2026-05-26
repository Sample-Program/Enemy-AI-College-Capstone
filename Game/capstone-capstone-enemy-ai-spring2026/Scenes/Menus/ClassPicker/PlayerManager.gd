extends Node

class_name PlayerManager
static var player_data: PlayerClassData
static var player_scene_path: String

static func set_player_class(data: PlayerClassData, scene_path: String):
	player_data = data
	player_scene_path = scene_path
