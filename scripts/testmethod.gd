extends Control

@onready var sprite = $Sprite
@onready var toggle_button = $Button

signal user_input_received

var step_index = 0
var total_steps = 5
var animation_in_progress = false

func _ready():
    toggle_button.visible = false
    toggle_button.connect("toggled", Callable(self, "_on_toggle_button_toggled"))
    start_animation()

func start_animation():
    animation_in_progress = true
    _next_step()

func _next_step():
    if step_index < total_steps:
        print("Step ", step_index + 1, " started.")

        # 3ステップ目でユーザー入力を待機
        if step_index == 2:
            print("Waiting for user input...")
            toggle_button.visible = true
        else:
            # アニメーションステップを進める
            _perform_step()
    else:
        print("Animation completed.")
        animation_in_progress = false

func _perform_step():
    # アニメーションの疑似処理
    sprite.position += Vector2(10, 0)
    print("Step ", step_index + 1, " completed.")

    # 次のステップに進むタイマーを設定
    get_tree().create_timer(0.5).connect("timeout", Callable(self, "_on_step_timer_timeout"))

func _on_step_timer_timeout():
    step_index += 1
    _next_step()

func _on_toggle_button_toggled(button_pressed: bool):
    if button_pressed:
        print("Toggle button pressed.")
        toggle_button.button_pressed = false
        toggle_button.visible = false
        emit_signal("user_input_received")
        step_index += 1
        _next_step()
