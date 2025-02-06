extends Node
class_name GameProcessBackend

enum State {
	INIT,
	SEATING_PLAYER,
	SEATING_DEALER,
	SEATING_CPUS,
	SEATING_COMPLETED,
	SETTING_DEALER_BUTTON,
	DEALER_SET,
	PAYING_SB_BB,
	SB_BB_PAID,
	DEALING_CARD,
	DEALED_CARD,
	PRE_FLOP_ACTION,
	PRE_FLOP_ACTION_END,
	FLOP_ACTION,
	FLOP_ACTION_END,
	TURN_ACTION,
	TURN_ACTION_END,
	RIVER_ACTION,
	RIVER_ACTION_END,
	SHOW_DOWN,
	SHOW_DOWN_END,
	DISTRIBUTIONING_POTS,
	DISTRIBUTIONED_POTS,
	ROUND_RESETTING,
	ROUND_RESETED,
	NEXT_DEALER_BUTTON,
	MOVED_DEALER_BUTTON,
}

enum SubState {
	READY,
	PLAYER_INPUT,
	PARTICIPANT_MOVING,
	CARD_MOVING,
	CARD_OPENING,
	CHIP_BETTING,
	CHIPS_COLLECTING,
	POTS_COLLECTING,
	DEALER_BUTTON_MOVING,
}

var state = State.INIT
var sub_state = SubState.READY

var bet_size
var bb
var sb
var buy_in
var dealer_name
var selected_cpus
var table_place
var animation_place
var player_flg
var seeing

var table_backend

var state_in_state = 0

var n_moving = 0

var initial_dealer
var seats
var start_index
var current_action
var n_active_players = 0
var active_players = []

var time_manager

func _init(_bet_size, _buy_in, _dealer_name, _selected_cpus, _table_place, _animation_place, _player_flg, _seeing):
	bet_size = _bet_size
	bb = bet_size["bb"]
	sb = bet_size["sb"]
	buy_in = _buy_in
	dealer_name = _dealer_name
	selected_cpus = _selected_cpus
	table_place = _table_place
	animation_place = _animation_place
	player_flg = _player_flg
	seeing = _seeing
	time_manager = TimeManager.new()

func _ready():
	add_child(time_manager)

func _on_n_moving_plus():
	n_moving += 1

func _on_n_active_players_plus():
	n_active_players += 1

func _on_moving_finished():
	n_moving -= 1
	print("n_moving: " + str(n_moving))
	if n_moving == 0:
		sub_state = SubState.READY
		if ((
				state == State.SETTING_DEALER_BUTTON and state_in_state != 3
			) or
			(
				state == State.DEALING_CARD and state_in_state != 2
			) or
			(
				(
					state == State.PRE_FLOP_ACTION_END or
					state == State.FLOP_ACTION_END or
					state == State.TURN_ACTION_END or
					state == State.RIVER_ACTION_END
				) and
				(state_in_state == 0 or
				state_in_state == 2)
			) or
			(
				state == State.SHOW_DOWN and
				state_in_state == 0
			)):
			state_in_state += 1
		elif (
			state == State.PRE_FLOP_ACTION_END or
			state == State.FLOP_ACTION_END or
			state == State.TURN_ACTION_END or
			state == State.RIVER_ACTION_END
			) and state_in_state == 1:
			if active_players.size() > 1:
				state_in_state = 2
			else:
				state_in_state = 4
		elif (
			state == State.PRE_FLOP_ACTION or
			state == State.FLOP_ACTION or
			state == State.TURN_ACTION or
			state == State.RIVER_ACTION
			):
			if n_active_players == 0:
				next_state()
		else:
			state_in_state = 0
			next_state()

func _on_moving_finished_queue_free(node):
	#print(node)
	node.queue_free()		# オブジェクト消去
	_on_moving_finished()

func _on_moving_finished_add_chip(node, already):
	#print(node)
	already.set_bet_value(node.current_chip_value)
	node.queue_free()		# オブジェクト消去
	_on_moving_finished()

func _on_action_finished():
	n_moving += 1
	n_active_players -= 1
	print("n_active_players: " + str(n_active_players))

