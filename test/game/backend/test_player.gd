extends GutTest

var player

func before_each():
    # `PlayerBackend` のインスタンスを作成
    player = PlayerBackend.new("TestPlayer", 1000, null, false)

func after_each():
    # メモリリークを防ぐ
    player.queue_free()


func test_init():
    """初期化時の属性のチェック"""
    assert_eq(player.player_name, "TestPlayer", "プレイヤー名が正しく設定されているか")
    assert_eq(player.chips, 1000, "初期のチップ数が正しく設定されているか")
    assert_eq(player.is_cpu, false, "CPUかどうかのフラグが正しく設定されているか")
    assert_eq(player.current_bet, 0, "初期ベット額が0であること")


func test_ready():
    """時間管理ノードが追加されるか"""

    add_child(player)

    await get_tree().process_frame  # `_ready()` の実行を待つ
    await get_tree().process_frame  # `_ready()` の実行を待つ

    assert_not_null(player.get_node_or_null("TimeManager"), "TimeManager が追加されているか")


func test_bet():
    """ベット処理のテスト"""
    var initial_chips = player.chips
    var bet_amount = 200

    var actual_bet = player.bet(bet_amount)

    assert_eq(actual_bet, bet_amount, "実際に支払ったベット額が正しいか")
    assert_eq(player.chips, initial_chips - bet_amount, "チップが正しく減っているか")
    assert_eq(player.current_bet, bet_amount, "current_bet が増えているか")

    # 所持チップよりも多くベットしようとする場合
    player.chips = 50
    var over_bet = player.bet(100)
    assert_eq(over_bet, 50, "所持チップを超えてベットできないか")
    assert_eq(player.chips, 0, "チップがゼロになるか")
    assert_eq(player.current_bet, bet_amount + 50, "ベット額が累積されているか")


func test_fold():
    """フォールド処理のテスト"""
    player.hand.append(CardBackend.new("A", "Spades", false))
    player.hand.append(CardBackend.new("K", "Hearts", false))

    player.fold(false)

    assert_eq(player.hand.size(), 0, "フォールド後、手札がクリアされるか")
    assert_eq(player.is_folded, true, "is_folded フラグが true になるか")


func test_select_action():
    """アクション選択のテスト"""
    var available_actions: Array[String] = ["fold", "call", "raise"]
    player.selected_action = "check/call"

    var action = player.select_action(available_actions)

    assert_eq(action, "call", "アクションマッピングが正しく適用されるか")


func test_set_selected_action():
    """アクション設定のテスト"""
    player.set_selected_action("raise")
    assert_eq(player.selected_action, "raise", "selected_action に正しく格納されるか")


func test_set_selected_bet_amount():
    """ベット額設定のテスト"""
    player.set_selected_bet_amount(300)
    assert_eq(player.selected_bet_amount, 300, "selected_bet_amount に正しく格納されるか")


func test_select_bet_amount():
    """ベット額選択のテスト"""
    var min_bet = 100
    var max_bet = 500

    player.is_cpu = true
    var cpu_bet = player.select_bet_amount(min_bet, max_bet)

    assert_true(cpu_bet >= min_bet and cpu_bet <= max_bet, "CPUのベット額が範囲内か")


func test_to_str():
    """to_str のテスト"""
    var expected = "=== PlayerBackend 状態 ===\n"
    expected += "プレイヤー名: TestPlayer\n"
    expected += "チップ: 1000\n"
    expected += "ハンド: なし\n"
    expected += "ディーラーボタン:false\n"
    expected += "ベット額: 0\n"
    expected += "最後のアクション: []\n"
    expected += "アクションしたか: false\n"
    expected += "フォールド: false\n"
    expected += "オールイン: false\n"
    expected += "手役: []\n"
    expected += "強さ: []\n"
    expected += "=======================\n"

    assert_eq(player.to_str(), expected, "to_str() の出力が期待通りか")
