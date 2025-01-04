extends Control

# 表示を管理する親ノード（Labelなど）
@onready var hBoxContainer = $ScrollContainer/VBoxContainer/HBoxContainer.get_children()
@onready var dealer = hBoxContainer[0]
@onready var dealer_button = $ScrollContainer/VBoxContainer/Seat/Dealer/DealerButton/DealerButtonTex

@onready var pots = hBoxContainer.slice(1)
@onready var front_pot = $ScrollContainer/VBoxContainer/Pot/Pot

@onready var animation_place = {}

@onready var burn_card = $ScrollContainer/VBoxContainer/Burn.get_children()
@onready var burn_card_place = {}

@onready var community_card = $ScrollContainer/VBoxContainer/Community.get_children()
@onready var community_card_place = {}

# ボタンの参照
@onready var fold_button = $FoldButton
@onready var check_call_button = $CheckCallButton
@onready var bet_raise_button = $BetRaiseButton

# スライダーとテキストフィールドの参照
@onready var bet_size_slider = $BetSize/HSlider
@onready var bet_size_input = $BetSize/HBoxContainer/LineEdit

#TODO 次のタスク
# リファクタリング
# 細かいステップごとに止める機能の実装
# アニメーションの実装

# 必要な値
var bet_size = { "name": "table_1 bb:2 sb:1", "bb": 2, "sb": 1 }
var buy_in = 100
var dealer_name = "ずんだもん"
var selected_cpus = ["四国めたん", "ずんだもん", "春日部つむぎ", "雨晴はう"]

var table_backend
var player_backend
var dealer_backend

var phase_timer

# プレイヤーのベット比率。単位はチップ数
var player_bet_size = 50

func _ready():
	# nodeの初期設定
	_initialize_node()

	# ボタン、スライダー、インプットの初期設定
	_initialize_ui()

	# バックエンドの初期設定
	_initialize_backend()

	# シグナルの初期設定
	_initialize_signals()

	# タイマー作成
	_initialize_timers()

	# ゲームを開始
	await table_backend.game_process.advance_phase()

func _initialize_node():
	# 座席の親ノードを取得
	var seat_container = $ScrollContainer/VBoxContainer/Seat.get_children()

	# 各座席の情報を動的に作成
	for seat_node in seat_container:
		var seat_name = seat_node.name  # 座席名を取得 (e.g., "Seat1", "Seat2")
		animation_place[seat_name] = {
			"Instance": seat_node,
			"Label": seat_node.get_node("Label"),
			"Hand": {
				"Card1": seat_node.get_node("Hand/Card1"),
				"Card2": seat_node.get_node("Hand/Card2"),
			},
			"Chip": seat_node.get_node("Chip"),
			"Bet": seat_node.get_node("Bet"),
			"DealerButton": seat_node.get_node("DealerButton"),
		}

	# ディーラーも追加
	var dealer_node = $ScrollContainer/VBoxContainer/Seat/Dealer
	animation_place["Dealer"] = {
		"Instance": dealer_node,
		"Label": dealer_node.get_node("Label"),
		"Hand": {
			"Card1": dealer_node.get_node("Hand/Card1"),
			"Card2": dealer_node.get_node("Hand/Card2"),
		},
		"Chip": dealer_node.get_node("Chip"),
		"Bet": dealer_node.get_node("Bet"),
		"DealerButton": dealer_node.get_node("DealerButton"),
	}

	# バーンカード用ノード
	for place in burn_card:
		var place_name = place.name
		burn_card_place[place_name] = place

	# コミュニティカード用ノード
	for place in community_card:
		var place_name = place.name
		community_card_place[place_name] = place

func _initialize_ui():
	# ボタンのトグル状態変更時に処理を設定
	fold_button.connect("toggled", Callable(self, "_on_fold_button_toggled"))
	check_call_button.connect("toggled", Callable(self, "_on_check_call_button_toggled"))
	bet_raise_button.connect("toggled", Callable(self, "_on_bet_raise_button_toggled"))
	# ベットサイズ用
	bet_size_slider.connect("value_changed", Callable(self, "_on_bet_size_slider_value_changed"))
	bet_size_input.connect("text_changed", Callable(self, "_on_bet_size_input_changed"))

