extends Control

var save_file_prefix = "user://save_slot_"
var save_file_extension = ".dat"

# セーブスロットのノード
@onready var save_slots = [$SaveSlot1, $SaveSlot2, $SaveSlot3]

func _ready():
	# 各セーブスロットのデータをロードして表示
	$SaveSlot1/NamePlateEmpty.connect("pressed", Callable(self, "_on_nameplateempty_pressed").bind(1))
	$SaveSlot2/NamePlateEmpty.connect("pressed", Callable(self, "_on_nameplateempty_pressed").bind(2))
	$SaveSlot3/NamePlateEmpty.connect("pressed", Callable(self, "_on_nameplateempty_pressed").bind(3))
	$SaveSlot1/NamePlateFill.connect("pressed", Callable(self, "_on_nameplatefill_pressed").bind(1))
	$SaveSlot2/NamePlateFill.connect("pressed", Callable(self, "_on_nameplatefill_pressed").bind(2))
	$SaveSlot3/NamePlateFill.connect("pressed", Callable(self, "_on_nameplatefill_pressed").bind(3))
	$SaveSlot1/NamePlateFill/Delete.connect("pressed", Callable(self, "_on_delete_pressed").bind(1))
	$SaveSlot2/NamePlateFill/Delete.connect("pressed", Callable(self, "_on_delete_pressed").bind(2))
	$SaveSlot3/NamePlateFill/Delete.connect("pressed", Callable(self, "_on_delete_pressed").bind(3))
	for i in range(save_slots.size()):
		var slot = i + 1
		check_save_data(slot, save_slots[i])

# セーブデータの有無を確認し、表示を切り替える
func check_save_data(slot: int, save_slot: Node):
	var file_path = save_file_prefix + str(slot) + save_file_extension

	if FileAccess.file_exists(file_path):
		# ファイルが存在する場合、データをロードして表示
		var data = load_game(slot)
		update_nameplate(save_slot, data)
		save_slot.get_node("NamePlateEmpty").hide()
		save_slot.get_node("NamePlateFill").show()
	else:
		# ファイルが存在しない場合、セーブ作成ボタンを表示
		save_slot.get_node("NamePlateEmpty").show()
		save_slot.get_node("NamePlateFill").hide()

# スロット情報を表示
func update_nameplate(save_slot: Node, data: Dictionary):
	var name_label = save_slot.get_node("NamePlateFill/Name")
	var chips_label = save_slot.get_node("NamePlateFill/Chips")
	var last_played_label = save_slot.get_node("NamePlateFill/LastPlayed")

	name_label.text = "Name: " + data["player_name"]
	chips_label.text = "Chips: " + str(data["chips"])
	last_played_label.text = "Last Played: " + data["last_save_date"]

# 新しいセーブデータを作成するボタンが押されたとき
func _on_nameplateempty_pressed(slot_number):
	var name_modal = preload("res://scenes/modals/save/NameSettingModal.tscn").instantiate()
	add_child(name_modal)
	name_modal.set_exclusive(true)
	name_modal.popup_centered()

	# モーダルのシグナルを接続して、名前を受け取る
	name_modal.connect("name_entered", Callable(self, "_on_name_entered").bind(slot_number))

# モーダルから名前が入力されたときに呼び出される関数
func _on_name_entered(player_name, slot_number):
	var now = Time.get_datetime_dict_from_system()
	var default_data = {
		"player_name": player_name,
		"chips": 1000,
		"last_save_date": "%04d-%02d-%02d %02d:%02d:%02d" % [now["year"], now["month"], now["day"], now["hour"], now["minute"], now["second"]]
	}
	save_game(slot_number, default_data)
	print("New save data created for slot", slot_number)
	# 作成後、表示を更新
	check_save_data(slot_number, save_slots[slot_number - 1])

func _on_nameplatefill_pressed(slot_number):
	# セーブデータをロード
	var data = load_game(slot_number)
	if data:
		# global.gdの変数にプレイヤー名とチップ数を設定
		Global.slot = slot_number
		Global.player_name = data["player_name"]
		Global.chips = data["chips"]

		var name_modal = preload("res://scenes/modals/save/LoadConfirmModal.tscn").instantiate()
		add_child(name_modal)
		name_modal.set_exclusive(true)
		name_modal.popup_centered()
	else:
		print("No save data found for slot", slot_number)

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

# セーブデータを削除するボタンが押されたとき
func _on_delete_pressed(slot_number):
	# セーブデータをロード
	var data = load_game(slot_number)
	if data:
		# global.gdの変数にプレイヤー名とチップ数を設定
		Global.slot = slot_number
		Global.player_name = data["player_name"]
		Global.chips = data["chips"]

		var name_modal = preload("res://scenes/modals/save/DeleteConfirmModal.tscn").instantiate()
		add_child(name_modal)
		name_modal.set_exclusive(true)
		name_modal.popup_centered()

		name_modal.slot_number = slot_number

		# 確認モーダルのシグナルを接続
		name_modal.connect("delete_confirmed", Callable(self, "_on_delete_confirmed"))

	else:
		print("No save data found for slot", slot_number)

func _on_delete_confirmed(slot_number):
	print("_on_delete_confirm")
	print(slot_number)
	# 実際にセーブデータを削除する処理
	var file_path = save_file_prefix + str(slot_number) + save_file_extension
	if FileAccess.file_exists(file_path):
		var dir_access = DirAccess.open("user://")
		if dir_access and dir_access.remove(file_path) == OK:
			print("Save data deleted for slot", slot_number)
			check_save_data(slot_number, save_slots[slot_number - 1])  # 表示更新
		else:
			print("Failed to delete save data for slot", slot_number)
	else:
		print("No save data found to delete for slot", slot_number)

# セーブデータをロードする関数
func load_game(slot: int) -> Dictionary:
	var file_path = save_file_prefix + str(slot) + save_file_extension
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file:
		var data = file.get_var()
		file.close()
		return data

	return {}