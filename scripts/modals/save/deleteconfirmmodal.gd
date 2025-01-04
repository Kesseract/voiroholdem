extends Window

var save_file_prefix = "user://save_slot_"
var save_file_extension = ".dat"

var slot_number = -1

signal delete_confirmed(slot_number)

func _ready():

    #Globalからプレイヤー名取得
    $VBoxContainer/Name.text = "Name:" + Global.player_name
    $VBoxContainer/Chips.text = "Chips:" + str(Global.chips)
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
    # セーブデータ削除処理
    emit_signal("delete_confirmed", slot_number)
    queue_free()