# テーブルとディーラーのバックエンドを初期化
func _initialize_backend():
	# テーブルバックエンドを生成
	table_backend = TableBackend.new(bet_size, buy_in, dealer_name, selected_cpus)

	# 各座席のプレイヤーを初期化
	for seat_name in table_backend.seat_assignments.keys():
		_initialize_player(seat_name)

	# ディーラーのバックエンドを取得
	dealer_backend = table_backend.dealer.dealer_script

# プレイヤーのバックエンドおよび関連するノードを初期化
func _initialize_player(seat_name: String):
	# 座席に割り当てられたプレイヤー情報を取得
	var player = table_backend.seat_assignments[seat_name]
	var participant = table_backend.seat_assignments[seat_name]

	if participant:
		# プレイヤースクリプトにディーラーフラグ変更のシグナルを接続
		participant.player_script.connect("dealer_changed", Callable(self, "_on_dealer_changed"))

		# プレイヤーが操作可能な場合の設定
		if !participant.is_cpu:
			player_backend = participant.player_script
			# プレイヤーのアクション完了時のシグナルを接続
			player_backend.connect("action_completed", Callable(self, "_on_action_completed"))
		else:
			# CPUプレイヤーの場合、ベットサイズの最小・最大値を設定
			_update_min_size_range(1)
			_update_max_size_range(participant.player_script.chips)

		# プレイヤー用のシーンをインスタンス化して追加
		var player_scene = preload("res://scenes/gamecomponents/Participant.tscn").instantiate()
		animation_place[seat_name]["Instance"].add_child(player_scene)

		# バックエンドとフロントエンドの関連付け
		player_scene.set_backend(player, seat_name)
		# チップ変更およびベット変更のシグナルを接続
		player_scene.backend.player_script.connect("chips_changed", Callable(player_scene, "_on_bet_updated"))
		player_scene.backend.player_script.connect("bet_changed", Callable(self, "_on_bet_changed"))
		player_scene.backend.player_script.connect("hand_clear", Callable(self, "_on_hand_clear"))

# ディーラー関連のシグナルを初期化
func _initialize_signals():
	# テーブルのバックエンドにシグナルを接続
	table_backend.game_process.connect("phase_completed", Callable(self, "_on_phase_completed"))

	# 各シグナルをディーラーのバックエンドに接続
	dealer_backend.connect("burn_card_signal", Callable(self, "_on_burn_card"))
	dealer_backend.connect("deal_card_signal", Callable(self, "_on_deal_card"))
	dealer_backend.connect("community_card_signal", Callable(self, "_on_community_card"))
	dealer_backend.connect("delete_front_bet", Callable(self, "_on_delete_front_bet"))
	dealer_backend.connect("set_pot", Callable(self, "_on_set_pot"))
	dealer_backend.connect("delete_front_pot", Callable(self, "_on_delete_front_pot"))
	dealer_backend.connect("delete_front_community", Callable(self, "_on_delete_front_community"))
	dealer_backend.connect("delete_front_burn", Callable(self, "_on_delete_front_burn"))
	dealer_backend.connect("min_size", Callable(self, "_update_min_size_range"))
	dealer_backend.connect("max_size", Callable(self, "_update_max_size_range"))
	dealer_backend.connect("step_completed", Callable(self, "_on_step_completed"))

func _initialize_timers():
	phase_timer = Timer.new()
	phase_timer.name = "PhaseTimer"
	phase_timer.one_shot = true
	add_child(phase_timer)
	phase_timer.connect("timeout", Callable(self, "_on_phase_timer_timeout"))

# Foldボタンのトグル状態変更時の処理
func _on_fold_button_toggled(toggled_on: bool):
	if toggled_on:
		player_backend.set_selected_action("fold")
	else:
		player_backend.set_selected_action("")

# Check/Callボタンのトグル状態変更時の処理
func _on_check_call_button_toggled(toggled_on: bool):
	if toggled_on:
		player_backend.set_selected_action("check/call")
	else:
		player_backend.set_selected_action("")

