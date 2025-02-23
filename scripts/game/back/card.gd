# ノード
extends Node

# クラス名
class_name CardBackend

# ランク、スート
var rank: String
var suit: String

# 表示フラグ、表示インスタンス
var seeing: bool
var front: Object

# 時間管理クラス
var time_manager: TimeManager


func _init(_rank: String, _suit: String, _seeing: bool) -> void:
    """初期化関数
    Args:
        _rank String: カードのランク 2～A
        _suit String: カードのスート ︎Spades, Hearts, Clubs, Diamonds
        _seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    rank = _rank
    suit = _suit
    seeing = _seeing

    # 時間管理クラス作成
    time_manager = TimeManager.new()

    # 見た目作成
    if seeing:
        var front_instance = load("res://scenes/gamecomponents/Card.tscn")
        front = front_instance.instantiate()


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    time_manager.name = "TimeManager"
    add_child(time_manager)


# スートをシンボルに変換する
func suit_to_symbol(suit_str) -> String:
    match suit_str:
        "Spades":
            return "♠︎"
        "Hearts":
            return "♥︎"
        "Clubs":
            return "♣︎"
        "Diamonds":
            return "♦︎"
        _:
            return "?"  # 不明なスートの場合


func to_str() -> String:
    """属性表示関数
    Args:
    Returns:
        str(rank) + str(suit) String: カードのランクとスートをつなげた文字列
    """
    return str(rank) + str(suit_to_symbol(suit))
