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

func _init(_bet_size, _buy_in, _dealer_name, _selected_cpus, _seeing):
	bet_size = _bet_size
	bb = bet_size["bb"]
	sb = bet_size["sb"]
	buy_in = _buy_in
	dealer_name = _dealer_name
	selected_cpus = _selected_cpus
	seeing = _seeing

func _ready():
	pass

func _on_n_moving_plus():
	n_moving += 1

func _on_n_active_players_plus():
	n_active_players += 1

func _on_moving_finished():
	n_moving -= 1
	print("n_moving: " + str(n_moving))
	if n_moving == 0:
		sub_state = SubState.READY
		if ((state == State.SETTING_DEALER_BUTTON and state_in_state != 3) or
			(state == State.DEALING_CARD and state_in_state != 2) or
			(state == State.PRE_FLOP_ACTION_END and (state_in_state == 0 or state_in_state == 2)) or
			(state == State.FLOP_ACTION_END and (state_in_state == 0 or state_in_state == 2)) or
			(state == State.TURN_ACTION_END and (state_in_state == 0 or state_in_state == 2)) or
			(state == State.RIVER_ACTION_END and (state_in_state == 0 or state_in_state == 2)) or
			(state == State.SHOW_DOWN and state_in_state == 0)):
			state_in_state += 1
		elif (state == State.PRE_FLOP_ACTION_END or state == State.FLOP_ACTION_END or state == State.TURN_ACTION_END or state == State.RIVER_ACTION_END) and state_in_state == 1:
			if active_players.size() > 1:
				state_in_state = 2
			else:
				state_in_state = 4
		elif state == State.PRE_FLOP_ACTION or state == State.FLOP_ACTION or state == State.TURN_ACTION or state == State.RIVER_ACTION:
			if n_active_players == 0:
				next_state()
		else:
			state_in_state = 0
			next_state()

func _on_action_finished():
	n_moving += 1
	n_active_players -= 1
	print("n_active_players: " + str(n_active_players))

func next_state():
	if sub_state != SubState.READY:
		# print("SubState:" + str(sub_state))
		return

	if state == State.INIT:
		if not seeing:
			state = State.SEATING_PLAYER
		else:
			state = State.SEATING_DEALER
	elif state == State.SEATING_PLAYER:
		state = State.SEATING_DEALER
	elif state == State.SEATING_DEALER:
		state = State.SEATING_CPUS
	elif state == State.SEATING_CPUS:
		state = State.SEATING_COMPLETED
	elif state == State.SEATING_COMPLETED:
		state = State.SETTING_DEALER_BUTTON
	elif state == State.SETTING_DEALER_BUTTON:
		state = State.DEALER_SET
	elif state == State.DEALER_SET:
		state = State.PAYING_SB_BB
	elif state == State.PAYING_SB_BB:
		state = State.SB_BB_PAID
	elif state == State.SB_BB_PAID:
		state = State.DEALING_CARD
	elif state == State.DEALING_CARD:
		state = State.DEALED_CARD
	elif state == State.DEALED_CARD:
		state = State.PRE_FLOP_ACTION
	elif state == State.PRE_FLOP_ACTION:
		state = State.PRE_FLOP_ACTION_END
	elif state == State.PRE_FLOP_ACTION_END:
		state = State.FLOP_ACTION
	elif state == State.FLOP_ACTION:
		state = State.FLOP_ACTION_END
	elif state == State.FLOP_ACTION_END:
		state = State.TURN_ACTION
	elif state == State.TURN_ACTION:
		state = State.TURN_ACTION_END
	elif state == State.TURN_ACTION_END:
		state = State.RIVER_ACTION
	elif state == State.RIVER_ACTION:
		state = State.RIVER_ACTION_END
	elif state == State.RIVER_ACTION_END:
		state = State.SHOW_DOWN
	elif state == State.SHOW_DOWN:
		state = State.SHOW_DOWN_END
	elif state == State.SHOW_DOWN_END:
		state = State.DISTRIBUTIONING_POTS
	elif state == State.DISTRIBUTIONING_POTS:
		state = State.DISTRIBUTIONED_POTS
	elif state == State.DISTRIBUTIONED_POTS:
		state = State.ROUND_RESETTING
	elif state == State.ROUND_RESETTING:
		state = State.ROUND_RESETED
	elif state == State.ROUND_RESETED:
		state = State.NEXT_DEALER_BUTTON
	elif state == State.NEXT_DEALER_BUTTON:
		state = State.MOVED_DEALER_BUTTON
	elif state == State.MOVED_DEALER_BUTTON:
		state = State.PAYING_SB_BB

