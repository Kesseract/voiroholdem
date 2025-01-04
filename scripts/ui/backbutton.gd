extends TextureButton

func _ready():
	connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed():
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		match scene_name:
			"Save":
				# ゲーム離脱確認モーダルを出す
				var config_modal = load("res://scenes/modals/save/TitleMoveConfirmModal.tscn").instantiate()
				add_child(config_modal)
				config_modal.set_exclusive(true)
				config_modal.popup_centered()
			_:
				print("未知の画面で戻るボタンが押されました")
				# デフォルトの動作
