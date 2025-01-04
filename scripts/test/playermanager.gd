extends Node

signal action_selected(action: String)

var selected_action: String = ""

# アクションを設定
func set_selected_action(action: String):
	selected_action = action
	print("Selected action updated to:", action)
	emit_signal("action_selected", action)  # シグナル発行で通知

# アクションを選択
func _player_select_action(available_actions: Array) -> String:
	var action_mapping = {
		"check/call": ["check", "call"],
		"bet/raise": ["bet", "raise"]
	}

	if selected_action in action_mapping:
		for action in action_mapping[selected_action]:
			if action in available_actions:
				emit_signal("action_completed")  # アクション完了を通知
				return action
		emit_signal("action_completed")  # デフォルトで "call"
		return "call"

	return selected_action  # その他の場合はそのまま返す
