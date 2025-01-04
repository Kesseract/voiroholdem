extends Window

var selected_characters = []  # 選択されたキャラクターを保持する変数

func _ready():
	populate_option_button(Global.BET_SIZES, $VBoxContainer/BetSize/OptionButton)

	for category in Global.CHARACTERS.keys():
		for character in Global.CHARACTERS[category]:
			$VBoxContainer/Dealer/OptionButton.add_item(character)
	# スタートボタンとクローズボタンのシグナルを接続
	$VBoxContainer/VBoxContainer/Start.connect("pressed", Callable(self, "_on_start_button_pressed"))
	$VBoxContainer/VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))

	$VBoxContainer/SelectChara/Button.connect("pressed", Callable(self, "_on_select_characters_pressed"))

	# Windowの×ボタンが押されたときにモーダルを閉じる
	self.connect("close_requested", Callable(self, "_on_close_requested"))

func populate_option_button(item, option_button):
	option_button.clear()  # 既存のアイテムをクリア
	for i in range(item.size()):
		option_button.add_item(item[i]["name"], i)  # キャラクター名を追加し、インデックスをIDとして使用

# スタートボタンが押されたときの処理
func _on_start_button_pressed():
	# 入力された値の取得
	# オプションボタンの選択された値の取得 (Godot 4)
	var bet_size_index = $VBoxContainer/BetSize/OptionButton.selected
	# 選択された辞書（bb, sb情報を含む）を取得
	var bet_size = Global.BET_SIZES[bet_size_index]

	# テキストフィールドの値の取得
	var buy_in = $VBoxContainer/AmountValue/LineEdit.text

	# ディーラーオプションの取得
	var dealer_index = $VBoxContainer/Dealer/OptionButton.selected
	var dealer = $VBoxContainer/Dealer/OptionButton.get_item_text(dealer_index)

	print(bet_size, buy_in, dealer, selected_characters)

	# すべての値が正しく入力されているか確認
	if buy_in == "" or  selected_characters.size() == 0:
		print("すべての項目を入力してください")
		return  # 画面遷移しない

	# 値を次のシーンに渡す
	Global.bet_size = bet_size
	Global.buy_in = buy_in
	Global.dealer = dealer
	Global.selected_characters = selected_characters

	Global.chips -= int(buy_in)

	# Gameシーンのインスタンスを生成
	var game_scene = preload("res://scenes/main/Game.tscn").instantiate()

	# インスタンスに値を渡す
	game_scene.set_game_data(bet_size, buy_in, dealer, selected_characters)

	# シーンの切り替え
	get_tree().root.add_child(game_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = game_scene

# クローズボタンが押されたときの処理
func _on_close_button_pressed():
	hide()

# キャラクター選択ボタンが押されたときの処理
func _on_select_characters_pressed():
	var name_modal = preload("res://scenes/modals/gamelobby/CharacterSelectModal.tscn").instantiate()
	add_child(name_modal)
	name_modal.set_exclusive(true)

	# 選択済みのキャラクターをモーダルに渡す
	name_modal.set_selected_characters(selected_characters)

	# シグナル接続して選択されたキャラクター情報を受け取る
	name_modal.connect("characters_selected", Callable(self, "_on_characters_selected"))

	# モーダルを表示
	name_modal.open_modal()

# キャラクター選択モーダルから選ばれたキャラクターを受け取る処理
func _on_characters_selected(selected_characters_from_modal):

	# 選ばれたキャラクターを保持する
	selected_characters = selected_characters_from_modal

	# 選ばれたキャラクター名をLabelに表示
	var character_names = []
	var characters_container = $VBoxContainer/SelectCharaText/ScrollContainer/HBoxContainer
	for character in selected_characters:
		character_names.append(character)
		# カテゴリラベルの追加
		var character_label = Label.new()
		character_label.text = character
		characters_container.add_child(character_label)

# ウィンドウの×ボタンが押されたときの処理
func _on_close_requested():
	queue_free()
