extends Node
class_name DealerBackend

# 属性
var deck
var pots: Array = []
var bet_record: Array = []
var community_cards: Array = []
var burn_cards: Array = []
var hand_evaluator
var game_process
var animation_place
var table_place

var seeing

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）

signal waiting_finished
signal action_finished

signal n_moving_plus
signal n_active_players_plus

# 初期化
func _init(_game_process, _seeing):
	game_process = _game_process
	seeing = _seeing
	deck = DeckBackend.new(seeing)
	deck.name = "DeckBackend"
	add_child(deck)
	pots.append(PotBackend.new())
	bet_record = []
	community_cards = []
	burn_cards = []
	hand_evaluator = HandEvaluatorBackend.new()

# 現在の状態を文字列として取得する
func to_str() -> String:
	var result = "=== DeckBackend 状態 ===\n"
	result += "ベット履歴: " + str(bet_record) + "\n"
	# community_cards の情報を文字列として取得
	if community_cards.size() > 0:
		var community_card_strings = []
		for card in community_cards:
			community_card_strings.append(card.to_str())
		result += "コミュニティカード: " + ", ".join(community_card_strings) + "\n"
	else:
		result += "コミュニティカード: なし\n"
	if burn_cards.size() > 0:
		var burn_card_strings = []
		for card in burn_cards:
			burn_card_strings.append(card.to_str())
		result += "バーンカード: " + ", ".join(burn_card_strings) + "\n"
	else:
		result += "コミュニティカード: なし\n"
	result += "=======================\n"
	return result

# バーンカードを行う
func burn_card(place):
	var card = deck.draw_card()
	if seeing:
		# ディーラーの場所からバーンカードの場所へ裏面でカードを配置する
		card.front.set_backend(card)
		card.front.show_back()
		card.front.set_position(table_place["Deck"].get_position() - table_place["Burn"]["Instance"].get_position())
		table_place["Burn"][place].add_child(card.front)
		card.front.move_to(table_place["Burn"][place].get_position(), 0.5)
		card.front.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
		card.front.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(card.front))
	else:
		card.wait_to(1.0)
		card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
	n_moving_plus.emit()
	burn_cards.append(card)

# プレイヤーにカードを配る
func deal_card(seat_assignments, start_position := 0):
	# 座席番号をリストに変換してインデックスでアクセス可能にする
	var seats = seat_assignments.keys()
	var seat_count = seats.size()

	var deal_seats = []

	for i in range(seat_count):
		var current_seat = seats[(start_position + i) % seat_count]
		var current_player = seat_assignments[current_seat]

		# プレイヤーがその席にいる場合のみ処理
		if current_player:
			deal_seats.append(current_seat)

	var wait = 0
	for current_seat in deal_seats:
		var current_player = seat_assignments[current_seat]
		var card = deck.draw_card()
		current_player.player_script.hand.append(card)
		if seeing:
			card.front.set_backend(card)
			card.front.show_front()
			# Dealer Seatの位置から、current_seat Seat + current_seat Hand1した位置を引いて、全体にHandのスケールの逆数をかける
			card.front.set_position((table_place["Deck"].get_position() - (animation_place[current_seat]["Seat"].get_position() + animation_place[current_seat]["Hand1"].get_position())) * (1 / 0.6))
			animation_place[current_seat]["Hand1"].add_child(card.front)
			card.front.wait_move_to(wait, Vector2(0, 0), 0.5)
			card.front.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			card.front.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(card.front))
		else:
			card.wait_wait_to(wait, 1.0)
			card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
		n_moving_plus.emit()
		wait += 0.3

