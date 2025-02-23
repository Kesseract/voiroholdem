# ノード
extends Node

# クラス名
class_name PlayerBackend

# 属性
var player_name: String
var chips: int
var is_cpu: bool
var hand: Array[CardBackend] = []
var is_dealer: bool = false
var current_bet: int = 0
var last_action: Array[String] = []
var has_acted: bool = false
var is_folded: bool = false
var is_all_in: bool = false
var hand_category: Array
var hand_rank: Array
var rebuy_count: int

# ボタンから受け取るアクションと実際のアクションの対応
var action_mapping = {
    "fold": ["fold"],
    "check/call": ["check", "call"],
    "bet/raise": ["bet", "raise"]
}

# アクションとベット額を保持するプロパティ
var selected_action: String  # プレイヤーが選択したアクション
var selected_bet_amount: int = 0  # プレイヤーが選択したベット額

# ゲームプロセスクラス
var game_process

# 時間管理クラス
var time_manager


func _init(_name: String, _chips: int, _game_process, _is_cpu: bool = false):
    """初期化関数
    Args:
        _name String: プレイヤー名
        _chips int: 持ち込みチップ数
        _is_cpu bool: True の場合、CPUとして扱う
                        False の場合、操作プレイヤーとして扱う
                        初期値 False
    Returns:
        void
    """
    # 引数受け取り
    player_name = _name
    chips = _chips
    game_process = _game_process
    is_cpu = _is_cpu

    # 時間管理クラス作成
    time_manager = TimeManager.new()


func _ready() -> void:
    """シーンがノードに追加されたときに呼ばれる関数
    Args:
    Returns:
        void
    """
    # 時間管理クラスをノードに追加する
    time_manager.name = "TimeManager"
    add_child(time_manager)


func bet(amount: int) -> int:
    """ベット関数
    Args:
        amount int: ベット額
    Returns:
        actual_bet int: 実際に支払った額
    """
    # 所持チップとベット額のうち、少ないほう
    var actual_bet = min(chips, amount)

    # 所持チップから引く
    chips -= actual_bet

    # ベット額に追加
    current_bet += actual_bet

    # 実際に支払った額を返す
    return actual_bet


func fold(seeing) -> void:
    """フォールド関数
    Args:
        seeing bool: True の場合、見た目 (front) を作成する
                        False の場合、データのみとして扱う
    Returns:
        void
    """
    # 表示部分があるなら、それを削除する
    if seeing:
        for i in range(hand.size()):
            var dst = hand[i].front.get_position() + Vector2(0, -50)
            hand[i].front.time_manager.wait_move_to(0.1, hand[i].front, dst, 0.5, Callable(game_process, "_on_moving_finished_queue_free").bind(hand[i].front))

    # 自分の手を削除する
    hand.clear()

    # フォールドしたフラグをtrueにする
    is_folded = true


func select_action(available_actions: Array[String]) -> String:
    """アクション選択関数
    Args:
        available_actions Array[String]: 選択可能アクションの配列
    Returns:
        action String: 選択されたアクション
    """
    # 選択されるアクション用変数
    var action = ""

    # CPUかプレイヤーかで分岐
    if is_cpu:
        # CPU用アクション選択関数実行
        action = _cpu_select_action(available_actions)
    else:
        # プレイヤー用アクション選択関数実行
        action = _player_select_action(available_actions)

    # 選択されたアクションを返す
    return action


# CPUとしてアクションを選択
func _cpu_select_action(available_actions: Array[String]) -> String:
    """CPUアクション選択関数
    Args:
        available_actions Array[String]: 選択可能アクションの配列
    Returns:
        String: 選択されたアクション
    """
    # アクションをランダムに返す
    return available_actions[randi() % available_actions.size()]


func _player_select_action(available_actions: Array[String]) -> String:
    """プレイヤーアクション選択関数
    Args:
        available_actions Array[String]: 選択可能アクションの配列
    Returns:
        action String: 選択されたアクション
    """
    # selected_action をマッピングで確認
    if selected_action in action_mapping:
        # マッピングの中身でループ
        for action in action_mapping[selected_action]:
            # 存在する方を返す
            if action in available_actions:
                return action

    # その他の場合はall-inを返す
    return "all-in"


func set_selected_action(action: String) -> void:
    """アクション設定関数
    Args:
        action String: プレイヤーが選択したアクション
    Returns:
        void
    """
    # 選択されたアクションを属性に入れる
    selected_action = action
    print("Selected action updated to:", action)


func set_selected_bet_amount(amount: int) -> void:
    """ベット額設定関数
    Args:
        amount int: ベット額
    Returns:
        void
    """
    # 設定されたベット額を属性に入れる
    selected_bet_amount = amount


func select_bet_amount(min_amount: int, max_amount: int) -> int:
    """ベット額選択関数
    Args:
        min_amount int: ベット額下限
        max_amount int: ベット額上限
    Returns:
        amount int: 選択されたベット額
    """
    # 選択されたベット額用変数
    var amount

    # CPUかプレイヤーかで分岐
    if is_cpu:
        # CPUベット額選択用関数実行
        amount = _cpu_select_bet_amount(min_amount, max_amount)
    else:
        # プレイヤーベット額選択用関数実行
        amount = _player_select_bet_amount()

    # 選択されたベット額を返す
    return amount


func _cpu_select_bet_amount(min_amount: int, max_amount: int) -> int:
    """CPUベット額選択用関数
    Args:
        min_amount int: ベット額下限
        max_amount int: ベット額上限
    Returns:
        amount int: 選択されたベット額
    """
    # ランダムに選択されたベット額
    return randi() % (max_amount - min_amount + 1) + min_amount


func _player_select_bet_amount() -> int:
    """プレイヤーベット額選択用関数
    Args:
    Returns:
        int(selected_bet_amount) int: 選択されたベット額
    """
    # あらかじめ選択していたベット額を整数にして返す
    return int(selected_bet_amount)


func to_str() -> String:
    """属性表示用関数
    Args:
    Returns:
        result String: インスタンスの現在の属性をまとめた文字列
    """
    var result = "=== PlayerBackend 状態 ===\n"
    result += "プレイヤー名: " + str(player_name) + "\n"
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