extends Window

func _ready():
    $VBoxContainer/OK.connect("pressed", Callable(self, "_on_ok_button_pressed"))

    $VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))

    # Windowの×ボタンが押されたときにモーダルを閉じる
    self.connect("close_requested", Callable(self, "_on_close_requested"))

func _on_close_button_pressed():
    hide()

func _on_ok_button_pressed():

    # モーダルを閉じる
    self.queue_free()

    # 次のゲーム画面に遷移
    get_tree().change_scene_to_file("res://scenes/main/GameLobby.tscn")
