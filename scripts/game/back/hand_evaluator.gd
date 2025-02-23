# クラス名
class_name HandEvaluatorBackend

# 固定値をグローバル変数から取得
const HandCategory = Global.HandCategory
const RANKS = Global.RANKS
const SUITS = Global.SUITS


func evaluate_hand(
    player_hand: Array[CardBackend],
    community_cards: Array[CardBackend],
) -> Dictionary:
    """ハンドの強さを評価する関数
    Args:
        player_hand Array[CardBackend]: プレイヤーのカード
        community_cards Array[CardBackend]: コミュニティカード
    Returns:
        best_hand_from_seven(combined_cards) Dictionary: 最も強い役とそれを構成するカードの辞書
    """
    # プレイヤーのカードとコミュニティカードを合わせて7枚の組にする
    var combined_cards = player_hand + community_cards

    # 7枚のカードから最も強い5枚の組み合わせを探す関数実行
    return best_hand_from_seven(combined_cards)


func best_hand_from_seven(cards: Array[CardBackend]) -> Dictionary:
    """7枚のカードから最も強い5枚の組み合わせを探す関数
    Args:
        cards Array[CardBackend]: 7枚のカード
    Returns:
        {"category": best_category, "rank": best_rank} Dictionary: 最も強い役とそれを構成するカードの辞書
    """
    # 最も強い役、最も強いランクを保持する変数
    var best_category = null
    var best_rank = null

    # 5枚ずつのカードの組み合わせを作成
    for combination in get_combinations(cards, 5):
        # 5枚のカードを評価する
        var result = evaluate_five(combination)

        # 返された結果を皮革用変数に入れる
        var category = result["category"]
        var rank = result["rank"]

        # 最も強い役、ランクが来た場合更新する
        if best_category == null or (category[1] > best_category[1] or (category == best_category and rank > best_rank)):
            best_category = category
            best_rank = rank

    # 最も強い役、ランクを返す
    return {"category": best_category, "rank": best_rank}


func get_combinations(cards: Array[CardBackend], length: int) -> Array:
    """組み合わせを生成する関数
    Args:
        cards Array[CardBackend]: 7枚のカード
        length int: 何枚の組み合わせにするか
    Returns:
        result Array: length枚の組み合わせをさらに組み合わせた配列
    """
    # 再帰してきたときに返す用の条件
    if length == 0:
        return [[]]
    if cards.size() == 0:
        return []

    # 結果用の配列
    var result = []

    # カード枚数分ループする
    for i in range(cards.size()):
        # 再帰的にget_combinations呼び出すことで、組み合わせを実現する
        for combination in get_combinations(cards.slice(i + 1, cards.size()), length - 1):
            # 結果用配列に追加する
            result.append([cards[i]] + combination)

    # 結果を返す
    return result