func set_initial_button(seat_assignments):

	# 座席リストを取得
	var seats = seat_assignments.keys()
	var dealer_player = seat_assignments[seats[0]]
	var dealer_seat = "Seat1"

	# ランク定義 (2〜10, J, Q, K, A)
	const RANKS = {
		"2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
		"J": 11, "Q": 12, "K": 13, "A": 14
	}

	const SUIT = {
		"♣︎": 1, "♦︎": 2, "♥︎": 3, "♠︎": 4
	}

	# 最高のカードを持つプレイヤーを探す
	for seat in seats:
		var current_player = seat_assignments[seat]
		if current_player:
			if dealer_player == null or (
				RANKS[current_player.player_script.hand[0].rank] > RANKS[dealer_player.player_script.hand[0].rank] or
				(RANKS[current_player.player_script.hand[0].rank] == RANKS[dealer_player.player_script.hand[0].rank] and
				SUIT[current_player.player_script.hand[0].suit] > SUIT[dealer_player.player_script.hand[0].suit])):
				dealer_player = current_player
				dealer_seat = seat

	# そもそもここでディーラーボタンを動かす
	dealer_player.player_script.is_dealer = true
	var dealer_button = DealerButtonBackend.new(seeing)
	add_child(dealer_button)
	n_moving_plus.emit()
	if seeing:
		dealer_button.front.set_position(animation_place["Dealer"]["Seat"].get_position() + animation_place["Dealer"]["DealerButton"].get_position())
		dealer_button.front.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
		table_place["DealerButton"].add_child(dealer_button.front)
		dealer_button.front.move_to(animation_place[dealer_seat]["Seat"].get_position() + animation_place[dealer_seat]["DealerButton"].get_position(), 0.5)
	else:
		dealer_button.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
		dealer_button.wait_to(1.0)

	return dealer_player


func hand_clear(seat_assignments):
	# 全プレイヤーの手札をクリア
	var seats = seat_assignments.keys()
	for seat in seats:
		var player = seat_assignments[seat]
		if player:
			if seeing:
				player.player_script.hand[0].front.queue_free_flg = true
				var player_dst = player.player_script.hand[0].front.get_position() + Vector2(0, -50)
				player.player_script.hand[0].front.wait_move_to(0.1, player_dst, 0.5)
			else:
				player.player_script.wait_wait_to(0.1, 0.5)
			player.player_script.hand.clear()
			n_moving_plus.emit()

	if seeing:
		burn_cards[0].front.queue_free_flg = true
		var dst = burn_cards[0].front.get_position() + Vector2(0, -50)
		burn_cards[0].front.wait_move_to(0.1, dst, 0.5)
	else:
		wait_to(0.5)
	burn_cards.clear()
	n_moving_plus.emit()


# ディーラーボタンから指定の隣のプレイヤーを取得
func get_dealer_button_index(seat_assignments: Dictionary, count: int = 0) -> String:
	# 座席リストを取得して順番に探索
	var seats = seat_assignments.keys()
	var dealer_seat = null

	# ディーラーを持つ座席を探す
	for seat in seats:
		var player = seat_assignments[seat]
		if player and player.player_script.is_dealer:
			dealer_seat = seat
			break

	# ディーラーが見つからない場合（異常系）
	if dealer_seat == null:
		return ""

	# プレイヤーがいる座席のみをリスト化
	var active_seats = []
	for seat in seats:
		if seat_assignments[seat] != null:
			active_seats.append(seat)

	# 次の座席を計算
	var dealer_index = active_seats.find(dealer_seat)
	var next_index = (dealer_index + count) % active_seats.size()
	return active_seats[next_index]  # 次の座席の名前を返す


# 各プレイヤーに2枚のホールカードを配る
func deal_hole_cards(seat_assignments: Dictionary, hand):

	var delay_base = 0.2  # 各プレイヤーへのディレイ間隔
	var card_delay = 1.0  # カード配布アニメーションの時間
	var total_delay = 0.0

	# 座席リストを取得してソート
	var seats = seat_assignments.keys()

	var start_position = (seats.find(get_dealer_button_index(seat_assignments, 1))) % seats.size()
	total_delay = distribute_single_card(seats, start_position, seat_assignments, total_delay, delay_base, card_delay, hand)

# 各プレイヤーに1枚のカードを配る
func distribute_single_card(seats, start_position, seat_assignments, base_delay, delay_base, card_delay, hand):
	var delay = base_delay
	for offset in range(seats.size()):
		var current_position = (start_position + offset) % seats.size()
		var player = seat_assignments[seats[current_position]]
		if player != null:  # 空の座席をスキップ
			var card = deck.draw_card()
			player.player_script.hand.append(card)
			if seeing:
				card.front.set_backend(card)
				# TODO playerだけshow_front(もしくはcard_open？)
				# TODO それ以外はshow_backにする必要あり
				# TODO 今はテストのためにshow_front()
				card.front.show_front()
				# Dealer Seatの位置から、current_seat Seat + current_seat Hand1した位置を引いて、全体にHandのスケールの逆数をかける
				card.front.set_position((table_place["Deck"].get_position() - (animation_place[seats[current_position]]["Seat"].get_position() + animation_place[seats[current_position]][hand].get_position())) * (1 / 0.6))
				animation_place[seats[current_position]][hand].add_child(card.front)
				card.front.wait_move_to(delay, Vector2(0, 0), card_delay)
				card.front.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
				card.front.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(card.front))
			else:
				player.player_script.wait_wait_to(delay, card_delay)
			n_moving_plus.emit()
			delay += delay_base  # 次のプレイヤーの待機時間を計算
	return delay

