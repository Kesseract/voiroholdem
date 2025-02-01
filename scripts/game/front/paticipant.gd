extends Node2D

signal moving_finished

var backend
var sprite
var name_action
var chips

@onready var add_child_node = null
var add_child_flg = false

var waiting_time = 0.0			# ウェイト時間（単位：秒）
var moving = false
var move_dur = 0.0				# 移動所要時間（単位：秒）
var move_elapsed = 0.0			# 移動経過時間（単位：秒）
var src_pos = Vector2(0, 0)		# 移動元位置
var dst_pos = Vector2(0, 0)		# 移動先位置

@onready var node = {
	"Player": {
		"Instance": $Player,
		"Sprite": $Player/VBoxContainer/Frame/Sprite2D,
		"NameAction": $Player/VBoxContainer/NameAction,
		"Chips": $Player/VBoxContainer/Chips,
	},
	"Dealer": {
		"Instance": $Dealer,
		"Sprite": $Dealer/VBoxContainer/Frame/Sprite2D,
		"NameAction": $Dealer/VBoxContainer/NameAction,
		"Chips": null,
	},
	"PlayingDealer": {
		"Instance": $PlayingDealer,
		"Sprite": $PlayingDealer/VBoxContainer/Frame/Sprite2D,
		"NameAction": $PlayingDealer/VBoxContainer/NameAction,
		"Chips": $PlayingDealer/VBoxContainer/Chips,
	}
}

func _init():
	pass

func _ready():
	pass

func set_sprite(value):
	sprite.texture = value

func set_name_action(value):
	name_action.text = value

func set_chips(value):
	chips.text = str(value)

func set_parameter(_backend, _seat):
	backend = _backend

	# 役割ごとのノードマッピング
	var node_place = {
		"Player": {
			"Instance": $Player,
			"Sprite": $Player/VBoxContainer/Frame/Sprite2D,
			"NameAction": $Player/VBoxContainer/NameAction,
			"Chips": $Player/VBoxContainer/Chips,
		},
		"Dealer": {
			"Instance": $Dealer,
			"Sprite": $Dealer/VBoxContainer/Frame/Sprite2D,
			"NameAction": $Dealer/VBoxContainer/NameAction,
			"Chips": null,
		},
		"PlayingDealer": {
			"Instance": $PlayingDealer,
			"Sprite": $PlayingDealer/VBoxContainer/Frame/Sprite2D,
			"NameAction": $PlayingDealer/VBoxContainer/NameAction,
			"Chips": $PlayingDealer/VBoxContainer/Chips,
		}
	}
	var role_map = {
		"player": node_place["Player"],
		"dealer": node_place["Dealer"],
		"playing_dealer": node_place["PlayingDealer"]
	}

	# 役割に基づいてノードを設定
	var role_node = role_map.get(backend.role)
	if role_node:
		sprite = role_node["Sprite"]
		name_action = role_node["NameAction"]
		chips = role_node["Chips"]

	# 他のノードは非表示
	for key in role_map.keys():
		if key != backend.role:
			role_map[key]["Instance"].visible = false

	# 座席から画像の方向を取得
	var direction = Global.SEAT_DIRECTIONS.get(_seat, "right")  # デフォルトは right

	# テクスチャパスを設定
	# var file_path = Global.player_name
	var file_path = backend.participant_name
	if backend.is_cpu == false:
		file_path = "player"
	var sprite_path = load(Global.CHARACTER_TEXTURE_PATHS[file_path][direction])
	set_sprite(sprite_path)

	# 名前とチップ数を設定
	set_name_action(backend.participant_name)
	set_chips(backend.chips)

func wait_move_to(wait : float, dst : Vector2, dur : float):
	waiting_time = wait
	#wait_elapsed = 0.0
	move_to(dst, dur)

func move_to(dst : Vector2, dur : float):
	src_pos = get_position()
	dst_pos = dst
	move_dur = dur
	move_elapsed = 0.0
	moving = true
	pass

func _process(delta):
	if waiting_time > 0.0:
		waiting_time -= delta
		return
	if moving:		# 移動処理中
		move_elapsed += delta	# 経過時間
		move_elapsed = min(move_elapsed, move_dur)	# 行き過ぎ防止
		var r = move_elapsed / move_dur				# 位置割合
		set_position(src_pos * (1.0 - r) + dst_pos * r)		# 位置更新
		if move_elapsed == move_dur:		# 移動終了の場合
			moving = false
			moving_finished.emit()