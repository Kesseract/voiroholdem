class_name CardBackend

var rank
var suit

func _init(_rank, _suit):
	rank = _rank
	suit = suit_to_symbol(_suit)

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