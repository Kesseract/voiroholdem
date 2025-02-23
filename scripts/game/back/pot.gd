# クラス名
class_name PotBackend

# 属性
# ポット内のチップの合計
var total: int = 0
# プレイヤーごとのチップ寄与額
var contributions: Dictionary = {}
# このポットに対する最大寄与額
var max_contribution: int = 0


func add_contribution(player: String, amount: int) -> void:
    """プレイヤーから指定された量の寄与を追加する関数
    Args:
        player String: プレイヤーの名前
        amount int: 寄与する額
    """
    # ポット内のチップ合計に加算
    total += amount

    # そのプレイヤーへの寄与を加算
    contributions[player] = contributions.get(player, 0) + amount

    # 対象のポットの最大寄与額を更新
    max_contribution = max(max_contribution, amount)


func get_contribution(player: String) -> int:
    """指定されたプレイヤーの寄与額を返す関数
    Args:
        player String: プレイヤーの名前
    Returns:
        contributions.get(player, 0) int: プレイヤーの寄与額
    """
    # 指定されたプレイヤーの寄与額を返す
    return contributions.get(player, 0)


func get_eligible_players() -> Array[String]:
    """このポットを獲得する資格があるプレイヤーのリストを返す
    Returns:
        Array: 資格があるプレイヤーのリスト
    """
    # 獲得資格があるプレイヤーのリスト
    var eligible_players: Array[String] = []

    # 獲得資格があるプレイヤーを追加する
    for player in contributions.keys():
        if contributions[player] >= max_contribution:
            eligible_players.append(player)

    # 獲得資格があるプレイヤーのリストを返す
    return eligible_players


func to_str() -> String:
    """属性表示用関数
    Args:
    Returns:
        result String: インスタンスの現在の属性をまとめた文字列
    """
    var result = "=== PotBackend 状態 ===\n"
    result += "合計: " + str(total) + "\n"
    result += "プレイヤーごとの寄与: " + str(contributions) + "\n"
    result += "最大寄与額: " + str(max_contribution) + "\n"
    result += "=======================\n"
    return result