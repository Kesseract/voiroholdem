# ノード
extends TextureButton

# 席の親ノードを保持
var seat_node: Node = null

# 信号
# 席の親ノードを通知
signal seat_clicked(seat_node)


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 信号接続
    connect("pressed", Callable(self, "_on_pressed"))


func setup(parent_node: Node) -> void:
    """セットアップ関数
    Args:
        parent_node Node: 親のノード
    Returns:
        void
    """
    # 属性に引数をセット
    seat_node = parent_node


func _on_pressed() -> void:
    """クリックされたときの関数
    Args:
    Returns:
        void
    """
    # 席の親ノードがある場合
    if seat_node:
        # 席の親ノードを通知
        seat_clicked.emit(seat_node)