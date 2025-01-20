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

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）

signal waiting_finished
signal action_finished

signal n_moving_plus
signal n_active_players_plus

signal n_number_reset

# 初期化
func _init(_game_process):
	game_process = _game_process
	deck = DeckBackend.new()
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
func burn_card():
	var card = deck.draw_card()
	card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
	emit_signal("n_moving_plus")
	card.wait_to(0.5)
	burn_cards.append(card)

# プレイヤーにカードを配る
func deal_card(seat_assignments, start_position := 0):
	# 座席番号をリストに変換してインデックスでアクセス可能にする
	var seats = seat_assignments.keys()
	var seat_count = seats.size()

	for i in range(seat_count):
		var current_seat = seats[(start_position + i) % seat_count]
		var current_player = seat_assignments[current_seat]

		# プレイヤーがその席にいる場合のみ処理
		if current_player:
			var card = deck.draw_card()
			current_player.player_script.hand.append(card)
			card.wait_wait_to(i * 0.3, 0.5)
			card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
			emit_signal("n_moving_plus")


func set_initial_button(seat_assignments):

	# 座席リストを取得
	var seats = seat_assignments.keys()
	var dealer_player = seat_assignments[seats[0]]

	# 最高のカードを持つプレイヤーを探す
	for seat in seats:
		var current_player = seat_assignments[seat]
		if current_player:
			if dealer_player == null or	(current_player.player_script.hand[0].rank > dealer_player.player_script.hand[0].rank or
				(current_player.player_script.hand[0].rank == dealer_player.player_script.hand[0].rank and
				current_player.player_script.hand[0].suit > dealer_player.player_script.hand[0].suit)):
				dealer_player = current_player

	# 全プレイヤーの手札をクリア
	for seat in seats:
		var player = seat_assignments[seat]
		if player:
			player.player_script.hand.clear()
			player.player_script.wait_wait_to(0.1, 0.5)
			emit_signal("n_moving_plus")

	return dealer_player


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
func deal_hole_cards(seat_assignments: Dictionary):

	var delay_base = 0.2  # 各プレイヤーへのディレイ間隔
	var card_delay = 0.5  # カード配布アニメーションの時間
	var total_delay = 0.0

	# 座席リストを取得してソート
	var seats = seat_assignments.keys()

	var start_position = (seats.find(get_dealer_button_index(seat_assignments, 1))) % seats.size()
	total_delay = distribute_single_card(seats, start_position, seat_assignments, total_delay, delay_base, card_delay)

# 各プレイヤーに1枚のカードを配る
func distribute_single_card(seats, start_position, seat_assignments, base_delay, delay_base, card_delay):
	var delay = base_delay
	for offset in range(seats.size()):
		var current_position = (start_position + offset) % seats.size()
		var player = seat_assignments[seats[current_position]]
		if player != null:  # 空の座席をスキップ
			var card = deck.draw_card()
			player.player_script.hand.append(card)
			player.player_script.wait_wait_to(delay, card_delay)
			emit_signal("n_moving_plus")
			delay += delay_base  # 次のプレイヤーの待機時間を計算
	return delay

# アクションリストを作成
func set_action_list(player, current_max_bet) -> Array:
	var action_list = ["fold"]

	if bet_record.size() >= 1:
		if player.player_script.chips <= current_max_bet - player.player_script.current_bet:
			action_list.append("all-in")
		else:
			action_list.append("call")
		if current_max_bet < player.player_script.current_bet + player.player_script.chips:
			action_list.append("raise")
	else:
		action_list.append("check")
		if current_max_bet < player.player_script.current_bet + player.player_script.chips:
			action_list.append("bet")

	return action_list

# 選択されたアクションによってプレイヤーの状態を更新
func selected_action(action, player, current_max_bet, bb_value):
	if action == "fold":
		player.player_script.fold()
		player.player_script.last_action.append("Fold")
	elif action == "check":
		player.player_script.last_action.append("Check")
	elif action == "call":
		var call_amount = current_max_bet - player.player_script.current_bet
		player.player_script.bet(call_amount)
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
		current_max_bet = bet_amount
		bet_record.append(player.player_script.current_bet)
	elif action == "raise":
		var min_raise
		if bet_record.size() == 1:
			min_raise = bet_record[-1] +  bet_record[-1] - player.player_script.current_bet
		else:
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
		bet_record.append(player.player_script.current_bet)
	elif action == "all-in":
		var all_in_amount = player.player_script.chips
		player.player_script.bet(all_in_amount)
		player.player_script.last_action.append("All-In")
		player.player_script.is_all_in = true
		if all_in_amount > current_max_bet:
			current_max_bet = all_in_amount

