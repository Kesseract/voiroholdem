# ノード
extends Node

# クラス名
class_name GameProcessBackend

# ステート
enum State {
    INIT,
    SEATING_PLAYER,
    SEATING_DEALER,
    SEATING_CPUS,
    SEATING_COMPLETED,
    SETTING_DEALER_BUTTON,
    DEALER_SET,
    PAYING_SB_BB,
    SB_BB_PAID,
    DEALING_CARD,
    DEALED_CARD,
    PRE_FLOP_ACTION,
    PRE_FLOP_ACTION_END,
    FLOP_ACTION,
    FLOP_ACTION_END,
    TURN_ACTION,
    TURN_ACTION_END,
    RIVER_ACTION,
    RIVER_ACTION_END,
    SHOW_DOWN,
    SHOW_DOWN_END,
    DISTRIBUTIONING_POTS,
    DISTRIBUTIONED_POTS,
    ROUND_RESETTING,
    ROUND_RESETED,
    NEXT_DEALER_BUTTON,
    MOVED_DEALER_BUTTON,
}

# サブステート
enum SubState {
    READY,
    PLAYER_INPUT,
    PARTICIPANT_MOVING,
    CARD_MOVING,
    CARD_OPENING,
    CHIP_BETTING,
    CHIPS_COLLECTING,
    POTS_COLLECTING,
    DEALER_BUTTON_MOVING,
}

# 属性
var state: State = State.INIT
var sub_state: SubState = SubState.READY
var state_in_state: int = 0
var bet_size: Dictionary
var bb: int
var sb: int
var buy_in: int
var dealer_name: String
var selected_cpus: Array[String]
var table_place: Dictionary
var animation_place: Dictionary
var player_flg: bool
var table_backend: TableBackend
var dealer: DealerBackend
var n_moving: int = 0
var initial_dealer: ParticipantBackend
var seats: Array[String]
var start_index: int
var current_action: int
var n_active_players: int = 0
var active_players: Array[ParticipantBackend] = []

# 表示フラグ
var seeing: bool

# 時間管理クラス
var time_manager: TimeManager

# ステートと関数の対応辞書
var state_function_map: Dictionary = {
    State.INIT: process_INIT,
    State.SEATING_PLAYER: process_SEATING_PLAYER,
    State.SEATING_DEALER: process_SEATING_DEALER,
    State.SEATING_CPUS: process_SEATING_CPUS,
    State.SEATING_COMPLETED: process_SEATING_COMPLETED,
    State.SETTING_DEALER_BUTTON: process_SETTING_DEALER_BUTTON,
    State.DEALER_SET: process_DEALER_SET,
    State.PAYING_SB_BB: process_PAYING_SB_BB,
    State.SB_BB_PAID: process_SB_BB_PAID,
    State.DEALING_CARD: process_DEALING_CARD,
    State.DEALED_CARD: process_DEALED_CARD,
    State.PRE_FLOP_ACTION: process_ACTION,
    State.PRE_FLOP_ACTION_END: process_ACTION_END,
    State.FLOP_ACTION: process_ACTION,
    State.FLOP_ACTION_END: process_ACTION_END,
    State.TURN_ACTION: process_ACTION,
    State.TURN_ACTION_END: process_ACTION_END,
    State.RIVER_ACTION: process_ACTION,
    State.RIVER_ACTION_END: process_ACTION_END,
    State.SHOW_DOWN: process_SHOW_DOWN,
    State.SHOW_DOWN_END: process_SHOW_DOWN_END,
    State.DISTRIBUTIONING_POTS: process_DISTRIBUTIONING_POTS,
    State.DISTRIBUTIONED_POTS: process_DISTRIBUTIONED_POTS,
    State.ROUND_RESETTING: process_ROUND_RESETTING,
    State.ROUND_RESETED: process_ROUND_RESETED,
    State.NEXT_DEALER_BUTTON: process_NEXT_DEALER_BUTTON,
    State.MOVED_DEALER_BUTTON: process_MOVED_DEALER_BUTTON
}


