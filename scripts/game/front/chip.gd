extends Node2D

# 現在のチップ値を保持する変数
var current_chip_value: int = 0

var time_manager

func _init():
	time_manager = TimeManager.new()

func _ready():
	add_child(time_manager)

# 指定された値をチップ表示に設定
func set_chip_value(value: int):
	var chip_value_label = $Value
	chip_value_label.text = str(value)

# ベット額を加算して表示を更新
func set_bet_value(value: int):
	# 累積するロジック
	current_chip_value += value

	# ノードのテキストを更新
	var chip_value_label = $Value
	chip_value_label.text = str(current_chip_value)

# ベット、またはチップのスプライト表示
func set_chip_sprite(is_chip_visible):
	var chip_sprite = $Chip
	var bet_sprite = $Bet
	if is_chip_visible == true:
		chip_sprite.visible = true
		bet_sprite.visible = false
	else:
		chip_sprite.visible = false
		bet_sprite.visible = true
