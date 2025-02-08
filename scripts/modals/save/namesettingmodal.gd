extends Window

# シグナルを定義
signal name_entered(name)

# 入力フィールドとOKボタンの参照
@onready var name_input = $VBoxContainer/LineEdit

func _ready():
    # OKボタンが押されたときの処理を設定
    $VBoxContainer/OK.connect("pressed", Callable(self, "_on_ok_pressed"))
    # Close ボタンのシグナル接続
    $VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))
    # Windowの×ボタンが押されたときにモーダルを閉じる
    self.connect("close_requested", Callable(self, "_on_close_requested"))

func _on_close_button_pressed():
    hide()

func _on_close_requested():
    queue_free()

func _on_ok_pressed():
    var player_name = name_input.text
    if player_name != "":
        emit_signal("name_entered", player_name)
        hide()  # モーダルを閉じる
    else:
        print("Name cannot be empty")
