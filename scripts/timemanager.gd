# ノード
extends Node

# クラス名
class_name TimeManager

# 属性
# 待機側
var waiting_time := 0.0
var wait_dur := 0.0
var wait_elapsed := 0.0
var waiting := false

# 移動側
var move_dur := 0.0
var move_elapsed := 0.0
var moving := false
var src_pos := Vector2()
var dst_pos := Vector2()
var target_node: Node2D = null  # 移動対象
var callback: Callable = Callable()


func wait_wait_to(wait: float, dur: float, cb: Callable) -> void:
    """待機関数を動かすまでに待機する秒数を設定する関数
    Args:
        wait float: 追加待機秒数
        dur float: 基準待機秒数
        cb Callable: 待機後に呼び出す関数
    Returns:
        void
    """
    # 変数にいれる
    waiting_time = wait

    # 待機関数呼び出し
    wait_to(dur, cb)


func wait_to(dur : float, cb: Callable):
    """待機関数
    Args:
        dur float: 基準待機秒数
        cb Callable: 待機後に呼び出す関数
    Returns:
        void
    """
    # 変数にいれる
    wait_dur = dur
    callback = cb

    # 待機部分を動かすための処理
    wait_elapsed = 0.0
    waiting = true


func wait_move_to(wait: float, target: Node2D, dst: Vector2, dur: float, cb: Callable) -> void:
    """移動関数を動かすまでに待機する秒数を設定する関数
    Args:
        wait float: 追加待機秒数
        target Node2D: 移動対象
        dst Vector2: 移動先座標
        dur float: 移動にかかる時間
        cb Callable: 移動後に呼び出す関数
    Returns:
        void
    """
    # 変数にいれる
    waiting_time = wait

    # 移動関数呼び出し
    move_to(target, dst, dur, cb)


func move_to(target: Node2D, dst: Vector2, dur: float, cb: Callable) -> void:
    """移動関数
    Args:
        target Node2D: 移動対象
        dst Vector2: 移動先座標
        dur float: 移動にかかる時間
        cb Callable: 移動後に呼び出す関数
    Returns:
        void
    """
    # 変数にいれる
    target_node = target
    src_pos = target.position
    dst_pos = dst
    move_dur = dur
    callback = cb

    # 移動処理を行うための処理
    move_elapsed = 0.0
    moving = true


func _process(delta):
    """毎フレーム実行される関数
    Args:
        _delta float: 関数実行から何フレーム経ったか
    Returns:
        void
    """
    # 待機時間内である場合
    if waiting_time > 0.0:
        # 待機時間からフレーム分の時間を減らし、リターンする
        waiting_time -= delta
        return

    # 待機処理の場合
    if waiting:
        # 経過時間を加算
        wait_elapsed += delta

        # 行き過ぎ防止
        wait_elapsed = min(wait_elapsed, wait_dur)

        # 待機終了の場合
        if wait_elapsed == wait_dur:
            # 追加の処理を行わないようにフラグをfalseにする
            waiting = false

            # コールバックが有効なら呼ぶ
            if callback.is_valid():
                callback.call()

    # 移動処理の場合
    if moving:
        # 経過時間を加算
        move_elapsed += delta

        # 行き過ぎ防止
        move_elapsed = min(move_elapsed, move_dur)

        # 位置割合
        var r = move_elapsed / move_dur

        # 移動対象が存在する場合、位置割合から移動距離を算出し、移動を行う
        if target_node:
            target_node.position = src_pos * (1.0 - r) + dst_pos * r

        # 移動終了の場合
        if move_elapsed == move_dur:
            # 追加の処理を行わないようにフラグをfalseにする
            moving = false

            # コールバックが有効なら呼ぶ
            if callback.is_valid():
                callback.call()
