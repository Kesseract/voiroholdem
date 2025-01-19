extends Node
class_name CardBackend

var rank
var suit

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）

signal waiting_finished

func _init(_rank, _suit):
	rank = _rank
	suit = suit_to_symbol(_suit)

# スートをシンボルに変換する
func suit_to_symbol(suit_str) -> String:
	match suit_str:
		"Spades":
			return "♠︎"
		"Hearts":
			return "♥︎"
		"Clubs":
			return "♣︎"
		"Diamonds":
			return "♦︎"
		_:
			return "?"  # 不明なスートの場合

func to_str():
	return str(rank) + str(suit)

func wait_wait_to(wait : float, dur : float):
	waiting_time = wait
	#wait_elapsed = 0.0
	wait_to(dur)
func wait_to(dur : float):
	move_dur = dur
	move_elapsed = 0.0
	moving = true

func _process(delta):
	if waiting_time > 0.0:
		waiting_time -= delta
		return
	if moving:		# 移動処理中
		move_elapsed += delta	# 経過時間
		move_elapsed = min(move_elapsed, move_dur)	# 行き過ぎ防止
		if move_elapsed == move_dur:		# 移動終了の場合
			moving = false
			emit_signal("waiting_finished")	# 移動終了シグナル発行