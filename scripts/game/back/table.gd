class_name TableBackend

var sb
var bb
var buy_in
var dealer_name
var selected_cpus
var dealer
var game_process

var seat_assignments = {
		"Seat1": null, "Seat2": null, "Seat3": null,
		"Seat4": null, "Seat5": null, "Seat6": null,
		"Seat7": null, "Seat8": null, "Seat9": null, "Seat10": null
	}

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

	# 席番号を取得し、ランダムにシャッフル
	var seat_keys = seat_assignments.keys()
	seat_keys.shuffle()

	# 初期化処理
	# 操作プレイヤーを作る
	var player = ParticipantBackend.new("test", buy_in, false, "player")
	var seat = seat_keys.pop_front()
	seat_assignments[seat] = player

	# CPUを作る
	var dealer_flg = false
	for cpu_name in selected_cpus:
		var role = "player"
		if cpu_name == dealer_name:
			role = "playing_dealer"
		var cpu_player = ParticipantBackend.new(cpu_name, buy_in, true, role)

		if role == "playing_dealer":
			dealer = cpu_player
			dealer_flg = true
			seat_assignments["Dealer"] = cpu_player
		else:
			seat_assignments[seat_keys.pop_front()] = cpu_player

	if !dealer_flg:
		dealer = ParticipantBackend.new(dealer_name, buy_in, true, "dealer")
		seat_assignments["Dealer"] = dealer

	game_process = GameProcessBackend.new(dealer.dealer_script, seat_assignments, sb, bb)
