class_name DealerBackend

# 属性
var deck
var pots: Array = []
var bet_record: Array = []
var community_cards: Array = []
var hand_evaluator
var game_process

signal burn_card_signal(place: String, card: CardBackend)
signal deal_card_signal(place: String, card: CardBackend)
signal community_card_signal(seat: String, place: String, card: CardBackend)
signal delete_front_bet(seat: String)
signal set_pot(total_chips: int)
signal delete_front_pot()
signal delete_front_community()
signal delete_front_burn()
signal min_size(min_size: int)
signal max_size(max_size: int)
signal step_completed()

# 初期化
func _init():
	deck = DeckBackend.new()
	pots.append(PotBackend.new())
	bet_record = []
	community_cards = []
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
	result += "=======================\n"
	return result

# バーンカードを行う
func burn_card(place: String):
	var card = deck.draw_card()
	emit_signal("burn_card_signal", place, card)

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
			emit_signal("deal_card_signal", current_seat, "Card1", card)
			emit_signal("step_completed")

func set_initial_button(seat_assignments):

	# バーンカードを1枚捨てる
	burn_card("SetDealer")

	# Stepタイマーを開始して次のStep（カードを配る）に進む
	emit_signal("step_completed")

	# 各プレイヤーに1枚ずつカードを配る
	deal_card(seat_assignments)

	# 座席リストを取得
	var seats = seat_assignments.keys()
	var dealer_player = seat_assignments[seats[0]]
	var dealer_seat = "Dealer"

	# 最高のカードを持つプレイヤーを探す
	for seat in seats:
		var current_player = seat_assignments[seat]
		if current_player:
			if dealer_player == null or	(current_player.player_script.hand[0].rank > dealer_player.player_script.hand[0].rank or
				(current_player.player_script.hand[0].rank == dealer_player.player_script.hand[0].rank and
				current_player.player_script.hand[0].suit > dealer_player.player_script.hand[0].suit)):
				dealer_player = current_player
				dealer_seat = seat

	# ディーラーを設定
	dealer_player.player_script.is_dealer = true
	dealer_player.player_script.set_dealer("Dealer", false)
	dealer_player.player_script.set_dealer(dealer_seat, true)

	# 全プレイヤーの手札をクリア
	for seat in seats:
		var player = seat_assignments[seat]
		if player:
			player.player_script.hand.clear()
			player.player_script.front_hands_clear(seat)

	emit_signal("delete_front_burn")

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
	burn_card("DealCard")

	# 座席リストを取得してソート
	var seats = seat_assignments.keys()

	var start_position = (seats.find(get_dealer_button_index(seat_assignments, 1))) % seats.size()

	# 各プレイヤーにカードを配る
	for i in ["Card1", "Card2"]:  # 2枚配る
		for j in range(seats.size()):
			var current_position = (start_position + j) % seats.size()
			var player = seat_assignments[seats[current_position]]
			if player != null:  # 空の座席をスキップ
				var card = deck.draw_card()
				player.player_script.hand.append(card)
				emit_signal("deal_card_signal", seats[current_position], i, card)


# アクションリストを作成
func set_action_list(player, current_max_bet) -> Array:
	var action_list = ["fold"]

	if bet_record.size() >= 2:
		if player.player_script.chips <= current_max_bet - player.player_script.current_bet:
			action_list.append("all-in")
		else:
			action_list.append("call")
		if current_max_bet < player.player_script.current_bet + player.player_script.chips:
			if bet_record.size() <= 4:
				action_list.append("raise")
	else:
		action_list.append("check")
		if current_max_bet < player.player_script.current_bet + player.player_script.chips:
			if bet_record.size() <= 4:
				action_list.append("bet")

	return action_list

