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
var waiting_time = 0.0
var state = 0
enum {
    STATE_NONE = 0,
    OPENING_FH,            # オープン中 前半
    OPENING_SH,            # オープン中 後半
    CLOSING_FH,            # オープン中 前半
    CLOSING_SH,            # オープン中 後半
}

# 回転スケール
var theta = 0.0
const TH_SCALE = 1.5


var callback: Callable = Callable()


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
    time_manager.name = "TimeManager"
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
    set_suit(backend.suit_to_symbol(backend.suit))


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


func do_open(cb: Callable):
    callback = cb
    state = OPENING_FH
    theta = 0.0
    set_visible_node(false)
    var back_node = get_node("Back")
    back_node.set_scale(Vector2(1.0, 1.0))


func do_wait_close(wait : float):
    waiting_time = wait
    do_close()


func do_close():
    state = CLOSING_FH
    theta = 0.0
    set_visible_node(true)
    var front_node = get_node("Front")
    front_node.set_scale(Vector2(1.0, 1.0))


func _process(delta):
    if state == OPENING_FH:
        # カードオープン前半なら
        # 角度を増やす
        theta += delta * TH_SCALE
        # 角度が90度かどうか
        if theta < PI/2:
            # 鋭角なら、裏側を削っていく
            var back = get_node("Back")
            back.set_scale(Vector2(cos(theta), 1.0))
        else:
            # 90度なら、表側を出す
            state = OPENING_SH
            set_visible_node(true)
            # 角度を-90度にする
            theta -= PI
            var front = get_node("Front")
            front.set_scale(Vector2(cos(theta), 1.0))
    elif state == OPENING_SH:
        # カードオープン後半なら
        # 角度を増やす
        theta += delta * TH_SCALE
        theta = min(theta, 0)
        var front = get_node("Front")
        # 角度が0度以下かどうか
        if theta < 0:
            # 表側をどんどん出していく
            front.set_scale(Vector2(cos(theta), 1.0))
        else:
            # 開き終わり
            state = STATE_NONE
            front.set_scale(Vector2(1.0, 1.0))
            # コールバックが有効なら呼ぶ
            if callback.is_valid():
                callback.call()