func next_state():
	if sub_state != SubState.READY:
		# print("SubState:" + str(sub_state))
		return

	if state == State.INIT:
		if player_flg:
			state = State.SEATING_PLAYER
		else:
			state = State.SEATING_DEALER
	elif state == State.MOVED_DEALER_BUTTON:
		state = State.PAYING_SB_BB
	else:
		var state_keys = State.keys()
		state = State[state_keys[state + 1]]

func bet_state():
	sub_state = SubState.CHIP_BETTING

	if n_active_players == 0:
		sub_state = SubState.READY
		next_state()
		return

	active_players = []
	for seat in seats:
		var player = table_backend.seat_assignments[seat]
		if player != null:
			if not player.player_script.is_folded:
				active_players.append(player)

	var all_players_all_in = true
	for player in active_players:
		if not player.player_script.is_folded:
			if not player.player_script.is_all_in:
				all_players_all_in = false

	if all_players_all_in:
		sub_state = SubState.READY
		next_state()
		return

	var action = table_backend.dealer.dealer_script.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

	if action != "none_player":
		print("action: " + str(action))

	if action == "none_player":
		sub_state = SubState.READY
		current_action += 1
		return

	if action == "folded":
		sub_state = SubState.READY
		current_action += 1
		return

	if action == "all-ined":
		sub_state = SubState.READY
		current_action += 1
		return

	var active_players_bet = []
	for player in active_players:
		if not player.player_script.is_folded:
			if not player.player_script.current_bet in active_players_bet:
				active_players_bet.append(player.player_script.current_bet)

	var active_players_acted = true
	for player in active_players:
		if not player.player_script.is_folded and not (player.player_script.has_acted or player.player_script.is_all_in):
			active_players_acted = false
			break

	if active_players_bet.size() >= 1 and active_players_acted:
		table_backend.dealer.dealer_script.bet_record = [0]
		# sub_state = SubState.READY
		next_state()
		return

	var all_in_players = []
	for player in active_players:
		if player.player_script.is_all_in:
			all_in_players.append(player)

	if all_in_players.size() == active_players.size() and active_players_acted:
		table_backend.dealer.dealer_script.bet_record = [0]
		# sub_state = SubState.READY
		next_state()
		return

	current_action += 1

