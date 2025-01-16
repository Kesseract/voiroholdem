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
	PRE_FLOP_ACITON_END,
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
	CHIPS_COLLECTING,
	POTS_COLLECTING,
	DEALER_BUTTON_MOVING,
}

var state = State.INIT
var sub_state = SubState.READY

var bet_size
var buy_in
var dealer_name
var selected_cpus
var seeing

var table_backend

var state_in_state = 0

var n_moving = 0

var initial_dealer

func _init(_bet_size, _buy_in, _dealer_name, _selected_cpus, _seeing):
	bet_size = _bet_size
	buy_in = _buy_in
	dealer_name = _dealer_name
	selected_cpus = _selected_cpus
	seeing = _seeing

func _ready():
	pass

func _on_n_moving_plus():
	n_moving += 1

func _on_moving_finished():
	n_moving -= 1
	if n_moving == 0:
		if (state == State.SETTING_DEALER_BUTTON and state_in_state != 3):
			state_in_state += 1
		else:
			sub_state = SubState.READY
			state_in_state = 0
			next_state()

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
		State.SEATING_PLAYER:
			print("State.SEATING_PLAYER")
			sub_state = SubState.PLAYER_INPUT
			table_backend.seat_player()
			# プレイヤーを席に着かせるための関数を実行
				# クリックできるシートを10個指定の場所に配置（もしくはあらかじめ配置しちゃう）
				# サブステートをPLAYER_INPUT(ユーザー入力待機に)
				# ユーザーからの入力（席のクリック）があったら、サブステートをPARTICIPANT_MOVINGにする
					# Paricipantのインスタンスを作成し、動かして席に着かせるように見せる
						# 終わったら、サブステートをREADYにし、信号を飛ばす
		State.SEATING_DEALER:
			print("State.SEATING_DEALER")
			sub_state = SubState.PARTICIPANT_MOVING
			table_backend.seat_dealer()
			# ディーラーを席に着かせる
				# サブステートをPARTICIPANT_MOVINGにする
				# 1個だけParicipantのインスタンスを作成し、動かして席に着かせるように見せる（move_toという関数が使えそう）
					# 終わったらステートをSEATING_CPUSに、サブステートをREADYにするための信号を飛ばす
		State.SEATING_CPUS:
			print("State.SEATING_CPUS")
			sub_state = SubState.PARTICIPANT_MOVING
			table_backend.seat_cpus()
			# CPUを席に着かせるための関数を実行
				# サブステートをPARTICIPANT_MOVINGにする
				# CPUの数分、Paricipantのインスタンスを作成し、動かして席に着かせるように見せる（wait_move_toという関数が使えそう）
					# 終わったらステートをSSEATING_COMPLETEDに、サブステートをREADYにするための信号を飛ばす
		State.SEATING_COMPLETED:
			print("State.SEATING_COMPLETED")
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
				table_backend.seat_assignments[initial_dealer].dealer.player_script.set_dealer(true)
		# State.DEALER_SET:
		# 	print("State.DEALER_SET")
		# State.PAYING_SB_BB:
		# 	print("State.PAYING_SB_BB")
		# State.SB_BB_PAID:
		# 	print("State.SB_BB_PAID")
		# 	state = State.DEALING_CARD
		# State.DEALING_CARD:
		# 	print("State.DEALING_CARD")
		# State.DEALED_CARD:
		# 	print("State.DEALED_CARD")
		# 	state = State.PRE_FLOP_ACTION
		# State.PRE_FLOP_ACTION:
		# 	print("State.PRE_FLOP_ACTION")
		# State.PRE_FLOP_ACITON_END:
		# 	print("State.PRE_FLOP_ACITON_END")
		# State.FLOP_ACTION:
		# 	print("State.FLOP_ACTION")
		# State.FLOP_ACTION_END:
		# 	print("State.FLOP_ACTION_END")
		# State.TURN_ACTION:
		# 	print("State.TURN_ACTION")
		# State.TURN_ACTION_END:
		# 	print("State.TURN_ACTION_END")
		# State.RIVER_ACTION:
		# 	print("State.RIVER_ACTION")
		# State.RIVER_ACTION_END:
		# 	print("State.RIVER_ACTION_END")
		# State.SHOW_DOWN:
		# 	print("State.SHOW_DOWN")
		# State.SHOW_DOWN_END:
		# 	print("State.SHOW_DOWN_END")
		# 	state = State.DISTRIBUTIONING_POTS
		# State.DISTRIBUTIONING_POTS:
		# 	print("State.DISTRIBUTIONING_POTS")
		# State.DISTRIBUTIONED_POTS:
		# 	print("State.DISTRIBUTIONED_POTS")
		# 	state = State.ROUND_RESETTING
		# State.ROUND_RESETTING:
		# 	print("State.ROUND_RESETTING")
		# State.ROUND_RESETED:
		# 	print("State.ROUND_RESETED")
		# 	state = State.NEXT_DEALER_BUTTON
		# State.NEXT_DEALER_BUTTON:
		# 	print("State.NEXT_DEALER_BUTTON")
		# State.MOVED_DEALER_BUTTON:
		# 	print("State.MOVED_DEALER_BUTTON")
		# 	state = State.PAYING_SB_BB

	next_state()

func on_player_seated(seat_node):
	print("Player seated at:", seat_node.name)
	# 席選択完了 → 状態遷移
	sub_state = SubState.READY
	state = State.SEATING_CPUS