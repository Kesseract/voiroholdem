class_name TableBackend

var sb
var bb
var buy_in
var dealer_name
var selected_cpus
var game_process

var player
var cpu_players = []
var dealer

# 現在の状態を文字列として取得する
func to_str() -> String:
	var result = "=== TableBackend 状態 ===\n"
	result += "SB: " + str(sb) + "\n"
	result += "BB: " + str(bb) + "\n"
	result += "持ち込み金額: " + str(buy_in) + "\n"
	result += "ディーラー: " + str(dealer_name) + "\n"
	result += "選択されたCPU: " + str(selected_cpus) + "\n"
	result += "=======================\n"
	return result

func _init(_bet_size, _buy_in, _dealer_name, _selected_cpus):
	sb = _bet_size["sb"]
	bb = _bet_size["bb"]
	buy_in = _buy_in
	dealer_name = _dealer_name
	selected_cpus = _selected_cpus

	# 初期化処理
	# 操作プレイヤーを作る
	player = ParticipantBackend.new("test", buy_in, false, "player")

	# CPUを作る
	var dealer_flg = false
	for cpu_name in selected_cpus:
		var role = "player"
		if cpu_name == dealer_name:
			role = "playing_dealer"
		var cpu_player = ParticipantBackend.new(cpu_name, buy_in, true, role)
		cpu_players.append(cpu_player)

		if role == "playing_dealer":
			dealer = cpu_player
			dealer_flg = true

	if !dealer_flg:
		dealer = ParticipantBackend.new(dealer_name, buy_in, true, "dealer")