# Bet/Raiseボタンのトグル状態変更時の処理
func _on_bet_raise_button_toggled(toggled_on: bool):
	if toggled_on:
		player_backend.set_selected_action("bet/raise")
	else:
		player_backend.set_selected_action("")

# プレイヤーのアクションが完了したときに呼ばれる
func _on_action_completed():
	fold_button.button_pressed = false
	check_call_button.button_pressed = false
	bet_raise_button.button_pressed = false

# 音量スライダーの値変更時に呼び出される関数
func _on_bet_size_slider_value_changed(value):
	# BGM音量の設定を反映
	bet_size_input.text = str(int(value))
	player_backend.set_selected_bet_amount(int(value))

func _on_bet_size_input_changed(text: String):
	# 入力が整数として有効か確認
	var value = int(text)
	if value >= bet_size_slider.min_value and value <= bet_size_slider.max_value:
		bet_size_slider.value = value
		player_backend.set_selected_bet_amount(value)

func _update_min_size_range(value: int):
	bet_size_slider.min_value = value
	if bet_size_slider.value < value:
		bet_size_slider.value = value
		bet_size_input.text = str(value)

func _update_max_size_range(value: int):
	bet_size_slider.max_value = value
	if bet_size_slider.value > value:
		bet_size_slider.value = value
		bet_size_input.text = str(value)

# 各プレイヤーから信号を受け取る関数
func _on_dealer_changed(seat_name: String, value: bool):
	move_dealer_button(seat_name, value)

# ディーラーボタンを指定座席で表示したり消したり
func move_dealer_button(seat_name: String, value: bool):
	var seat_instance = animation_place[seat_name]["DealerButton"]

	if value:
		# ディーラーボタンを座席のインスタンスに追加
		if not dealer_button.get_parent():
			seat_instance.add_child(dealer_button)
	else:
		# ディーラーボタンを座席から取り外す
		if dealer_button.get_parent() == seat_instance:
			seat_instance.remove_child(dealer_button)

# バーンカードを設置する
func _on_burn_card(place: String, card: CardBackend):
	var burn_cade_place_node = burn_card_place[place]
	# 新しいカードシーンのインスタンスを生成
	var card_scene = preload("res://scenes/gamecomponents/Card.tscn").instantiate()
	card_scene.set_backend(card)
	card_scene.set_visible_node(false)
	burn_cade_place_node.add_child(card_scene)

# ディールカードを設置する
func _on_deal_card(seat_name: String, place: String, card: CardBackend):
	var deal_card = animation_place[seat_name]["Hand"][place]
	# 新しいカードシーンのインスタンスを生成
	var card_scene = preload("res://scenes/gamecomponents/Card.tscn").instantiate()
	card_scene.set_backend(card)
	deal_card.add_child(card_scene)

# コミュニティカードを設置する
func _on_community_card(place: String, card: CardBackend):
	var community_card_place_node = community_card_place[place]
	# 新しいカードシーンのインスタンスを生成
	var card_scene = preload("res://scenes/gamecomponents/Card.tscn").instantiate()
	card_scene.set_backend(card)
	community_card_place_node.add_child(card_scene)

# プレイヤーのハンドを消す
func _on_hand_clear(seat_name: String):
	var card1_instance = animation_place[seat_name]["Hand"]["Card1"]
	var card2_instance = animation_place[seat_name]["Hand"]["Card2"]
	# ディーラーボタンを座席から取り外す
	# カード1が存在する場合、直接削除
	if card1_instance:
		# Bet ノード内の Chip ノードを取得して削除
		for child in card1_instance.get_children():
			if child.name == "Card":
				child.queue_free()

	# カード2が存在する場合、直接削除
	if card2_instance:
		for child in card2_instance.get_children():
			if child.name == "Card":
				child.queue_free()

