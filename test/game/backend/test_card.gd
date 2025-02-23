extends GutTest


var init_params = [
    ["10", "Hearts", false, false],
    ["10", "Hearts", true, true],
]


var to_str_params = [
    ["10", "Hearts", "10♥︎"],
    ["A", "Spades", "A♠︎"],
    ["2", "Diamonds", "2♦︎"],
    ["K", "Clubs", "K♣︎"],
]


func before_each():
    # 各テストの前に実行される関数
    pass


func after_each():
    # 各テストの後に実行される関数
    pass


func before_all():
    # 一番最初に実行される関数
    pass


func after_all():
    # 一番最後に実行される関数
    pass


func test_init(params=use_parameters(init_params)):
    """seeingの値によって、front部分が正しく設定されているか
    """
    var card = CardBackend.new(params[0], params[1], params[2])
    if params[2]:
        assert_not_null(card.front, "Front should be instantiated when seeing " + str(params[2]))
    else:
        assert_null(card.front, "Front should be instantiated when seeing " + str(params[2]))

    card.queue_free()


func test_ready():
    """time_managerが正しくツリーに追加されているか
    """
    # `CardBackend` インスタンスを作成
    var card = CardBackend.new("10", "Hearts", true)

    # `card` をツリーに追加
    add_child(card)
    await get_tree().process_frame  # `_ready()` の実行を待つ
    await get_tree().process_frame  # `_ready()` の実行を待つ

    # `time_manager` が追加されているかチェック
    var time_manager = card.get_node_or_null("TimeManager")

    assert_not_null(time_manager, "time_manager should be added as a child node")

    card.queue_free()


func test_suit_to_symbol():
    var card = CardBackend.new("10", "Spades", false)
    assert_eq(card.suit_to_symbol(card.suit), "♠︎")
    card = CardBackend.new("10", "Hearts", false)
    assert_eq(card.suit_to_symbol(card.suit), "♥︎")
    card = CardBackend.new("10", "Clubs", false)
    assert_eq(card.suit_to_symbol(card.suit), "♣︎")
    card = CardBackend.new("10", "Diamonds", false)
    assert_eq(card.suit_to_symbol(card.suit), "♦︎")


func test_to_str(params=use_parameters(to_str_params)):
    """正しく文字列表示できるか
    """
    var card = CardBackend.new(params[0], params[1], false)
    assert_eq(card.to_str(), params[2], "to_str() should return " + params[2])

    card.queue_free()
