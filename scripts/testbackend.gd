extends Control

# 事実上のメイン。モーダルから値が飛んできた直後

# 表示を管理する親ノード（Labelなど）
@onready var dealer = $ScrollContainer/VBoxContainer/Dealer/Dealer

@onready var pots = $ScrollContainer/VBoxContainer/Pots.get_children()

@onready var label_place = {
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

@onready var table_place = {
    "Instance": $Table/Rect,
    "CommunityCard": {
        "Flop1": $Table/Flop1,
        "Flop2": $Table/Flop2,
        "Flop3": $Table/Flop3,
        "Turn": $Table/Turn,
        "River": $Table/River,
    },
    "Deck": $Table/Deck,
    "Burn": {
        "Instance": $Table/Burn,
        "SetInitialDealer": $Table/Burn/SetInitialDealer,
        "PreFlop": $Table/Burn/PreFlop,
        "Flop": $Table/Burn/Flop,
        "Turn": $Table/Burn/Turn,
        "River": $Table/Burn/River,
    },
    "Pot": $Table/Pot,
    "DealerButton": $Table/DealerButton
}

@onready var animation_place = {
    "Seat1": {
        "Seat": $Table/Seat/Seat1,
        "Participant": $Table/Seat/Seat1/Participant,
        "Hand1": $Table/Seat/Seat1/Hand1,
        "Hand2": $Table/Seat/Seat1/Hand2,
        "Bet": $Table/Seat/Seat1/Bet,
        "DealerButton":$Table/Seat/Seat1/DealerButton
    },
    "Seat2": {
        "Seat": $Table/Seat/Seat2,
        "Participant": $Table/Seat/Seat2/Participant,
        "Hand1": $Table/Seat/Seat2/Hand1,
        "Hand2": $Table/Seat/Seat2/Hand2,
        "Bet": $Table/Seat/Seat2/Bet,
        "DealerButton":$Table/Seat/Seat2/DealerButton
    },
    "Seat3": {
        "Seat": $Table/Seat/Seat3,
        "Participant": $Table/Seat/Seat3/Participant,
        "Hand1": $Table/Seat/Seat3/Hand1,
        "Hand2": $Table/Seat/Seat3/Hand2,
        "Bet": $Table/Seat/Seat3/Bet,
        "DealerButton":$Table/Seat/Seat3/DealerButton
    },
    "Seat4": {
        "Seat": $Table/Seat/Seat4,
        "Participant": $Table/Seat/Seat4/Participant,
        "Hand1": $Table/Seat/Seat4/Hand1,
        "Hand2": $Table/Seat/Seat4/Hand2,
        "Bet": $Table/Seat/Seat4/Bet,
        "DealerButton":$Table/Seat/Seat4/DealerButton
    },
    "Seat5": {
        "Seat": $Table/Seat/Seat5,
        "Participant": $Table/Seat/Seat5/Participant,
        "Hand1": $Table/Seat/Seat5/Hand1,
        "Hand2": $Table/Seat/Seat5/Hand2,
        "Bet": $Table/Seat/Seat5/Bet,
        "DealerButton":$Table/Seat/Seat5/DealerButton
    },
    "Seat6": {
        "Seat": $Table/Seat/Seat6,
        "Participant": $Table/Seat/Seat6/Participant,
        "Hand1": $Table/Seat/Seat6/Hand1,
        "Hand2": $Table/Seat/Seat6/Hand2,
        "Bet": $Table/Seat/Seat6/Bet,
        "DealerButton":$Table/Seat/Seat6/DealerButton
    },
    "Seat7": {
        "Seat": $Table/Seat/Seat7,
        "Participant": $Table/Seat/Seat7/Participant,
        "Hand1": $Table/Seat/Seat7/Hand1,
        "Hand2": $Table/Seat/Seat7/Hand2,
        "Bet": $Table/Seat/Seat7/Bet,
        "DealerButton":$Table/Seat/Seat7/DealerButton
    },
    "Seat8": {
        "Seat": $Table/Seat/Seat8,
        "Participant": $Table/Seat/Seat8/Participant,
        "Hand1": $Table/Seat/Seat8/Hand1,
        "Hand2": $Table/Seat/Seat8/Hand2,
        "Bet": $Table/Seat/Seat8/Bet,
        "DealerButton":$Table/Seat/Seat8/DealerButton
    },
    "Seat9": {
        "Seat": $Table/Seat/Seat9,
        "Participant": $Table/Seat/Seat9/Participant,
        "Hand1": $Table/Seat/Seat9/Hand1,
        "Hand2": $Table/Seat/Seat9/Hand2,
        "Bet": $Table/Seat/Seat9/Bet,
        "DealerButton":$Table/Seat/Seat9/DealerButton
    },
    "Seat10": {
        "Seat": $Table/Seat/Seat10,
        "Participant": $Table/Seat/Seat10/Participant,
        "Hand1": $Table/Seat/Seat10/Hand1,
        "Hand2": $Table/Seat/Seat10/Hand2,
        "Bet": $Table/Seat/Seat10/Bet,
        "DealerButton":$Table/Seat/Seat10/DealerButton
    },
    "Dealer": {
        "Seat": $Table/Seat/Dealer,
        "Participant": $Table/Seat/Dealer/Participant,
        "Hand1": $Table/Seat/Dealer/Hand1,
        "Hand2": $Table/Seat/Dealer/Hand2,
        "Bet": $Table/Seat/Dealer/Bet,
        "DealerButton":$Table/Seat/Dealer/DealerButton
    },
}

#TODO 次のタスク
# テストのためのリファクタリング

# 必要な値
var bet_size: Dictionary = { "name": "table_1 bb:2 sb:1", "bb": 2, "sb": 1 }
var buy_in: int = 100
var dealer_name: String = "ずんだもん"
var selected_cpus: Array[String] = ["四国めたん", "ずんだもん", "春日部つむぎ", "雨晴はう", "冥鳴ひまり"]
var player: bool = false
var seeing: bool = false    # 表側を表示するかどうか。trueなら見せる。falseなら見せない

var game_process

func _ready():
    # ゲームプロセスのインスタンスを作成する
    game_process = GameProcessBackend.new(bet_size, buy_in, dealer_name, selected_cpus, table_place, animation_place, player, seeing)
    game_process.name = "GameProcessBackend"
    add_child(game_process)

func _process(_delta):

    # 各クラスの状態を更新
    update_debug_label()

func _input(event):
    if get_tree().paused and event.is_action_pressed("ui_accept"):
        get_tree().paused = false

# ラベルを更新する
func update_debug_label():
    if game_process.table_backend != null:
        for seat_key in game_process.table_backend.seat_assignments.keys():
            var seat_player = game_process.table_backend.seat_assignments[seat_key]
            if seat_player != null:
                if seat_player.player_script != null:
                    label_place[seat_key]["Label"].text = "===== " + seat_key + " =====\n"
                    label_place[seat_key]["Label"].text += seat_player.player_script.to_str()
                if seat_player.role != "player":
                    dealer.text = seat_player.dealer_script.to_str()
                    label_place["Dealer"]["Label"].text = "===== Dealer =====\n"
                    label_place["Dealer"]["Label"].text += seat_player.player_script.to_str()

            else:
                # プレイヤーが存在しない場合は空文字に
                label_place[seat_key]["Label"].text = ""

        for i in range(pots.size()):
            if i < game_process.table_backend.dealer.dealer_script.pots.size():
                pots[i].text = game_process.table_backend.dealer.dealer_script.pots[i].to_str()
            else:
                pots[i].text = ""  # 余ったポットをクリア
