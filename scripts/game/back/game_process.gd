class_name GameProcessBackend

signal phase_completed

var current_phase = -1
var dealer
var seat_assignments = {}
var sb
var bb
var remaining_players = []

func _init(_dealer, _seat_assignments, _sb, _bb):
	dealer = _dealer
	seat_assignments = _seat_assignments
	sb = _sb
	bb = _bb
	emit_signal("phase_completed")

func advance_phase():
	match current_phase:
		0:
			# ディーラーボタンを決定する
			dealer.set_initial_button(seat_assignments)
		1:
			# BBとSB、アンティを支払わせる
			# 現在のディーラーボタンの位置を取得する
			var sb_player = seat_assignments[dealer.get_dealer_button_index(seat_assignments, 1)]
			var bb_player = seat_assignments[dealer.get_dealer_button_index(seat_assignments, 2)]
			sb_player.player_script.bet(dealer.get_dealer_button_index(seat_assignments, 1), sb)
			bb_player.player_script.bet(dealer.get_dealer_button_index(seat_assignments, 2), bb)
			dealer.bet_record.append(sb)
			dealer.bet_record.append(bb)
		2:
			# 各プレイヤーにカードを2枚配る
			dealer.deal_hole_cards(seat_assignments)
		3:
			# プリフロップアクション
			remaining_players = await dealer.bet_round(seat_assignments, bb)
		4:
			# ベット額をポットに集める
			dealer.pot_collect(seat_assignments)
		5:
			# コミュニティカード3枚
			dealer.reveal_community_cards(["Flop1", "Flop2", "Flop3"], "Flop")
		6:
			# フロップアクション
			remaining_players = await dealer.bet_round(seat_assignments, bb)
		7:
			# ベット額をポットに集める
			dealer.pot_collect(seat_assignments)
		8:
			# コミュニティカード1枚
			dealer.reveal_community_cards(["Turn"], "Turn")
		9:
			# ターンアクション
			remaining_players = await dealer.bet_round(seat_assignments, bb)
		10:
			# ベット額をポットに集める
			dealer.pot_collect(seat_assignments)
		11:
			# コミュニティカード1枚
			dealer.reveal_community_cards(["River"], "River")
		12:
			# リバーアクション
			remaining_players = await dealer.bet_round(seat_assignments, bb)
		13:
			# ベット額をポットに集める
			dealer.pot_collect(seat_assignments)
		14:
			# チップの払い出し(プリフロップアクションからここに飛ぶ可能性もある)
			dealer.distribute_pots(seat_assignments)
		15:
			# リセット処理
			dealer.reset_round(seat_assignments)
		16:
			# ディーラーボタン移動
			dealer.move_dealer_button(seat_assignments)

	emit_signal("phase_completed")  # フェーズ完了を通知
