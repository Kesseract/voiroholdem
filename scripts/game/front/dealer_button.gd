extends Node2D

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）
var src_pos = Vector2(0, 0)		# 移動元位置
var dst_pos = Vector2(0, 0)		# 移動先位置

signal moving_finished

func _init():
	pass

func move_to(dst : Vector2, dur : float):
	src_pos = get_position()
	dst_pos = dst
	move_dur = dur
	move_elapsed = 0.0
	moving = true
	pass

func _process(delta):
	if waiting_time > 0.0:
		waiting_time -= delta
		return
	if moving:		# 移動処理中
		move_elapsed += delta	# 経過時間
		move_elapsed = min(move_elapsed, move_dur)	# 行き過ぎ防止
		var r = move_elapsed / move_dur				# 位置割合
		set_position(src_pos * (1.0 - r) + dst_pos * r)		# 位置更新
		if move_elapsed == move_dur:		# 移動終了の場合
			moving = false
			moving_finished.emit()	# 移動終了シグナル発行