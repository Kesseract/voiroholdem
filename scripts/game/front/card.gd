extends Node2D

signal opening_finished
signal closing_finished
signal moving_finished
signal moving_finished_queue_free

var backend
var front
var rank
var suit
var back

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）
var src_pos = Vector2(0, 0)		# 移動元位置
var dst_pos = Vector2(0, 0)		# 移動先位置
var state = STATE_NONE
var theta = 0.0
var queue_free_flg = false

enum {		# state
	STATE_NONE = 0,
	OPENING_FH,			# オープン中 前半
	OPENING_SH,			# オープン中 後半
	CLOSING_FH,			# オープン中 前半
	CLOSING_SH,			# オープン中 後半
}

const TH_SCALE = 1.5

func _init():
	pass

func _ready():
	pass

func set_rank(value):
	rank.text = value

func set_suit(value):
	suit.text = value

func set_backend(_backend):
	backend = _backend

	# Front内の子ノードを取得して設定
	var front_node = get_node("Front")
	for child in front_node.get_children():
		if child.name == "Rank":
			rank = child
		elif child.name == "Suit":
			suit = child

	set_rank(backend.rank)
	set_suit(backend.suit)

func set_visible_node(flg: bool):
	var front_node = get_node("Front")
	var back_node = get_node("Back")

	if flg:
		# 見える
		front_node.visible = true
		back_node.visible = false
	else:
		# 見えない
		front_node.visible = false
		back_node.visible = true

func wait_move_to(wait : float, dst : Vector2, dur : float):
	waiting_time = wait
	#wait_elapsed = 0.0
	move_to(dst, dur)
func move_to(dst : Vector2, dur : float):
	src_pos = get_position()
	dst_pos = dst
	move_dur = dur
	move_elapsed = 0.0
	moving = true
	pass
func show_front():
	#print("show_front()")
	set_visible_node(true)
func show_back():
	set_visible_node(false)
func do_open():
	state = OPENING_FH
	theta = 0.0
	$Front.hide()
	$Back.show()
	$Back.set_scale(Vector2(1.0, 1.0))
func do_wait_close(wait : float):
	waiting_time = wait
	do_close()
func do_close():
	state = CLOSING_FH
	theta = 0.0
	$Back.hide()
	$Front.show()
	$Front.set_scale(Vector2(1.0, 1.0))

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
			if queue_free_flg:
				moving_finished_queue_free.emit()
			else:
				moving_finished.emit()
	#if state != STATE_NONE:
	#	print("state = ", state)
	if state == OPENING_FH:
		theta += delta * TH_SCALE
		if theta < PI/2:
			$Back.set_scale(Vector2(cos(theta), 1.0))
		else:
			state = OPENING_SH
			$Front.show()
			$Back.hide()
			theta -= PI
			$Front.set_scale(Vector2(cos(theta), 1.0))
	elif state == OPENING_SH:
		theta += delta * TH_SCALE
		theta = min(theta, 0)
		if theta < 0:
			$Front.set_scale(Vector2(cos(theta), 1.0))
		else:
			state = STATE_NONE
			$Front.set_scale(Vector2(1.0, 1.0))
			opening_finished.emit()
	elif state == CLOSING_FH:
		theta += delta * TH_SCALE * 1.5
		if theta < PI/2:
			$Front.set_scale(Vector2(cos(theta), 1.0))
		else:
			state = CLOSING_SH
			$Back.show()
			$Front.hide()
			theta -= PI
			$Back.set_scale(Vector2(cos(theta), 1.0))
	elif state == CLOSING_SH:
		theta += delta * TH_SCALE * 1.5
		theta = min(theta, 0)
		if theta < 0:
			$Back.set_scale(Vector2(cos(theta), 1.0))
		else:
			state = STATE_NONE
			$Back.set_scale(Vector2(1.0, 1.0))
			closing_finished.emit()
	pass