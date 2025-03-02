extends GutTest

var dealer

var game_process_mock = DummyGameProcessBackend.new()

# モックの `GameProcessBackend`
class DummyGameProcessBackend extends GameProcessBackend:
    func _init(
        _bet_size: Dictionary = {},
        _buy_in: int = 0,
        _dealer_name: String = "",
        _selected_cpus: Array[String] = [],
        _table_place: Dictionary = {},
        _animation_place: Dictionary = {},
        _player_flg: bool = false,
        _seeing: bool = false,
    ):
        pass


func before_each():
    # テスト前に `ParticipantBackend` を初期化
    dealer = DealerBackend.new(game_process_mock, false)

    add_child(dealer)


func after_each():
    # メモリリークを防ぐ
    dealer.queue_free()


func test_ready():

    # `card` をツリーに追加
    await get_tree().process_frame  # `_ready()` の実行を待つ
    await get_tree().process_frame  # `_ready()` の実行を待つ

    # `time_manager` が追加されているかチェック
    var time_manager = dealer.get_node_or_null("TimeManager")

    assert_not_null(time_manager, "time_manager should be added as a child node")


func test_burn_card():
    """バーンカードのテスト"""

    # `DeckBackend` をダブルにする
    var deck_double = double(DeckBackend).new(false)
    var card = CardBackend.new("A", "Spades", false)
    add_child(card)
    stub(deck_double, "draw_card").to_return(card)
    dealer.deck = deck_double

    # `TimeManager` をダブルにする
    var time_manager_double = double(TimeManager).new()
    stub(time_manager_double, "wait_to")  # `wait_to()` が呼ばれることを期待
    dealer.time_manager = time_manager_double

    # シグナルをウォッチ
    watch_signals(dealer)

    # テスト実行
    dealer.burn_card("Burn1")

    # ✅ 1. カードがデッキから1枚引かれたか
    assert_called(deck_double, "draw_card")

    # ✅ 2. burn_cards に追加されているか
    assert_eq(dealer.burn_cards.size(), 1, "バーンカードが1枚追加されるべき")
    assert_true(dealer.burn_cards[-1] is CardBackend, "追加されたカードが正しい")

    # ✅ 4. `n_moving_plus.emit()` が発火しているか
    assert_signal_emitted(dealer, "n_moving_plus")


func test_deal_card():
    """1枚のカードが適切にプレイヤーに配られるかを確認"""

    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "TestPlayer1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "TestPlayer2", 1000, false, "player", false),
    }

    dealer.seats = dealer.seat_assignments.keys()

    dealer.deal_card()

    # シグナルをウォッチ
    watch_signals(dealer)

    # ✅ 2. 各プレイヤーの手札にカードが追加されているか
    assert_eq(dealer.seat_assignments["Seat1"].player_script.hand.size(), 1, "プレイヤーの手札が増えているべき")
    assert_eq(dealer.seat_assignments["Seat2"].player_script.hand.size(), 1, "プレイヤーの手札が増えているべき")

    # ✅ 4. `n_moving_plus.emit()` が発火しているか
    assert_has_signal(dealer, "n_moving_plus")


func test_get_card_param():
    """プレイヤーの1枚目のカード情報を正しく取得できるかを確認"""

    # ✅ 1. 手札がある場合 (正常系)
    var player = ParticipantBackend.new(game_process_mock, "TestPlayer", 1000, false, "player", false)
    var card = CardBackend.new("A", "Spades", false)  # モックカード
    player.player_script.hand.append(card)

    var expected = {"rank": "A", "suit": "Spades"}
    var actual = dealer.get_card_param(player)

    assert_eq(actual, expected, "get_card_param() should return correct rank and suit")


func test_set_initial_button():
    """ディーラーボタンの初期配置が正しく行われるかを確認"""

    # ✅ 1. プレイヤーが1人しかいない場合
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "SoloPlayer", 1000, false, "player", false),
    }
    dealer.seats = dealer.seat_assignments.keys()
    var solo_player = dealer.seat_assignments["Seat1"]
    dealer.seat_assignments["Seat1"].player_script.hand.append(CardBackend.new("5", "Spades", false))
    var result = dealer.set_initial_button()

    assert_eq(result, solo_player, "唯一のプレイヤーがディーラーになるべき")
    assert_true(result.player_script.is_dealer, "ディーラーのフラグが正しく設定されるべき")

    # ✅ 2. 強いカードを持つプレイヤーが選ばれるか
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
    }
    dealer.seats = dealer.seat_assignments.keys()
    dealer.seat_assignments["Seat1"].player_script.hand.append(CardBackend.new("5", "Spades", false))
    dealer.seat_assignments["Seat2"].player_script.hand.append(CardBackend.new("K", "Diamonds", false))  # 一番強いカード

    var expected_dealer = dealer.seat_assignments["Seat2"]
    var actual_dealer = dealer.set_initial_button()

    assert_eq(actual_dealer, expected_dealer, "最強のカードを持つプレイヤーがディーラーになるべき")
    assert_true(actual_dealer.player_script.is_dealer, "ディーラーのフラグが正しく設定されるべき")

    # ✅ 3. 同じランクのカードを持つプレイヤーがいる場合、スートで判定
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
    }
    dealer.seats = dealer.seat_assignments.keys()
    dealer.seat_assignments["Seat1"].player_script.hand.append(CardBackend.new("Q", "Clubs", false))  # クラブのQ
    dealer.seat_assignments["Seat2"].player_script.hand.append(CardBackend.new("Q", "Spades", false))  # スペードのQ (スートが強い)

    var expected_stronger_suit = dealer.seat_assignments["Seat2"]
    var actual_stronger_suit = dealer.set_initial_button()

    assert_eq(actual_stronger_suit, expected_stronger_suit, "同じランクならスートが強い方がディーラーになるべき")
    assert_true(actual_stronger_suit.player_script.is_dealer, "ディーラーのフラグが正しく設定されるべき")


