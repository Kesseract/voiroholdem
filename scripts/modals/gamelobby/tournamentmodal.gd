extends Window

func _ready():
	$VBoxContainer/Start.connect("pressed", Callable(self, "_on_start_button_pressed"))

	$VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))

	# Windowの×ボタンが押されたときにモーダルを閉じる
	self.connect("close_requested", Callable(self, "_on_close_requested"))

func _on_close_button_pressed():
	hide()

func _on_close_requested():
	queue_free()

func _on_start_button_pressed():

	# モーダルを閉じる
	self.queue_free()

	# 次のゲーム画面に遷移
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