func _process(_delta):
	if sub_state != SubState.READY:
		# print(n_moving)
		# print("SubState:" + str(sub_state))
		return

	match state:
		State.INIT:
			print("State.INIT")
			table_backend = TableBackend.new(self, bet_size, buy_in, dealer_name, selected_cpus, table_place, animation_place, seeing)
			table_backend.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))
			table_backend.dealer.dealer_script.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))
			table_backend.name = "TableBackend"
			add_child(table_backend)
			next_state()
		State.SEATING_PLAYER:
			print("State.SEATING_PLAYER")
			sub_state = SubState.PLAYER_INPUT
			table_backend.seat_player()
		State.SEATING_DEALER:
			print("State.SEATING_DEALER")
			sub_state = SubState.PARTICIPANT_MOVING
			table_backend.seat_dealer()
		State.SEATING_CPUS:
			print("State.SEATING_CPUS")
			sub_state = SubState.PARTICIPANT_MOVING
			table_backend.seat_cpus()
		State.SEATING_COMPLETED:
			print("State.SEATING_COMPLETED")
			next_state()
		State.SETTING_DEALER_BUTTON:
			print("State.SETTING_DEALER_BUTTON")
			if state_in_state == 0:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card("SetInitialDealer")
			elif state_in_state == 1:
				print("State_in_State.deal_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.deal_card(table_backend.seat_assignments)
			elif state_in_state == 2:
				print("State_in_State.set_initial_button")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.set_initial_button(table_backend.seat_assignments)
			elif state_in_state == 3:
				print("State_in_State.set_dealer")
				sub_state = SubState.DEALER_BUTTON_MOVING
				table_backend.dealer.dealer_script.hand_clear(table_backend.seat_assignments)
		State.DEALER_SET:
			print("State.DEALER_SET")

			# デッキのリセット
			for child in table_backend.dealer.dealer_script.get_children():
				# 子ノードに接続されているシグナルを解除
				for signal_name in child.get_signal_list():
					if child.is_connected(signal_name["name"], Callable(self, "_signal_handler")):
						child.disconnect(signal_name["name"], Callable(self, "_signal_handler"))

				# 子ノードを削除
				table_backend.dealer.dealer_script.remove_child(child)
				child.queue_free()

			table_backend.dealer.dealer_script.deck = DeckBackend.new(seeing)
			table_backend.dealer.dealer_script.deck.name = "DeckBackend"
			table_backend.dealer.dealer_script.add_child(table_backend.dealer.dealer_script.deck)
			table_backend.dealer.dealer_script.time_manager = TimeManager.new()

			next_state()
		State.PAYING_SB_BB:
			print("State.PAYING_SB_BB")
			sub_state = SubState.CHIP_BETTING
			var sb_seat = table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 1)
			var sb_player = table_backend.seat_assignments[sb_seat]
			sb_player.player_script.bet(sb)
			if seeing:
				sb_player.front.set_chips(sb_player.player_script.chips)
				var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
				var chip = chip_instance.instantiate()
				chip.set_chip_sprite(false)
				chip.set_bet_value(sb)
				chip.connect("moving_finished", Callable(self, "_on_moving_finished"))
				chip.connect("moving_finished_queue_free", Callable(self, "_on_moving_finished_queue_free").bind(chip))
				chip.set_position(-1 * animation_place[sb_seat]["Bet"].get_position())
				animation_place[sb_seat]["Bet"].add_child(chip)
				chip.move_to(Vector2(0, 0), 1.0)
			else:
				sb_player.player_script.time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
			table_backend.dealer.dealer_script.bet_record.append(sb)
			_on_n_moving_plus()

			var bb_seat = table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 2)
			var bb_player = table_backend.seat_assignments[bb_seat]
			bb_player.player_script.bet(bb)
			if seeing:
				bb_player.front.set_chips(bb_player.player_script.chips)
				var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
				var chip = chip_instance.instantiate()

				chip.set_chip_sprite(false)
				chip.set_bet_value(bb)
				chip.connect("moving_finished", Callable(self, "_on_moving_finished"))
				chip.connect("moving_finished_queue_free", Callable(self, "_on_moving_finished_queue_free").bind(chip))
				chip.set_position(-1 * animation_place[bb_seat]["Bet"].get_position())
				animation_place[bb_seat]["Bet"].add_child(chip)
				chip.move_to(Vector2(0, 0), 1.0)
			else:
				bb_player.player_script.time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
			table_backend.dealer.dealer_script.bet_record.append(bb)
			_on_n_moving_plus()

		State.SB_BB_PAID:
			print("State.SB_BB_PAID")
			next_state()
		State.DEALING_CARD:
			print("State.DEALING_CARD")
			sub_state = SubState.CARD_MOVING
			if state_in_state == 0:
				print("State_in_State.burn_card")
				table_backend.dealer.dealer_script.burn_card("PreFlop")
			elif state_in_state == 1:
				print("State_in_State.deal_card_one")
				table_backend.dealer.dealer_script.deal_hole_cards(table_backend.seat_assignments, "Hand1")
			elif state_in_state == 2:
				print("State_in_State.deal_card_two")
				table_backend.dealer.dealer_script.deal_hole_cards(table_backend.seat_assignments, "Hand2")
		State.DEALED_CARD:
			print("State.DEALED_CARD")
			seats = table_backend.seat_assignments.keys()
			start_index = (seats.find(table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 3))) % seats.size()
			current_action = 0
			n_active_players = 0
			for seat in seats:
				var player = table_backend.seat_assignments[seat]
				if player != null and player.player_script != null:
					n_active_players += 1
					player.player_script.has_acted = false
			next_state()
		State.PRE_FLOP_ACTION:
			print("State.PRE_FLOP_ACTION")
			bet_state()
		State.PRE_FLOP_ACTION_END:
			print("State.PRE_FLOP_ACITON_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				var pot_value = table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = [0]
				if pot_value == 0:
					sub_state = SubState.READY
					state_in_state = 1
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							active_players.append(player)
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card("Flop")
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["Flop1", "Flop2", "Flop3"])

				current_action = 0
				n_active_players = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and not player.player_script.is_folded and not player.player_script.is_all_in:
						n_active_players += 1
						player.player_script.has_acted = false
						player.player_script.last_action.clear()

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.FLOP_ACTION:
			print("State.FLOP_ACTION")
			bet_state()
		State.FLOP_ACTION_END:
			print("State.FLOP_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				var pot_value = table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = [0]
				if pot_value == 0:
					sub_state = SubState.READY
					state_in_state = 1
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							active_players.append(player)
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card("Turn")
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["Turn"])

				current_action = 0
				n_active_players = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and player.player_script != null and not player.player_script.is_folded and not player.player_script.is_all_in:
						n_active_players += 1
						player.player_script.has_acted = false
						player.player_script.last_action.clear()

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.TURN_ACTION:
			print("State.TURN_ACTION")
			bet_state()
		State.TURN_ACTION_END:
			print("State.TURN_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				var pot_value = table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = [0]
				if pot_value == 0:
					sub_state = SubState.READY
					state_in_state = 1
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							active_players.append(player)
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card("River")
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["River"])

				current_action = 0
				n_active_players = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and player.player_script != null and not player.player_script.is_folded and not player.player_script.is_all_in:
						n_active_players += 1
						player.player_script.has_acted = false
						player.player_script.last_action.clear()

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.RIVER_ACTION:
			print("State.RIVER_ACTION")
			bet_state()
		State.RIVER_ACTION_END:
			print("State.RIVER_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				var pot_value = table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = [0]
				if pot_value == 0:
					sub_state = SubState.READY
					state_in_state = 1
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							active_players.append(player)
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				_on_n_moving_plus()
				_on_moving_finished()
				# sub_state = SubState.CARD_MOVING
				# table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				_on_n_moving_plus()
				_on_moving_finished()
				# sub_state = SubState.CARD_MOVING
				# # コミュニティカードを3枚開く
				# table_backend.dealer.dealer_script.reveal_community_cards(["River"])

				# current_action = 0
				# for seat in seats:
				# 	var player = table_backend.seat_assignments[seat]
				# 	if player != null and player.player_script != null and not player.player_script.is_folded and not player.player_script.is_all_in:
				# 		n_active_players += 1

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.SHOW_DOWN:
			print("State.SHOW_DOWN")
			if state_in_state == 0:
				print("State_inState:CARD_OPENING")
				sub_state = SubState.CARD_OPENING
				# カードオープン
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
			elif state_in_state == 1:
				print("State_inState:evaluate_hand")
				# 手の強さ判定
				sub_state = SubState.CARD_OPENING
				active_players = table_backend.dealer.dealer_script.evaluate_hand(table_backend.seat_assignments)
				time_manager.wait_to(1.0, Callable(self, "_on_moving_finished"))
				_on_n_moving_plus()
		State.SHOW_DOWN_END:
			print("State.SHOW_DOWN_END")
			next_state()
		State.DISTRIBUTIONING_POTS:
			print("State.DISTRIBUTIONING_POTS")
			sub_state = SubState.POTS_COLLECTING
			table_backend.dealer.dealer_script.distribute_pots(active_players, table_backend.seat_assignments)
		State.DISTRIBUTIONED_POTS:
			print("State.DISTRIBUTIONED_POTS")
			next_state()
		State.ROUND_RESETTING:
			print("State.ROUND_RESETTING")
			sub_state = SubState.CARD_MOVING
			table_backend.dealer.dealer_script.reset_round(table_backend.seat_assignments, buy_in)
		State.ROUND_RESETED:
			print("State.ROUND_RESETED")
			next_state()
		State.NEXT_DEALER_BUTTON:
			print("State.NEXT_DEALER_BUTTON")
			sub_state = SubState.DEALER_BUTTON_MOVING
			table_backend.dealer.dealer_script.move_dealer_button(table_backend.seat_assignments)
		State.MOVED_DEALER_BUTTON:
			print("State.MOVED_DEALER_BUTTON")
			next_state()

func on_player_seated(seat_node):
	print("Player seated at:", seat_node.name)
	# 席選択完了 → 状態遷移
	sub_state = SubState.READY
	state = State.SEATING_CPUS