# アクションリストを作成
func set_action_list(player, current_max_bet, seats, seat_assignments) -> Array:

	var action_list = []
	if bet_record[-1] > player.player_script.current_bet:
		action_list.append("fold")

	if bet_record.size() >= 2:
		if player.player_script.chips <= current_max_bet - player.player_script.current_bet:
			action_list.append("all-in")
		else:
			if bet_record[-1] > player.player_script.current_bet:
				action_list.append("call")
			else:
				action_list.append("check")
		if current_max_bet < player.player_script.current_bet + player.player_script.chips:
			if bet_record[-1] > player.player_script.current_bet:
				action_list.append("raise")
			else:
				action_list.append("bet")
	else:
		action_list.append("check")
		# 再度アクティブなプレイヤーを更新
		var active_players = []
		for seat in seats:
			var p = seat_assignments[seat]
			if p != null and not p.player_script.is_folded and not p.player_script.is_all_in:
				active_players.append(p)
		if active_players.size() > 1:
			if current_max_bet < player.player_script.current_bet + player.player_script.chips:
				action_list.append("bet")
	return action_list

# 選択されたアクションによってプレイヤーの状態を更新
func selected_action(action, player, current_max_bet, bb_value, current_seat):
	if action == "fold":
		player.player_script.fold(seeing)
		if seeing:
			n_moving_plus.emit()
		player.player_script.last_action.append("Fold")
	elif action == "check":
		player.player_script.last_action.append("Check")
		if seeing:
			player.front.move_to(Vector2(0, 0), 0.5)
	elif action == "call":
		var call_amount = current_max_bet - player.player_script.current_bet
		player.player_script.bet(call_amount)
		if seeing:
			player.front.set_chips(player.player_script.chips)
			var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
			var chip = chip_instance.instantiate()
			chip.set_chip_sprite(false)
			chip.set_bet_value(call_amount)
			chip.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			chip.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(chip))
			if animation_place[current_seat]["Bet"].get_child_count() > 0:
				var already_chip = animation_place[current_seat]["Bet"].get_child(0)
				chip.connect("moving_finished_add_chip", Callable(game_process, "_on_moving_finished_add_chip").bind(chip, already_chip))
				chip.add_chip = true
			chip.set_position(-1 * animation_place[current_seat]["Bet"].get_position())
			animation_place[current_seat]["Bet"].add_child(chip)
			chip.move_to(Vector2(0, 0), 0.5)
		else:
			player.player_script.wait_to(0.5)
		player.player_script.last_action.append("Call")
	elif action == "bet":
		var min_bet = bb_value * 2 - player.player_script.current_bet
		var max_bet = player.player_script.chips
		var bet_amount
		if player.player_script.chips < min_bet:
			bet_amount = player.player_script.chips
		else:
			bet_amount = player.player_script.select_bet_amount(min_bet, max_bet)
		if bet_amount == player.player_script.chips:
			player.player_script.is_all_in = true
			player.player_script.last_action.append("All-In")
		else:
			player.player_script.last_action.append("Bet")
		player.player_script.bet(bet_amount)
		if seeing:
			player.front.set_chips(player.player_script.chips)
			var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
			var chip = chip_instance.instantiate()
			chip.set_chip_sprite(false)
			chip.set_bet_value(bet_amount)
			chip.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			chip.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(chip))
			if animation_place[current_seat]["Bet"].get_child_count() > 0:
				var already_chip = animation_place[current_seat]["Bet"].get_child(0)
				chip.connect("moving_finished_add_chip", Callable(game_process, "_on_moving_finished_add_chip").bind(chip, already_chip))
				chip.add_chip = true
			chip.set_position(-1 * animation_place[current_seat]["Bet"].get_position())
			animation_place[current_seat]["Bet"].add_child(chip)
			chip.move_to(Vector2(0, 0), 0.5)
		else:
			player.player_script.wait_to(0.5)
		current_max_bet = bet_amount
		bet_record.append(player.player_script.current_bet)
	elif action == "raise":
		var min_raise
		if bet_record.size() >= 2:
			min_raise = bet_record[-1] - bet_record[-2] + bet_record[-1] - player.player_script.current_bet
		var max_raise = player.chips
		var raise_amount
		if player.player_script.chips < min_raise:
			raise_amount = player.player_script.chips
		else:
			raise_amount = player.player_script.select_bet_amount(min_raise, max_raise)
		current_max_bet = raise_amount
		if raise_amount == player.player_script.chips:
			player.player_script.is_all_in = true
			player.player_script.last_action.append("All-In")
		else:
			player.player_script.last_action.append("Raise")
		player.player_script.bet(raise_amount)
		if seeing:
			player.front.set_chips(player.player_script.chips)
			var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
			var chip = chip_instance.instantiate()
			chip.set_chip_sprite(false)
			chip.set_bet_value(raise_amount)
			chip.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			chip.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(chip))
			if animation_place[current_seat]["Bet"].get_child_count() > 0:
				var already_chip = animation_place[current_seat]["Bet"].get_child(0)
				chip.connect("moving_finished_add_chip", Callable(game_process, "_on_moving_finished_add_chip").bind(chip, already_chip))
				chip.add_chip = true
			chip.set_position(-1 * animation_place[current_seat]["Bet"].get_position())
			animation_place[current_seat]["Bet"].add_child(chip)
			chip.move_to(Vector2(0, 0), 0.5)
		else:
			player.player_script.wait_to(0.5)
		bet_record.append(player.player_script.current_bet)
	elif action == "all-in":
		var all_in_amount = player.player_script.chips
		player.player_script.bet(all_in_amount)
		if seeing:
			player.front.set_chips(player.player_script.chips)
			var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
			var chip = chip_instance.instantiate()
			chip.set_chip_sprite(false)
			chip.set_bet_value(all_in_amount)
			chip.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			chip.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(chip))
			if animation_place[current_seat]["Bet"].get_child_count() > 0:
				var already_chip = animation_place[current_seat]["Bet"].get_child(0)
				chip.connect("moving_finished_add_chip", Callable(game_process, "_on_moving_finished_add_chip").bind(chip, already_chip))
				chip.add_chip = true
			chip.set_position(-1 * animation_place[current_seat]["Bet"].get_position())
			animation_place[current_seat]["Bet"].add_child(chip)
			chip.move_to(Vector2(0, 0), 0.5)
		else:
			player.player_script.wait_to(0.5)
		player.player_script.last_action.append("All-In")
		player.player_script.is_all_in = true
		if all_in_amount > current_max_bet:
			current_max_bet = all_in_amount

