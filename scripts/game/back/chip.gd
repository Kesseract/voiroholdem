extends Node
class_name ChipBackend

var seeing
var front
var time_manager

func _init(_seeing):
	seeing = _seeing
	time_manager = TimeManager.new()

	if seeing:
		var front_instance = load("res://scenes/gamecomponents/Chip.tscn")
		front = front_instance.instantiate()

func _ready() -> void:
	add_child(time_manager)