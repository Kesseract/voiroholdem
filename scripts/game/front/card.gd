# ノード
extends Node2D

# ランク、スート
var rank: Label
var suit: Label

# バックエンド
var backend: CardBackend

# 時間管理クラス
var time_manager: TimeManager

# state
enum {
    STATE_NONE = 0,
    OPENING_FH,            # オープン中 前半
    OPENING_SH,            # オープン中 後半
    CLOSING_FH,            # オープン中 前半
    CLOSING_SH,            # オープン中 後半
}

# 回転スケール
const TH_SCALE = 1.5

# 信号
# signal opening_finished
# signal closing_finished


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


func set_rank(value: String) -> void:
    """ランクセット関数
    Args:
        value String: 表示させたいランク
    Returns:
        void
    """
    # テキストに引数をセット
    rank.text = value


func set_suit(value: String) -> void:
    """スートセット関数
    Args:
        value String: 表示させたいスート
    Returns:
        void
    """
    # テキストに引数をセット
    suit.text = value


func set_backend(_backend: CardBackend) -> void:
    """バックエンドセット関数
    Args:
        _backend CardBackend: カードバックエンド
    Returns:
        void
    """
    # 属性に引数をセット
    backend = _backend

    # Front内の子ノードを取得して設定
    var front_node = get_node("Front")
    for child in front_node.get_children():
        if child.name == "Rank":
            rank = child
        elif child.name == "Suit":
            suit = child

    # バックエンドの値と同期させる
    set_rank(backend.rank)
    set_suit(backend.suit)


func set_visible_node(flg: bool) -> void:
    """表裏表示切替関数
    Args:
        flg bool: True の場合、表面を表示する
                    False の場合、裏面を表示する
    Returns:
        void
    """
    # 表面ノード、裏面ノードを取得
    var front_node = get_node("Front")
    var back_node = get_node("Back")

    # フラグによって分岐
    if flg:
        # カードの表面表示
        front_node.visible = true
        back_node.visible = false
    else:
        # カードの裏面表示
        front_node.visible = false
        back_node.visible = true


func show_front() -> void:
    """表面にする関数
    Args:
    Returns:
        void
    """
    # 表面表示に切り替える
    set_visible_node(true)


func show_back() -> void:
    """裏面にする関数
    Args:
    Returns:
        void
    """
    # 表面表示に切り替える
    set_visible_node(false)

# カードを回転させる必要があったらこれを使う
# func do_open():
#     state = OPENING_FH
#     theta = 0.0
#     $Front.hide()
#     $Back.show()
#     $Back.set_scale(Vector2(1.0, 1.0))
# func do_wait_close(wait : float):
#     waiting_time = wait
#     do_close()
# func do_close():
#     state = CLOSING_FH
#     theta = 0.0
#     $Back.hide()
#     $Front.show()
#     $Front.set_scale(Vector2(1.0, 1.0))

    #if state != STATE_NONE:
    #    print("state = ", state)
    # if state == OPENING_FH:
    #     theta += delta * TH_SCALE
    #     if theta < PI/2:
    #         $Back.set_scale(Vector2(cos(theta), 1.0))
    #     else:
    #         state = OPENING_SH
    #         $Front.show()
    #         $Back.hide()
    #         theta -= PI
    #         $Front.set_scale(Vector2(cos(theta), 1.0))
    # elif state == OPENING_SH:
    #     theta += delta * TH_SCALE
    #     theta = min(theta, 0)
    #     if theta < 0:
    #         $Front.set_scale(Vector2(cos(theta), 1.0))
    #     else:
    #         state = STATE_NONE
    #         $Front.set_scale(Vector2(1.0, 1.0))
    #         opening_finished.emit()
    # elif state == CLOSING_FH:
    #     theta += delta * TH_SCALE * 1.5
    #     if theta < PI/2:
    #         $Front.set_scale(Vector2(cos(theta), 1.0))
    #     else:
    #         state = CLOSING_SH
    #         $Back.show()
    #         $Front.hide()
    #         theta -= PI
    #         $Back.set_scale(Vector2(cos(theta), 1.0))
    # elif state == CLOSING_SH:
    #     theta += delta * TH_SCALE * 1.5
    #     theta = min(theta, 0)
    #     if theta < 0:
    #         $Back.set_scale(Vector2(cos(theta), 1.0))
    #     else:
    #         state = STATE_NONE
    #         $Back.set_scale(Vector2(1.0, 1.0))
    #         closing_finished.emit()
    # pass