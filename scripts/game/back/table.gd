extends Node
class_name TableBackend

var sb
var bb
var buy_in
var dealer_name
var selected_cpus
var table_place
var animation_place
var seeing

var game_process

var player
var cpu_players = []
var dealer

var seat_assignments = {
    "Seat1": null, "Seat2": null, "Seat3": null, "Seat4": null,
    "Seat5": null, "Seat6": null, "Seat7": null,
    "Seat8": null, "Seat9": null, "Seat10": null, "Dealer": null,
}

var front

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

func _init(_game_process, _bet_size, _buy_in, _dealer_name, _selected_cpus, _table_place, _animation_place, _seeing):
    game_process = _game_process
    sb = _bet_size["sb"]
    bb = _bet_size["bb"]
    buy_in = _buy_in
    dealer_name = _dealer_name
    selected_cpus = _selected_cpus
    table_place = _table_place
    animation_place = _animation_place
    seeing = _seeing

    if not seeing:
        var front_instance = load("res://scenes/gamecomponents/Table.tscn")
        front = front_instance.instantiate()
        table_place["Instance"].add_child(front)

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
            dealer_flg = true
        else:
            cpu_players.append(cpu_player)

    if !dealer_flg:
        dealer = ParticipantBackend.new(game_process, dealer_name, buy_in, true, "dealer", seeing)

func seat_player():
    pass

func seat_dealer():
    seat_assignments["Dealer"] = dealer
    dealer.name = dealer.participant_name
    add_child(dealer)
    if seeing:
        # ディーラーの必要な情報をいろいろと更新する
        dealer.front.set_parameter(dealer, "Dealer")
        var dst = dealer.front.get_position()
        dealer.front.set_position(dealer.front.get_position() + Vector2(0, -75))
        animation_place["Dealer"]["Participant"].add_child(dealer.front)
        dealer.front.time_manager.move_to(dealer.front, dst, 1.0, Callable(game_process, "_on_moving_finished"))
    else:
        dealer.dealer_script.time_manager.wait_to(1.0, Callable(game_process, "_on_moving_finished"))
    dealer.dealer_script.connect("n_active_players_plus", Callable(game_process, "_on_n_active_players_plus"))
    dealer.dealer_script.connect("action_finished", Callable(game_process, "_on_action_finished"))
    dealer.dealer_script.animation_place = animation_place
    dealer.dealer_script.table_place = table_place

    n_moving_plus.emit()


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
            cpu.name = cpu.participant_name
            add_child(cpu)
            if seeing:
                cpu.front.set_parameter(cpu, random_seat)
                var dst = cpu.front.get_position()
                cpu.front.set_position(cpu.front.get_position() + Vector2(0, -75))
                animation_place[random_seat]["Participant"].add_child(cpu.front)
                # cpu.front.add_child_node = animation_place[random_seat]["Participant"]
                cpu.front.time_manager.wait_move_to(wait, cpu.front, dst, 1.0, Callable(game_process, "_on_moving_finished"))
                # 初期チップの表示
            else:
                cpu.player_script.time_manager.wait_wait_to(wait, 1.0, Callable(game_process, "_on_moving_finished"))
            wait += 0.3

            n_moving_plus.emit()