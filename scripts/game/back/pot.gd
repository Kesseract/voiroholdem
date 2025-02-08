class_name PotBackend

# クラスの属性
var total: int = 0  # ポット内のチップの合計
var contributions: Dictionary = {}  # プレイヤーごとのチップ寄与額
var max_contribution: int = 0  # このポットに対する最大寄与額

# 現在の状態を文字列として取得する
func to_str() -> String:
    var result = "=== PotBackend 状態 ===\n"
    result += "合計: " + str(total) + "\n"
    result += "プレイヤーごとの寄与: " + str(contributions) + "\n"
    result += "最大寄与額: " + str(max_contribution) + "\n"
    result += "=======================\n"
    return result

# プレイヤーの寄与を追加する
func add_contribution(player: String, amount: int) -> void:
    """プレイヤーから指定された量の寄与を追加します。

    Args:
        player (String): プレイヤーの名前。
        amount (int): 寄与する額。
    """
    total += amount
    contributions[player] = contributions.get(player, 0) + amount
    max_contribution = max(max_contribution, amount)

# 指定されたプレイヤーの寄与額を返す
func get_contribution(player: String) -> int:
    """指定されたプレイヤーの寄与額を返します。

    Args:
        player (String): プレイヤーの名前。

    Returns:
        int: プレイヤーの寄与額。
    """
    return contributions.get(player, 0)

# 獲得資格があるプレイヤーのリストを返す
func get_eligible_players() -> Array:
    """このポットを獲得する資格があるプレイヤーのリストを返します。

    Returns:
        Array: 資格があるプレイヤーのリスト。
    """
    var eligible_players = []
    for player in contributions.keys():
        if contributions[player] >= max_contribution:
            eligible_players.append(player)
    return eligible_players