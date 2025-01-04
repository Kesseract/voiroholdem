extends Window

func _ready():
	populate_option_button(Global.BET_SIZES, $VBoxContainer/BetSize/OptionButton)

	for category in Global.CHARACTERS.keys():
		for character in Global.CHARACTERS[category]:
			$VBoxContainer/Dealer/OptionButton.add_item(character)
	for category in Global.CHARACTERS.keys():
		for character in Global.CHARACTERS[category]:
			$VBoxContainer/SelectChara/OptionButton2.add_item(character)
	# スタートボタンとクローズボタンのシグナルを接続
	$VBoxContainer/VBoxContainer/Start.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$VBoxContainer/VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))

	# Windowの×ボタンが押されたときにモーダルを閉じる
	self.connect("close_requested", Callable(self, "_on_close_requested"))

func populate_option_button(item, option_button_place):
	var option_button = option_button_place  # OptionButtonノードを取得

	option_button.clear()  # 既存のアイテムをクリア

	# Global.CHARACTERS からキャラクター名を追加し、IDも設定
	for i in range(item.size()):
		var character = item[i]
		option_button.add_item(character["name"], i)  # キャラクター名を追加し、インデックスをIDとして使用

func _on_close_button_pressed():
	hide()

func _on_close_requested():
	queue_free()

func _on_start_button_pressed():

	# モーダルを閉じる
	self.queue_free()

	# 次のゲーム画面に遷移
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
