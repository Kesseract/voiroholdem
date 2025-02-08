extends Control

var bet_size = ""
var buy_in = 0
var dealer = ""
var selected_characters = []

# データを受け取るためのメソッド
func set_game_data(_bet_size, _buy_in, _dealer, _selected_characters):
    bet_size = _bet_size
    buy_in = _buy_in
    dealer = _dealer
    selected_characters = _selected_characters

func _ready():
    print("ゲーム開始時")
    print("ベットサイズ:", bet_size)
    print("持ち込み金額:", buy_in)
    print("ディーラー:", dealer)
    print("選択されたキャラクター:", selected_characters)

    # ゲームの初期化処理をここで行う
    var table_scene = preload("res://scenes/gamecomponents/Table.tscn")
    var table = table_scene.instantiate()

    # スクリプトのプロパティに値をセット
    table.bet_size = Global.bet_size
    table.buy_in = int(Global.buy_in)
    table.dealer_name = Global.dealer
    table.selected_cpus = Global.selected_characters.duplicate()  # 配列の複製

    # 一旦ノードツリーに追加
    add_child(table)

    # TableノードをFoldButtonの上に移動
    move_child(table, get_children().find($FoldButton))