func test_hand_clear():
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
    }
    dealer.seats = dealer.seat_assignments.keys()
    dealer.seat_assignments["Seat1"].player_script.hand.append(CardBackend.new("5", "Spades", false))
    dealer.seat_assignments["Seat2"].player_script.hand.append(CardBackend.new("K", "Diamonds", false))  # 一番強いカード

    dealer.burn_cards.append(CardBackend.new("5", "Spades", false))

    assert_eq(dealer.seat_assignments["Seat1"].player_script.hand.size(), 1)
    assert_eq(dealer.seat_assignments["Seat2"].player_script.hand.size(), 1)
    assert_eq(dealer.burn_cards.size(), 1)

    dealer.hand_clear()

    assert_eq(dealer.seat_assignments["Seat1"].player_script.hand.size(), 0)
    assert_eq(dealer.seat_assignments["Seat2"].player_script.hand.size(), 0)
    assert_eq(dealer.burn_cards.size(), 0)


func test_get_dealer_button_index():
    """ディーラーボタンの隣のプレイヤーを取得するテスト"""

    # 1. **ディーラーを含む座席のセットアップ**
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
        "Seat3": ParticipantBackend.new(game_process_mock, "Player3", 1000, false, "player", false),
        "Dealer": ParticipantBackend.new(game_process_mock, "Dealer", 1000, false, "playing_dealer", false),
    }
    dealer.seats = ["Seat1", "Seat2", "Seat3", "Dealer"]

    # **Dealer をディーラーに設定**
    dealer.seat_assignments["Dealer"].player_script.is_dealer = true

    # 2. **ディーラーの席を取得する**
    var seat_0 = dealer.get_dealer_button_index(0)
    assert_eq(seat_0, "Dealer", "count = 0 の場合、ディーラーの座席を取得するべき")

    # 3. **次のプレイヤーを取得する**
    var seat_1 = dealer.get_dealer_button_index(1)
    assert_eq(seat_1, "Seat1", "count = 1 の場合、Seat1 を取得するべき")

    # 4. **さらに次のプレイヤーを取得する**
    var seat_2 = dealer.get_dealer_button_index(2)
    assert_eq(seat_2, "Seat2", "count = 2 の場合、Seat2 を取得するべき")

    # 5. **Seat3 から 2 個進んで Seat1 に戻るか確認**
    var seat_3_start = dealer.get_dealer_button_index(2)
    assert_eq(seat_3_start, "Seat2", "count = 2 で Seat3 から Seat1 に移動するべき")

    # 6. **逆方向のテスト**
    var seat_neg1 = dealer.get_dealer_button_index(-1)
    assert_eq(seat_neg1, "Seat3", "count = -1 の場合、前の Seat3 に戻るべき")

    # 7. **ディーラーがいない場合**
    dealer.seat_assignments["Dealer"].player_script.is_dealer = false
    var no_dealer = dealer.get_dealer_button_index(0)
    assert_eq(no_dealer, "", "ディーラーがいない場合、空文字を返すべき")

    # 8. **プレイヤーが1人しかいない場合**
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false)
    }
    dealer.seats = ["Seat1"]
    dealer.seat_assignments["Seat1"].player_script.is_dealer = true

    var single_player = dealer.get_dealer_button_index(1)
    assert_eq(single_player, "Seat1", "プレイヤーが1人の場合、同じ Seat1 を返すべき")


