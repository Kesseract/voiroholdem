extends GutTest


var init_params = [
    [false, false],
    [true, true],
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
    var dealer_button = DealerButtonBackend.new(params[0])
    if params[1]:
        assert_not_null(dealer_button.front, "Front should be instantiated when seeing " + str(params[1]))
    else:
        assert_null(dealer_button.front, "Front should be instantiated when seeing " + str(params[1]))

    dealer_button.queue_free()


func test_ready():
    """time_managerが正しくツリーに追加されているか
    """
    # `CardBackend` インスタンスを作成
    var dealer_button = DealerButtonBackend.new(true)

    # `card` をツリーに追加
    add_child(dealer_button)
    await get_tree().process_frame  # `_ready()` の実行を待つ
    await get_tree().process_frame  # `_ready()` の実行を待つ

    # `time_manager` が追加されているかチェック
    var time_manager = dealer_button.get_node_or_null("TimeManager")

    assert_not_null(time_manager, "time_manager should be added as a child node")

    dealer_button.queue_free()
