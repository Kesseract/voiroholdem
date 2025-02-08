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
var game_process

# 現在の状態を文字列として取得する
func to_str() -> String:
	var result = "=== ParticipantBackend 状態 ===\n"
	result += "参加者名: " + str(participant_name) + "\n"
	result += "チップ数: " + str(chips) + "\n"
	result += "CPUか: " + str(is_cpu) + "\n"
	result += "ロール: " + str(role) + "\n"
	result += "=======================\n"
	return result

func _init(_game_process, _participant_name, _chips, _is_cpu, _role, _seeing):
	game_process = _game_process
	participant_name = _participant_name
	chips = _chips
	is_cpu = _is_cpu
	role = _role
	seeing = _seeing

	if role != "dealer":
		player_script = PlayerBackend.new(participant_name, chips, game_process, is_cpu)
		player_script.name = "PlayerBackend"
		add_child(player_script)

	if role != "player":
		dealer_script = DealerBackend.new(game_process, seeing)
		dealer_script.name = "DealerBackend"
		add_child(dealer_script)

	if seeing:
		var front_instance = load("res://scenes/gamecomponents/Participant.tscn")
		front = front_instance.instantiate()