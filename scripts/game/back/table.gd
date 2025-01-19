extends Node
class_name TableBackend

var sb
var bb
var buy_in
var dealer_name
var selected_cpus
var seeing

var game_process
var front

var player
var cpu_players = []
var dealer

var seat_assignments = {
	"Seat1": null, "Seat2": null, "Seat3": null, "Seat4": null,
	"Seat5": null, "Seat6": null, "Seat7": null,
	"Seat8": null, "Seat9": null, "Seat10": null, "Dealer": null,
}

signal n_moving_plus

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

func _init(_game_process, _bet_size, _buy_in, _dealer_name, _selected_cpus, _seeing):
	game_process = _game_process
	sb = _bet_size["sb"]
	bb = _bet_size["bb"]
	buy_in = _buy_in
	dealer_name = _dealer_name
	selected_cpus = _selected_cpus
	seeing = _seeing

	if not seeing:
		var front_instance = load("res://scenes/gamecomponents/Table.tscn")
		front = front_instance.instantiate()

	# 初期化処理
	# 操作プレイヤーを作る
	player = ParticipantBackend.new(game_process, "test", buy_in, false, "player", seeing)

	# CPUを作る
	var dealer_flg = false
	for cpu_name in selected_cpus:
		var role = "player"
		if cpu_name == dealer_name:
			role = "playing_dealer"
		var cpu_player = ParticipantBackend.new(game_process, cpu_name, buy_in, true, role, seeing)

		if role == "playing_dealer":
			dealer = cpu_player
			dealer.player_script.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
			dealer_flg = true
		else:
			cpu_players.append(cpu_player)

	if !dealer_flg:
		dealer = ParticipantBackend.new(game_process, dealer_name, buy_in, true, "dealer", seeing)

func seat_player():
	pass

func seat_dealer():
	seat_assignments["Dealer"] = dealer

	add_child(dealer)
	dealer.dealer_script.wait_to(0.5)
	dealer.dealer_script.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
	dealer.dealer_script.connect("n_active_players_plus", Callable(game_process, "_on_n_active_players_plus"))
	dealer.dealer_script.connect("action_finished", Callable(game_process, "_on_action_finished"))

	emit_signal("n_moving_plus")


func seat_cpus():
	var available_seats = []  # 空いている席のリストを作成
	for seat in seat_assignments.keys():
		if seat_assignments[seat] == null and seat != "Dealer":
			available_seats.append(seat)

	available_seats.shuffle()  # 席の順番をシャッフル

	var wait = 0
	for cpu in cpu_players:
		if available_seats.size() > 0:
			var random_seat = available_seats.pop_front()  # シャッフル済みリストから1つ取り出す
			seat_assignments[random_seat] = cpu

			add_child(cpu)
			cpu.player_script.wait_wait_to(wait, 0.5)
			cpu.player_script.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
			wait += 0.3

			emit_signal("n_moving_plus")