func evaluate_five(cards: Array) -> Dictionary:
    """5枚のカードを評価する
    Args:
        cards Array: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # 評価関数名のリスト
    var evaluators = [
        "is_royal_flush",
        "is_straight_flush",
        "is_four_of_a_kind",
        "is_full_house",
        "is_flush",
        "is_straight",
        "is_three_of_a_kind",
        "is_two_pair",
        "is_one_pair",
        "is_high_card"
    ]

    # 関数を順に呼び出して評価
    for evaluator_name in evaluators:
        # `call`で関数を名前で呼び出す
        var result = call(evaluator_name, cards)

        # 結果を返す
        if result["category"] != null:
            return result

    # 例外処理
    return {"category": null, "rank": null}


func is_royal_flush(cards: Array) -> Dictionary:
    """ロイヤルフラッシュ判定関数
    ストレートフラッシュであり、カードがA, K, Q, J, 10で構成されている
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ストレートフラッシュであるかどうかを判定する
    var straight_flush_result = is_straight_flush(cards)

    # ストレートフラッシュであるかを判定
    if straight_flush_result["category"] == HandCategory.STRAIGHT_FLUSH:
        # ランクの並び替えをする
        var ranks = sorted_ranks(cards)

        # カードがA, K, Q, J, 10で構成されているかを判定
        if ranks.slice(0, 5) == [RANKS["A"], RANKS["K"], RANKS["Q"], RANKS["J"], RANKS["10"]]:
            # どちらも満たす場合、ロイヤルフラッシュとして判定
            return {"category": HandCategory.ROYAL_FLUSH, "rank": ranks}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_straight_flush(cards: Array) -> Dictionary:
    """ストレートフラッシュ判定関数
    ストレートであり、フラッシュである
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ストレートであり、フラッシュである化を判定する
    if is_flush(cards)["category"] and is_straight(cards)["category"]:
        # どちらも満たす場合、ストレートフラッシュとして判定
        return {"category": HandCategory.STRAIGHT_FLUSH, "rank": sorted_ranks(cards)}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_four_of_a_kind(cards: Array) -> Dictionary:
    """フォーオブアカインド判定関数
    同じランクのカードが4枚存在する
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクの数を数える
    var rank_counts = get_rank_counts(cards)

    # 結果用変数
    var four_of_a_kind_rank = null
    var kicker = null

    # ランクの数が4つのものが存在する場合、フォーオブアカインドとして判定する
    for rank in rank_counts.keys():
        if rank_counts[rank] == 4:
            four_of_a_kind_rank = RANKS[rank]

    if four_of_a_kind_rank != null:
        # キッカーを特定（フォーオブアカインドに含まれない1枚）
        for card in cards:
            if RANKS[card.rank] != four_of_a_kind_rank:
                kicker = RANKS[card.rank]  # 文字列から数値に変換
                break  # キッカーは1枚だけなのでループ終了

        return {"category": HandCategory.FOUR_OF_A_KIND, "rank": [four_of_a_kind_rank, kicker]}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_full_house(cards: Array) -> Dictionary:
    """フルハウス判定関数
    同じランクのカードが3枚と2枚のペアが存在する
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクの数を数える
    var rank_counts = get_rank_counts(cards)

    # 3枚セット、2枚セットが存在するか判定する変数
    var three = null
    var pair = null

    # 同じランクのカードが3枚、または2枚存在する場合、そのランクを変数に入れる
    for rank in rank_counts.keys():
        if rank_counts[rank] == 3:
            three = RANKS[rank]
        elif rank_counts[rank] == 2:
            pair = RANKS[rank]

    # 3枚セット、2枚セットが両方とも存在する場合、フルハウスとして判定する
    if three and pair:
        return {"category": HandCategory.FULL_HOUSE, "rank": [three, pair]}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_flush(cards: Array) -> Dictionary:
    """フラッシュ判定関数
    すべてのスートが等しい
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # スートを入れる用の変数
    var suits = []

    # スートだけを抜きだす
    for card in cards:
        suits.append(card.suit)

    # 最初のスートの数と、スート全体の数が等しい場合、フラッシュとして判定する
    if suits.size() > 0 and suits.count(suits[0]) == suits.size():
        # ランク用の配列を準備する
        var ranks = cards.map(func(card): return RANKS[card.rank])
        # 数値が高い順に並べなおす
        ranks.sort()
        ranks.reverse()
        return {"category": HandCategory.FLUSH, "rank": ranks}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_straight(cards: Array) -> Dictionary:
    """ストレート判定関数
    数値が並んでいる
    ->                 ->                  ->
    A, K, Q, J, 10, 9, 8, 7, 6, 5, 4, 3, 2, A
    基本的にこの順だが、Aを介してループはしない
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクを入れる用の配列
    var ranks = []

    # 手札のランクを数値処理できるように
    for card in cards:
        ranks.append(RANKS[card.rank])

    # 重複を削除してソート
    ranks.sort()
    ranks = ranks.duplicate()
    var unique_ranks = []
    for rank in ranks:
        if not unique_ranks.has(rank):
            unique_ranks.append(rank)

    # 通常のストレート
    # Aceがトップランクとして扱われる場合
    for top_rank in range(14, 4, -1):
        var straight = []
        for i in range(5):
            straight.append(top_rank - i)

        # すべてのランクが含まれているか確認
        var is_straight_flg = true
        for rank in straight:
            if not unique_ranks.has(rank):
                is_straight_flg = false
                break

        # ストレートとして返す
        if is_straight_flg:
            return {"category": HandCategory.STRAIGHT, "rank": [top_rank]}

    # A-2-3-4-5のストレート
    var low_straight = [14, 2, 3, 4, 5]
    var is_low_straight = true
    for rank in low_straight:
        if not unique_ranks.has(rank):
            is_low_straight = false
            break

    # ストレートとして返す
    if is_low_straight:
        return {"category": HandCategory.STRAIGHT, "rank": [5]}

    # ストレートではない場合nullとして返す
    return {"category": null, "rank": null}


func is_three_of_a_kind(cards: Array) -> Dictionary:
    """スリーオブアカインド判定関数
    同じランクのカードが3枚存在する
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクの数を数える
    var rank_counts = get_rank_counts(cards)

    # スリーオブアカインドのランクを入れる用の配列
    var three_of_a_kind_rank = []

    # 同じランクのカードが3枚存在する場合、そのランクを変数に入れる
    for rank in rank_counts.keys():
        if rank_counts[rank] == 3:
            three_of_a_kind_rank.append(RANKS[rank])

    # 1個でも変数に値がある場合、キッカーを追加する
    if three_of_a_kind_rank.size() > 0:
        var kickers = []
        for card in cards:
            if RANKS[card.rank] != three_of_a_kind_rank[0]:
                kickers.append(RANKS[card.rank])

        # 数値が高い順に並べなおす
        kickers.sort()
        kickers.reverse()

        # スリーオブアカインドとして判定する
        return {"category": HandCategory.THREE_OF_A_KIND, "rank": [three_of_a_kind_rank[0]] + kickers.slice(0, 2)}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_two_pair(cards: Array) -> Dictionary:
    """ツーペア判定用関数
    同じランクのカードが2枚、それが2セット存在している
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクの数を数える
    var rank_counts = get_rank_counts(cards)

    # ペアの数を数える配列
    var pairs = []

    # ペアが存在する場合、配列に追加する
    for rank in rank_counts.keys():
        if rank_counts[rank] == 2:
            pairs.append(RANKS[rank])

    # ペアが2個以上存在する
    if pairs.size() >= 2:
        # ペアのランクが高い順に並び変える
        pairs.sort()
        pairs.reverse()

        # キッカーを用意する
        var kickers = []
        for card in cards:
            if not pairs.has(RANKS[card.rank]):
                kickers.append(RANKS[card.rank])

        # キッカーのランクが高い順に並び変える
        kickers.sort()
        kickers.reverse()

        # ツーペアとして判定する
        return {"category": HandCategory.TWO_PAIR, "rank": pairs + [kickers[0]]}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_one_pair(cards: Array) -> Dictionary:
    """ワンペア判定用関数
    同じランクのカードが2枚、それが1セット存在している
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクの数を数える
    var rank_counts = get_rank_counts(cards)

    # ペアの数を数える配列
    var pairs = []

    # ペアが存在する場合、配列に追加する
    for rank in rank_counts.keys():
        if rank_counts[rank] == 2:
            pairs.append(RANKS[rank])

    # ペアが1個以上存在する
    if pairs.size() > 0:
        # キッカーを用意する
        var kickers = []
        for card in cards:
            if RANKS[card.rank] != pairs[0]:
                kickers.append(RANKS[card.rank])

        # キッカーのランクが高い順に並び変える
        kickers.sort()
        kickers.reverse()

        # ワンペアとして判定する
        return {"category": HandCategory.ONE_PAIR, "rank": [pairs[0]] + kickers.slice(0, 3)}

    # そうでない場合はnullを返す
    return {"category": null, "rank": null}


