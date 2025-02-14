# ノード
extends Node

# クラス名
class_name TableBackend

# 属性
var sb: int
var bb: int
var buy_in: int
var dealer_name: String
var selected_cpus: Array[String]
var table_place: Dictionary
var animation_place: Dictionary
var player: ParticipantBackend
var cpu_players: Array[ParticipantBackend] = []
var dealer: ParticipantBackend

# 表示フラグ、表示インスタンス
var seeing: bool
var front: Object

# ゲームプロセスクラス
var game_process: GameProcessBackend

# 座席一覧
var seat_assignments: Dictionary = {
    "Seat1": null, "Seat2": null, "Seat3": null, "Seat4": null,
    "Seat5": null, "Seat6": null, "Seat7": null,
    "Seat8": null, "Seat9": null, "Seat10": null, "Dealer": null,
}

# 信号
# 待機、動作の数を加算するシグナル
signal n_moving_plus


func _init(
    _game_process: GameProcessBackend,
    _bet_size: Dictionary,
    _buy_in: int,
    _dealer_name: String,
    _selected_cpus: Array[String],
    _table_place: Dictionary,
    _animation_place: Dictionary,
    _seeing: bool,
) -> void:
    """初期化関数
    Args:
        _game_process GameBackend: ゲームプロセスクラス
        _bet_size Dictionary: SB、BBをまとめた辞書
        _buy_in int: 持ち込みチップ数
        _dealer_name String: ディーラーの名前
        _selected_cpus Array[String]: 参加者の名前リスト
        _table_place Dictionary: テーブルにまつわるノードをまとめた辞書
        _animation_place Dictionary: プレイヤーにまつわるノードをまとめた辞書
        _seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    game_process = _game_process
    sb = _bet_size["sb"]
    bb = _bet_size["bb"]
    buy_in = _buy_in
    dealer_name = _dealer_name
    selected_cpus = _selected_cpus
    table_place = _table_place
    animation_place = _animation_place
    seeing = _seeing

    # 見た目作成
    if not seeing:
        var front_instance = load("res://scenes/gamecomponents/Table.tscn")
        front = front_instance.instantiate()

    # 参加者初期化処理実行
    _init_participant()

func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # テーブルの見た目をノードに追加する
    table_place["Instance"].add_child(front)

func _init_participant() -> void:
    """参加者初期化処理
    Args:
    Returns:
        void
    """
    # 操作プレイヤーを作る
    player = ParticipantBackend.new(game_process, "test", buy_in, false, "player", seeing)

    # CPUを作る
    # ディーラーが作られたか判定する
    var dealer_flg = false

    # 参加CPU分ループ
    for cpu_name in selected_cpus:
        # ロールによって、プレイヤーだけを作るか、ディーラーだけを作るか、両方作るかを分岐する
        var role = "player"

        # 対象のCPUがディーラー名と一致する場合、プレイヤーでありディーラーでもある（プレイングディーラー）
        if cpu_name == dealer_name:
            role = "playing_dealer"

        # 参加者インスタンス作成
        var cpu_player = ParticipantBackend.new(game_process, cpu_name, buy_in, true, role, seeing)

        # プレイングディーラーの場合
        if role == "playing_dealer":
            # ディーラーとして追加する
            dealer = cpu_player
            dealer_flg = true
        else:
            # プレイヤー側の参加者として参加させる
            cpu_players.append(cpu_player)

    # この時点でディーラーが作られていない場合
    if !dealer_flg:
        # ディーラー名で参加者インスタンスを作成する
        dealer = ParticipantBackend.new(game_process, dealer_name, buy_in, true, "dealer", seeing)


func seat_player() -> void:
    """プレイヤーを席に着かせる関数
    Args:
    Returns:
        void
    """
    pass


func seat_dealer() -> void:
    """ディーラーを席に着かせる関数
    Args:
    Returns:
        void
    """
    # ディーラーの座席にディーラーを座らせる
    seat_assignments["Dealer"] = dealer

    # ノードの名前をディーラー名に設定
    dealer.name = dealer.participant_name

    # ノードを追加
    add_child(dealer)

    # 見た目処理
    if seeing:
        # ディーラーの必要な情報をいろいろと更新する
        dealer.front.set_parameter(dealer, "Dealer")

        # dealer.frontの座標取得（0, 0）
        var dst = dealer.front.get_position()

        # y座標を-にすることで少し上に置く
        dealer.front.set_position(dealer.front.get_position() + Vector2(0, -75))

        # add_childで表示
        animation_place["Dealer"]["Participant"].add_child(dealer.front)

        # 動作アニメーション実行
        dealer.front.time_manager.move_to(dealer.front, dst, 1.0, Callable(game_process, "_on_moving_finished"))
    else:
        # 待機処理
        dealer.dealer_script.time_manager.wait_to(1.0, Callable(game_process, "_on_moving_finished"))

    # 信号接続
    dealer.dealer_script.connect("n_active_players_plus", Callable(game_process, "_on_n_active_players_plus"))
    dealer.dealer_script.connect("action_finished", Callable(game_process, "_on_action_finished"))

    # 座標情報をdealerに渡す
    dealer.dealer_script.animation_place = animation_place
    dealer.dealer_script.table_place = table_place

    # 待機または動作1回分のsignal発火
    n_moving_plus.emit()


func seat_cpus():
    """CPUを席に着かせる関数
    Args:
    Returns:
        void
    """
    # 空いている席のリストを作成
    var available_seats = []
    for seat in seat_assignments.keys():
        if seat_assignments[seat] == null and seat != "Dealer":
            available_seats.append(seat)

    # 席の順番をシャッフル
    available_seats.shuffle()

    # 参加cpu分だけループ
    var wait = 0
    for cpu in cpu_players:
        # まだ座席が残っている場合
        if available_seats.size() > 0:
            # 席を一つ選択
            var random_seat = available_seats.pop_front()  # シャッフル済みリストから1つ取り出す

            # CPUを座らせる
            seat_assignments[random_seat] = cpu

            # ノードの名前を参加者名に設定
            cpu.name = cpu.participant_name

            # ノードを追加
            add_child(cpu)

            # 見た目処理
            if seeing:
                # 参加者のいろいろな情報をfrontに渡す
                cpu.front.set_parameter(cpu, random_seat)

                # cpu.frontの座標取得（0, 0）
                var dst = cpu.front.get_position()

                # y座標を-にすることで少し上に置く
                cpu.front.set_position(cpu.front.get_position() + Vector2(0, -75))

                # add_childで表示
                animation_place[random_seat]["Participant"].add_child(cpu.front)

                # 動作アニメーション実行
                cpu.front.time_manager.wait_move_to(wait, cpu.front, dst, 1.0, Callable(game_process, "_on_moving_finished"))
            else:
                # 待機処理
                cpu.player_script.time_manager.wait_wait_to(wait, 1.0, Callable(game_process, "_on_moving_finished"))

            # 少しずつ動作時間をずらす
            wait += 0.3

            # 待機、または動作1回に着き信号発火
            n_moving_plus.emit()


func to_str() -> String:
    """属性表示用関数
    Args:
    Returns:
        result String: インスタンスの現在の属性をまとめた文字列
    """
    var result = "=== TableBackend 状態 ===\n"
    result += "SB: " + str(sb) + "\n"
    result += "BB: " + str(bb) + "\n"
    result += "持ち込み金額: " + str(buy_in) + "\n"
    result += "ディーラー: " + str(dealer_name) + "\n"
    result += "選択されたCPU: " + str(selected_cpus) + "\n"
    result += "=======================\n"
    return result