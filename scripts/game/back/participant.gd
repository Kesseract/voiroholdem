# ノード
extends Node

# クラス名
class_name ParticipantBackend

# 属性
var participant_name: String = "Anonymous"
var chips: int = 0
var is_cpu: bool = false
var role: String = "player"  # "player", "dealer", "playing_dealer"
var player_script: PlayerBackend
var dealer_script: DealerBackend

# 表示フラグ、表示インスタンス
var seeing: bool
var front: Object

# ゲームプロセスクラス
var game_process: GameProcessBackend


func _init(
    _game_process: GameProcessBackend,
    _participant_name: String,
    _chips: int,
    _is_cpu: bool,
    _role: String,
    _seeing: bool,
) -> void:
    """初期化関数
    Args:
        _game_process GameProcessBackend: ゲーム進行管理のインスタンス
        _participant_name String: 参加者名
        _chips int: 持ち込みチップ数
        _is_cpu bool: True の場合、CPUとして扱う
                        False の場合、操作プレイヤーとして扱う
        _role String: 参加者の役割。以下のいずれかを指定する
            - "player": 通常のプレイヤー（カードを受け取る）
            - "dealer": ディーラー（カードを配るが、プレイには参加しない）
            - "playing_dealer": ディーラー兼プレイヤー（カードを配りつつ、自身もプレイヤーとして参加）
        _seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 引数受け取り
    game_process = _game_process
    participant_name = _participant_name
    chips = _chips
    is_cpu = _is_cpu
    role = _role
    seeing = _seeing

    # ロールがplayer、playing_dealerの場合
    if role != "dealer":
        # プレイヤー用のスクリプトをインスタンス化する
        player_script = PlayerBackend.new(participant_name, chips, game_process, is_cpu)

        # ノードの名前を設定
        player_script.name = "PlayerBackend"

        # ノードを追加
        add_child(player_script)

    # ロールがdealer、playing_dealerの場合
    if role != "player":
        # ディーラー用のスクリプトをインスタンス化する
        dealer_script = DealerBackend.new(game_process, seeing)

        # ノードの名前を設定
        dealer_script.name = "DealerBackend"

        # ノードを追加
        add_child(dealer_script)

    # 見た目作成
    if seeing:
        var front_instance = load("res://scenes/gamecomponents/Participant.tscn")
        front = front_instance.instantiate()


func to_str() -> String:
    """属性表示用関数
    Args:
    Returns:
        result String: インスタンスの現在の属性をまとめた文字列
    """
    var result = "=== ParticipantBackend 状態 ===\n"
    result += "参加者名: " + str(participant_name) + "\n"
    result += "チップ数: " + str(chips) + "\n"
    result += "CPUか: " + str(is_cpu) + "\n"
    result += "ロール: " + str(role) + "\n"
    result += "=======================\n"
    return result