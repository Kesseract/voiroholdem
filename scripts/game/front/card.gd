extends Node2D

# signal opening_finished
# signal closing_finished

var backend
var front
var rank
var suit
var back

var time_manager

enum {		# state
	STATE_NONE = 0,
	OPENING_FH,			# オープン中 前半
	OPENING_SH,			# オープン中 後半
	CLOSING_FH,			# オープン中 前半
	CLOSING_SH,			# オープン中 後半
}

const TH_SCALE = 1.5

func _init():
	time_manager = TimeManager.new()

func _ready():
	add_child(time_manager)

func set_rank(value):
	rank.text = value

func set_suit(value):
	suit.text = value

func set_backend(_backend):
	backend = _backend

	# Front内の子ノードを取得して設定
	var front_node = get_node("Front")
	for child in front_node.get_children():
		if child.name == "Rank":
			rank = child
		elif child.name == "Suit":
			suit = child

	set_rank(backend.rank)
	set_suit(backend.suit)

func set_visible_node(flg: bool):
	var front_node = get_node("Front")
	var back_node = get_node("Back")

	if flg:
		# 見える
		front_node.visible = true
		back_node.visible = false
	else:
		# 見えない
		front_node.visible = false
		back_node.visible = true

func show_front():
	#print("show_front()")
	set_visible_node(true)
func show_back():
	set_visible_node(false)
# func do_open():
# 	state = OPENING_FH
# 	theta = 0.0
# 	$Front.hide()
# 	$Back.show()
# 	$Back.set_scale(Vector2(1.0, 1.0))
# func do_wait_close(wait : float):
# 	waiting_time = wait
# 	do_close()
# func do_close():
# 	state = CLOSING_FH
# 	theta = 0.0
# 	$Back.hide()
# 	$Front.show()
# 	$Front.set_scale(Vector2(1.0, 1.0))

	#if state != STATE_NONE:
	#	print("state = ", state)
	# if state == OPENING_FH:
	# 	theta += delta * TH_SCALE
	# 	if theta < PI/2:
	# 		$Back.set_scale(Vector2(cos(theta), 1.0))
	# 	else:
	# 		state = OPENING_SH
	# 		$Front.show()
	# 		$Back.hide()
	# 		theta -= PI
	# 		$Front.set_scale(Vector2(cos(theta), 1.0))
	# elif state == OPENING_SH:
	# 	theta += delta * TH_SCALE
	# 	theta = min(theta, 0)
	# 	if theta < 0:
	# 		$Front.set_scale(Vector2(cos(theta), 1.0))
	# 	else:
	# 		state = STATE_NONE
	# 		$Front.set_scale(Vector2(1.0, 1.0))
	# 		opening_finished.emit()
	# elif state == CLOSING_FH:
	# 	theta += delta * TH_SCALE * 1.5
	# 	if theta < PI/2:
	# 		$Front.set_scale(Vector2(cos(theta), 1.0))
	# 	else:
	# 		state = CLOSING_SH
	# 		$Back.show()
	# 		$Front.hide()
	# 		theta -= PI
	# 		$Back.set_scale(Vector2(cos(theta), 1.0))
	# elif state == CLOSING_SH:
	# 	theta += delta * TH_SCALE * 1.5
	# 	theta = min(theta, 0)
	# 	if theta < 0:
	# 		$Back.set_scale(Vector2(cos(theta), 1.0))
	# 	else:
	# 		state = STATE_NONE
	# 		$Back.set_scale(Vector2(1.0, 1.0))
	# 		closing_finished.emit()
	# pass