# ノード
extends Node

# クラス名
class_name DealerButtonBackend

# 表示フラグ、表示インスタンス
var seeing: bool
var front: Object

# 時間管理クラス
var time_manager: TimeManager


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

    # 時間管理クラス作成
    time_manager = TimeManager.new()

    # カードの見た目作成
    if seeing:
        var front_instance = load("res://scenes/gamecomponents/DealerButton.tscn")
        front = front_instance.instantiate()


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    add_child(time_manager)