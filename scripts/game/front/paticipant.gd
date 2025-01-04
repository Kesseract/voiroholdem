extends Control

var backend
var sprite
var name_action
var chips

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

# ベット額と残りチップを画面に反映
func _on_bet_updated(remaining_chips: int):
	set_chips(remaining_chips)  # チップ残高のUIを更新

func set_sprite(value):
	sprite.texture = value

func set_name_action(value):
	name_action.text = value

func set_chips(value):
	chips.text = str(value)

func set_backend(_backend, _seat):
	backend = _backend

	# 役割ごとのノードマッピング
	var role_map = {
		"player": node["Player"],
		"dealer": node["Dealer"],
		"playing_dealer": node["PlayingDealer"]
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
