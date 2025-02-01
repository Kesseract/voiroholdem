extends Node
class_name DeckBackend

var seeing

var cards: Array = []

func _init(_seeing):
	seeing = _seeing
	generate_deck()

func generate_deck():

	var suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
	var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

	for suit in suits:
		for rank in ranks:
			# Cardシーンをインスタンス化してプロパティを設定
			var card_instance = CardBackend.new(rank, suit, seeing)
			cards.append(card_instance)  # インスタンス化したカードをデッキに追加
			card_instance.name = card_instance.to_str()
			add_child(card_instance)

	shuffle()

# デッキをシャッフルする
func shuffle():
	cards.shuffle()

# デッキの一番上のカードを引く
func draw_card() -> CardBackend:
	return cards.pop_back()