func test_deal_hole_cards():
    """各プレイヤーに2枚のホールカードを配る処理のテスト"""

    # **座席とプレイヤーをセットアップ**
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
        "Seat3": ParticipantBackend.new(game_process_mock, "Player3", 1000, false, "player", false),
        "Dealer": ParticipantBackend.new(game_process_mock, "Dealer", 1000, false, "playing_dealer", false),
    }
    dealer.seats = ["Seat1", "Seat2", "Seat3", "Dealer"]

    # **ディーラーを設定**
    dealer.seat_assignments["Dealer"].player_script.is_dealer = true

    # **テスト実行 (1枚目)**
    dealer.deal_hole_cards("Hand1")

    # ✅ 1. **ディーラーの次のプレイヤーからカードが配られたか**
    var start_seat = dealer.get_dealer_button_index(1)
    assert_eq(start_seat, "Seat1", "ディーラーの次の席 'Seat1' から開始されるべき")

    # ✅ 2. **各プレイヤーに1枚目のカードが配られたか**
    assert_eq(dealer.seat_assignments["Seat1"].player_script.hand.size(), 1, "Seat1 のプレイヤーは1枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Seat2"].player_script.hand.size(), 1, "Seat2 のプレイヤーは1枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Seat3"].player_script.hand.size(), 1, "Seat3 のプレイヤーは1枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Dealer"].player_script.hand.size(), 1, "Dealer のプレイヤーは1枚のカードを持つべき")

    # ✅ 3. **2枚目のカードを配る**
    dealer.deal_hole_cards("Hand2")

    assert_eq(dealer.seat_assignments["Seat1"].player_script.hand.size(), 2, "Seat1 のプレイヤーは2枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Seat2"].player_script.hand.size(), 2, "Seat2 のプレイヤーは2枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Seat3"].player_script.hand.size(), 2, "Seat3 のプレイヤーは2枚のカードを持つべき")
    assert_eq(dealer.seat_assignments["Dealer"].player_script.hand.size(), 2, "Dealer のプレイヤーは2枚のカードを持つべき")

    # ✅ 4. **カードが `CardBackend` インスタンスであること**
    assert_true(dealer.seat_assignments["Seat1"].player_script.hand[0] is CardBackend, "配られたカードは CardBackend であるべき")
    assert_true(dealer.seat_assignments["Seat2"].player_script.hand[1] is CardBackend, "配られたカードは CardBackend であるべき")

    # # ✅ 5. **`seeing == false` の場合、待機処理が発生**
    # assert_called(dealer.seat_assignments["Seat1"].player_script.time_manager, "wait_wait_to", 2)
    # assert_called(dealer.seat_assignments["Seat2"].player_script.time_manager, "wait_wait_to", 2)

    # ✅ 6. **シグナル `n_moving_plus.emit()` が2回発火**
    assert_has_signal(dealer, "n_moving_plus")


func test_set_action_list():
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
        "Seat3": ParticipantBackend.new(game_process_mock, "Player3", 1000, false, "player", false),
        "Dealer": ParticipantBackend.new(game_process_mock, "Dealer", 1000, false, "playing_dealer", false),
    }
    dealer.seats = ["Seat1", "Seat2", "Seat3", "Dealer"]

    dealer.seat_assignments["Dealer"].player_script.is_dealer = true

    # **ダミーのプレイヤーを作成**
    var player = dealer.seat_assignments["Seat3"]

    # **状況別にテストを実行**
    var test_cases = [
        # 1. 初手のプレイヤー → コールとレイズが可能
        {
            "bet_record": [1, 2], "current_max_bet": 2, "current_bet": 0, "chips": 1000,
            "expected": ["fold", "call", "raise"]
        },
        # 2. 誰かがベット済みで、プレイヤーがまだコールしていない → フォールドとコール、レイズが可能
        {
            "bet_record": [50], "current_max_bet": 50, "current_bet": 0, "chips": 1000,
            "expected": ["fold", "call", "raise"]
        },
        # 3. 誰もベットしていない状況 → チェックとベットが可能
        {
            "bet_record": [], "current_max_bet": 0, "current_bet": 0, "chips": 1000,
            "expected": ["check", "bet"]
        },
        # 4. 所持チップが足りないが、コールできる → オールインのみ可能
        {
            "bet_record": [100, 1000], "current_max_bet": 1000, "current_bet": 0, "chips": 500,
            "expected": ["fold", "all-in"]
        },
        # 5. 誰かがベット済みで、プレイヤーがすでにコール済み → チェックとベットが可能
        {
            "bet_record": [50], "current_max_bet": 50, "current_bet": 50, "chips": 1000,
            "expected": ["check", "bet"]
        },
    ]

    for case in test_cases:
        dealer.bet_record = case["bet_record"]
        player.player_script.current_bet = case["current_bet"]
        player.player_script.chips = case["chips"]

        # **アクションリストを生成**
        var action_list = dealer.set_action_list(player, case["current_max_bet"])

        # **結果を検証**
        assert_eq(action_list, PackedStringArray(case["expected"]), "期待されるアクションリストと一致するべき")


