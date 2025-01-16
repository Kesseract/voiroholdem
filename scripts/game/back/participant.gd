extends Node
class_name ParticipantBackend

var participant_name: String = "Anonymous"
var chips: int = 0
var is_cpu: bool = false
var role: String = "player"  # "player", "dealer", "playing_dealer"
var seeing
var player_script
var dealer_script

var front

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）

signal waiting_finished

# 現在の状態を文字列として取得する
func to_str() -> String:
	var result = "=== ParticipantBackend 状態 ===\n"
	result += "参加者名: " + str(participant_name) + "\n"
	result += "チップ数: " + str(chips) + "\n"
	result += "CPUか: " + str(is_cpu) + "\n"
	result += "ロール: " + str(role) + "\n"
	result += "=======================\n"
	return result

func _init(_participant_name, _chips, _is_cpu, _role, _seeing):
	participant_name = _participant_name
	chips = _chips
	is_cpu = _is_cpu
	role = _role
	if role != "dealer":
		player_script = PlayerBackend.new(participant_name, chips, is_cpu)
	if role != "player":
		dealer_script = DealerBackend.new()
	if not _seeing:
		var front_instance = load("res://scenes/gamecomponents/Participant.tscn")
		front = front_instance.instantiate()

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