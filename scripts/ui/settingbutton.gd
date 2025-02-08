extends TextureButton

func _ready():
    connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed():
    var config_modal = load("res://scenes/modals/config/ConfigModal.tscn").instantiate()
    add_child(config_modal)
    # config_modal.set_exclusive(true)
    config_modal.popup_centered()