# 選択されたアクションによってプレイヤーの状態を更新
func selected_action(action, player, current_max_bet, bb_value, seat_name):
	if action == "fold":
		player.player_script.fold(seat_name)
		player.player_script.last_action.append("Fold")
	elif action == "check":
		player.player_script.last_action.append("Check")
	elif action == "call":
		var call_amount = current_max_bet - player.player_script.current_bet
		player.player_script.bet(seat_name, call_amount)
		if 0 == player.player_script.chips:
			player.player_script.is_all_in = true
			player.player_script.last_action.append("All-In")
		else:
			player.player_script.last_action.append("Call")
	elif action == "bet":
		var min_bet = bb_value * 2 - player.player_script.current_bet
		var max_bet = player.player_script.chips
		var bet_amount = min_bet if player.player_script.chips < min_bet else player.player_script.select_bet_amount(min_bet, max_bet)
		if bet_amount == player.player_script.chips:
			player.player_script.is_all_in = true
			player.player_script.last_action.append("All-In")
		else:
			player.player_script.last_action.append("Bet")
		player.player_script.bet(seat_name, bet_amount)
		current_max_bet = bet_amount
		bet_record.append(player.player_script.current_bet)
	elif action == "raise":
		var min_raise = bet_record[-1] - bet_record[-2] + bet_record[-1] - player.player_script.current_bet
		var max_raise = player.chips
		var raise_amount = min_raise if player.player_script.chips < min_raise else player.player_script.select_bet_amount(min_raise, max_raise)
		current_max_bet = raise_amount
		if raise_amount == player.player_script.chips:
			player.player_script.is_all_in = true
			player.player_script.last_action.append("All-In")
		else:
			player.player_script.last_action.append("Raise")
		player.player_script.bet(seat_name, raise_amount)
		bet_record.append(player.player_script.current_bet)

# ベットラウンドのアクションを処理
func bet_round(seat_assignments: Dictionary, bb_value: int):
	var seats = seat_assignments.keys()
	var start_index = (seats.find(get_dealer_button_index(seat_assignments, 3))) % seats.size()

	# 全プレイヤーのアクションを未完了に初期化
	for seat in seats:
		var player = seat_assignments[seat]
		if player != null:
			player.player_script.has_acted = false

	while true:
		# 各プレイヤーに対してアクションを実行
		for i in range(seats.size()):
			var current_seat = seats[(start_index + i) % seats.size()]
			var player = seat_assignments[current_seat]

			if player == null:
				continue  # 空席はスキップ

			# アクティブなプレイヤーを取得
			var active_players = []
			for seat in seats:
				var p = seat_assignments[seat]
				if p != null and not p.player_script.is_folded:
					active_players.append(p)

			# アクティブなプレイヤーが1人だけの場合、アクションを終了
			if active_players.size() == 1:
				return active_players

			# フォールドまたはオールインしているプレイヤーはスキップ
			if player.player_script.is_folded or player.player_script.is_all_in:
				continue

			# 現在の最大掛け金を取得
			var current_max_bet = 0
			for seat in seats:
				var p = seat_assignments[seat]
				if p != null:
					current_max_bet = max(current_max_bet, p.player_script.current_bet)

			# プレイヤーが選択可能なアクションを取得
			var slider_min_size = 1
			if bet_record.size() >= 2:
				slider_min_size = bet_record[-1] - bet_record[-2] + bet_record[-1] - player.player_script.current_bet
			else:
				slider_min_size = bb_value * 2 - player.player_script.current_bet

			if !player.player_script.is_cpu:
				var slider_max_size = player.player_script.chips
				if slider_min_size > slider_max_size:
					slider_min_size = slider_max_size
				emit_signal("min_size", slider_min_size)
				emit_signal("max_size", slider_max_size)

			var action_list = set_action_list(player, current_max_bet)

			var action = await player.player_script.select_action(action_list)

			# 選択したアクションを実行
			selected_action(action, player, current_max_bet, bb_value, current_seat)
			player.player_script.has_acted = true

			# 再度アクティブなプレイヤーを更新
			active_players.clear()
			for seat in seats:
				var p = seat_assignments[seat]
				if p != null and not p.player_script.is_folded:
					active_players.append(p)

			# レイズやベットの場合、他プレイヤーのアクションフラグをリセット
			if action in ["bet", "raise", "all-in"]:
				for p in active_players:
					if p != player:
						p.player_script.has_acted = false

			# アクティブなプレイヤーのベット金額を確認
			var active_players_bet = []
			for p in active_players:
				active_players_bet.append(p.player_script.current_bet)

			# アクティブなプレイヤーが全員アクション済みまたはオールインの場合
			var active_players_acted = true
			for p in active_players:
				if not (p.player_script.has_acted or p.player_script.is_all_in):
					active_players_acted = false
					break

			if active_players_bet.size() >= 1 and active_players_acted:
				bet_record = [0]
				return active_players


