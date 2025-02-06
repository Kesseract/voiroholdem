
extends Node
class_name TimeManager

var waiting_time := 0.0

var wait_dur := 0.0
var wait_elapsed := 0.0
var waiting := false

var move_dur := 0.0
var move_elapsed := 0.0
var moving := false
var src_pos := Vector2()
var dst_pos := Vector2()
var target_node: Node2D = null  # 移動対象
var callback: Callable = Callable()

# ✅ 「待機＋待機」処理
func wait_wait_to(wait : float, dur : float, cb: Callable):
	waiting_time = wait
	wait_to(dur, cb)

# ✅ 「待機」処理
func wait_to(dur : float, cb: Callable):
	wait_dur = dur
	wait_elapsed = 0.0
	waiting = true
	callback = cb

# ✅ 「待機＋移動」処理
func wait_move_to(wait: float, target: Node2D, dst: Vector2, dur: float, cb: Callable):
	waiting_time = wait
	move_to(target, dst, dur, cb)

# ✅ 「移動」処理
func move_to(target: Node2D, dst: Vector2, dur: float, cb: Callable):
	target_node = target
	src_pos = target.position
	dst_pos = dst
	move_dur = dur
	move_elapsed = 0.0
	moving = true
	callback = cb

func _process(delta):
	if waiting_time > 0.0:
		waiting_time -= delta
		return

	if waiting:
		wait_elapsed += delta	# 経過時間
		wait_elapsed = min(wait_elapsed, wait_dur)	# 行き過ぎ防止
		if wait_elapsed == wait_dur:		# 移動終了の場合
			waiting = false
			if callback.is_valid():  # ✅ コールバックが有効なら呼ぶ
				callback.call()

	if moving:
		move_elapsed += delta
		move_elapsed = min(move_elapsed, move_dur)
		var r = move_elapsed / move_dur  # 位置割合
		if target_node:
			target_node.position = src_pos * (1.0 - r) + dst_pos * r
		if move_elapsed == move_dur:
			moving = false
			if callback.is_valid():  # ✅ コールバックが有効なら呼ぶ
				callback.call()