func is_high_card(cards: Array) -> Dictionary:
    """ハイカード判定用関数
    どの役もそろっていない。カードのランクを高い順に並べ替える
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        result Dictionary: 役とランクの辞書
    """
    # ランクを並び替える用の配列
    var ranks = []

    # 数値計算できるようにする
    for card in cards:
        ranks.append(RANKS[card.rank])

    # 高い順に並び変える
    ranks.sort()
    ranks.reverse()

    # ハイカードとして判定する
    return {"category": HandCategory.HIGH_CARD, "rank": ranks.slice(0, 5)}


func get_rank_counts(cards: Array) -> Dictionary:
    """カードのランクをカウントする関数
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        counts Dictionary: ランクとその個数の辞書
    """
    # 結果用辞書
    var counts = {}

    # ランクごとに個数をカウントする
    for card in cards:
        counts[card.rank] = counts.get(card.rank, 0) + 1

    # 結果を返す
    return counts


func sorted_ranks(cards: Array) -> Array[int]:
    """カードのランクをソートする関数
    カードのランクをRANKSに基づいて数値に変換し、降順でソート
    Args:
        cards Array[CardBackend]: 5枚のカードの配列
    Returns:
        ranks Array[int]: 数値変換され、降順に並びなおされたカード
    """
    # 結果用配列
    var ranks: Array[int] = []

    # 数値変換
    for card in cards:
        ranks.append(RANKS[card.rank])

    # 降順にする
    ranks.sort()
    ranks.reverse()

    # 結果を返す
    return ranks
