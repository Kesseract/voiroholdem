# ノード
extends Node2D

# 属性
var sprite: Sprite2D
var name_action: Label
var chips: Label

# バックエンド
var backend: ParticipantBackend

# 時間管理クラス
var time_manager: TimeManager


func _init() -> void:
    """初期化関数
    Args:
    Returns:
        void
    """
    # 時間管理クラス作成
    time_manager = TimeManager.new()


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    add_child(time_manager)


func set_sprite(value: Texture2D) -> void:
    """画像設定クラス
    Args:
        value Texture2D: 設定する画像
    Returns:
        void
    """
    # 画像を設定する
    sprite.texture = value


func set_name_action(value: String) -> void:
    """名前セット関数
    Args:
        value String: 表示させたい名前
    Returns:
        void
    """
    # テキストに引数をセット
    name_action.text = value


func set_chips(value: int) -> void:
    """チップセット関数
    Args:
        value String: 表示させたいチップ数
    Returns:
        void
    """
    # テキストに引数をセット
    chips.text = str(value)


func set_parameter(_backend: ParticipantBackend, _seat: String) -> void:
    """バックエンドセット関数
    Args:
        _backend CardBackend: カードバックエンド
    Returns:
        void
    """
    # 属性に引数をセット
    backend = _backend

    # 役割ごとのノードマッピング
    var role_map = {
        "player": {
            "Instance": $Player,
            "Sprite": $Player/VBoxContainer/Frame/Sprite2D,
            "NameAction": $Player/VBoxContainer/NameAction,
            "Chips": $Player/VBoxContainer/Chips,
        },
        "dealer": {
            "Instance": $Dealer,
            "Sprite": $Dealer/VBoxContainer/Frame/Sprite2D,
            "NameAction": $Dealer/VBoxContainer/NameAction,
            "Chips": null,
        },
        "playing_dealer": {
            "Instance": $PlayingDealer,
            "Sprite": $PlayingDealer/VBoxContainer/Frame/Sprite2D,
            "NameAction": $PlayingDealer/VBoxContainer/NameAction,
            "Chips": $PlayingDealer/VBoxContainer/Chips,
        }
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