func _process(delta):
	if sub_state != SubState.READY:
		# print(n_moving)
		# print("SubState:" + str(sub_state))
		return

	match state:
		State.INIT:
			print("State.INIT")
			table_backend = TableBackend.new(self, bet_size, buy_in, dealer_name, selected_cpus, seeing)
			table_backend.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))
			table_backend.dealer.dealer_script.connect("n_moving_plus", Callable(self, "_on_n_moving_plus"))
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
				table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 1:
				print("State_in_State.deal_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.deal_card(table_backend.seat_assignments)
			elif state_in_state == 2:
				print("State_in_State.set_initial_button")
				sub_state = SubState.CARD_MOVING
				initial_dealer = table_backend.dealer.dealer_script.set_initial_button(table_backend.seat_assignments)
			elif state_in_state == 3:
				print("State_in_State.set_dealer")
				sub_state = SubState.DEALER_BUTTON_MOVING
				table_backend.dealer.dealer_script.burn_cards.clear()
				_on_n_moving_plus()
				table_backend.dealer.dealer_script.wait_to(0.5)
				initial_dealer.player_script.is_dealer = true
				_on_n_moving_plus()
				initial_dealer.player_script.wait_to(0.5)
		State.DEALER_SET:
			print("State.DEALER_SET")
			next_state()
		State.PAYING_SB_BB:
			print("State.PAYING_SB_BB")
			sub_state = SubState.CHIP_BETTING
			var sb_player = table_backend.seat_assignments[table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 1)]
			var bb_player = table_backend.seat_assignments[table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 2)]
			sb_player.player_script.bet(sb)
			table_backend.dealer.dealer_script.bet_record.append(sb)
			_on_n_moving_plus()
			sb_player.player_script.wait_to(0.4)
			bb_player.player_script.bet(bb)
			table_backend.dealer.dealer_script.bet_record.append(bb)
			_on_n_moving_plus()
			bb_player.player_script.wait_to(0.4)
		State.SB_BB_PAID:
			print("State.SB_BB_PAID")
			next_state()
		State.DEALING_CARD:
			# TODO 1度チップの清算まで全部終わった後、2度目のburn_cardで止まる。どちらかといえば関数側で止まっている
			print("State.DEALING_CARD")
			sub_state = SubState.CARD_MOVING
			if state_in_state == 0:
				print("State_in_State.burn_card")
				table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 1:
				print("State_in_State.deal_card_one")
				table_backend.dealer.dealer_script.deal_hole_cards(table_backend.seat_assignments)
			elif state_in_state == 2:
				print("State_in_State.deal_card_two")
				table_backend.dealer.dealer_script.deal_hole_cards(table_backend.seat_assignments)
		State.DEALED_CARD:
			print("State.DEALED_CARD")
			seats = table_backend.seat_assignments.keys()
			start_index = (seats.find(table_backend.dealer.dealer_script.get_dealer_button_index(table_backend.seat_assignments, 3))) % seats.size()
			current_action = 0
			for seat in seats:
				var player = table_backend.seat_assignments[seat]
				if player != null and player.player_script != null and not player.player_script.is_folded:
					n_active_players += 1
			next_state()
		State.PRE_FLOP_ACTION:
			print("State.PRE_FLOP_ACTION")
			sub_state = SubState.CHIP_BETTING

			var action = table_backend.dealer.dealer_script.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

			if not action:
				sub_state = SubState.READY

			if n_active_players == 0 or n_active_players == 1:
				var fold_check = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							fold_check.append(player)
				if fold_check.size() == 1:
					sub_state = SubState.READY
					state = State.PRE_FLOP_ACTION_END

			current_action += 1
		State.PRE_FLOP_ACTION_END:
			# 全員のアクションが終わったらこっちに来て、1人かどうかの判定をするのはこっちでいい
			# n_active_playersが0になったら、next_stateを呼び出す感じ
			print("State.PRE_FLOP_ACITON_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = []
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded:
							active_players.append(player)
				table_backend.dealer.dealer_script.wait_to(0.5)
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["Flop1", "Flop2", "Flop3"])

				current_action = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and not player.player_script.is_folded:
						n_active_players += 1
						player.player_script.has_acted = false

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.FLOP_ACTION:
			print("State.FLOP_ACTION")
			sub_state = SubState.CHIP_BETTING

			var all_in_players = []
			for seat in seats:
				var player = table_backend.seat_assignments[seat]
				if player != null and player.player_script != null and not player.player_script.is_folded and player.player_script.is_all_in:
					all_in_players.append(player)
			if all_in_players.size() == n_active_players:
				sub_state = SubState.READY
				state_in_state = 2
				next_state()
			else:
				var action = table_backend.dealer.dealer_script.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

				if not action:
					sub_state = SubState.READY

				if n_active_players == 0 or n_active_players == 1:
					var fold_check = []
					for seat in seats:
						var player = table_backend.seat_assignments[seat]
						if player != null:
							if not player.player_script.is_folded:
								fold_check.append(player)
					if fold_check.size() == 1:
						sub_state = SubState.READY
						state = State.FLOP_ACTION_END

				current_action += 1
		State.FLOP_ACTION_END:
			print("State.FLOP_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = []
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded and not player.player_script.is_all_in:
							active_players.append(player)
				table_backend.dealer.dealer_script.wait_to(0.5)
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["Turn"])

				current_action = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and player.player_script != null and not player.player_script.is_folded and not player.player_script.is_all_in:
						n_active_players += 1

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.TURN_ACTION:
			print("State.TURN_ACTION")
			sub_state = SubState.CHIP_BETTING

			var all_in_players = []
			for seat in seats:
				var player = table_backend.seat_assignments[seat]
				if player != null and player.player_script != null and not player.player_script.is_folded and player.player_script.is_all_in:
					all_in_players.append(player)
			if all_in_players.size() == n_active_players:
				sub_state = SubState.READY
				state_in_state = 2
				next_state()
			else:
				var action = table_backend.dealer.dealer_script.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

				if not action:
					sub_state = SubState.READY

				if n_active_players == 0 or n_active_players == 1:
					var fold_check = []
					for seat in seats:
						var player = table_backend.seat_assignments[seat]
						if player != null:
							if not player.player_script.is_folded:
								fold_check.append(player)
					if fold_check.size() == 1:
						sub_state = SubState.READY
						state = State.TURN_ACTION_END

				current_action += 1
		State.TURN_ACTION_END:
			print("State.TURN_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = []
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded and not player.player_script.is_all_in:
							active_players.append(player)
				table_backend.dealer.dealer_script.wait_to(0.5)
				_on_n_moving_plus()
			elif state_in_state == 2:
				print("State_in_State.burn_card")
				sub_state = SubState.CARD_MOVING
				table_backend.dealer.dealer_script.burn_card()
			elif state_in_state == 3:
				print("State_in_State.reveal_community_cards")
				sub_state = SubState.CARD_MOVING
				# コミュニティカードを3枚開く
				table_backend.dealer.dealer_script.reveal_community_cards(["River"])

				current_action = 0
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null and player.player_script != null and not player.player_script.is_folded and not player.player_script.is_all_in:
						n_active_players += 1

			elif state_in_state == 4:
				# ステートを一気にポット分配まで飛ばす
				print("State_in_State.JUMP_TO_DISTRIBUTIONING_POTS")
				state_in_state = 0
				sub_state = SubState.READY
				state = State.DISTRIBUTIONING_POTS
		State.RIVER_ACTION:
			print("State.RIVER_ACTION")
			sub_state = SubState.CHIP_BETTING

			var all_in_players = []
			for seat in seats:
				var player = table_backend.seat_assignments[seat]
				if player != null and player.player_script != null and not player.player_script.is_folded and player.player_script.is_all_in:
					all_in_players.append(player)
			if all_in_players.size() == n_active_players:
				sub_state = SubState.READY
				state_in_state = 2
				next_state()
			else:
				var action = table_backend.dealer.dealer_script.bet_round(seats, start_index, table_backend.seat_assignments, bb, current_action)

				if not action:
					sub_state = SubState.READY

				if n_active_players == 0 or n_active_players == 1:
					var fold_check = []
					for seat in seats:
						var player = table_backend.seat_assignments[seat]
						if player != null:
							if not player.player_script.is_folded:
								fold_check.append(player)
					if fold_check.size() == 1:
						sub_state = SubState.READY
						state = State.RIVER_ACTION_END

				current_action += 1
		State.RIVER_ACTION_END:
			print("State.RIVER_ACTION_END")
			if state_in_state == 0:
				print("State_in_State.pot_collect")
				sub_state = SubState.CHIPS_COLLECTING
				# まずベットされたものをポットとして集める
				table_backend.dealer.dealer_script.pot_collect(table_backend.seat_assignments)
				table_backend.dealer.dealer_script.bet_record = []
			elif state_in_state == 1:
				print("State_in_State.active_players_check")
				sub_state = SubState.CHIPS_COLLECTING
				active_players = []
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						if not player.player_script.is_folded and not player.player_script.is_all_in:
							active_players.append(player)
				table_backend.dealer.dealer_script.wait_to(0.5)
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
				for seat in seats:
					var player = table_backend.seat_assignments[seat]
					if player != null:
						for card in player.player_script.hand:
							card.connect("waiting_finished", Callable(self, "_on_moving_finished"))
							card.wait_to(0.5)
						_on_n_moving_plus()
						_on_n_moving_plus()
			elif state_in_state == 1:
				print("State_inState:evaluate_hand")
				# 手の強さ判定
				active_players = table_backend.dealer.dealer_script.evaluate_hand(table_backend.seat_assignments)
				state_in_state = 0
				next_state()
		State.SHOW_DOWN_END:
			print("State.SHOW_DOWN_END")
			next_state()
		State.DISTRIBUTIONING_POTS:
			print("State.DISTRIBUTIONING_POTS")
			sub_state = SubState.POTS_COLLECTING
			table_backend.dealer.dealer_script.distribute_pots(active_players)
		State.DISTRIBUTIONED_POTS:
			print("State.DISTRIBUTIONED_POTS")
			next_state()
		State.ROUND_RESETTING:
			print("State.ROUND_RESETTING")
			sub_state = SubState.CARD_MOVING
			table_backend.dealer.dealer_script.reset_round(table_backend.seat_assignments)
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