func _init(
    _bet_size: Dictionary,
    _buy_in: int,
    _dealer_name: String,
    _selected_cpus: Array[String],
    _table_place: Dictionary,
    _animation_place: Dictionary,
    _player_flg: bool,
    _seeing: bool,
) -> void:
    """初期化関数
    Args:
        _bet_size Dictionary: SB、BBをまとめた辞書
        _buy_in int: 持ち込みチップ数
        _dealer_name String: ディーラーの名前
        _selected_cpus Array[String]: 参加者の名前リスト
        _table_place Dictionary: テーブルにまつわるノードをまとめた辞書
        _animation_place Dictionary: プレイヤーにまつわるノードをまとめた辞書
        _player_flg bool: Trueの場合、操作プレイヤーが参加する
                            Falseの場合、CPUのみでゲームを開始する
        _seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    bet_size = _bet_size
    bb = bet_size["bb"]
    sb = bet_size["sb"]
    buy_in = _buy_in
    dealer_name = _dealer_name
    selected_cpus = _selected_cpus
    table_place = _table_place
    animation_place = _animation_place
    player_flg = _player_flg
    seeing = _seeing

    # 時間管理クラス作成
    time_manager = TimeManager.new()


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    add_child(time_manager)


func _on_n_moving_plus() -> void:
    """移動、待機が行われている数を追加する関数
    Args:
    Returns:
        void
    """
    # 移動、待機が行われている数を追加
    n_moving += 1


func _on_n_active_players_plus() -> void:
    """アクションを行うプレイヤーの数を追加する関数
    Args:
    Returns:
        void
    """
    # アクションを行うプレイヤーの数を追加
    n_active_players += 1


func _on_moving_finished() -> void:
    """移動、待機が終了したときに動かす関数
    Args:
    Returns:
        void
    """
    # 移動、待機が行われている数を減らす
    n_moving -= 1

    # 現在値の書き出し
    print("n_moving: " + str(n_moving))

    # 動かすものがない場合
    if n_moving == 0:
        # サブステートをREADYにする
        sub_state = SubState.READY

        # 条件分岐
        """
            ・stateがSETTING_DEALER_BUTTONで、state_in_stateが3以外
            ・stateがDEALING_CARDで、state_in_stateが2以外
            ・stateがPRE_FLOP_ACTION_END、FLOP_ACTION_END、TURN_ACTION_END、RIVER_ACTION_ENDのどれかで、
                state_in_stateが0か2の時
            ・stateがSHOW_DOWNで、state_in_stateが0以外
            →state_in_stateを1追加する

            ・stateがPRE_FLOP_ACTION_END、FLOP_ACTION_END、TURN_ACTION_END、RIVER_ACTION_ENDのどれかで、
                state_in_stateが1の時
                ・アクションを行えるプレイヤーが1人の時
                →state_in_stateを2に
                ・そうでないとき
                →state_in_stateを4に

            ・stateがPRE_FLOP_ACTION、FLOP_ACTION、TURN_ACTION、RIVER_ACTIONのどれか
                ・アクションを行えるプレイヤーが0人の時
                →次のステートへ

            ・上記以外の場合
                →次のステートへ
        """
        if ((
                state == State.SETTING_DEALER_BUTTON and state_in_state != 3
            ) or
            (
                state == State.DEALING_CARD and state_in_state != 2
            ) or
            (
                (
                    state == State.PRE_FLOP_ACTION_END or
                    state == State.FLOP_ACTION_END or
                    state == State.TURN_ACTION_END or
                    state == State.RIVER_ACTION_END
                ) and
                (state_in_state == 0 or
                state_in_state == 2)
            ) or
            (
                state == State.SHOW_DOWN and
                state_in_state == 0
            )):
            state_in_state += 1
        elif (
            state == State.PRE_FLOP_ACTION_END or
            state == State.FLOP_ACTION_END or
            state == State.TURN_ACTION_END or
            state == State.RIVER_ACTION_END
            ) and state_in_state == 1:
            if active_players.size() > 1:
                state_in_state = 2
            else:
                state_in_state = 4
        elif (
            state == State.PRE_FLOP_ACTION or
            state == State.FLOP_ACTION or
            state == State.TURN_ACTION or
            state == State.RIVER_ACTION
            ):
            if n_active_players == 0:
                next_state()
        else:
            state_in_state = 0
            next_state()


func _on_moving_finished_queue_free(node: Node) -> void:
    """移動、待機が終了したときに、対象のノードを削除する関数
    Args:
        node Node: 削除対象ノード
    Returns:
        void
    """
    # オブジェクト消去
    node.queue_free()

    # 移動終了関数を動かす
    _on_moving_finished()


func _on_moving_finished_add_chip(node: Node, already: Node) -> void:
    """移動、待機が終了したときに、対象のノード（チップ）を削除する関数
    Args:
        node Node: 削除対象ノード
        already Node: すでにあるノード（加算対象）
    Returns:
        void
    """
    # チップの加算
    already.set_bet_value(node.current_chip_value)

    # オブジェクト消去
    node.queue_free()

    # 移動終了関数を動かす
    _on_moving_finished()


func _on_action_finished():
    n_moving += 1
    n_active_players -= 1
    print("n_active_players: " + str(n_active_players))


func _on_player_seated(seat_node):
    print("Player seated at:", seat_node.name)
    # 席選択完了 → 状態遷移
    sub_state = SubState.READY
    state = State.SEATING_CPUS


func next_state() -> void:
    """次のステートに移行する関数
    Args:
    Returns:
        void
    """
    # sub_stateがREADYじゃない場合はそのまま返す
    if sub_state != SubState.READY:
        # print("SubState:" + str(sub_state))
        return

    if state == State.INIT:
        # stateがINITの場合
        # 操作プレイヤーが参加しているかによって分岐
        if player_flg:
            # 操作プレイヤーを席に着かせる
            state = State.SEATING_PLAYER
        else:
            # ディーラーを席に着かせる
            state = State.SEATING_DEALER
    elif state == State.MOVED_DEALER_BUTTON:
        # stateがMOVED_DEALER_BUTTONの場合
        # SB、BBを支払う処理に戻る（ループ処理）
        state = State.PAYING_SB_BB
    else:
        # それ以外の場合
        # 次のステートに進む
        var state_keys = State.keys()
        state = State[state_keys[state + 1]]


func bet_state() -> void:
    """賭けを行う関数
    Args:
    Returns:
        void
    """
    # sub_stateをCHIP_BETTING（チップベット中）にする
    sub_state = SubState.CHIP_BETTING

    # アクティブなプレイヤーがいない場合
    if n_active_players == 0:
        # sub_stateをREADYにして、次のステートに移す
        sub_state = SubState.READY
        next_state()
        return

    # アクティブなプレイヤーを計算
    active_players = []
    for seat in seats:
        var player = table_backend.seat_assignments[seat]
        if player != null:
            if not player.player_script.is_folded:
                active_players.append(player)

    # アクティブなプレイヤーのうち、オールインしていないプレイヤーがいるかチェック
    var all_players_all_in = true
    for player in active_players:
        if not player.player_script.is_folded:
            if not player.player_script.is_all_in:
                # 一人でもいればfalseとなる
                all_players_all_in = false

    # 全員がオールインしている場合
    if all_players_all_in:
        # sub_stateをREADYにして、次のステートに移す
        sub_state = SubState.READY
        next_state()
        return

    # アクションを行う関数を実行
    var action = dealer.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

    # 何らかのアクションが行われた場合、それをprintする
    if action != "none_player":
        print("action: " + str(action))

    # プレイヤーが席にいなかった場合
    if action == "none_player":
        # sub_stateをREADYにして、次のプレイヤーに回す
        sub_state = SubState.READY
        current_action += 1
        return

    # プレイヤーがフォールドしていた場合
    if action == "folded":
        # sub_stateをREADYにして、次のプレイヤーに回す
        sub_state = SubState.READY
        current_action += 1
        return

    # プレイヤーがオールインしていた場合
    if action == "all-ined":
        # sub_stateをREADYにして、次のプレイヤーに回す
        sub_state = SubState.READY
        current_action += 1
        return

    # ベットしたプレイヤーを取得
    var active_players_bet = []
    for player in active_players:
        if not player.player_script.is_folded:
            if not player.player_script.current_bet in active_players_bet:
                active_players_bet.append(player.player_script.current_bet)

    # アクティブなプレイヤーが全員ベットしたかをチェック
    var active_players_acted = true
    for player in active_players:
        if not player.player_script.is_folded and not (player.player_script.has_acted or player.player_script.is_all_in):
            # 一人でもしていない場合falseになる
            active_players_acted = false
            break

    # 全員かけ終わった場合
    if active_players_bet.size() >= 1 and active_players_acted:
        # ベット履歴をリセットして、次のステートに移す
        dealer.bet_record = [0]
        # sub_state = SubState.READY
        next_state()
        return

    # オールインしたプレイヤーを再度取得
    var all_in_players = []
    for player in active_players:
        if player.player_script.is_all_in:
            all_in_players.append(player)

    # オールインしたプレイヤーの数とアクティブなプレイヤーの数が等しい
    # 全員オールインしている
    if all_in_players.size() == active_players.size() and active_players_acted:
        # ベット履歴をリセットして、次のステートに移す
        dealer.bet_record = [0]
        # sub_state = SubState.READY
        next_state()
        return

    current_action += 1


func process_INIT() -> void:
    """ステートINITに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.INIT")

    # テーブル作成
    table_backend = TableBackend.new(self, bet_size, buy_in, dealer_name, selected_cpus, table_place, animation_place, seeing)

    # ディーラーを変数に入れる
    dealer = table_backend.dealer.dealer_script

    # 信号接続
    table_backend.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))
    dealer.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))

    # ノード名変更
    table_backend.name = "TableBackend"

    # ノードを追加
    add_child(table_backend)

    # 次のステートへ
    next_state()


