extends TextureButton

func _ready():
	connect("pressed", Callable(self, "_on_button_pressed"))

func _on_button_pressed():
	var current_scene = get_tree().current_scene
	print(current_scene.name)
	if current_scene:
		var scene_name = current_scene.name
		match scene_name:
			"GameLobby":
				print("ゲームロビー画面でセーブボタンが押されました")
				save_game_data()
			_:
				print("セーブできる画面ではありません")

# セーブデータを保存する関数
func save_game_data():
	# global.gd からスロット番号を取得
	var slot_number = Global.slot
	if slot_number == -1:
		print("スロット番号が設定されていません")
		return

	# セーブデータファイルのパスを作成
	var file_path = "user://save_slot_" + str(slot_number) + ".dat"

	# セーブデータを準備
	var now = Time.get_datetime_dict_from_system()
	var save_data = {
		"player_name": Global.player_name,
		"chips": Global.chips,  # 現在のチップ数
		"last_save_date": "%04d-%02d-%02d %02d:%02d:%02d" % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]
	}

	# ファイルに保存
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("スロット", slot_number, "にセーブしました。", save_data)
	else:
		print("セーブに失敗しました。")
