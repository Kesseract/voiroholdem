extends Control

func _ready():
	$VBoxContainer/Start.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$VBoxContainer/Exit.connect("pressed", Callable(self, "_on_exit_button_pressed"))

func _on_start_button_pressed():
	print("Start button pressed")
	var result = get_tree().change_scene_to_file("res://scenes/main/Save.tscn")
	if result != OK:
		print("Failed to change scene:", result)

func _on_config_button_pressed():
	print("Config button pressed")
	var config_modal = load("res://scenes/modals/config/TitleConfigModal.tscn").instantiate()
	add_child(config_modal)
	config_modal.set_exclusive(true)
	config_modal.popup_centered()

func _on_exit_button_pressed():
	get_tree().quit()
