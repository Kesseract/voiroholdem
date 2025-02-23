extends GutTest


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


func test_init():
    var deck = DeckBackend.new(false)  # seeing=False で初期化
    assert_eq(deck.cards.size(), 52, "Deck should be initialized with 52 cards")

    for card in deck.cards:
        assert_null(card.front, "Card front should be instantiated when seeing=False")

    deck.queue_free()


func test_init_with_seeing():
    var deck = DeckBackend.new(true)  # seeing=True で初期化

    for card in deck.cards:
        assert_not_null(card.front, "Card front should be instantiated when seeing=True")

    deck.queue_free()


func test_generate_deck():
    var deck = DeckBackend.new(false)
    assert_eq(deck.cards.size(), 52, "Deck should contain 52 cards")

    # 各スートとランクの組み合わせが正しく生成されているか
    var expected_suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
    var expected_ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    var card_strings = deck.cards.map(func(c): return c.to_str())

    for suit in expected_suits:
        for rank in expected_ranks:
            var card = CardBackend.new(rank, suit, false)
            assert_true(card_strings.has(card.to_str()), "Deck should contain " + rank + suit)

    deck.queue_free()


func test_shuffle():
    var deck = DeckBackend.new(false)
    var original_order = deck.cards.duplicate()  # 元の順序を保存

    deck.shuffle()

    assert_ne(deck.cards, original_order, "Deck order should change after shuffle")
    assert_eq(deck.cards.size(), 52, "Deck should still contain 52 cards after shuffle")

    deck.queue_free()


func test_draw_card():
    var deck = DeckBackend.new(false)
    var initial_size = deck.cards.size()

    var drawn_card = deck.draw_card()

    assert_not_null(drawn_card, "Drawn card should not be null")
    assert_eq(deck.cards.size(), initial_size - 1, "Deck size should decrease by 1 after drawing a card")

    deck.queue_free()


func test_draw_all_cards():
    var deck = DeckBackend.new(false)

    for i in range(52):
        deck.draw_card()

    assert_eq(deck.cards.size(), 0, "Deck should be empty after drawing 52 cards")

    deck.queue_free()


func test_draw_card_empty_deck():
    var deck = DeckBackend.new(false)

    # 全部引く
    for i in range(52):
        deck.draw_card()

    var drawn_card = deck.draw_card()
    assert_null(drawn_card, "Drawing from an empty deck should return null")

    deck.queue_free()
