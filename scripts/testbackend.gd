extends Control

# 事実上のメイン。モーダルから値が飛んできた直後

# 表示を管理する親ノード（Labelなど）
@onready var dealer = $ScrollContainer/VBoxContainer/Dealer/Dealer

@onready var pots = $ScrollContainer/VBoxContainer/Pots.get_children()

@onready var animation_place = {
	"Seat1": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat1/Label,
	},
	"Seat2": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat2/Label,
	},
	"Seat3": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat3/Label,
	},
	"Seat4": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat4/Label,
	},
	"Seat5": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat5/Label,
	},
	"Seat6": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat6/Label,
	},
	"Seat7": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat7/Label,
	},
	"Seat8": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat8/Label,
	},
	"Seat9": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat9/Label,
	},
	"Seat10": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Seat10/Label,
	},
	"Dealer": {
		"Label": $ScrollContainer/VBoxContainer/Seat/Dealer/Label,
	},
}

#TODO 次のタスク

# 必要な値
var bet_size = { "name": "table_1 bb:2 sb:1", "bb": 2, "sb": 1 }
var buy_in = 100
var dealer_name = "ずんだもん"
var selected_cpus = ["四国めたん", "ずんだもん", "春日部つむぎ", "雨晴はう", "冥鳴ひまり"]
var seeing = true	# 観戦だけかどうか

var game_process

func _ready():
	# ゲームプロセスのインスタンスを作成する

	game_process = GameProcessBackend.new(bet_size, buy_in, dealer_name, selected_cpus, seeing)
	game_process.name = "GameProcessBackend"
	add_child(game_process)

func _process(delta):

	# 各クラスの状態を更新
	update_debug_label()

func _input(event):
	if get_tree().paused and event.is_action_pressed("ui_accept"):
		get_tree().paused = false

# ラベルを更新する
func update_debug_label():
	if game_process.table_backend != null:
		for seat_key in game_process.table_backend.seat_assignments.keys():
			var player = game_process.table_backend.seat_assignments[seat_key]
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
			if i < game_process.table_backend.dealer.dealer_script.pots.size():
				pots[i].text = game_process.table_backend.dealer.dealer_script.pots[i].to_str()
			else:
				pots[i].text = ""  # 余ったポットをクリア