# ベットラウンドのアクションを処理
func bet_round(seats, start_index: int, seat_assignments: Dictionary, bb_value: int, current_action: int):

	var current_seat = seats[(start_index + current_action) % seats.size()]
	var player = seat_assignments[current_seat]

	if player == null:
		return "none_player" # 空席はスキップ

	# フォールドまたはオールインしているプレイヤーはスキップ
	if player.player_script.is_folded:
		return "folded"

	if player.player_script.is_all_in:
		return "all-ined"

	# 現在の最大掛け金を取得
	var current_max_bet = bet_record[-1]

	var action_list = set_action_list(player, current_max_bet, seats, seat_assignments)

	var action = player.player_script.select_action(action_list)

	# 選択したアクションを実行
	selected_action(action, player, current_max_bet, bb_value, current_seat)
	player.player_script.has_acted = true

	# 再度アクティブなプレイヤーを更新
	var active_players = []
	for seat in seats:
		var p = seat_assignments[seat]
		if p != null and not p.player_script.is_folded and not p.player_script.is_all_in:
			active_players.append(p)

	# レイズやベットの場合、他プレイヤーのアクションフラグをリセット
	if action in ["bet", "raise", "all-in"]:
		for other_player in active_players:
			if other_player != player:
				if other_player.player_script.has_acted:
					n_active_players_plus.emit()
				other_player.player_script.has_acted = false

	if not seeing:
		player.player_script.wait_to(0.5)
	action_finished.emit()

	return action