# ベットとチップの更新
func _on_bet_changed(seat_name: String, bet_value: int):
	# ベットのノードを取得
	var bet_node = animation_place[seat_name]["Bet"]

	if !bet_node.has_node("Chip"):
		# 初回ベット: 新しいChipインスタンスを作成
		var bet_scene = preload("res://scenes/gamecomponents/Chip.tscn").instantiate()
		bet_scene.set_bet_value(bet_value)  # ベット額を設定
		bet_scene.set_chip_sprite(false)  # 表示を設定
		bet_node.add_child(bet_scene)  # ノードツリーに追加
	else:
		# 2回目以降のベット: 既存のChipノードを取得して更新
		var chip_instance = bet_node.get_node("Chip")
		chip_instance.set_bet_value(bet_value)  # ベット額を更新

# ポットに集める際にベットの部分を削除する
func _on_delete_front_bet(seat_name: String):
	var bet_node = animation_place[seat_name]["Bet"]
	if bet_node:
		# Bet ノード内の Chip ノードを取得して削除
		for child in bet_node.get_children():
			if child.name == "Chip":
				child.queue_free()

# ポットを追加する
func _on_set_pot(total_chips: int):
	# ポットのノードを取得
	if !front_pot.has_node("Chip"):
		# 初回ベット: 新しいChipインスタンスを作成
		var bet_scene = preload("res://scenes/gamecomponents/Chip.tscn").instantiate()
		bet_scene.set_bet_value(total_chips)  # ベット額を設定
		bet_scene.set_chip_sprite(true)  # 表示を設定
		front_pot.add_child(bet_scene)  # ノードツリーに追加
	else:
		# 2回目以降のベット: 既存のChipノードを取得して更新
		var chip_instance = front_pot.get_node("Chip")
		chip_instance.set_chip_value(total_chips)  # ベット額を更新

# ポットの部分を削除する
func _on_delete_front_pot():
	# Bet ノード内の Chip ノードを取得して削除
	for child in front_pot.get_children():
		if child.name == "Chip":
			child.queue_free()

# コミュニティカードリセット
func _on_delete_front_community():
	# Community ノード内の Chip ノードを取得して削除
	for place in burn_card_place.keys():
		for child in burn_card_place[place].get_children():
			if child.name == "Card":
				child.queue_free()

# バーンカードリセット
func _on_delete_front_burn():
	# Burn ノード内の Chip ノードを取得して削除
	for place in community_card_place.keys():
		for child in community_card_place[place].get_children():
			if child.name == "Card":
				child.queue_free()

func _on_phase_completed():
	print("[Phase] completed. Preparing for next phase...")
	phase_timer.start(2.0)  # 次のフェーズまで2秒待機

func _on_phase_timer_timeout():
	# current_phaseが3, 6, 8, 11のときだけ、remaining_playerが1以上なら+=1する
	if table_backend.game_process.current_phase in [3, 6, 9, 12]:
		if table_backend.game_process.remaining_players.size() > 1:
			table_backend.game_process.current_phase += 1
		else:
			# そうでない場合、current_phaseは13へと移行する
			table_backend.game_process.current_phase = 13
	# そうでない場合通常ルート
	else:
		# その中でもreset処理である16になったら1にする
		if table_backend.game_process.current_phase == 16:
			table_backend.game_process.current_phase = 1
		else:
			table_backend.game_process.current_phase += 1

	await table_backend.game_process.advance_phase()

func _process(delta):
	# 各クラスの状態を更新
	update_debug_label()

func _input(event):
	if get_tree().paused and event.is_action_pressed("ui_accept"):
		get_tree().paused = false

# ラベルを更新する
func update_debug_label():
	for seat_key in table_backend.seat_assignments.keys():
		var player = table_backend.seat_assignments[seat_key]
		if player != null:
			if player.player_script != null:
				animation_place[seat_key]["Label"].text = "===== " + seat_key + " =====\n"
				animation_place[seat_key]["Label"].text += player.player_script.to_str()
			if player.role != "player":
				dealer.text = player.dealer_script.to_str()
				animation_place["Dealer"]["Label"].text = "===== Dealer =====\n"
				animation_place["Dealer"]["Label"].text += player.player_script.to_str()

		else:
			# プレイヤーが存在しない場合は空文字に
			animation_place[seat_key]["Label"].text = ""

	for i in range(pots.size()):
		if i < dealer_backend.pots.size():
			pots[i].text = dealer_backend.pots[i].to_str()
		else:
			pots[i].text = ""  # 余ったポットをクリア
