class_name PlayerBackend

# プロパティ
var name: String
var chips: int
var is_cpu: bool
var hand: Array = []
var is_dealer: bool = false
var current_bet: int = 0
var last_action: Array = []
var has_acted: bool = false
var is_folded: bool = false
var is_all_in: bool = false
var hand_category
var hand_rank
var rebuy_count

# アクションとベット額を保持するプロパティ
var selected_action: String  # プレイヤーが選択したアクション
var selected_bet_amount: int = 0  # プレイヤーが選択したベット額

# 初期化
func _init(_name: String, _chips: int, _is_cpu: bool = false):
	name = _name
	chips = _chips
	is_cpu = _is_cpu

# 現在の状態を文字列として取得する
func to_str() -> String:
	var result = "=== PlayerBackend 状態 ===\n"
	result += "プレイヤー名: " + str(name) + "\n"
	result += "チップ: " + str(chips) + "\n"
	# hand の情報を文字列として取得
	if hand.size() > 0:
		var hand_strings = []
		for card in hand:
			hand_strings.append(card.to_str())
		result += "ハンド: " + ", ".join(hand_strings) + "\n"
	else:
		result += "ハンド: なし\n"
	result += "ディーラーボタン:" + str(is_dealer) + "\n"
	result += "ベット額: " + str(current_bet) + "\n"
	result += "最後のアクション: " + str(last_action) + "\n"
	result += "アクションしたか: " + str(has_acted) + "\n"
	result += "フォールド: " + str(is_folded) + "\n"
	result += "オールイン: " + str(is_all_in) + "\n"
	result += "手役: " + str(hand_category) + "\n"
	result += "強さ: " + str(hand_rank) + "\n"
	result += "=======================\n"
	return result

# ベットする
func bet(amount: int) -> int:
	var actual_bet = min(chips, amount)
	chips -= actual_bet
	current_bet += actual_bet
	return actual_bet

# フォールドする
func fold():
	hand.clear()
	is_folded = true

# 利用可能なアクションの中からアクションを選択する。
func select_action(available_actions):
	var action = ""
	if is_cpu:
		action = _cpu_select_action(available_actions)
	else:
		action = _player_select_action(available_actions)
	return action

# アクションを設定
func set_selected_action(action: String):
	selected_action = action
	print("Selected action updated to:", action)

# ベット額をセットする
func set_selected_bet_amount(amount: int):
	selected_bet_amount = amount

# CPUとしてアクションを選択
func _cpu_select_action(available_actions: Array) -> String:
	return available_actions[randi() % available_actions.size()]

func _player_select_action(available_actions: Array) -> String:
	# マッピングテーブル
	var action_mapping = {
		"fold": ["fold"],
		"check/call": ["check", "call"],
		"bet/raise": ["bet", "raise"]
	}

	# selected_action をマッピングで確認
	if selected_action in action_mapping:
		for action in action_mapping[selected_action]:
			if action in available_actions:
				return action  # 存在する方を返す

	return "all-in"  # その他の場合はそのまま返す

# ベットまたはレイズの額を選択する。
func select_bet_amount(min_amount, max_amount):
	if is_cpu:
		return _cpu_select_bet_amount(min_amount, max_amount)
	else:
		return _player_select_bet_amount(min_amount, max_amount)

# CPUとしてベット額を選択
func _cpu_select_bet_amount(min_amount: int, max_amount: int) -> int:
	return randi() % (max_amount - min_amount + 1) + min_amount

# プレイヤーとしてのベットまたはレイズの額を選択する
func _player_select_bet_amount(min_amount: int, max_amount: int) -> int:
	return int(selected_bet_amount)  # スケーリング結果を整数に変換して返す

# ディーラーフラグをセットする
func set_dealer(status: bool):
	is_dealer = status