# プレイヤーの賭け金をポットとして集める
func pot_collect(seat_assignments: Dictionary) -> int:
	# 現在のアクティブなベット額を収集し、ソート
	var active_bets = []
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			if not player.player_script.is_folded and player.player_script.current_bet > 0:
				if not player.player_script.current_bet in active_bets:
					active_bets.append(player.player_script.current_bet)
	active_bets.sort()

	if active_bets.size() == 0:
		return 0

	var last_bet = 0
	var i = 0
	for index in range(active_bets.size()):
		var bet = active_bets[index]

		# 最初のポット（メインポット）であれば既存のものを使用、それ以外は新しいポットを作成
		var pot
		if index == 0 and pots.size() > 0:
			pot = pots[0]
		else:
			# 寄与が発生する場合のみサブポットを作成
			pot = PotBackend.new()
			pots.append(pot)

		# 各プレイヤーの貢献を計算

		for seat in seat_assignments.keys():
			var player = seat_assignments[seat]
			if player != null and not player.player_script.is_folded:
				var contribution = min(bet - last_bet, player.player_script.current_bet)
				if contribution > 0:
					pot.add_contribution(player.player_script.player_name, contribution)
					player.player_script.current_bet -= contribution
					var chip = ChipBackend.new(seeing)
					chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
					add_child(chip)
					if not seeing:
						chip.wait_wait_to(i * 0.3, 1.0)
						n_moving_plus.emit()
						i += 1

		last_bet = bet

	# プレイヤーの現在のベットが0でない場合、残りを新しいサイドポットに追加
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			if player.player_script.current_bet > 0:
				# サブポットを作成するのは寄与が発生する場合のみ
				if pots.size() == 0 or player.player_script.current_bet > pots[-1].total:
					var pot = PotBackend.new()
					pots.append(pot)
				pots[-1].add_contribution(player.player_script.player_name, player.player_script.current_bet)
				var chip = ChipBackend.new(seeing)
				chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
				add_child(chip)
				if not seeing:
					chip.wait_wait_to(i * 0.3, 1.0)
					n_moving_plus.emit()
					i += 1
				player.player_script.current_bet = 0

			player.player_script.last_action.clear()

	# 全てのポットの合計値を返す
	var total_chips = 0
	for pot in pots:
		total_chips += pot.total

	# プレイヤーのチップを集めて消す処理
	if seeing:
		for seat in seat_assignments.keys():
			if animation_place[seat]["Bet"].get_child_count() > 0:
				var bet = animation_place[seat]["Bet"].get_child(0)
				bet.add_chip = false
				bet.queue_free_flg = true
				bet.move_to(table_place["Pot"].get_position() - (animation_place[seat]["Seat"].get_position() + animation_place[seat]["Bet"].get_position()), 0.5)
				n_moving_plus.emit()

		# ここで全部集めて、合計値をポットとして表示する
		if table_place["Pot"].get_child_count() > 0:
			var already_pot = table_place["Pot"].get_child(0)
			already_pot.set_bet_value(total_chips)
		else:
			var chip_instance = load("res://scenes/gamecomponents/Chip.tscn")
			var chip = chip_instance.instantiate()
			chip.set_chip_sprite(true)
			chip.set_bet_value(total_chips)
			chip.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			chip.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(chip))
			table_place["Pot"].add_child(chip)

	return total_chips


# 指定された枚数のコミュニティカードを公開する
func reveal_community_cards(num_cards: Array) -> Array:

	# 指定された枚数のカードを公開
	for place in num_cards:
		var card = deck.draw_card()  # デッキからカードを1枚引く
		community_cards.append(card)
		if seeing:
			card.front.set_backend(card)
			card.front.show_front()
			# Dealer Seatの位置から、current_seat Seat + current_seat Hand1した位置を引いて、全体にHandのスケールの逆数をかける
			card.front.set_position(table_place["Deck"].get_position() - table_place["CommunityCard"][place].get_position())
			table_place["CommunityCard"][place].add_child(card.front)
			card.front.move_to(Vector2(0, 0), 0.5)
			card.front.connect("moving_finished", Callable(game_process, "_on_moving_finished"))
			card.front.connect("moving_finished_queue_free", Callable(game_process, "_on_moving_finished_queue_free").bind(card.front))
		else:
			card.wait_to(1.0)
			card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
		n_moving_plus.emit()

	return community_cards

