extends GutTest

var pot

func before_each():
    # `PotBackend` のインスタンスを作成
    pot = PotBackend.new()

func after_each():
    # メモリリークを防ぐ
    # pot.queue_free()
    pass


func test_add_contribution():
    """寄与追加のテスト"""
    pot.add_contribution("Player1", 100)
    assert_eq(pot.total, 100, "ポットの合計が100になること")
    assert_eq(pot.contributions["Player1"], 100, "Player1 の寄与額が100であること")
    assert_eq(pot.max_contribution, 100, "最大寄与額が100であること")

    pot.add_contribution("Player2", 150)
    assert_eq(pot.total, 250, "ポットの合計が250になること")
    assert_eq(pot.contributions["Player2"], 150, "Player2 の寄与額が150であること")
    assert_eq(pot.max_contribution, 150, "最大寄与額が150に更新されること")

    pot.add_contribution("Player1", 50)
    assert_eq(pot.total, 300, "ポットの合計が300になること")
    assert_eq(pot.contributions["Player1"], 150, "Player1 の寄与額が150（100+50）になること")
    assert_eq(pot.max_contribution, 150, "最大寄与額は変わらず150であること")


func test_get_contribution():
    """寄与額取得のテスト"""
    pot.add_contribution("Player1", 100)
    pot.add_contribution("Player2", 150)

    assert_eq(pot.get_contribution("Player1"), 100, "Player1 の寄与額が100であること")
    assert_eq(pot.get_contribution("Player2"), 150, "Player2 の寄与額が150であること")
    assert_eq(pot.get_contribution("Player3"), 0, "未登録の Player3 の寄与額が0であること")


func test_get_eligible_players():
    """獲得資格のあるプレイヤー取得のテスト"""
    pot.add_contribution("Player1", 100)
    pot.add_contribution("Player2", 150)
    pot.add_contribution("Player3", 150)

    var eligible_players = pot.get_eligible_players()
    assert_eq(eligible_players.size(), 2, "獲得資格のあるプレイヤーは2人であること")
    assert_true(eligible_players.has("Player2"), "Player2 がリストに含まれていること")
    assert_true(eligible_players.has("Player3"), "Player3 がリストに含まれていること")
    assert_false(eligible_players.has("Player1"), "Player1 は最大寄与額未満のため含まれないこと")


func test_to_str():
    """to_str のテスト"""
    pot.add_contribution("Player1", 100)
    pot.add_contribution("Player2", 150)

    var expected = "=== PotBackend 状態 ===\n"
    expected += "合計: 250\n"
    expected += 'プレイヤーごとの寄与: { "Player1": 100, "Player2": 150 }\n'
    expected += "最大寄与額: 150\n"
    expected += "=======================\n"

    assert_eq(pot.to_str(), expected, "to_str() の出力が期待通りか")