func test_selected_action():
    """選択されたアクションによってプレイヤーの状態を適切に更新するか確認"""

    # **ダミーのプレイヤーを作成**
    var player = ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false)
    dealer.seat_assignments["Seat1"] = player

    # `set_bet` をモック化する
    watch_signals(dealer)
    watch_signals(player.player_script)
    watch_signals(player.player_script.time_manager)

    # テストケース
    var test_cases = [
        {
            "action": "fold",
            "expected_last_action": "Fold",
            "expected_is_folded": true,
            "expected_bet": null,
        },
        {
            "action": "check",
            "expected_last_action": "Check",
            "expected_is_folded": false,
            "expected_bet": null,
        },
        {
            "action": "call",
            "current_max_bet": 100,
            "current_bet": 50,
            "expected_last_action": "Call",
            "expected_bet": 50,
        },
        {
            "action": "bet",
            "bb_value": 50,
            "current_bet": 0,
            "expected_last_action": "Bet",
            "expected_bet": 100,
        },
        {
            "action": "raise",
            "bet_record": [50, 100],
            "current_max_bet": 100,
            "current_bet": 50,
            "expected_last_action": "Raise",
            "expected_bet": 150,
        },
        {
            "action": "all-in",
            "chips": 200,
            "expected_last_action": "All-In",
            "expected_is_all_in": true,
            "expected_bet": 200,
        },
    ]

    for case in test_cases:
        # 初期化
        player.player_script.last_action.clear()
        player.player_script.is_folded = false
        player.player_script.is_all_in = false
        player.player_script.current_bet = case.get("current_bet", 0)
        player.player_script.chips = case.get("chips", 1000)
        dealer.bet_record = case.get("bet_record", [0])

        # アクションを実行
        dealer.selected_action(
            case["action"],
            player,
            case.get("current_max_bet", 0),
            case.get("bb_value", 50),
            "Seat1"
        )

        # ✅ 1. `last_action` に適切なアクションが追加されたか
        assert_eq(player.player_script.last_action[-1], case["expected_last_action"], "アクション履歴が正しい")

        # ✅ 2. `is_folded` または `is_all_in` のフラグが正しく設定されているか
        if "expected_is_folded" in case:
            assert_eq(player.player_script.is_folded, case["expected_is_folded"], "フォールド状態が正しい")

        if "expected_is_all_in" in case:
            assert_eq(player.player_script.is_all_in, case["expected_is_all_in"], "オールイン状態が正しい")

        # ✅ 3. `set_bet()` が適切に呼ばれたか
        # if case["expected_bet"] != null:
        #     assert_called(dealer, "set_bet", [case["expected_bet"], player, "Seat1"])

        # ✅ 4. `n_moving_plus.emit()` が適切に発火しているか
        assert_has_signal(dealer, "n_moving_plus")


func test_bet_round():
    """ベットラウンドのアクション処理が正しく動作するかテスト"""

    # **プレイヤーを作成**
    dealer.seat_assignments = {
        "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
        "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
        "Seat3": ParticipantBackend.new(game_process_mock, "Player3", 1000, false, "player", false),
        "Seat4": null,
    }
    dealer.seats = ["Seat1", "Seat2", "Seat3"]

    # ダミープレイヤー
    var player = dealer.seat_assignments["Seat1"]

    # `set_action_list`, `selected_action`, `n_active_players_plus.emit()` をモック化
    watch_signals(dealer)
    watch_signals(player.player_script)

    # **テストケース**
    var test_cases = [
        # 1. 空席
        # {
        #     "seat": "Seat4", "start_index": 0, "current_action": 5, "expected_result": "none_player"
        # },
        # 2. フォールド済み
        {
            "seat": "Seat1", "start_index": 0, "current_action": 0, "is_folded": true, "is_all_in": false, "expected_result": "folded"
        },
        # 3. オールイン済み
        {
            "seat": "Seat1", "start_index": 1, "current_action": 0, "is_folded": false, "is_all_in": true, "expected_result": "all-in"
        },
        # 4. アクションが実行される（コール）
        {
            "seat": "Seat1", "start_index": 0, "current_action": 0, "is_folded": false, "is_all_in": false, "bet_record": [50], "current_max_bet": 50, "expected_result": "all-in"
        },
        # 5. レイズの場合、n_active_players_plus.emit() が発火するか
        {
            "seat": "Seat1", "start_index": 1, "current_action": 0, "is_folded": false, "is_all_in": false, "bet_record": [50], "current_max_bet": 50, "expected_result": "all-ined"
        },
    ]

    for case in test_cases:
        # **状態のリセット**
        player.player_script.is_folded = case.get("is_folded", false)
        player.player_script.is_all_in = case.get("is_all_in", false)
        dealer.bet_record = case.get("bet_record", [0])

        # **テスト対象関数を実行**
        var result = dealer.bet_round(case["start_index"], 50, case["current_action"])

        # ✅ 1. 返り値のチェック
        assert_eq(result, case["expected_result"], "期待される結果と一致するべき")

        # ✅ 3. `n_active_players_plus.emit()` が発火するか（レイズ時）
        if case.get("expected_action") == "raise":
            assert_has_signal(dealer, "n_active_players_plus")

        # ✅ 4. `action_finished.emit()` が発火しているか
        assert_has_signal(dealer, "action_finished")


