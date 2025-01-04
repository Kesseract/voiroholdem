extends Node2D

var backend
var front
var rank
var suit
var back

func _init():
	pass

func _ready():
	pass

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