# プレイヤーの賭け金をポットとして集める
func pot_collect(seat_assignments: Dictionary) -> int:
	# 現在のアクティブなベット額を収集し、ソート
	var active_bets = []
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null:
			# ここでfront_betの表示を消す
			emit_signal("delete_front_bet", seat)
			if not player.player_script.is_folded:
				active_bets.append(player.player_script.current_bet)
	active_bets.sort()

	var last_bet = 0
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
					pot.add_contribution(player.player_script.name, contribution)
					player.player_script.current_bet -= contribution

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
				pots[-1].add_contribution(player.player_script.name, player.player_script.current_bet)
				player.player_script.current_bet = 0

			player.player_script.last_action.clear()

	# 全てのポットの合計値を返す
	var total_chips = 0
	for pot in pots:
		total_chips += pot.total

	# ここでfront_potに追加する
	emit_signal("set_pot", total_chips)
	return total_chips


# 指定された枚数のコミュニティカードを公開する
func reveal_community_cards(num_cards: Array, phase: String) -> Array:
	# デッキからカードをバーン
	burn_card(phase)

	# 指定された枚数のカードを公開
	for place in num_cards:
		var card = deck.draw_card()  # デッキからカードを1枚引く
		community_cards.append(card)

		emit_signal("community_card_signal", place, card)

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

# ポットをプレイヤーに分配
func distribute_pots(seat_assignments: Dictionary):
	# フォールドしていないプレイヤーを取得
	var active_players = []
	for seat in seat_assignments.keys():
		var player = seat_assignments[seat]
		if player != null and not player.player_script.is_folded:
			active_players.append(player)

	# プレイヤーが1人ならそのまま全ポットを獲得
	if active_players.size() == 1:
		var winner = active_players[0]
		var total_chips = 0
		for pot in pots:
			total_chips += pot.total
		winner.player_script.chips += total_chips
		winner.player_script.front_chips()
		# ポットを削除
		emit_signal("delete_front_pot")
		return

	# 複数人の場合、手を評価
	for player in active_players:
		var hand_category_rank = hand_evaluator.evaluate_hand(player.player_script.hand, community_cards)
		player.player_script.hand_category = hand_category_rank["category"]
		player.player_script.hand_rank = hand_category_rank["rank"]

	# プレイヤーをソート
	active_players.sort_custom(compare_players)

	# ポットごとに分配
	for pot in pots:
		var contributors = pot.contributions.keys()
		if contributors.size() > 0:
			var eligible_players = active_players.filter(func(player): return player.player_script.name in contributors)

			# チェック: eligible_playersが空の場合、スキップ
			if eligible_players.size() == 0:
				continue

			# 最も強いプレイヤーを取得
			var strongest_hand = eligible_players[0].player_script.hand_rank
			var winners = eligible_players.filter(func(player): return player.player_script.hand_rank == strongest_hand)

			# 勝者にポットを分配
			var chips_per_winner = pot.total / winners.size()
			for winner in winners:
				winner.player_script.chips += chips_per_winner
				winner.player_script.front_chips()

	# ポットを削除
	emit_signal("delete_front_pot")

# ラウンドの終了後に必要な情報をリセットする
func reset_round(seat_assignments: Dictionary):
	# 1. 各プレイヤーのカレントベットと手札をリセット
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
			player.player_script.front_hands_clear(seat)

	# 2. コミュニティカードのリセット
	community_cards = []

	# 3. ポットのリセット
	pots.clear()
	pots.append(PotBackend.new())

	# 4. ベット履歴のリセット
	bet_record.clear()

	# 5. デッキのリセット
	deck = DeckBackend.new()

	# 6. 表示項目のリセット
	# シグナルを飛ばす
	# バーンカードとコミュニティカードをリセット
	emit_signal("delete_front_community")
	emit_signal("delete_front_burn")

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
		seat_assignments[current_dealer_seat].player_script.set_dealer(current_dealer_seat, false)

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
		seat_assignments[next_dealer_seat].player_script.set_dealer(next_dealer_seat, true)