# func test_pot_collect():
#     """ポットの集計処理が正しく動作するかテスト"""

    # # **プレイヤーを作成**
    # dealer.seat_assignments = {
    #     "Seat1": ParticipantBackend.new(game_process_mock, "Player1", 1000, false, "player", false),
    #     "Seat2": ParticipantBackend.new(game_process_mock, "Player2", 1000, false, "player", false),
    #     "Seat3": ParticipantBackend.new(game_process_mock, "Player3", 1000, false, "player", false),
    # }
    # dealer.seats = ["Seat1", "Seat2", "Seat3"]

    # # **シグナル監視**
    # watch_signals(dealer)

    # # **テストケース**
    # var test_cases = [
    #     # 1. 全員フォールド済み（ポットなし）
    #     {
    #         "bets": {"Seat1": 0, "Seat2": 0, "Seat3": 0},
    #         "folds": ["Seat1", "Seat2", "Seat3"],
    #         "expected_pot": 0
    #     },
    #     # 2. 1人がベット、他はフォールド
    #     {
    #         "bets": {"Seat1": 50, "Seat2": 0, "Seat3": 0},
    #         "folds": ["Seat2", "Seat3"],
    #         "expected_pot": 50
    #     },
    #     # 3. 2人がベット（ポットが統合される）
    #     {
    #         "bets": {"Seat1": 100, "Seat2": 100, "Seat3": 0},
    #         "folds": ["Seat3"],
    #         "expected_pot": 200
    #     },
    #     # 4. 1人オールイン（サイドポット）
    #     {
    #         "bets": {"Seat1": 500, "Seat2": 1000, "Seat3": 1000},
    #         "folds": [],
    #         "expected_pot": 2500  # サイドポット + メインポット
    #     }
    # ]

    # for case in test_cases:
    #     # **状態リセット**
    #     for seat in dealer.seat_assignments.keys():
    #         dealer.seat_assignments[seat].player_script.current_bet = case["bets"][seat]
    #         dealer.seat_assignments[seat].player_script.is_folded = seat in case["folds"]

    #     # **テスト対象関数を実行**
    #     var result = dealer.pot_collect()

    #     # ✅ 1. ポットの合計が正しいか
    #     assert_eq(result, case["expected_pot"], "ポットの合計が期待される値と一致するべき")

    #     # ✅ 2. プレイヤーのベット額が適切に0になっているか
    #     for seat in dealer.seat_assignments.keys():
    #         assert_eq(dealer.seat_assignments[seat].player_script.current_bet, 0, "ベット額は0になっているべき")

    #     # ✅ 3. `n_moving_plus.emit()` が発火しているか
    #     assert_signal_emitted(dealer, "n_moving_plus")


