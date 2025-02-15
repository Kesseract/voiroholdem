# ノード
extends Node2D

# 時間管理クラス
var time_manager

func _init() -> void:
    """初期化関数
    Args:
    Returns:
        void
    """
    # 時間管理クラス作成
    time_manager = TimeManager.new()

func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    add_child(time_manager)