# ベットラウンドのアクションを処理
func bet_round(seats, start_index: int, seat_assignments: Dictionary, bb_value: int, current_action: int):

	var current_seat = seats[(start_index + current_action) % seats.size()]
	var player = seat_assignments[current_seat]

	if player == null:
		return false # 空席はスキップ

	# フォールドまたはオールインしているプレイヤーはスキップ
	if player.player_script.is_folded or player.player_script.is_all_in:
		return false

	# 現在の最大掛け金を取得
	var current_max_bet = 0
	for seat in seats:
		var p = seat_assignments[seat]
		if p != null:
			current_max_bet = max(current_max_bet, p.player_script.current_bet)

	var action_list = set_action_list(player, current_max_bet)

	var action = player.player_script.select_action(action_list)

	# 選択したアクションを実行
	selected_action(action, player, current_max_bet, bb_value)
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
					emit_signal("n_active_players_plus")
				other_player.player_script.has_acted = false


	player.player_script.wait_to(1.0)
	emit_signal("action_finished")

	return true

# プレイヤーの賭け金をポットとして集める
func pot_collect(seat_assignments: Dictionary) -> int:
	# 現在のアクティブなベット額を収集し、ソート
	var active_bets = []
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			if not player.player_script.is_folded and player.player_script.current_bet > 0:
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
					var chip = ChipBackend.new()
					chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
					add_child(chip)
					chip.wait_wait_to(i * 0.3, 0.5)
					emit_signal("n_moving_plus")
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
				var chip = ChipBackend.new()
				chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
				add_child(chip)
				chip.wait_wait_to(i * 0.3, 0.5)
				emit_signal("n_moving_plus")
				i += 1
				player.player_script.current_bet = 0

			player.player_script.last_action.clear()

	# 全てのポットの合計値を返す
	var total_chips = 0
	for pot in pots:
		total_chips += pot.total

	return total_chips


# 指定された枚数のコミュニティカードを公開する
func reveal_community_cards(num_cards: Array) -> Array:

	# 指定された枚数のカードを公開
	for place in num_cards:
		var card = deck.draw_card()  # デッキからカードを1枚引く
		community_cards.append(card)
		card.wait_to(0.5)
		card.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
		emit_signal("n_moving_plus")

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
func distribute_pots(active_players):

	# プレイヤーが1人ならそのまま全ポットを獲得
	if active_players.size() == 1:
		var winner = active_players[0]
		var total_chips = 0
		for pot in pots:
			total_chips += pot.total
		winner.player_script.chips += total_chips
		var chip = ChipBackend.new()
		chip.wait_to(0.5)
		chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
		add_child(chip)
		emit_signal("n_moving_plus")
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
			var i = 0
			for winner in winners:
				winner.player_script.chips += chips_per_winner
				var chip = ChipBackend.new()
				chip.wait_wait_to(i, 0.5)
				chip.connect("waiting_finished", Callable(game_process, "_on_moving_finished"))
				add_child(chip)
				emit_signal("n_moving_plus")
				i += 0.3

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
	var i = 0
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			player.player_script.hand = []
			player.player_script.wait_wait_to(i, 0.5)
			emit_signal("n_moving_plus")
			player.player_script.current_bet = 0  # 現在のベット額
			player.player_script.last_action = []  # 最後のアクションを保存する属性
			player.player_script.has_acted = false
			player.player_script.is_folded = false  # プレイヤーがフォールドしたかどうかを示すフラグ
			player.player_script.is_all_in = false
			player.player_script.hand_category = null
			player.player_script.hand_rank = null
			i += 0.3
			# a. いったんここでchipsが0なら100に戻すように設定
			if player.player_script.chips == 0:
				player.player_script.chips = buy_in
	# 2. コミュニティカード、バーンカードのリセット
	community_cards = []
	burn_cards = []
	wait_to(0.5)
	emit_signal("n_moving_plus")

	# 3. ポットのリセット
	pots.clear()
	pots.append(PotBackend.new())

	# 4. ベット履歴のリセット
	bet_record.clear()

	# 5. デッキのリセット
	deck = DeckBackend.new()
	add_child(deck)

	# n. その他の必要な情報をリセット（必要に応じて追加）

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

	wait_to(0.5)
	emit_signal("n_moving_plus")

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
			emit_signal("waiting_finished")	# 移動終了シグナル発行