func process_SEATING_PLAYER() -> void:
    """ステートSEATING_PLAYERに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SEATING_PLAYER")

    # sub_stateをPLAYER_INPUTに
    sub_state = SubState.PLAYER_INPUT

    # 操作プレイヤーを席に着かせる関数実行
    table_backend.seat_player()


func process_SEATING_DEALER() -> void:
    """ステートSEATING_DEALERに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SEATING_DEALER")

    # sub_stateをPARTICIPANT_MOVINGに
    sub_state = SubState.PARTICIPANT_MOVING

    # ディーラーを席に着かせる関数実行
    table_backend.seat_dealer()


func process_SEATING_CPUS() -> void:
    """ステートSEATING_CPUSに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SEATING_CPUS")

    # sub_stateをPARTICIPANT_MOVINGに
    sub_state = SubState.PARTICIPANT_MOVING

    # CPUを席に着かせる関数実行
    table_backend.seat_cpus()


func process_SEATING_COMPLETED() -> void:
    """ステートSEATING_COMPLETEDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SEATING_COMPLETED")

    # 次のステートへ
    next_state()


func process_SETTING_DEALER_BUTTON() -> void:
    """ステートSETTING_DEALER_BUTTONに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SETTING_DEALER_BUTTON")

    # state_in_stateによって分岐
    if state_in_state == 0:
        # バーンカード
        # state_in_stateのprint
        print("State_in_State.burn_card")

        # sub_stateをCARD_MOVINGに
        sub_state = SubState.CARD_MOVING

        # バーンカード実行
        dealer.burn_card("SetInitialDealer")
    elif state_in_state == 1:
        # カードを1枚だけ配る
        # state_in_stateのprint
        print("State_in_State.deal_card")

        # sub_stateをCARD_MOVINGに
        sub_state = SubState.CARD_MOVING

        # カードを1枚だけ配る関数実行
        dealer.deal_card(table_backend.seat_assignments)
    elif state_in_state == 2:
        # ディーラーボタンの初期配置
        # state_in_stateのprint
        print("State_in_State.set_initial_button")

        # sub_stateをCARD_MOVINGに
        sub_state = SubState.CARD_MOVING

        # ディーラーボタンの初期配置関数実行
        dealer.set_initial_button(table_backend.seat_assignments)
    elif state_in_state == 3:
        # ディーラーボタンを動かす
        # state_in_stateのprint
        print("State_in_State.set_dealer")

        # sub_stateをDEALER_BUTTON_MOVINGに
        sub_state = SubState.DEALER_BUTTON_MOVING

        # ハンドを削除して、ディーラーボタンを動かす関数実行
        dealer.hand_clear(table_backend.seat_assignments)


func process_DEALER_SET() -> void:
    """ステートDEALER_SETに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.DEALER_SET")

    # デッキのリセット
    for child in dealer.get_children():
        # 子ノードに接続されているシグナルを解除
        for signal_name in child.get_signal_list():
            if child.is_connected(signal_name["name"], Callable(self, "_signal_handler")):
                child.disconnect(signal_name["name"], Callable(self, "_signal_handler"))

        # 子ノードを削除
        dealer.remove_child(child)
        child.queue_free()

    # デッキのリセット
    dealer.deck = DeckBackend.new(seeing)

    # ノード名を再度設定し、ノードを追加
    dealer.deck.name = "DeckBackend"
    dealer.add_child(dealer.deck)

    # 時間管理クラスも作成しなおして、追加する
    dealer.time_manager = TimeManager.new()
    dealer.add_child(dealer.time_manager)

    # 次のステートへ
    next_state()


