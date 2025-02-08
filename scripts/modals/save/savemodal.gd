extends Window

@onready var slot_number = Global.slot_number

var save_file_prefix = "user://save_slot_"
var save_file_extension = ".dat"

func _ready():

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

    # 現在Globalにおいてあるslot_numberに、チップ数と現在時刻をセーブする
    var now = Time.get_datetime_dict_from_system()
    var data = {
        "player_name": Global.player_name,
        "chips": Global.chips,
        "last_save_date": "%04d-%02d-%02d %02d:%02d:%02d" % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]
    }
    save_game(slot_number, data)

    # モーダルを閉じる
    queue_free()


# セーブデータを保存する関数
func save_game(slot: int, data: Dictionary):
    var file_path = save_file_prefix + str(slot) + save_file_extension
    var file = FileAccess.open(file_path, FileAccess.WRITE)

    if file:
        file.store_var(data)
        file.close()
        print("Slot", slot, "data saved successfully.")
    else:
        print("Failed to save slot", slot, "data.")