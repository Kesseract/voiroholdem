class_name DeckBackend

var cards: Array = []

func _init():
	generate_deck()

func generate_deck():

	var suits = ["Spades", "Hearts", "Diamonds", "Clubs"]
	var ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]

	for suit in suits:
		for rank in ranks:
			# Cardシーンをインスタンス化してプロパティを設定
			var card_instance = CardBackend.new(rank, suit)
			cards.append(card_instance)  # インスタンス化したカードをデッキに追加

	shuffle()

# デッキをシャッフルする
func shuffle():
	cards.shuffle()

# デッキの一番上のカードを引く
func draw_card() -> CardBackend:
	return cards.pop_back()