func process_PAYING_SB_BB() -> void:
    """ステートPAYING_SB_BBに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.PAYING_SB_BB")

    # sub_stateをCHIP_BETTINGに
    sub_state = SubState.CHIP_BETTING

    # ディーラーボタンの一つとなりをSBを支払うプレイヤーとして取得
    var sb_seat = dealer.get_dealer_button_index(table_backend.seat_assignments, 1)
    var sb_player = table_backend.seat_assignments[sb_seat]

    # SBをベットさせる
    sb_player.player_script.bet(sb)

    # 見た目処理
    if seeing:
        # チップを追加し、対象プレイヤーのベット位置に動かす
        sb_player.front.set_chips(sb_player.player_script.chips)
        var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
        var chip = chip_instance.instantiate()
        chip.set_chip_sprite(false)
        chip.set_bet_value(sb)
        chip.set_position(-1 * animation_place[sb_seat]["Bet"].get_position())
        animation_place[sb_seat]["Bet"].add_child(chip)
        chip.time_manager.move_to(chip, Vector2(0, 0), 1.0, Callable(self, "_on_moving_finished"))
    else:
        # 待機処理
        sb_player.player_script.time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))

    # ベット履歴にSBを追加
    dealer.bet_record.append(sb)

    # 動作、待機の分だけ数を加算する
    _on_n_moving_plus()

    # ディーラーボタンの二つとなりをBBを支払うプレイヤーとして取得
    var bb_seat = dealer.get_dealer_button_index(table_backend.seat_assignments, 2)
    var bb_player = table_backend.seat_assignments[bb_seat]

    # BBをベットさせる
    bb_player.player_script.bet(bb)

    # 見た目処理
    if seeing:
        # チップを追加し、対象プレイヤーのベット位置に動かす
        bb_player.front.set_chips(bb_player.player_script.chips)
        var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
        var chip = chip_instance.instantiate()
        chip.set_chip_sprite(false)
        chip.set_bet_value(bb)
        chip.set_position(-1 * animation_place[bb_seat]["Bet"].get_position())
        animation_place[bb_seat]["Bet"].add_child(chip)
        chip.time_manager.move_to(chip, Vector2(0, 0), 1.0, Callable(self, "_on_moving_finished"))
    else:
        # 待機処理
        bb_player.player_script.time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))

    # ベット履歴にBBを追加
    dealer.bet_record.append(bb)

    # 動作、待機の分だけ数を加算する
    _on_n_moving_plus()


func process_SB_BB_PAID() -> void:
    """ステートSB_BB_PAIDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SB_BB_PAID")

    # 次のステートへ
    next_state()