func test_distribute_pots():

    # テストケース1
    # 勝者が一人のパターン（メインポットのみ）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   10
    Seat3   10
    Seat4   10
    Seat5   10
    Seat6   10
    Seat7   10
    Seat8   10
    Seat9   10
    Seat10   10
    Dealer   10
    としたとき、Seat1から順に全員が賭けた場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    """
    # アクティブプレイヤーは1人のパターン
    single_active_player_single_winner_main_pot()

    # アクティブプレイヤーは1人以上、勝者は一人
    multiple_active_player_single_winner_main_pot()

    # テストケース2
    # 勝者が一人以上のパターン（メインポットのみ）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   10
    Seat3   10
    Seat4   10
    Seat5   10
    Seat6   10
    Seat7   10
    Seat8   10
    Seat9   10
    Seat10   10
    Dealer   10
    としたとき、Seat1から順に全員が賭けた場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    """

    """
    ２人勝ち引き分けまで
    """
    multiple_winners_main_pot()


    # テストケース3
    # 勝者が一人のパターン（サブポットあり）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   10
    Seat3   10
    Seat4   20
    Seat5   20
    Seat6   20
    Seat7   30
    Seat8   30
    Seat9   30
    Seat10   40
    Dealer   40
    としたとき、Seat1から順に全員が賭けた場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    サブポット1  Seat4～Dealer   10
    サブポット2  Seat7～Dealer   10
    サブポット3  Seat10～Dealer   10
    """
    # アクティブプレイヤーは1人のパターン
    single_active_player_single_winner_with_side_pot()

    # アクティブプレイヤーは1人以上、勝者は一人
    multiple_active_player_single_winner_with_side_pot()


    # テストケース4
    # 勝者が一人以上のパターン（サブポットあり）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   10
    Seat3   10
    Seat4   20
    Seat5   20
    Seat6   20
    Seat7   30
    Seat8   30
    Seat9   30
    Seat10   40
    Dealer   40
    としたとき、Seat1から順に全員が賭けた場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    サブポット1  Seat4～Dealer   10
    サブポット2  Seat7～Dealer   10
    サブポット3  Seat10～Dealer   10
    """

    """
    ２人勝ち引き分けまで
    """
    multiple_winners_with_side_pot()


    # テストケース5
    # 勝者が一人のパターン（考えうる限り最もサブポットが多いパターン）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   20
    Seat3   30
    Seat4   40
    Seat5   50
    Seat6   60
    Seat7   70
    Seat8   80
    Seat9   90
    Seat10   100
    Dealer   110
    としたとき、Seat1から順に全員が賭けた場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    サブポット1  Seat2～Dealer   10
    サブポット2  Seat3～Dealer   10
    サブポット3  Seat4～Dealer   10
    サブポット4  Seat5～Dealer   10
    サブポット5  Seat6～Dealer   10
    サブポット6  Seat7～Dealer   10
    サブポット7  Seat8～Dealer   10
    サブポット8  Seat9～Dealer   10
    サブポット9  Seat10～Dealer   10
    サブポット10  Dealer   10
    """
    # アクティブプレイヤーは1人のパターン
    single_active_player_single_winner_maximum_side_pot()

    # アクティブプレイヤーは1人以上、勝者は一人
    multiple_active_player_single_winner_maximum_side_pot()


    # テストケース6
    # 勝者が一人以上のパターン（考えうる限り最もサブポットが多いパターン）
    """
    ポットを設定
    基本はメインポットに入ってくる
    誰かがオールインしたとき、さらに追加の掛け金があった場合、それがサイドポットになる
            bet
    Seat1   10
    Seat2   20
    Seat3   30
    Seat4   40
    Seat5   50
    Seat6   60
    Seat7   70
    Seat8   80
    Seat9   90
    Seat10   100
    Dealer   110
    としたとき、Seat1から順に全員がオールインした場合のポットは次のようになる
    メイン  Seat1～Dealer   10
    サブポット1  Seat2～Dealer   10
    サブポット2  Seat3～Dealer   10
    サブポット3  Seat4～Dealer   10
    サブポット4  Seat5～Dealer   10
    サブポット5  Seat6～Dealer   10
    サブポット6  Seat7～Dealer   10
    サブポット7  Seat8～Dealer   10
    サブポット8  Seat9～Dealer   10
    サブポット9  Seat10～Dealer   10
    サブポット10  Dealer   10
    """

    """
    ２人勝ち引き分けまで
    """
    multiple_winners_maximum_side_pot()


func setup_players():
    """プレイヤーを初期化"""
    dealer.seat_assignments = {}
    for i in range(1, 11):
        dealer.seat_assignments["Seat" + str(i)] = ParticipantBackend.new(
            game_process_mock, "Player" + str(i), 0, false, "player", false
        )
    dealer.seat_assignments["Dealer"] = ParticipantBackend.new(
        game_process_mock, "Dealer", 0, false, "playing_dealer", false
    )


func setup_pot(seat_assignments, pot_contributions: Array[Dictionary]):
    """複数のポットを作成し、それぞれの掛け金を設定"""
    dealer.pots.clear()  # 既存のポットをクリア

    for contributions in pot_contributions:
        var pot = PotBackend.new()
        for seat in contributions.keys():
            pot.add_contribution(seat_assignments[seat].player_script.player_name, contributions[seat])
        dealer.pots.append(pot)


func setup_active_players(flg: bool):
    var active_players = []
    if flg:
        active_players.append(dealer.seat_assignments["Seat1"])
        active_players.append(dealer.seat_assignments["Seat2"])
        active_players.append(dealer.seat_assignments["Seat3"])
        active_players.append(dealer.seat_assignments["Seat4"])
        active_players.append(dealer.seat_assignments["Seat5"])
        active_players.append(dealer.seat_assignments["Seat6"])
        active_players.append(dealer.seat_assignments["Seat7"])
        active_players.append(dealer.seat_assignments["Seat8"])
        active_players.append(dealer.seat_assignments["Seat9"])
        active_players.append(dealer.seat_assignments["Seat10"])
        active_players.append(dealer.seat_assignments["Dealer"])
    else:
        active_players.append(dealer.seat_assignments["Seat1"])

    return active_players


func setup_winners(active_players: Array, m: int):
    """残っているプレイヤーの先頭から m 人を勝者にする"""
    var winning_players = active_players.slice(0, m)  # 先頭 m 人を勝者に

    var strongest_category = dealer.hand_evaluator.HandCategory.ROYAL_FLUSH
    var strongest_rank = [14, 13, 12, 11, 10]  # 最強のハンド

    # 勝者を設定
    for player in winning_players:
        player.player_script.hand_category = strongest_category
        player.player_script.hand_rank = strongest_rank

    # 負ける人は低ランクにする
    for player in active_players:
        if player not in winning_players:
            player.player_script.hand_category = dealer.hand_evaluator.HandCategory.HIGH_CARD
            player.player_script.hand_rank = [2, 3, 4, 5, 6]  # 負け確定


func check_chips(expected_chips: Dictionary):
    """プレイヤーのチップが正しいか確認"""
    for seat in expected_chips.keys():
        assert_eq(dealer.seat_assignments[seat].player_script.chips, expected_chips[seat], seat + "のチップが正しくない")


func check_chips_range(expected_chips: int, winners: int = 0, winner_chips: int = 0):
    """全席のチップ額を簡潔にチェックする"""
    for i in range(1, 11):  # Seat1 ～ Seat10
        var seat = "Seat" + str(i)
        var expected = winner_chips if i <= winners else expected_chips
        assert_eq(dealer.seat_assignments[seat].player_script.chips, expected, "チップ数が合わない: " + seat)

    # Dealer（ディーラー）は常に expected_chips で固定
    assert_eq(dealer.seat_assignments["Dealer"].player_script.chips, expected_chips, "チップ数が合わない: Dealer")


func single_active_player_single_winner_main_pot():
    """勝者が1人でメインポットのみのテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    }])

    var active_players = setup_active_players(false)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 1, 110)