# 比較関数を定義
func compare_players(a, b):
	# 1. 手役の強さを比較
	if a.player_script.hand_category[1] != b.player_script.hand_category[1]:
		return a.player_script.hand_category[1] > b.player_script.hand_category[1]

	# 2. ランクの強さを比較
	for i in range(min(a.player_script.hand_rank.size(), b.player_script.hand_rank.size())):
		if a.player_script.hand_rank[i] != b.player_script.hand_rank[i]:
			return a.player_script.hand_rank[i] > b.player_script.hand_rank[i]

	return false

func evaluate_hand(seat_assignments: Dictionary):
	# フォールドしていないプレイヤーを取得
	var active_players = []
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null and not player.player_script.is_folded:
			active_players.append(player)

	# 複数人の場合、手を評価
	for player in active_players:
		var hand_category_rank = hand_evaluator.evaluate_hand(player.player_script.hand, community_cards)
		player.player_script.hand_category = hand_category_rank["category"]
		player.player_script.hand_rank = hand_category_rank["rank"]

	# プレイヤーをソート
	active_players.sort_custom(compare_players)

	return active_players

# ポットをプレイヤーに分配
func distribute_pots(active_players, seat_assignments):

	# プレイヤーが1人ならそのまま全ポットを獲得
	if active_players.size() == 1:
		var winner = active_players[0]
		var total_chips = 0
		for pot in pots:
			total_chips += pot.total
		winner.player_script.chips += total_chips
		var winner_seat = null
		for seat in seat_assignments.keys():
			var player = seat_assignments[seat]
			if player != null and player.player_script.player_name == winner.player_script.player_name:
				winner_seat = seat

		if seeing:
			winner.front.set_bet_value(total_chips)
			var pot = table_place["Pot"].get_child(0)
			pot.add_chip = false
			pot.queue_free_flg = true
			pot.move_to((animation_place[winner_seat]["Seat"].get_position() + animation_place[winner_seat]["Bet"].get_position()) - table_place["Pot"].get_position(), 0.5)
			n_moving_plus.emit()
		else:
			wait_to(0.5)
			n_moving_plus.emit()
		return

	# ポットごとに分配
	for pot in pots:
		var contributors = pot.contributions.keys()
		if contributors.size() > 0:
			var eligible_players = active_players.filter(func(player): return player.player_script.player_name in contributors)

			# チェック: eligible_playersが空の場合、スキップ
			if eligible_players.size() == 0:
				continue

			# 最も強いプレイヤーを取得
			var strongest_hand = eligible_players[0].player_script.hand_rank
			var winners = eligible_players.filter(func(player): return player.player_script.hand_rank == strongest_hand)

			# 勝者にポットを分配
			var chips_per_winner = pot.total / winners.size()
			var i = 1
			for winner in winners:
				winner.player_script.chips += chips_per_winner
				var winner_seat
				for seat in seat_assignments.keys():
					var player = seat_assignments[seat]
					if player != null and player.player_script.player_name == winner.player_script.player_name:
						winner_seat = seat
				if seeing:
					winner.front.set_chips(chips_per_winner)
					var pot_front = null
					if i == winners.size():
						pot_front = table_place["Pot"].get_child(0)
					else:
						var pot_instance = load("res://scenes/gamecomponents/Chip.tscn")
						pot_front = pot_instance.instantiate()
						pot_front.set_chip_sprite(true)
						pot_front.set_bet_value(chips_per_winner)
						table_place["Pot"].add_child(pot_front)
						table_place["Pot"].get_child(0).set_bet_value(-1 * chips_per_winner)
					pot_front.add_chip = false
					pot_front.queue_free_flg = true
					pot_front.move_to((animation_place[winner_seat]["Seat"].get_position() + animation_place[winner_seat]["Bet"].get_position()) - table_place["Pot"].get_position(), 0.5)
					n_moving_plus.emit()
					i += 1
				else:
					winner.player_script.wait_to(0.5)
					n_moving_plus.emit()

