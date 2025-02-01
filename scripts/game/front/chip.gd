extends Node2D

signal moving_finished
signal moving_finished_add_chip
signal moving_finished_queue_free

# 現在のチップ値を保持する変数
var current_chip_value: int = 0

var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）
var src_pos = Vector2(0, 0)		# 移動元位置
var dst_pos = Vector2(0, 0)		# 移動先位置
var queue_free_flg = false
var add_chip = false

func _init():
	pass

func _ready():
	pass

# 指定された値をチップ表示に設定
func set_chip_value(value: int):
	var chip_value_label = $Value
	chip_value_label.text = str(value)

# ベット額を加算して表示を更新
func set_bet_value(value: int):
	# 累積するロジック
	current_chip_value += value

	# ノードのテキストを更新
	var chip_value_label = $Value
	chip_value_label.text = str(current_chip_value)

# ベット、またはチップのスプライト表示
func set_chip_sprite(is_chip_visible):
	var chip_sprite = $Chip
	var bet_sprite = $Bet
	if is_chip_visible == true:
		chip_sprite.visible = true
		bet_sprite.visible = false
	else:
		chip_sprite.visible = false
		bet_sprite.visible = true

func move_to(dst : Vector2, dur : float):
	src_pos = get_position()
	dst_pos = dst
	move_dur = dur
	move_elapsed = 0.0
	moving = true

func _process(delta):
	if moving:		# 移動処理中
		move_elapsed += delta	# 経過時間
		move_elapsed = min(move_elapsed, move_dur)	# 行き過ぎ防止
		var r = move_elapsed / move_dur				# 位置割合
		set_position(src_pos * (1.0 - r) + dst_pos * r)		# 位置更新
		if move_elapsed == move_dur:		# 移動終了の場合
			moving = false
			if add_chip:
				moving_finished_add_chip.emit()
			elif not add_chip and queue_free_flg:
				moving_finished_queue_free.emit()
			else:
				moving_finished.emit()
