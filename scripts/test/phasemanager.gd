extends Node

signal step_completed(step_count, total_steps)

var current_phase = 1
var step_count = 0
var total_steps = 0
var waiting_for_input = false

func start_phase():
	print("Phase ", current_phase, " started.")
	step_count = 0
	total_steps = _calculate_total_steps(current_phase)
	start_step()

func start_step():
	step_count += 1
	print("  Step ", step_count, " in Phase ", current_phase)

	# 特定のステップでユーザー入力を待つ
	if current_phase == 1 and step_count == 2:
		print("  Waiting for user input...")
		waiting_for_input = true
	else:
		emit_signal("step_completed", step_count, total_steps)

func _on_user_input(action: String):
	if waiting_for_input:
		print("User input received:", action)
		waiting_for_input = false
		emit_signal("step_completed", step_count, total_steps)

func _calculate_total_steps(phase: int) -> int:
	return 5  # 例: 固定ステップ数
