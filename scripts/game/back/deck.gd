# ノード
extends Node

# クラス名
class_name DeckBackend

# デッキ用配列
var cards: Array = []

# 表示フラグ
var seeing: bool


func _init(_seeing: bool) -> void:
    """初期化関数
    Args:
        _seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    seeing = _seeing

    # デッキ作成
    generate_deck()


func generate_deck() -> void:
    """デッキ作成関数
    Args:
    Returns:
        void
    """
    # デッキに使うランクとスートを宣言
    var suits = ["Spades", "Hearts", "Clubs", "Diamonds"]
    var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

    # ランクとスートでループし、カードを1枚ずつ作成する
    for suit in suits:
        for rank in ranks:
            # Cardシーンをインスタンス化してプロパティを設定
            var card_instance = CardBackend.new(rank, suit, seeing)

            # インスタンス化したカードをデッキに追加
            cards.append(card_instance)

            # ノードの名前をランクとスートの結合文字列に設定
            card_instance.name = card_instance.to_str()

            # ノードを追加
            add_child(card_instance)

    # 完成したデッキをシャッフル
    shuffle()


func shuffle() -> void:
    """デッキシャッフル関数
    Args:
    Returns:
        void
    """
    # デッキ用配列をシャッフル
    cards.shuffle()


func draw_card() -> CardBackend:
    """デッキの一番上のカードを引く関数
    Args:
    Returns:
        cards.pop_back() CardBackend: デッキの一番上のカード
    """
    return cards.pop_back()