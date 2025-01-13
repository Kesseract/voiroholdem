extends Node2D

var selected_seat = null  # プレイヤーが選択した席

var game_process

func _init(_game_process):
	game_process = _game_process

func _ready():

	# 席の初期化
	for seat in get_children():
		var seat_button = seat.get_node("SeatButton")
		seat_button.setup(seat)  # 親ノード（席）を渡す

		seat_button.connect("seat_clicked", Callable(self, "_on_seat_clicked"))

func _on_seat_clicked(seat_node):
	print("Signal received: Player selected seat:", seat_node.name)

	if selected_seat != null:
		print("Player already selected a seat")
		return

	selected_seat = seat_node
	print("Seat selected successfully:", seat_node.name)

	# 席に参加者を登録
	var participant =load("res://scenes/gamecomponents/Participant.tscn").instantiate()
	seat_node.add_child(participant)
	participant.position = Vector2(0, -75)
	participant.move_to(Vector2(0, 0), 0.3)

	# 他の席のボタンを無効化
	for seat in get_children():
		var seat_button = seat.get_node("SeatButton")
		seat_button.visible = false
		if seat != seat_node:
			seat_button.disabled = true

	# プレイヤーが席に着いたことを game_process に通知
	game_process.emit_signal("player_seated", seat_node)
