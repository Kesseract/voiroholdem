extends GutTest

var table_backend
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

var test_bet_size
var test_table_place
var test_animation_place

func before_each():
    var game_process_mock = DummyGameProcessBackend.new()
    # ダミーの SB / BB 設定
    test_bet_size = {"sb": 50, "bb": 100}

    # ダミーのテーブル・アニメーション情報
    test_table_place = {"Instance": Node.new()}
    test_animation_place = {}

    # `TableBackend` のインスタンスを作成
    table_backend = TableBackend.new(
        game_process_mock, test_bet_size, 1000,
        "Dealer1", ["CPU1", "CPU2"],
        test_table_place, test_animation_place, false
    )

func after_each():
    # メモリリークを防ぐ
    table_backend.queue_free()
    test_table_place["Instance"].queue_free()


func test_init():
    """初期化テスト"""
    assert_eq(table_backend.sb, 50, "SB は 50 であるべき")
    assert_eq(table_backend.bb, 100, "BB は 100 であるべき")
    assert_eq(table_backend.buy_in, 1000, "持ち込みチップ数は 1000 であるべき")
    assert_eq(table_backend.dealer_name, "Dealer1", "ディーラー名が Dealer1 であるべき")
    assert_eq(table_backend.selected_cpus, ["CPU1", "CPU2"], "CPU プレイヤーが正しく選択されているべき")


func test_ready():
    """time_managerが正しくツリーに追加されているか
    """
    # `CardBackend` インスタンスを作成

    # `card` をツリーに追加
    add_child(table_backend)
    await get_tree().process_frame  # `_ready()` の実行を待つ
    await get_tree().process_frame  # `_ready()` の実行を待つ

    # `time_manager` が追加されているかチェック
    var table_front = test_table_place["Instance"].get_node_or_null("Table")

    assert_not_null(table_front, "Table should be added as a child node")


func test_seat_dealer():
    """ディーラー着席テスト"""

    table_backend.seat_dealer()

    assert_eq(table_backend.seat_assignments["Dealer"], table_backend.dealer, "ディーラーが正しい座席に配置されるべき")
    assert_eq(table_backend.dealer.name, "Dealer1", "ディーラー名が Dealer1 であるべき")
    assert_true(table_backend.dealer is ParticipantBackend, "ディーラーは ParticipantBackend のインスタンスであるべき")


func test_seat_cpus():
    """CPU 着席テスト"""
    table_backend.seat_cpus()

    var assigned_cpus = 0
    for seat in table_backend.seat_assignments.keys():
        if seat != "Dealer" and table_backend.seat_assignments[seat] != null:
            assigned_cpus += 1

    assert_eq(assigned_cpus, 2, "CPU プレイヤーが 2 人正しく着席するべき")
    assert_eq(table_backend.cpu_players.size(), 2, "CPU プレイヤーリストのサイズが 2 であるべき")


func test_to_str():
    """to_str のテスト"""
    var expected = "=== TableBackend 状態 ===\n"
    expected += "SB: 50\n"
    expected += "BB: 100\n"
    expected += "持ち込み金額: 1000\n"
    expected += "ディーラー: Dealer1\n"
    expected += '選択されたCPU: ["CPU1", "CPU2"]\n'
    expected += "=======================\n"

    assert_eq(table_backend.to_str(), expected, "to_str() の出力が期待通りであるべき")
