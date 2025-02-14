# ノード
extends Node

# クラス名
class_name DealerBackend

# 属性
var deck
var pots: Array = []
var bet_record: Array = []
var community_cards: Array = []
var burn_cards: Array = []
var hand_evaluator
var game_process
var animation_place
var table_place

# 表示フラグ、表示インスタンス
var seeing: bool

# 時間管理クラス
var time_manager: TimeManager

# 信号
signal action_finished
signal n_moving_plus
signal n_active_players_plus

func _init(_game_process: GameProcessBackend, _seeing: bool) -> void:
    """初期化関数
    Args:
        _game_process GameProcessBackend: ゲームプロセスクラス
        _seeing bool:_seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    game_process = _game_process
    seeing = _seeing

    # デッキインスタンスの作成
    deck = DeckBackend.new(seeing)

    # ノードの名前を変更
    deck.name = "DeckBackend"

    # ノードを追加
    add_child(deck)

    # ポットインスタンスの作成
    pots.append(PotBackend.new())

    # 役判定クラスのインスタンス作成
    hand_evaluator = HandEvaluatorBackend.new()

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


func burn_card(place: String) -> void:
    """バーンカード処理関数
    Args:
        place String: バーンカードの場所
    Returns:
        void
    """
    # デッキからカードを1枚引く
    var card = deck.draw_card()

    # 見た目処理
    if seeing:
        # デッキの場所からバーンカードの場所へ裏面でカードを移動する
        card.front.set_backend(card)
        card.front.show_back()
        card.front.set_position(table_place["Deck"].get_position() - table_place["Burn"]["Instance"].get_position())
        table_place["Burn"][place].add_child(card.front)
        card.front.time_manager.move_to(card.front, table_place["Burn"][place].get_position(), 0.5, Callable(game_process, "_on_moving_finished"))
    else:
        # 待機処理を行う
        card.time_manager.wait_to(1.0, Callable(game_process, "_on_moving_finished"))

    # 移動、待機処理の数分信号を送る
    n_moving_plus.emit()

    # バーンカードをデータとして保持する
    burn_cards.append(card)


func deal_card(seat_assignments: Dictionary, start_position: int = 0) -> void:
    """プレイヤーに1枚だけカードを配る関数
    Args:
        seat_assignments Dictionary: 座席情報
        start_position int: どこから配るか
    Returns:
        void
    """
    # 座席番号をリストに変換してインデックスでアクセス可能にする
    var seats = seat_assignments.keys()

    # 座席数のカウント
    var seat_count = seats.size()

    # プレイヤーが存在する席のみの配列
    var deal_seats = []

    # 座席でループ
    for i in range(seat_count):
        var current_seat = seats[(start_position + i) % seat_count]
        var current_player = seat_assignments[current_seat]

        # プレイヤーがその席にいる場合のみ処理
        if current_player:
            # 配列に追加
            deal_seats.append(current_seat)

    # カードを配る処理
    var wait = 0

    # プレイヤーが存在する席分ループ
    for current_seat in deal_seats:
        # プレイヤー取得
        var current_player = seat_assignments[current_seat]

        # デッキからカードを1枚取得
        var card = deck.draw_card()

        # プレイヤーの手札に追加
        current_player.player_script.hand.append(card)

        # 見た目処理
        if seeing:
            # デッキの位置から表面でプレイヤーの位置に移動する
            card.front.set_backend(card)
            card.front.show_front()

            # Dealer Seatの位置から、current_seat Seat + current_seat Hand1した位置を引いて、全体にHandのスケールの逆数をかける
            card.front.set_position((table_place["Deck"].get_position() - (animation_place[current_seat]["Seat"].get_position() + animation_place[current_seat]["Hand1"].get_position())) * (1 / 0.6))
            animation_place[current_seat]["Hand1"].add_child(card.front)
            card.front.time_manager.wait_move_to(wait, card.front, Vector2(0, 0), 0.5, Callable(game_process, "_on_moving_finished"))
        else:
            # 待機処理を行う
            card.time_manager.wait_wait_to(wait, 1.0, Callable(game_process, "_on_moving_finished"))

        # 移動、待機処理の数分信号を送る
        n_moving_plus.emit()

        # 少しずつずらす分の値
        wait += 0.3


func get_card_param(player: ParticipantBackend) -> Dictionary:
    """プレイヤーが持っている1枚目のカードの情報を返す関数
    Args:
        player ParticipantBackend: 参加者情報
    Returns:
        Dictionary: プレイヤーが持っているカードの情報
    """
    return {
        "rank": player.player_script.hand[0].rank,
        "suit": player.player_script.hand[0].suit,
    }


func set_initial_button(seat_assignments: Dictionary) -> ParticipantBackend:
    """ディーラーボタン初期配置関数
    Args:
        seat_assignments Dictionary: 座席情報
    Returns:
        dealer_player ParticipantBackend: ディーラーボタン所持参加者
    """
    # 座席リストを取得
    var seats = seat_assignments.keys()

    # 初期設定
    var dealer_player = seat_assignments[seats[0]]
    var dealer_seat = "Seat1"

    # ランク定義 (2〜10, J, Q, K, A)
    var ranks = hand_evaluator.RANKS
    var suits = hand_evaluator.SUITS

    # 最高のカードを持つプレイヤーを探す
    for seat in seats:
        # プレイヤー取得
        var current_player = seat_assignments[seat]
        if current_player:
            # 対象のプレイヤーと暫定ディーラーのカードを比較する
            var player_card = get_card_param(current_player)
            var dealer_card
            if dealer_player != null:
                dealer_card = get_card_param(dealer_player)

            # 対象のプレイヤーのほうが強い場合
            if dealer_player == null or (
                ranks[player_card.rank] > ranks[dealer_card.rank] or
                (ranks[player_card.rank] == ranks[dealer_card.rank] and suits[player_card.suit] > suits[dealer_card.suit])):
                # 暫定ディーラーを更新する
                dealer_player = current_player
                dealer_seat = seat

    # ディーラーボタンを動かす
    dealer_player.player_script.is_dealer = true

    # ディーラーボタンクラスの作成
    var dealer_button = DealerButtonBackend.new(seeing)

    # ノードの追加
    add_child(dealer_button)

    # 見た目処理
    if seeing:
        # ディーラーの位置から、ディーラーボタン所持プレイヤーの位置にディーラーボタンを動かす
        dealer_button.front.set_position(animation_place["Dealer"]["Seat"].get_position() + animation_place["Dealer"]["DealerButton"].get_position())
        table_place["DealerButton"].add_child(dealer_button.front)
        dealer_button.front.time_manager.move_to(dealer_button.front, animation_place[dealer_seat]["Seat"].get_position() + animation_place[dealer_seat]["DealerButton"].get_position(), 0.5, Callable(game_process, "_on_moving_finished"))
    else:
        # 待機処理を行う
        dealer_button.time_manager.wait_to(1.0, Callable(game_process, "_on_moving_finished"))

    # 移動、待機処理の数分信号を送る
    n_moving_plus.emit()

    # ディーラーボタン所持プレイヤーを返す
    return dealer_player


func hand_clear(seat_assignments: Dictionary) -> void:
    """全プレイヤーの手札をクリアする関数
    Args:
        seat_assignments Dictionary: 座席情報
    Returns:
        void
    """
    # 座席リストを取得
    var seats = seat_assignments.keys()

    # 座席の数だけループ
    for seat in seats:
        # プレイヤーを取得
        var player = seat_assignments[seat]

        # プレイヤーがいる場合、手を削除する
        if player:
            # 見た目処理
            if seeing:
                # 少し上に持ち上げてから削除する
                var front_node = player.player_script.hand[0].front
                var player_dst = front_node.get_position() + Vector2(0, -50)
                front_node.time_manager.wait_move_to(0.1, front_node, player_dst, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(front_node))
            else:
                # 待機処理
                player.player_script.time_manager.wait_wait_to(0.1, 0.5, Callable(game_process, "_on_moving_finished"))

            # プレイヤーの手を削除
            player.player_script.hand.clear()

            # 移動、待機処理の数分信号を送る
            n_moving_plus.emit()

    # 見た目処理
    if seeing:
        # バーンカードを削除する
        var dst = burn_cards[0].front.get_position() + Vector2(0, -50)
        burn_cards[0].front.time_manager.wait_move_to(0.1, burn_cards[0].front, dst, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(burn_cards[0].front))
    else:
        # 待機処理
        time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))

    # バーンカードを削除する
    burn_cards.clear()

    # 移動、待機処理の数分信号を送る
    n_moving_plus.emit()


func get_dealer_button_index(seat_assignments: Dictionary, count: int = 0) -> String:
    """ディーラーボタンから指定の隣のプレイヤーを取得する関数
    Args:
        seat_assignments Dictionary: 座席情報
        count int: いくつ隣か 初期値0
    Returns:
        active_seats[next_index] String: 指定の数隣の席
    """
    # 座席リストを取得して順番に探索
    var seats = seat_assignments.keys()
    var dealer_seat = null

    # ディーラーを持つ座席を探す
    for seat in seats:
        var player = seat_assignments[seat]
        if player and player.player_script.is_dealer:
            dealer_seat = seat
            break

    # ディーラーが見つからない場合（異常系）
    if dealer_seat == null:
        return ""

    # プレイヤーがいる座席のみをリスト化
    var active_seats = []
    for seat in seats:
        if seat_assignments[seat] != null:
            active_seats.append(seat)

    # 次の座席を計算
    var dealer_index = active_seats.find(dealer_seat)
    var next_index = (dealer_index + count) % active_seats.size()

    # 次の座席の名前を返す
    return active_seats[next_index]


func deal_hole_cards(seat_assignments: Dictionary, hand: String) -> void:
    """各プレイヤーに2枚のホールカードを配る関数
    Args:
        seat_assignments Dictionary: 座席情報
        hand String: 1枚目なのか2枚目なのか
    Returns:
        void
    """
    # 各プレイヤーへのディレイ間隔
    var delay_base = 0.2

    # カード配布アニメーションの時間
    var card_delay = 1.0

    # 次プレイヤーの待機時間
    var total_delay = 0.0

    # 座席リストを取得してソート
    var seats = seat_assignments.keys()

    # カードを配り始めるポジション
    var start_position = (seats.find(get_dealer_button_index(seat_assignments, 1))) % seats.size()

    # 各プレイヤーにカードを1枚ずつ配る関数実行
    total_delay = distribute_single_card(seats, start_position, seat_assignments, total_delay, delay_base, card_delay, hand)


func distribute_single_card(
    seats: Array[String],
    start_position: int,
    seat_assignments: Dictionary,
    base_delay: float,
    delay_base: float,
    card_delay: float,
    hand: String
) -> int:
    """各プレイヤーに1枚のカードを配る関数
    Args:
        seats Array[String]: 座席リスト
        start_position int: カードを配り始めるポジション
        seat_assignments Dictionary: 座席情報
        base_delay float: 次プレイヤーの待機時間
        delay_base float: 各プレイヤーへのディレイ間隔
        card_delay float: カード配布アニメーションの時間
        hand String: 1枚目なのか2枚目なのか
    """
    # 待機時間を変数に
    var delay = base_delay

    # 座席リスト分ループ
    for offset in range(seats.size()):
        # 現在のポジションを計算
        var current_position = (start_position + offset) % seats.size()

        # プレイヤーの取得
        var player = seat_assignments[seats[current_position]]

        # 空の座席をスキップ
        if player != null:
            # カードを1枚取得し、プレイヤーに追加
            var card = deck.draw_card()
            player.player_script.hand.append(card)

            # 見た目処理
            if seeing:
                card.front.set_backend(card)
                # TODO playerだけshow_front(もしくはcard_open？)
                # TODO それ以外はshow_backにする必要あり
                # TODO 今はテストのためにshow_front()
                card.front.show_front()
                # デッキの位置から、current_seat Seat + current_seat Hand1|2した位置を引いて、全体にHandのスケールの逆数をかける
                card.front.set_position((table_place["Deck"].get_position() - (animation_place[seats[current_position]]["Seat"].get_position() + animation_place[seats[current_position]][hand].get_position())) * (1 / 0.6))
                animation_place[seats[current_position]][hand].add_child(card.front)
                card.front.time_manager.wait_move_to(delay, card.front, Vector2(0, 0), card_delay, Callable(game_process, "_on_moving_finished"))
            else:
                # 待機処理
                player.player_script.time_manager.wait_wait_to(delay, card_delay, Callable(game_process, "_on_moving_finished"))

            # 移動、待機処理の数分信号を送る
            n_moving_plus.emit()

            # 次のプレイヤーの待機時間を計算
            delay += delay_base

    # 待機時間を返す
    return delay


func set_action_list(player: ParticipantBackend, current_max_bet: int, seats: Array[String], seat_assignments: Dictionary) -> Array[String]:
    """アクションリストを作成する関数
    Args:
        player ParticipantBackend: アクションリストを作成するプレイヤー
        current_max_bet int: 最大掛け金
        seats Array[String]: 席順
        seat_assignments Dictionary: 座席情報
    Returns:
        action_list Array[String]: アクションリスト
    """
    # アクションリストを保持する配列
    var action_list = []

    # チップを出さなければならない場合
    if bet_record[-1] > player.player_script.current_bet:
        # フォールドのアクションが許可される
        action_list.append("fold")

    # 誰かが賭けているなら
    if bet_record.size() >= 1:
        # 最大掛け金 - すでに自分が賭けている金額が自分の所持チップより少ない場合
        if player.player_script.chips <= current_max_bet - player.player_script.current_bet:
            # オールインが許可される
            action_list.append("all-in")
        else:
            # チップを出さなければならない場合
            if bet_record[-1] > player.player_script.current_bet:
                # コールが許可される
                action_list.append("call")
            else:
                # チップを出さなくてよい場合
                # チェック処理が許可される
                action_list.append("check")

        # 最大掛け金より、自分が賭け、所持しているチップが多い場合
        if current_max_bet < player.player_script.current_bet + player.player_script.chips:
            # 自分より前にチップを出した人がいる場合
            if bet_record[-1] > player.player_script.current_bet:
                # レイズ処理が許可される
                action_list.append("raise")
            else:
                # そうでない場合
                # ベット処理が許可される
                action_list.append("bet")
    else:
        # まだ誰もかけていない場合
        # まずチェック処理が許可される
        action_list.append("check")

        # 再度アクティブなプレイヤーを更新
        var active_players = []

        # フォールドもオールインもしていないプレイヤーを集計
        for seat in seats:
            var p = seat_assignments[seat]
            if p != null and not p.player_script.is_folded and not p.player_script.is_all_in:
                active_players.append(p)

        # アクティブなプレイヤーが一人でもいて、自分が賭け、所持しているチップが多い場合
        if active_players.size() > 1:
            if current_max_bet < player.player_script.current_bet + player.player_script.chips:
                # ベット処理が許可される
                action_list.append("bet")

    # アクションリストを返す
    return action_list


func selected_action(action: String, player: ParticipantBackend, current_max_bet: int, bb_value: int, current_seat: String) -> void:
    """選択されたアクションによってプレイヤーの状態を更新する関数
    Args:
        action String: 選択されたアクション
        player ParticipantBackend: アクションを行うプレイヤオ
        current_max_bet int: 最大掛け金
        bb_value: BBの金額
        current_seat String: 現在の席
    Returns:
        void
    """
    # 選択されたアクションによって分岐
    if action == "fold":
        # フォールドが選択された場合
        # フォールド処理
        player.player_script.fold(seeing)

        # 見た目がある場合、カード破棄アニメーションに対応した信号を送る
        if seeing:
            n_moving_plus.emit()

        # アクション履歴にフォールドを追加
        player.player_script.last_action.append("Fold")
    elif action == "check":
        # チェックが選択された場合
        # 見た目がある場合、対応した信号を送る
        # TODO ここのn_moving_plus（fold含む）結構謎なので調査する
        if seeing:
            player.front.time_manager.move_to(player.front, Vector2(0, 0), 0.5, Callable(game_process, "_on_moving_finished"))

        # アクション履歴にチェックを追加
        player.player_script.last_action.append("Check")
    elif action == "call":
        # コールが選択された場合
        # コールするべき金額を計算
        var call_amount = current_max_bet - player.player_script.current_bet

        # チップ支払処理を行う
        set_bet(call_amount, player, current_seat)

        # アクション履歴にコールを追加
        player.player_script.last_action.append("Call")
    elif action == "bet":
        # ベットが選択された場合
        # 最小掛け金、最大掛け金を計算
        var min_bet = bb_value * 2 - player.player_script.current_bet
        var max_bet = player.player_script.chips

        # 現在チップが最小掛け金より少ない場合、オールインとして処理する
        var bet_amount
        if player.player_script.chips < min_bet:
            bet_amount = player.player_script.chips
        else:
            # そうでない場合、プレイヤーに掛け金を選択させる
            bet_amount = player.player_script.select_bet_amount(min_bet, max_bet)

        # オールイン処理の場合
        if bet_amount == player.player_script.chips:
            # オールインフラグをtrueにする
            player.player_script.is_all_in = true

            # アクション履歴にオールインを追加
            player.player_script.last_action.append("All-In")
        else:
            # そうでない場合、アクション履歴にベットを追加
            player.player_script.last_action.append("Bet")

        # チップ支払処理を行う
        set_bet(bet_amount, player, current_seat)

        # 現在の最大掛け金を更新する
        current_max_bet = bet_amount

        # ベット履歴に賭けた金額を追加
        bet_record.append(player.player_script.current_bet)
    elif action == "raise":
        # レイズが選択された場合
        # 最小掛け金を計算する
        var min_raise
        if bet_record.size() >= 2:
            min_raise = bet_record[-1] - bet_record[-2] + bet_record[-1] - player.player_script.current_bet

        # 最大掛け金はプレイヤーの所持チップまで
        var max_raise = player.chips

        # 現在チップが最小掛け金より少ない場合、オールインとして処理する
        var raise_amount
        if player.player_script.chips < min_raise:
            raise_amount = player.player_script.chips
        else:
            # そうでない場合、プレイヤーに掛け金を選択させる
            raise_amount = player.player_script.select_bet_amount(min_raise, max_raise)

        # オールイン処理の場合
        if raise_amount == player.player_script.chips:
            # オールインフラグをtrueにする
            player.player_script.is_all_in = true

            # アクション履歴にオールインを追加
            player.player_script.last_action.append("All-In")
        else:
            # そうでない場合、アクション履歴にレイズを追加
            player.player_script.last_action.append("Raise")

        # チップ支払処理を行う
        set_bet(raise_amount, player, current_seat)

        # 現在の最大掛け金を更新する
        current_max_bet = raise_amount

        # ベット履歴に賭けた金額を追加
        bet_record.append(player.player_script.current_bet)
    elif action == "all-in":
        # オールインが選択された場合
        # 自分が所持しているチップを全て賭ける
        var all_in_amount = player.player_script.chips

        # チップ支払処理を行う
        set_bet(all_in_amount, player, current_seat)

        # オールインフラグをtrueにする
        player.player_script.is_all_in = true

        # アクション履歴にオールインを追加
        player.player_script.last_action.append("All-In")

        # 現在の最大掛け金より今回の掛け金のほうが多い場合
        if all_in_amount > current_max_bet:
            # 現在の最大掛け金を更新する
            current_max_bet = all_in_amount

        # ベット履歴に賭けた金額を追加
        bet_record.append(player.player_script.current_bet)


func set_bet(amount, player, current_seat) -> void:
    """チップ支払関数
    Args:
        amount int: 掛け金
        player ParticipantBackend: 賭けたプレイヤー
        current_sest String: 賭けた人の席
    Returns:
        void
    """
    # プレイヤーのベット処理
    player.player_script.bet(amount)

    # 見た目処理
    if seeing:
        # 表側のベット処理
        player.front.set_chips(player.player_script.chips)

        # チップの表示部分を作成
        var chip_scene = load("res://scenes/gamecomponents/Chip.tscn")
        var chip_instance = chip_scene.instantiate()

        # ベット用として作成
        chip_instance.set_chip_sprite(false)

        # チップのそばにある数値を更新
        chip_instance.set_bet_value(amount)

        # チップの設置箇所から見て、プレイヤーの原点に設置する
        chip_instance.set_position(-1 * animation_place[current_seat]["Bet"].get_position())

        # すでにチップが存在する場合
        if animation_place[current_seat]["Bet"].get_child_count() > 0:
            # 既に存在しているチップを取得
            var already_chip = animation_place[current_seat]["Bet"].get_child(0)

            # チップに重ねるように動かしつつ、加算。動かしたほうは消去
            chip_instance.time_manager.move_to(chip_instance, Vector2(0, 0), 0.5, Callable(game_process, "_on_moving_finished_add_chip").bind(chip_instance, already_chip))
        else:
            # 新規設置なのでそのまま動かす
            chip_instance.time_manager.move_to(chip_instance, Vector2(0, 0), 0.5, Callable(game_process, "_on_moving_finished"))

        # ノードに追加
        animation_place[current_seat]["Bet"].add_child(chip_instance)
    else:
        # 待機処理
        player.player_script.time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))


func bet_round(seats: Array[String], start_index: int, seat_assignments: Dictionary, bb_value: int, current_action: int) -> String:
    """ベットラウンドのアクションを処理する関数
    Args:
        seats Array[String]: 座席
        start_index int: 開始位置
        seat_assignments: 座席情報
        bb_value: BBの金額
        current_action: いくつ進んだか
    Returns:
        String: アクションの結果、またはアクション
    """
    # 現在アクションを行う座席、その席にいるプレイヤーの取得
    var current_seat = seats[(start_index + current_action) % seats.size()]
    var player = seat_assignments[current_seat]

    # 空席はスキップ
    if player == null:
        return "none_player"

    # フォールドまたはオールインしているプレイヤーはスキップ
    if player.player_script.is_folded:
        return "folded"

    if player.player_script.is_all_in:
        return "all-ined"

    # 現在の最大掛け金を取得
    var current_max_bet = bet_record[-1]

    # アクションのリストを取得
    var action_list = set_action_list(player, current_max_bet, seats, seat_assignments)

    # アクションを行う
    var action = player.player_script.select_action(action_list)

    # 選択したアクションを実行
    selected_action(action, player, current_max_bet, bb_value, current_seat)

    # アクションを行ったフラグをtrueにする
    player.player_script.has_acted = true

    # 再度アクティブなプレイヤーを更新
    var active_players = []
    for seat in seats:
        var p = seat_assignments[seat]
        if p != null and not p.player_script.is_folded and not p.player_script.is_all_in:
            active_players.append(p)

    # レイズやベットの場合、他プレイヤーのアクションフラグをリセット
    if action in ["bet", "raise", "all-in"]:
        for other_player in active_players:
            if other_player != player:
                if other_player.player_script.has_acted:
                    n_active_players_plus.emit()
                other_player.player_script.has_acted = false

    # 見た目処理がない場合
    if not seeing:
        # 待機処理を入れる
        player.player_script.time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))

    # 動作、待機の分だけ信号を送る
    action_finished.emit()

    # 選択されたアクションを返す
    return action


func pot_collect(seat_assignments: Dictionary) -> int:
    """プレイヤーの賭け金をポットとして集める関数
    Args:
        seat_assignments Dictionary: 座席情報
    Returns:
        total_chips int: ポットとして集まった合計金額
    """
    # 現在のアクティブなベット額を収集し、ソート
    var active_bets = []
    for seat in seat_assignments.keys():
        var player = seat_assignments[seat]
        if player != null:
            if not player.player_script.is_folded and player.player_script.current_bet > 0:
                if not player.player_script.current_bet in active_bets:
                    active_bets.append(player.player_script.current_bet)
    active_bets.sort()

    # アクティブなベット額がない場合、0として返す
    if active_bets.size() == 0:
        return 0

    # メインポットに寄与する額をプレイヤーごとに計算する
    var last_bet = 0
    var i = 0
    # ベット額が少ないものから順にループ
    for index in range(active_bets.size()):
        # ベット額を取得
        var bet = active_bets[index]

        # 最初のポット（メインポット）であれば既存のものを使用、それ以外は新しいポットを作成
        var pot
        if index == 0 and pots.size() > 0:
            pot = pots[0]
        else:
            # 寄与が発生する場合のみサブポットを作成
            pot = PotBackend.new()
            pots.append(pot)

        # 各プレイヤーの貢献を計算
        for seat in seat_assignments.keys():
            # 席に座っているプレイヤーを取得
            var player = seat_assignments[seat]

            # プレイヤーがまだゲームに参加している場合
            if player != null and not player.player_script.is_folded:
                # そのポットに対する寄与額を計算
                var contribution = min(bet - last_bet, player.player_script.current_bet)

                # 寄与が存在する場合
                if contribution > 0:
                    # ポットクラスに追加
                    pot.add_contribution(player.player_script.player_name, contribution)

                    # プレイヤーの掛け金から減算
                    player.player_script.current_bet -= contribution

                    # ポットを作成する
                    var chip = ChipBackend.new(seeing)
                    add_child(chip)

                    # 見た目処理がない場合、待機処理を入れる
                    if not seeing:
                        chip.time_manager.wait_wait_to(i * 0.3, 1.0, Callable(game_process, "_on_moving_finished"))
                        n_moving_plus.emit()
                        i += 1

        # 最後のベット額を更新
        last_bet = bet

    # プレイヤーの現在のベットが0でない場合、残りを新しいサイドポットに追加
    for seat in seat_assignments.keys():
        # 席に座っているプレイヤーを取得
        var player = seat_assignments[seat]
        # その席にプレイヤーがいて、ベット額が0でない場合
        if player != null:
            if player.player_script.current_bet > 0:
                # サブポットを作成するのは寄与が発生する場合のみ
                if pots.size() == 0 or player.player_script.current_bet > pots[-1].total:
                    var pot = PotBackend.new()
                    pots.append(pot)
                # ポットの最後に追加しておく
                pots[-1].add_contribution(player.player_script.player_name, player.player_script.current_bet)

                # ポットを作成する
                var chip = ChipBackend.new(seeing)
                add_child(chip)

                # 見た目処理がない場合、待機処理を入れる
                if not seeing:
                    chip.time_manager.wait_wait_to(i * 0.3, 1.0, Callable(game_process, "_on_moving_finished"))
                    n_moving_plus.emit()
                    i += 1

                # プレイヤーの掛け金を0にする
                player.player_script.current_bet = 0

            # アクション履歴を削除する
            player.player_script.last_action.clear()

    # 全てのポットの合計値を返す
    var total_chips = 0
    for pot in pots:
        total_chips += pot.total

    # プレイヤーのチップを集めて消す処理
    if seeing:
        # 席順ごとにループ処理
        for seat in seat_assignments.keys():
            # ベット処理行われている場合
            if animation_place[seat]["Bet"].get_child_count() > 0:
                # 1つしかないので、先頭のノードを取得
                var bet = animation_place[seat]["Bet"].get_child(0)

                # ポットの位置に向かって動かす
                bet.time_manager.move_to(bet, table_place["Pot"].get_position() - (animation_place[seat]["Seat"].get_position() + animation_place[seat]["Bet"].get_position()), 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(bet))
                n_moving_plus.emit()

        # ここで全部集めて、合計値をポットとして表示する
        # すでにポットが存在している場合
        if table_place["Pot"].get_child_count() > 0:
            # そこに合計する
            var already_pot = table_place["Pot"].get_child(0)
            already_pot.set_bet_value(total_chips)
        else:
            # そうでない場合、あらたにポットとしてインスタンスを作成する
            var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
            var chip = chip_instance.instantiate()
            chip.set_chip_sprite(true)
            chip.set_bet_value(total_chips)
            table_place["Pot"].add_child(chip)

    # ポットの合計金額を返す
    return total_chips


func reveal_community_cards(num_cards: Array[String]) -> Array[CardBackend]:
    """指定された枚数のコミュニティカードを公開する関数
    Args:
        num_cards Arra[String]: どこに配置するかの配列
    Returns:
        community_cards Array[CardBackend]: コミュニティカードの配列
    """
    # 指定された枚数のカードを公開
    for place in num_cards:
        # デッキからカードを1枚引く
        var card = deck.draw_card()

        # コミュニティカードに追加
        community_cards.append(card)

        # 見た目処理
        if seeing:
            # 見た目設定
            card.front.set_backend(card)
            card.front.show_front()
            # Dealer Seatの位置から、current_seat Seat + current_seat Hand1した位置を引いて、全体にHandのスケールの逆数をかける
            card.front.set_position(table_place["Deck"].get_position() - table_place["CommunityCard"][place].get_position())
            table_place["CommunityCard"][place].add_child(card.front)

            # 移動処理
            card.front.time_manager.move_to(card.front, Vector2(0, 0), 0.5, Callable(game_process, "_on_moving_finished"))
        else:
            # 待機処理
            card.time_manager.wait_to(1.0, Callable(game_process, "_on_moving_finished"))

        # 動作、待機の分だけ信号を送る
        n_moving_plus.emit()

    # コミュニティカードを返す
    return community_cards


func compare_players(a: ParticipantBackend, b: ParticipantBackend) -> bool:
    """手の強さを比較する関数
    Args:
        a ParticipantBackend: 比較対象1
        b ParticipantBackend: 比較対象2
    Returns:
        bool: ソートするかどうか
    """
    # 1. 手役の強さを比較
    if a.player_script.hand_category[1] != b.player_script.hand_category[1]:
        return a.player_script.hand_category[1] > b.player_script.hand_category[1]

    # 2. ランクの強さを比較
    for i in range(min(a.player_script.hand_rank.size(), b.player_script.hand_rank.size())):
        if a.player_script.hand_rank[i] != b.player_script.hand_rank[i]:
            return a.player_script.hand_rank[i] > b.player_script.hand_rank[i]

    return false

func evaluate_hand(seat_assignments: Dictionary) -> Array[ParticipantBackend]:
    """手の強さ比較関数
    Args:
        seat_assignments Dictionary: 座席情報
    Returns:
        active_players Array[ParticipantBackend]: 手の強さ順に並べたプレイヤーリスト
    """
    # フォールドしていないプレイヤーを取得
    var active_players = []
    for seat in seat_assignments.keys():
        var player = seat_assignments[seat]
        if player != null and not player.player_script.is_folded:
            active_players.append(player)

    # 複数人の場合、手を評価
    for player in active_players:
        var hand_category_rank = hand_evaluator.evaluate_hand(player.player_script.hand, community_cards)
        player.player_script.hand_category = hand_category_rank["category"]
        player.player_script.hand_rank = hand_category_rank["rank"]

    # プレイヤーをソート
    active_players.sort_custom(compare_players)

    return active_players


func distribute_pots(active_players: Array[ParticipantBackend], seat_assignments: Dictionary) -> void:
    """ポットをプレイヤーに分配する関数
    Args:
        active_players Array[ParticipantBackend]: 手の強さ順に並べたプレイヤーリスト,
        seat_assignments Dictionary: 座席情報
    Returns:
        void
    """
    # プレイヤーが1人ならそのまま全ポットを獲得
    if active_players.size() == 1:
        # 先頭の人だけ取得
        var winner = active_players[0]

        # ポットの合計値を計算
        var total_chips = 0
        for pot in pots:
            total_chips += pot.total

        # 勝者に加算
        winner.player_script.chips += total_chips

        # 勝者の席を取得
        var winner_seat = null
        for seat in seat_assignments.keys():
            var player = seat_assignments[seat]
            if player != null and player.player_script.player_name == winner.player_script.player_name:
                winner_seat = seat

        # 見た目処理
        if seeing:
            # チップ数表示を更新
            winner.front.set_chips(winner.player_script.chips)

            # ポットの位置から、勝者の位置に移動
            var pot = table_place["Pot"].get_child(0)
            pot.time_manager.move_to(pot, (animation_place[winner_seat]["Seat"].get_position() + animation_place[winner_seat]["Bet"].get_position()) - table_place["Pot"].get_position(), 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(pot))
        else:
            # 待機処理
            time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))

        # 動作、待機の分だけ信号を送る
        n_moving_plus.emit()
        return

    # ポットごとに分配
    for pot in pots:
        # 祖のポットにおけるプレイヤーの貢献度を取得
        var contributors = pot.contributions.keys()

        # 貢献地が存在する場合
        if contributors.size() > 0:
            # ポットを受け取ることが可能な人の中から、貢献度を持っている人を取得
            var eligible_players = active_players.filter(func(player): return player.player_script.player_name in contributors)

            # チェック: eligible_playersが空の場合、スキップ
            if eligible_players.size() == 0:
                continue

            # 最も強いプレイヤーを取得
            var strongest_hand = eligible_players[0].player_script.hand_rank
            var winners = eligible_players.filter(func(player): return player.player_script.hand_rank == strongest_hand)

            # 勝者にポットを分配
            var chips_per_winner = pot.total / winners.size()
            var i = 1
            for winner in winners:
                # 勝者にチップを加算
                winner.player_script.chips += chips_per_winner

                # 勝者の席を取得
                var winner_seat
                for seat in seat_assignments.keys():
                    var player = seat_assignments[seat]
                    if player != null and player.player_script.player_name == winner.player_script.player_name:
                        winner_seat = seat

                # 見た目処理
                if seeing:
                    # チップ数表示を更新
                    winner.front.set_chips(chips_per_winner)

                    # チップが分割されるかどうか
                    var pot_front = null
                    if i == winners.size():
                        # 最後に残ったポットを移動する
                        pot_front = table_place["Pot"].get_child(0)
                    else:
                        # 新たにチップを作って、移動する
                        var pot_instance = load("res://scenes/gamecomponents/Chip.tscn")
                        pot_front = pot_instance.instantiate()
                        pot_front.set_chip_sprite(true)
                        pot_front.set_bet_value(chips_per_winner)
                        table_place["Pot"].add_child(pot_front)
                        table_place["Pot"].get_child(0).set_bet_value(-1 * chips_per_winner)
                    pot_front.time_manager.move_to(pot_front, (animation_place[winner_seat]["Seat"].get_position() + animation_place[winner_seat]["Bet"].get_position()) - table_place["Pot"].get_position(), 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(pot_front))

                    # 動作、待機の分だけ信号を送る
                    n_moving_plus.emit()

                    # いくつのポットを動かしたかを加算
                    i += 1

    # 見た目処理がない場合、待機処理を入れる
    if not seeing:
        time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))
        n_moving_plus.emit()


func reset_round(seat_assignments: Dictionary, buy_in: int) -> void:
    """ラウンドの終了後に必要な情報をリセットする
    Args:
        seat_assignments Dictionary: 座席情報
        buy_in int: 持ち込みチップ数
    Returns:
        void
    """
    # 0. 各Node（deck、chip）のremove
    for child in get_children():
        # 子ノードに接続されているシグナルを解除
        for signal_name in child.get_signal_list():
            if child.is_connected(signal_name["name"], Callable(self, "_signal_handler")):
                child.disconnect(signal_name["name"], Callable(self, "_signal_handler"))

        # 子ノードを削除
        remove_child(child)
        child.queue_free()

    # 1. 各プレイヤーのカレントベットと手札をリセット
    if seeing:
        var seats = seat_assignments.keys()
        for seat in seats:
            var player = seat_assignments[seat]
            if player and player.player_script.hand.size() == 2:
                # 少し上に持ち上げて削除する
                var hand = player.player_script.hand[0].front
                var dst1 = hand.get_position() + Vector2(0, -50)
                hand.time_manager.wait_move_to(0.1, hand, dst1, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(hand))
                hand = player.player_script.hand[1].front
                var dst2 = hand.get_position() + Vector2(0, -50)
                hand.time_manager.wait_move_to(0.1, hand, dst2, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(hand))
                n_moving_plus.emit()
                n_moving_plus.emit()

    # プレイヤー情報のリセット
    for seat in seat_assignments.keys():
        var player = seat_assignments[seat]
        if player != null:
            player.player_script.hand = []
            player.player_script.current_bet = 0  # 現在のベット額
            player.player_script.last_action = []  # 最後のアクションを保存する属性
            player.player_script.has_acted = false
            player.player_script.is_folded = false  # プレイヤーがフォールドしたかどうかを示すフラグ
            player.player_script.is_all_in = false
            player.player_script.hand_category = null
            player.player_script.hand_rank = null
            # a. いったんここでchipsが0なら100に戻すように設定
            if player.player_script.chips == 0:
                player.player_script.chips = buy_in
                if seeing:
                    player.front.set_chips(buy_in)

    # 2. コミュニティカード、バーンカードのリセット
    if seeing:
        for j in range(community_cards.size()):
            var card_front = community_cards[j].front
            var community_card = card_front.get_position() + Vector2(0, -50)
            card_front.time_manager.move_to(card_front, community_card, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(card_front))
            n_moving_plus.emit()

        for k in range(burn_cards.size()):
            var card_front = burn_cards[k].front
            var burn_card_place = card_front.get_position() + Vector2(0, -50)
            card_front.time_manager.move_to(card_front, burn_card_place, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(card_front))
            n_moving_plus.emit()

    community_cards = []
    burn_cards = []

    # 3. ポットのリセット
    pots.clear()
    pots.append(PotBackend.new())

    # 4. ベット履歴のリセット
    bet_record.clear()

    # 5. デッキのリセット
    deck = DeckBackend.new(seeing)
    add_child(deck)

    # 6. タイムマネージャーのリセット
    time_manager = TimeManager.new()
    add_child(time_manager)

    # n. その他の必要な情報をリセット（必要に応じて追加）

    # 見た目がない場合、待機処理
    if not seeing:
        time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))
        n_moving_plus.emit()


func move_dealer_button(seat_assignments: Dictionary) -> void:
    """ディーラーボタンを次のプレイヤーに移動します
    Args:
        seat_assignments Dictionary: 座席情報
    Returns:
        void
    """
    # 現在のディーラーを見つける
    var current_dealer_seat = null
    for seat in seat_assignments.keys():
        var player = seat_assignments[seat]
        if player != null and player.player_script.is_dealer:
            current_dealer_seat = seat
            break

    # 現在のディーラーのフラグをFalseにする
    if current_dealer_seat != null:
        seat_assignments[current_dealer_seat].player_script.is_dealer = false

    # プレイヤーがいる座席のみをリスト化
    var active_seats = []
    for seat in seat_assignments.keys():
        if seat_assignments[seat] != null:
            active_seats.append(seat)

    # 現在のディーラーの座席を基準に次のディーラーを決定
    var current_index = active_seats.find(current_dealer_seat)
    var next_index = (current_index + 1) % active_seats.size()
    var next_dealer_seat = active_seats[next_index]

    # 次のディーラーのフラグをTrueにする
    if seat_assignments[next_dealer_seat] != null:
        seat_assignments[next_dealer_seat].player_script.is_dealer = true

    # 見た目処理
    if seeing:
        # ディーラーボタンを次のプレイヤーに動かす
        var dealer_button_node = table_place["DealerButton"].get_children(0)[0]
        dealer_button_node.time_manager.move_to(dealer_button_node, animation_place[next_dealer_seat]["Seat"].get_position() + animation_place[next_dealer_seat]["DealerButton"].get_position(), 0.5, Callable(game_process, "_on_moving_finished"))
    else:
        # 待機処理
        time_manager.wait_to(0.5, Callable(game_process, "_on_moving_finished"))

    # 動作、待機の分だけ信号を送る
    n_moving_plus.emit()


func to_str() -> String:
    """属性表示関数
    Args:
    Returns:
        result String: インスタンスの現在の属性をまとめた文字列
    """
    var result = "=== DeckBackend 状態 ===\n"
    result += "ベット履歴: " + str(bet_record) + "\n"
    # community_cards の情報を文字列として取得
    if community_cards.size() > 0:
        var community_card_strings = []
        for card in community_cards:
            community_card_strings.append(card.to_str())
        result += "コミュニティカード: " + ", ".join(community_card_strings) + "\n"
    else:
        result += "コミュニティカード: なし\n"
    if burn_cards.size() > 0:
        var burn_card_strings = []
        for card in burn_cards:
            burn_card_strings.append(card.to_str())
        result += "バーンカード: " + ", ".join(burn_card_strings) + "\n"
    else:
        result += "コミュニティカード: なし\n"
    result += "=======================\n"
    return result