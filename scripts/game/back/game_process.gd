extends Node
class_name GameProcessBackend

enum State {
	INIT,
	SEATING_PLAYER,
	SEATING_CPUS,
	SEATING_DEALER,
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

var participant = load("res://scenes/gamecomponents/Participant.tscn")
var card = load("res://scenes/gamecomponents/Card.tscn")
var chip = load("res://scenes/gamecomponents/Chip.tscn")
var dealer_button = load("res://scenes/gamecomponents/DealerButton.tscn")
var table = load("res://scenes/gamecomponents/Table.tscn")

func _init():
	pass

func _ready():
	pass

func _process(delta):
	if sub_state != SubState.READY:
		print("SubState:" + str(sub_state))
		return

	match state:
		State.INIT:
			print("State.INIT")
			state = State.SEATING_PLAYER
		State.SEATING_PLAYER:
			print("State.SEATING_PLAYERS")
			sub_state = SubState.PLAYER_INPUT
			# プレイヤーを席に着かせるための関数を実行
				# クリックできるシートを10個指定の場所に配置（もしくはあらかじめ配置しちゃう）
				# サブステートをPLAYER_INPUT(ユーザー入力待機に)
				# ユーザーからの入力（席のクリック）があったら、サブステートをPARTICIPANT_MOVINGにする
					# Paricipantのインスタンスを作成し、動かして席に着かせるように見せる
						# 終わったら、サブステートをREADYにし、信号を飛ばす
		State.SEATING_CPUS:
			pass
			# CPUを席に着かせるための関数を実行
				# サブステートをPARTICIPANT_MOVINGにする
				# CPUの数分、Paricipantのインスタンスを作成し、動かして席に着かせるように見せる（wait_move_toという関数が使えそう）
					# 終わったらサブステートをREADYにし、信号を飛ばす
		State.SEATING_DEALER:
			pass
			# (ディーラーを席に着かせる？ ディーラーってCPUでもあるんだよね)
				# サブステートをPARTICIPANT_MOVINGのままでいい
				# CPUの数分、Paricipantのインスタンスを作成し、動かして席に着かせるように見せる（wait_move_toという関数が使えそう）
					# 終わったら信号を飛ばす
			# 全部終わったら、ステートをSEATING_COMPLETEDに、サブステートをREADYに
		State.SEATING_COMPLETED:
			print("State.SEATING_COMPLETED")
		# State.SETTING_DEALER_BUTTON:
		#	 print("State.SETTING_DEALER_BUTTON")
		# State.DEALER_SET:
		#	 print("State.DEALER_SET")
		# State.PAYING_SB_BB:
		#	 print("State.PAYING_SB_BB")
		# State.SB_BB_PAID:
		#	 print("State.SB_BB_PAID")
		# State.DEALING_CARD:
		#	 print("State.DEALING_CARD")
		# State.DEALED_CARD:
		#	 print("State.DEALED_CARD")
		# State.PRE_FLOP_ACTION:
		#	 print("State.PRE_FLOP_ACTION")
		# State.PRE_FLOP_ACITON_END:
		#	 print("State.PRE_FLOP_ACITON_END")
		# State.FLOP_ACTION:
		#	 print("State.FLOP_ACTION")
		# State.FLOP_ACTION_END:
		#	 print("State.FLOP_ACTION_END")
		# State.TURN_ACTION:
		#	 print("State.TURN_ACTION")
		# State.TURN_ACTION_END:
		#	 print("State.TURN_ACTION_END")
		# State.RIVER_ACTION:
		#	 print("State.RIVER_ACTION")
		# State.RIVER_ACTION_END:
		#	 print("State.RIVER_ACTION_END")
		# State.SHOW_DOWN:
		#	 print("State.SHOW_DOWN")
		# State.SHOW_DOWN_END:
		#	 print("State.SHOW_DOWN_END")
		# State.DISTRIBUTIONING_POTS:
		#	 print("State.DISTRIBUTIONING_POTS")
		# State.DISTRIBUTIONED_POTS:
		#	 print("State.DISTRIBUTIONED_POTS")
		# State.ROUND_RESETTING:
		#	 print("State.ROUND_RESETTING")
		# State.ROUND_RESETED:
		#	 print("State.ROUND_RESETED")
		# State.NEXT_DEALER_BUTTON:
		#	 print("State.NEXT_DEALER_BUTTON")
		# State.MOVED_DEALER_BUTTON:
		#	 print("State.MOVED_DEALER_BUTTON")

func on_player_seated(seat_node):
	print("Player seated at:", seat_node.name)
	# 席選択完了 → 状態遷移
	sub_state = SubState.READY
	state = State.SEATING_CPUS