extends Node
class_name CardBackend

var rank
var suit

var front
var seeing
var time_manager

func _init(_rank, _suit, _seeing):
	rank = _rank
	suit = suit_to_symbol(_suit)
	seeing = _seeing
	time_manager = TimeManager.new()

	if seeing:
		var front_instance = load("res://scenes/gamecomponents/Card.tscn")
		front = front_instance.instantiate()

func _ready() -> void:
	add_child(time_manager)

# スートをシンボルに変換する
func suit_to_symbol(suit_str) -> String:
	match suit_str:
		"Spades":
			return "♠︎"
		"Hearts":
			return "♥︎"
		"Clubs":
			return "♣︎"
		"Diamonds":
			return "♦︎"
		_:
			return "?"  # 不明なスートの場合

func to_str():
	return str(rank) + str(suit)