func multiple_active_player_single_winner_main_pot():
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    }])

    var active_players = setup_active_players(true)
    setup_winners(active_players, 1)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 1, 110)


func multiple_winners_main_pot():
    """勝者が複数人（メインポットのみ）のテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    }])


    # 勝者2
    setup_players()
    var active_players = setup_active_players(true)
    setup_winners(active_players, 2)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 2, 55)


    # 勝者3
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 3)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 3, 36)

    # 勝者4
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 4)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 4, 27)


    # 勝者5
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 5)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 5, 22)


    # 勝者6
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 6)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 6, 18)


    # 勝者7
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 7)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 7, 15)


    # 勝者8
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 8)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 8, 13)


    # 勝者9
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 9)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 9, 12)


    # 勝者10
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 10)
    dealer.distribute_pots(active_players)

    check_chips_range(0, 10, 11)


    # 引き分け
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 11)
    dealer.distribute_pots(active_players)

    check_chips_range(10, 11, 10)


func single_active_player_single_winner_with_side_pot():
    """勝者が1人（サブポットあり）のテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    }])
    # total_chips = 110 + 80 + 50 + 20 = 260

    var active_players = [dealer.seat_assignments["Seat1"]]
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 110, "Seat2": 0, "Seat3": 0, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 20, "Seat8": 20, "Seat9": 20, "Seat10": 30,
        "Dealer": 30
    })


func multiple_active_player_single_winner_with_side_pot():
    """勝者が1人（サブポットあり）のテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    }])

    var active_players = setup_active_players(true)
    setup_winners(active_players, 1)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 110, "Seat2": 0, "Seat3": 0, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 20, "Seat8": 20, "Seat9": 20, "Seat10": 30,
        "Dealer": 30
    })


func multiple_winners_with_side_pot():
    """勝者が複数人（サブポットあり）のテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    }])


    # 勝者2
    setup_players()
    var active_players = setup_active_players(true)
    setup_winners(active_players, 2)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 55, "Seat2": 55, "Seat3": 0, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 20, "Seat8": 20, "Seat9": 20, "Seat10": 30,
        "Dealer": 30
    })


    # 勝者3
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 3)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 36, "Seat2": 36, "Seat3": 36, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 20, "Seat8": 20, "Seat9": 20, "Seat10": 30,
        "Dealer": 30
    })

    # 勝者4
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 4)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 27, "Seat2": 27, "Seat3": 27, "Seat4": 107, "Seat5": 0,
        "Seat6": 0, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 20,
        "Dealer": 20
    })


    # 勝者5
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 5)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 22, "Seat2": 22, "Seat3": 22, "Seat4": 62, "Seat5": 62,
        "Seat6": 0, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 20,
        "Dealer": 20
    })


    # 勝者6
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 6)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 18, "Seat2": 18, "Seat3": 18, "Seat4": 44, "Seat5": 44,
        "Seat6": 44, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 20,
        "Dealer": 20
    })


    # 勝者7
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 7)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 15, "Seat2": 15, "Seat3": 15, "Seat4": 35, "Seat5": 35,
        "Seat6": 35, "Seat7": 85, "Seat8": 0, "Seat9": 0, "Seat10": 10,
        "Dealer": 10
    })


    # 勝者8
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 8)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 13, "Seat2": 13, "Seat3": 13, "Seat4": 29, "Seat5": 29,
        "Seat6": 29, "Seat7": 54, "Seat8": 54, "Seat9": 0, "Seat10": 10,
        "Dealer": 10
    })


    # 勝者9
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 9)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 12, "Seat2": 12, "Seat3": 12, "Seat4": 25, "Seat5": 25,
        "Seat6": 25, "Seat7": 41, "Seat8": 41, "Seat9": 41, "Seat10": 10,
        "Dealer": 10
    })


    # 勝者10
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 10)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 11, "Seat2": 11, "Seat3": 11, "Seat4": 22, "Seat5": 22,
        "Seat6": 22, "Seat7": 34, "Seat8": 34, "Seat9": 34, "Seat10": 54,
        "Dealer": 0
    })


    # 引き分け
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 11)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 20, "Seat5": 20,
        "Seat6": 20, "Seat7": 30, "Seat8": 30, "Seat9": 30, "Seat10": 40,
        "Dealer": 40
    })


