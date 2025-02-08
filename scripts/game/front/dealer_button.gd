extends Node2D

var time_manager

func _init():
    time_manager = TimeManager.new()

func _ready():
    add_child(time_manager)