func process_DEALING_CARD() -> void:
    """ステートDEALING_CARDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.DEALING_CARD")

    # sub_stateをCARD_MOVINGに
    sub_state = SubState.CARD_MOVING

    # state_in_stateによって分岐
    if state_in_state == 0:
        # バーンカード
        # state_in_stateのprint
        print("State_in_State.burn_card")

        # バーンカード実行
        dealer.burn_card("PreFlop")
    elif state_in_state == 1:
        # プレイヤーに1枚目のカードを配る
        # state_in_stateのprint
        print("State_in_State.deal_card_one")

        # カードを配る関数実行
        dealer.deal_hole_cards(table_backend.seat_assignments, "Hand1")
    elif state_in_state == 2:
        # プレイヤーに2枚目のカードを配る
        # state_in_stateのprint
        print("State_in_State.deal_card_two")

        # カードを配る関数実行
        dealer.deal_hole_cards(table_backend.seat_assignments, "Hand2")


func process_DEALED_CARD() -> void:
    """ステートDEALED_CARDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.DEALED_CARD")

    # 座席情報を配列にする
    seats = table_backend.seat_assignments.keys()

    # ディーラーボタンの3つとなりの座席を取得
    start_index = (seats.find(dealer.get_dealer_button_index(table_backend.seat_assignments, 3))) % seats.size()

    # その箇所からいくつ隣化の変数を初期化
    current_action = 0

    # アクションを行った人数の初期化
    n_active_players = 0

    # 座席でループ
    for seat in seats:
        # プレイヤーがいる場合、その人数を加算し、アクションフラグをfalseにする
        var player = table_backend.seat_assignments[seat]
        if player != null and player.player_script != null:
            n_active_players += 1
            player.player_script.has_acted = false

    # 次のステートへ
    next_state()