func single_active_player_single_winner_maximum_side_pot():
    """最大限サブポットが発生するケースのテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    },
    {
        "Dealer": 10
    }])

    var active_players = [dealer.seat_assignments["Seat1"]]
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 110, "Seat2": 10, "Seat3": 20, "Seat4": 30, "Seat5": 40,
        "Seat6": 50, "Seat7": 60, "Seat8": 70, "Seat9": 80, "Seat10": 90,
        "Dealer": 100
    })


func multiple_active_player_single_winner_maximum_side_pot():
    """最大限サブポットが発生するケースのテスト"""
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    },
    {
        "Dealer": 10
    }])

    var active_players = setup_active_players(true)
    setup_winners(active_players, 1)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 110, "Seat2": 10, "Seat3": 20, "Seat4": 30, "Seat5": 40,
        "Seat6": 50, "Seat7": 60, "Seat8": 70, "Seat9": 80, "Seat10": 90,
        "Dealer": 100
    })


func multiple_winners_maximum_side_pot():
    setup_players()

    setup_pot(dealer.seat_assignments, [{
        "Seat1": 10, "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat2": 10, "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat3": 10, "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat4": 10, "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat5": 10,
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat6": 10, "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat7": 10, "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat8": 10, "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat9": 10, "Seat10": 10,
        "Dealer": 10
    },
    {
        "Seat10": 10, "Dealer": 10
    },
    {
        "Dealer": 10
    }])


    # 勝者2
    setup_players()
    var active_players = setup_active_players(true)
    setup_winners(active_players, 2)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 55, "Seat2": 155, "Seat3": 10, "Seat4": 20, "Seat5": 30,
        "Seat6": 40, "Seat7": 50, "Seat8": 60, "Seat9": 70, "Seat10": 80,
        "Dealer": 90
    })


    # 勝者3
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 3)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 36, "Seat2": 86, "Seat3": 176, "Seat4": 10, "Seat5": 20,
        "Seat6": 30, "Seat7": 40, "Seat8": 50, "Seat9": 60, "Seat10": 70,
        "Dealer": 80
    })

    # 勝者4
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 4)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 27, "Seat2": 60, "Seat3": 105, "Seat4": 185, "Seat5": 10,
        "Seat6": 20, "Seat7": 30, "Seat8": 40, "Seat9": 50, "Seat10": 60,
        "Dealer": 70
    })


    # 勝者5
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 5)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 22, "Seat2": 47, "Seat3": 77, "Seat4": 117, "Seat5": 187,
        "Seat6": 10, "Seat7": 20, "Seat8": 30, "Seat9": 40, "Seat10": 50,
        "Dealer": 60
    })


    # 勝者6
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 6)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 18, "Seat2": 38, "Seat3":60, "Seat4": 86, "Seat5": 121,
        "Seat6": 181, "Seat7": 10, "Seat8": 20, "Seat9": 30, "Seat10": 40,
        "Dealer": 50
    })


    # 勝者7
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 7)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 15, "Seat2": 31, "Seat3": 49, "Seat4": 69, "Seat5": 92,
        "Seat6": 122, "Seat7": 172, "Seat8": 10, "Seat9": 20, "Seat10": 30,
        "Dealer": 40
    })


    # 勝者8
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 8)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 13, "Seat2": 27, "Seat3": 42, "Seat4": 58, "Seat5": 75,
        "Seat6": 95, "Seat7": 120, "Seat8": 160, "Seat9": 10, "Seat10": 20,
        "Dealer": 30
    })


    # 勝者9
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 9)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 12, "Seat2": 24, "Seat3": 36, "Seat4": 49, "Seat5": 63,
        "Seat6": 78, "Seat7": 94, "Seat8": 114, "Seat9": 144, "Seat10": 10,
        "Dealer": 20
    })


    # 勝者10
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 10)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 11, "Seat2": 22, "Seat3": 33, "Seat4": 44, "Seat5": 55,
        "Seat6": 67, "Seat7": 79, "Seat8": 92, "Seat9": 107, "Seat10": 127,
        "Dealer": 10
    })


    # 引き分け
    setup_players()
    active_players = setup_active_players(true)
    setup_winners(active_players, 11)
    dealer.distribute_pots(active_players)

    check_chips({
        "Seat1": 10, "Seat2": 20, "Seat3": 30, "Seat4": 40, "Seat5": 50,
        "Seat6": 60, "Seat7": 70, "Seat8": 80, "Seat9": 90, "Seat10": 100,
        "Dealer": 110
    })