# ノード
extends Node2D

# 現在のチップ値を保持する変数
var current_chip_value: int = 0

# 時間管理クラス
var time_manager: TimeManager


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


func set_chip_value(value: int) -> void:
    """指定された値をチップ表示に設定する関数
    Args:
        value int: 表示したいチップ数
    Returns:
        void
    """
    # チップ数表示用ノード取得
    var chip_value_label = $Value

    # チップ数更新
    chip_value_label.text = str(value)


func set_bet_value(value: int) -> void:
    """ベット額を加算して表示を更新する関数
    Args:
        value int: 表示したいチップ数
    Returns:
        void
    """
    # 累積ロジック
    current_chip_value += value

    # ノードのテキストを更新
    var chip_value_label = $Value
    chip_value_label.text = str(current_chip_value)


func set_chip_sprite(is_chip_visible: bool) -> void:
    """ベット、またはチップのスプライト表示する関数
    Args:
        is_chip_visible bool: True の場合、チップ（ポット）を表示する
                                False の場合、ベットを表示する
    Returns:
        void
    """
    # チップ用、ベット用ノードを取得
    var chip_sprite = $Chip
    var bet_sprite = $Bet

    # フラグによって分岐
    if is_chip_visible == true:
        # チップ表示
        chip_sprite.visible = true
        bet_sprite.visible = false
    else:
        # ベット表示
        chip_sprite.visible = false
        bet_sprite.visible = true