func process_ACTION() -> void:
    """ステートSEATING_DEALERに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    if state == State.PRE_FLOP_ACTION:
        print("State.PRE_FLOP_ACTION")
    elif state == State.FLOP_ACTION:
        print("State.FLOP_ACTION")
    elif state == State.TURN_ACTION:
        print("State.TURN_ACTION")
    else:
        print("State.RIVER_ACTION")

    # ベット処理実行
    bet_state()


func process_ACTION_END() -> void:
    """ステートACTION_ENDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    if state == State.PRE_FLOP_ACTION_END:
        print("State.PRE_FLOP_ACTION_END")
    elif state == State.FLOP_ACTION_END:
        print("State.FLOP_ACTION_END")
    elif state == State.TURN_ACTION_END:
        print("State.TURN_ACTION_END")
    else:
        print("State.RIVER_ACTION_END")

    # state_in_stateによって分岐
    if state_in_state == 0:
        # チップをポットとして集める
        # state_in_stateのprint
        print("State_in_State.pot_collect")

        # sub_stateをCHIPS_COLLECTINGに
        sub_state = SubState.CHIPS_COLLECTING

        # まずベットされたものをポットとして集める
        var pot_value = dealer.pot_collect(table_backend.seat_assignments)

        # ベット履歴をリセット
        dealer.bet_record = [0]

        # ポットが0の場合
        if pot_value == 0:
            # sub_stateをREADYにし、つぎのstate_in_stateへ
            sub_state = SubState.READY
            state_in_state = 1
    elif state_in_state == 1:
        # アクティブなプレイヤーの数を数える
        # state_in_stateのprint
        print("State_in_State.active_players_check")

        # sub_stateをCHIPS_COLLECTINGに
        sub_state = SubState.CHIPS_COLLECTING

        # アクティブなプレイヤーの数を数える
        active_players = []
        for seat in seats:
            var player = table_backend.seat_assignments[seat]
            if player != null:
                if not player.player_script.is_folded:
                    active_players.append(player)

        # 待機処理
        time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
        _on_n_moving_plus()
    elif state_in_state == 2:
        # バーンカード
        # state_in_stateのprint
        print("State_in_State.burn_card")
        sub_state = SubState.CARD_MOVING
        if state == State.PRE_FLOP_ACTION_END:
            dealer.burn_card("Flop")
        elif state == State.FLOP_ACTION_END:
            dealer.burn_card("Turn")
        elif state == State.TURN_ACTION_END:
            dealer.burn_card("River")
        else:
            # RIVER_ACTION_ENDの場合だけバーンカードはなし
            # 次のステートへ進む
            _on_n_moving_plus()
            _on_moving_finished()
    elif state_in_state == 3:
        # コミュニティカードを設置
        # state_in_stateのprint
        print("State_in_State.reveal_community_cards")

        # sub_stateをCARD_MOVINGに
        sub_state = SubState.CARD_MOVING

        # コミュニティカードを指定枚数開く
        var community_card_place = []
        if state == State.PRE_FLOP_ACTION_END:
            community_card_place = ["Flop1", "Flop2", "Flop3"]
        elif state == State.FLOP_ACTION_END:
            community_card_place = ["Turn"]
        elif state == State.TURN_ACTION_END:
            community_card_place = ["River"]

        # RIVER_ACTION_END以外はコミュニティカードを開く
        if state != State.RIVER_ACTION_END:
            dealer.reveal_community_cards(community_card_place)

            # アクションを行うプレイヤーの再計算
            current_action = 0
            n_active_players = 0
            for seat in seats:
                var player = table_backend.seat_assignments[seat]
                if player != null and not player.player_script.is_folded and not player.player_script.is_all_in:
                    # アクションを行うプレイヤーの追加
                    n_active_players += 1

                    # アクションしたかのフラグをfalseに
                    player.player_script.has_acted = false

                    # アクション履歴をリセットする
                    player.player_script.last_action.clear()
        else:
            # RIVER_ACTION_ENDの場合だけなにもなし
            # 次のステートへ進む
            _on_n_moving_plus()
            _on_moving_finished()

    elif state_in_state == 4:
        # ステートを一気にポット分配まで飛ばす
        # state_in_stateのprint
        print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")

        # state_in_stateの初期化
        state_in_state = 0

        # sub_stateをREADYに
        sub_state = SubState.READY

        # stateもDISTRIBUTIONING_POTSに
        state = State.DISTRIBUTIONING_POTS