# ラウンドの終了後に必要な情報をリセットする
func reset_round(seat_assignments: Dictionary, buy_in: int):

	# 0. 各Node（deck、chip）のremove
	for child in get_children():
		# 子ノードに接続されているシグナルを解除
		for signal_name in child.get_signal_list():
			if child.is_connected(signal_name["name"], Callable(self, "_signal_handler")):
				child.disconnect(signal_name["name"], Callable(self, "_signal_handler"))

		# 子ノードを削除
		remove_child(child)
		child.queue_free()

	# 1. 各プレイヤーのカレントベットと手札をリセット
	if seeing:
		var seats = seat_assignments.keys()
		for seat in seats:
			var player = seat_assignments[seat]
			if player and player.player_script.hand.size() == 2:
				player.player_script.hand[0].front.queue_free_flg = true
				var dst1 = player.player_script.hand[0].front.get_position() + Vector2(0, -50)
				player.player_script.hand[0].front.wait_move_to(0.1, dst1, 0.5)
				player.player_script.hand[1].front.queue_free_flg = true
				var dst2 = player.player_script.hand[1].front.get_position() + Vector2(0, -50)
				player.player_script.hand[1].front.wait_move_to(0.1, dst2, 0.5)
				n_moving_plus.emit()
				n_moving_plus.emit()

	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			player.player_script.hand = []
			player.player_script.current_bet = 0  # 現在のベット額
			player.player_script.last_action = []  # 最後のアクションを保存する属性
			player.player_script.has_acted = false
			player.player_script.is_folded = false  # プレイヤーがフォールドしたかどうかを示すフラグ
			player.player_script.is_all_in = false
			player.player_script.hand_category = null
			player.player_script.hand_rank = null
			# a. いったんここでchipsが0なら100に戻すように設定
			if player.player_script.chips == 0:
				player.player_script.chips = buy_in
				if seeing:
					player.front.set_chips(buy_in)

	# 2. コミュニティカード、バーンカードのリセット

	if seeing:
		for j in range(community_cards.size()):
			community_cards[j].front.queue_free_flg = true
			var community_card = community_cards[j].front.get_position() + Vector2(0, -50)
			community_cards[j].front.move_to(community_card, 0.5)
			n_moving_plus.emit()

		for k in range(burn_cards.size()):
			burn_cards[k].front.queue_free_flg = true
			var burn_card_place = burn_cards[k].front.get_position() + Vector2(0, -50)
			burn_cards[k].front.move_to(burn_card_place, 0.5)
			n_moving_plus.emit()

	community_cards = []
	burn_cards = []

	# 3. ポットのリセット
	pots.clear()
	pots.append(PotBackend.new())

	# 4. ベット履歴のリセット
	bet_record.clear()

	# 5. デッキのリセット
	deck = DeckBackend.new(seeing)
	add_child(deck)

	# n. その他の必要な情報をリセット（必要に応じて追加）

	if not seeing:
		wait_to(0.5)
		n_moving_plus.emit()

# ディーラーボタンを次のプレイヤーに移動します
func move_dealer_button(seat_assignments: Dictionary):
	# 現在のディーラーを見つける
	var current_dealer_seat = null
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null and player.player_script.is_dealer:
			current_dealer_seat = seat
			break

	# 現在のディーラーのフラグをFalseにする
	if current_dealer_seat != null:
		seat_assignments[current_dealer_seat].player_script.is_dealer = false

	# プレイヤーがいる座席のみをリスト化
	var active_seats = []
	for seat in seat_assignments.keys():
		if seat_assignments[seat] != null:
			active_seats.append(seat)

	# 現在のディーラーの座席を基準に次のディーラーを決定
	var current_index = active_seats.find(current_dealer_seat)
	var next_index = (current_index + 1) % active_seats.size()
	var next_dealer_seat = active_seats[next_index]

	# 次のディーラーのフラグをTrueにする
	if seat_assignments[next_dealer_seat] != null:
		seat_assignments[next_dealer_seat].player_script.is_dealer = true

	if seeing:
		var dealer_button_node = table_place["DealerButton"].get_children(0)[0]
		dealer_button_node.move_to(animation_place[next_dealer_seat]["Seat"].get_position() + animation_place[next_dealer_seat]["DealerButton"].get_position(), 0.5)
		n_moving_plus.emit()
	else:
		wait_to(0.5)
		n_moving_plus.emit()

func wait_wait_to(wait : float, dur : float):
	waiting_time = wait
	#wait_elapsed = 0.0
	wait_to(dur)

func wait_to(dur : float):
	move_dur = dur
	move_elapsed = 0.0
	moving = true

func _process(delta):
	if waiting_time > 0.0:
		waiting_time -= delta
		return
	if moving:		# 移動処理中
		move_elapsed += delta	# 経過時間
		move_elapsed = min(move_elapsed, move_dur)	# 行き過ぎ防止
		if move_elapsed == move_dur:		# 移動終了の場合
			moving = false
			waiting_finished.emit()