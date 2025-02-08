extends Window

func _ready():

    #Globalからプレイヤー名取得
    $VBoxContainer/Name.text = "Name:" + Global.player_name
    # OKボタンが押されたときの処理を設定
    $VBoxContainer/OK.connect("pressed", Callable(self, "_on_ok_pressed"))
    # Close ボタンのシグナル接続
    $VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))
    # Windowの×ボタンが押されたときにモーダルを閉じる
    self.connect("close_requested", Callable(self, "_on_close_requested"))

func _on_close_button_pressed():
    hide()

func _on_close_requested():
    queue_free()

func _on_ok_pressed():
    # ゲームロビー画面に移動
    get_tree().change_scene_to_file("res://scenes/main/GameLobby.tscn")