func process_SHOW_DOWN() -> void:
    """ステートSHOW_DOWNに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SHOW_DOWN")
    # state_in_stateによって分岐
    if state_in_state == 0:
        # カードを開く処理
        # state_in_stateのprint
        print("State_inState:CARD_OPENING")

        # sub_stateをCARD_OPENINGに
        sub_state = SubState.CARD_OPENING

        # カードオープン（未実装）
        time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))

        # 動作の数を加算
        _on_n_moving_plus()
    elif state_in_state == 1:
        # 手の強さを判定
        # state_in_stateのprint
        print("State_inState:evaluate_hand")

        # sub_stateをCARD_OPENINGに
        sub_state = SubState.CARD_OPENING

        # 手の強さ判定
        active_players = dealer.evaluate_hand(table_backend.seat_assignments)

        # 待機処理
        time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))

        # 動作の数を加算
        _on_n_moving_plus()


func process_SHOW_DOWN_END() -> void:
    """ステートSHOW_DOWN_ENDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.SHOW_DOWN_END")

    # 次のステートへ
    next_state()


func process_DISTRIBUTIONING_POTS() -> void:
    """ステートDISTRIBUTIONING_POTSに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.DISTRIBUTIONING_POTS")

    # sub_stateをPOTS_COLLECTINGに
    sub_state = SubState.POTS_COLLECTING

    # ポットの分配を行う関数実行
    dealer.distribute_pots(active_players, table_backend.seat_assignments)


func process_DISTRIBUTIONED_POTS() -> void:
    """ステートDISTRIBUTIONED_POTSに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.DISTRIBUTIONED_POTS")

    # 次のステートへ
    next_state()


func process_ROUND_RESETTING() -> void:
    """ステートROUND_RESETTINGに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.ROUND_RESETTING")

    # sub_stateをCARD_MOVINGに
    sub_state = SubState.CARD_MOVING

    # ラウンドのリセット関数実行
    dealer.reset_round(table_backend.seat_assignments, buy_in)


func process_ROUND_RESETED() -> void:
    """ステートROUND_RESETEDに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.ROUND_RESETED")

    # 次のステートへ
    next_state()


func process_NEXT_DEALER_BUTTON() -> void:
    """ステートNEXT_DEALER_BUTTONに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.NEXT_DEALER_BUTTON")

    # sub_stateをDEALER_BUTTON_MOVINGに
    sub_state = SubState.DEALER_BUTTON_MOVING

    # ディーラーボタンを次の人に動かす関数実行
    dealer.move_dealer_button(table_backend.seat_assignments)


func process_MOVED_DEALER_BUTTON() -> void:
    """ステートMOVED_DEALER_BUTTONに実行する関数
    Args:
    Returns:
        void
    """
    # ステートのprint
    print("State.MOVED_DEALER_BUTTON")

    # 次のステートへ
    next_state()


func _process(_delta) -> void:
    """枚フレーム実行される関数
    Args:
        _delta float: 関数実行から何フレーム経ったか
    Returns:
        void
    """
    # サブステートがREADYじゃない場合、すぐにリターンして次のフレームへ
    if sub_state != SubState.READY:
        # print(n_moving)
        # print("SubState:" + str(sub_state))
        return

    # State に対応する関数を呼び出す
    if state_function_map.has(state):
        state_function_map[state].call()
    else:
        print("⚠️ 未対応のState:", state)
