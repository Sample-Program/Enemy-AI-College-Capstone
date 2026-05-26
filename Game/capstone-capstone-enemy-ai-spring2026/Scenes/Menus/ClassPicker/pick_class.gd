extends Control

# Preload class data resources
var samurai_data = preload("res://Entities/Player/PlayerClasses/Samurai.tres")
var ranger_data = preload("res://Entities/Player/PlayerClasses/Ranger.tres")
var pyro_data = preload("res://Entities/Player/PlayerClasses/Pyromancer.tres")

# Preload scenes
var samurai_scene_path = "res://Entities/Player/PlayerClasses/Samurai.tscn"
var ranger_scene_path = "res://Entities/Player/PlayerClasses/Ranger.tscn"
var pyro_scene_path = "res://Entities/Player/PlayerClasses/Pyromancer.tscn"

const BUTTON_ICON_SIZE = Vector2(128, 128)

@onready var select_class: VBoxContainer = $SelectClass
@onready var samurai_btn = $SelectClass/CenterContainer/PlayerPickerHBox/SamuraiPanelContainer/SamuraiVBox/SamuraiImgButton
@onready var ranger_btn  = $SelectClass/CenterContainer/PlayerPickerHBox/RangerPanelContainer/RangerVBox/RangerImgButton
@onready var pyro_btn  = $SelectClass/CenterContainer/PlayerPickerHBox/PyroPanelContainer/PyroVBox/PyroImgButton
@onready var center_container = $SelectClass/CenterContainer
@onready var picker = $SelectClass/CenterContainer/PlayerPickerHBox
@onready var select_label = $SelectClass/SelectClassLabel

func _ready() -> void:
	await get_tree().process_frame
	select_class.alignment = BoxContainer.ALIGNMENT_CENTER
	picker.position = (get_viewport_rect().size - picker.size) / 2
	select_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	select_label.position.y = picker.position.y - select_label.size.y - 10
	_equalize_button_icons()

func _equalize_button_icons() -> void:
	for btn in [samurai_btn, ranger_btn, pyro_btn]:
		btn.custom_minimum_size = BUTTON_ICON_SIZE
		btn.ignore_texture_size = true
		btn.stretch_mode        = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

func _on_samurai_pressed() -> void:
	PlayerManager.set_player_class(samurai_data, samurai_scene_path)
	get_tree().change_scene_to_file("res://FirstDungeon.tscn")
	queue_free()

func _on_ranger_pressed() -> void:
	PlayerManager.set_player_class(ranger_data, ranger_scene_path)
	get_tree().change_scene_to_file("res://FirstDungeon.tscn")
	queue_free()

func _on_pyro_pressed() -> void:
	PlayerManager.set_player_class(pyro_data, pyro_scene_path)
	get_tree().change_scene_to_file("res://FirstDungeon.tscn")
	queue_free()
