extends TextureButton

func _ready():
	connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed():
	var current_scene = get_tree().current_scene
	if current_scene:
		var scene_name = current_scene.name
		match scene_name:
			"Game":
				print("ゲーム画面で離脱ボタンが押されました")
				# ゲーム離脱確認モーダルを出す
				var config_modal = load("res://scenes/modals/game/GameLeaveModal.tscn").instantiate()
				add_child(config_modal)
				config_modal.set_exclusive(true)
				config_modal.popup_centered()
			"Tutorial":
				print("チュートリアル画面で離脱ボタンが押されました")
				var config_modal = load("res://scenes/modals/tutorial/TutorialLeaveModal.tscn").instantiate()
				add_child(config_modal)
				config_modal.set_exclusive(true)
				config_modal.popup_centered()
				# チュートリアル離脱確認モーダルを出す
			_:
				print("未知の画面で設定ボタンが押されました")
				# デフォルトの動作
