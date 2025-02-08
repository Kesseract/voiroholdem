class_name HandEvaluatorBackend

const HandCategory = {
    HIGH_CARD = ["ハイカード", 1],
    ONE_PAIR = ["ワンペア", 2],
    TWO_PAIR = ["ツーペア", 3],
    THREE_OF_A_KIND = ["スリーカード", 4],
    STRAIGHT = ["ストレート", 5],
    FLUSH = ["フラッシュ", 6],
    FULL_HOUSE = ["フルハウス", 7],
    FOUR_OF_A_KIND = ["フォーカード", 8],
    STRAIGHT_FLUSH = ["ストレートフラッシュ", 9],
    ROYAL_FLUSH = ["ロイヤルフラッシュ", 10]
}

# ランク定義 (2〜10, J, Q, K, A)
const RANKS = {
    "2": 2, "3": 3, "4": 4, "5": 5, "6": 6, "7": 7, "8": 8, "9": 9, "10": 10,
    "J": 11, "Q": 12, "K": 13, "A": 14
}

const SUITS = {
    "♣︎": 1, "♦︎": 2, "♥︎": 3, "♠︎": 4
}

# ハンドの強さを評価する
func evaluate_hand(player_hand: Array, community_cards: Array) -> Dictionary:
    var combined_cards = player_hand + community_cards
    return best_hand_from_seven(combined_cards)

# 7枚のカードから最も強い5枚の組み合わせを探す
func best_hand_from_seven(cards: Array) -> Dictionary:
    var best_category = null
    var best_rank = null

    # カードの組み合わせを5枚ずつ作成
    for combination in get_combinations(cards, 5):
        var result = evaluate_five(combination)
        var category = result["category"]
        var rank = result["rank"]
        if best_category == null or (category[1] > best_category[1] or (category == best_category and rank > best_rank)):
            best_category = category
            best_rank = rank

    return {"category": best_category, "rank": best_rank}

# 5枚のカードを評価する
func evaluate_five(cards: Array) -> Dictionary:
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
        var result = call(evaluator_name, cards)  # `call`で関数を名前で呼び出す
        if result["category"] != null:
            return result

    return {"category": null, "rank": null}

# 各ハンドの判定関数 (例: ロイヤルフラッシュ)
func is_royal_flush(cards: Array) -> Dictionary:
    var straight_flush_result = is_straight_flush(cards)
    if straight_flush_result["category"] == HandCategory.STRAIGHT_FLUSH:
        var ranks = sorted_ranks(cards)
        if ranks.slice(0, 5) == [RANKS["A"], RANKS["K"], RANKS["Q"], RANKS["J"], RANKS["10"]]:
            return {"category": HandCategory.ROYAL_FLUSH, "rank": ranks}
    return {"category": null, "rank": null}

func is_straight_flush(cards: Array) -> Dictionary:
    if is_flush(cards)["category"] and is_straight(cards)["category"]:
        return {"category": HandCategory.STRAIGHT_FLUSH, "rank": sorted_ranks(cards)}
    return {"category": null, "rank": null}

func is_four_of_a_kind(cards: Array) -> Dictionary:
    var rank_counts = get_rank_counts(cards)
    for rank in rank_counts.keys():
        if rank_counts[rank] == 4:
            return {"category": HandCategory.FOUR_OF_A_KIND, "rank": [rank]}
    return {"category": null, "rank": null}

func is_full_house(cards: Array) -> Dictionary:
    var rank_counts = get_rank_counts(cards)
    var three = null
    var pair = null
    for rank in rank_counts.keys():
        if rank_counts[rank] == 3:
            three = rank
        elif rank_counts[rank] == 2:
            pair = rank
    if three and pair:
        return {"category": HandCategory.FULL_HOUSE, "rank": [three, pair]}
    return {"category": null, "rank": null}

# フラッシュの判定
func is_flush(cards: Array) -> Dictionary:
    var suits = []
    for card in cards:
        suits.append(card.suit)
    if suits.size() > 0 and suits.count(suits[0]) == suits.size():
        var ranks = cards.map(func(card): return RANKS[card.rank])
        ranks.sort()
        ranks.reverse()
        return {"category": HandCategory.FLUSH, "rank": ranks}
    return {"category": null, "rank": null}

# ストレートの判定
func is_straight(cards: Array) -> Dictionary:
    var ranks = []
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
    for top_rank in range(14, 4, -1):  # Aceがトップランクとして扱われる場合
        var straight = []
        for i in range(5):
            straight.append(top_rank - i)

        # すべてのランクが含まれているか確認
        var is_straight_flg = true
        for rank in straight:
            if not unique_ranks.has(rank):
                is_straight_flg = false
                break

        if is_straight_flg:
            return {"category": HandCategory.STRAIGHT, "rank": [top_rank]}

    # A-2-3-4-5のストレート
    var low_straight = [14, 2, 3, 4, 5]
    var is_low_straight = true
    for rank in low_straight:
        if not unique_ranks.has(rank):
            is_low_straight = false
            break

    if is_low_straight:
        return {"category": HandCategory.STRAIGHT, "rank": [5]}

    # ストレートではない場合
    return {"category": null, "rank": null}


# スリーカードの判定
func is_three_of_a_kind(cards: Array) -> Dictionary:
    var rank_counts = get_rank_counts(cards)
    var three_of_a_kind_rank = []
    for rank in rank_counts.keys():
        if rank_counts[rank] == 3:
            three_of_a_kind_rank.append(RANKS[rank])
    if three_of_a_kind_rank.size() > 0:
        var kickers = []
        for card in cards:
            if RANKS[card.rank] != three_of_a_kind_rank[0]:
                kickers.append(RANKS[card.rank])
        kickers.sort()
        kickers.reverse()
        return {"category": HandCategory.THREE_OF_A_KIND, "rank": [three_of_a_kind_rank[0]] + kickers.slice(0, 2)}
    return {"category": null, "rank": null}

# ツーペアの判定
func is_two_pair(cards: Array) -> Dictionary:
    var rank_counts = get_rank_counts(cards)
    var pairs = []
    for rank in rank_counts.keys():
        if rank_counts[rank] == 2:
            pairs.append(RANKS[rank])
    if pairs.size() >= 2:
        pairs.sort()
        pairs.reverse()
        var kickers = []
        for card in cards:
            if not pairs.has(RANKS[card.rank]):
                kickers.append(RANKS[card.rank])
        kickers.sort()
        kickers.reverse()
        return {"category": HandCategory.TWO_PAIR, "rank": pairs + [kickers[0]]}
    return {"category": null, "rank": null}

# ワンペアの判定
func is_one_pair(cards: Array) -> Dictionary:
    var rank_counts = get_rank_counts(cards)
    var pairs = []
    for rank in rank_counts.keys():
        if rank_counts[rank] == 2:
            pairs.append(RANKS[rank])
    if pairs.size() > 0:
        var kickers = []
        for card in cards:
            if RANKS[card.rank] != pairs[0]:
                kickers.append(RANKS[card.rank])
        kickers.sort()
        kickers.reverse()
        return {"category": HandCategory.ONE_PAIR, "rank": [pairs[0]] + kickers.slice(0, 3)}
    return {"category": null, "rank": null}

# ハイカードの判定
func is_high_card(cards: Array) -> Dictionary:
    var ranks = []
    for card in cards:
        ranks.append(RANKS[card.rank])
    ranks.sort()
    ranks.reverse()
    return {"category": HandCategory.HIGH_CARD, "rank": ranks.slice(0, 5)}

# カードのランクをカウントする
func get_rank_counts(cards: Array) -> Dictionary:
    var counts = {}
    for card in cards:
        counts[card.rank] = counts.get(card.rank, 0) + 1
    return counts

# カードのランクをソートするヘルパーメソッド
func sorted_ranks(cards: Array) -> Array:
    # カードのランクをRANKSに基づいて数値に変換し、降順でソート
    var ranks = []
    for card in cards:
        ranks.append(RANKS[card.rank])
    ranks.sort()  # 昇順でソート
    ranks.reverse()  # 降順にする
    return ranks


# 組み合わせを生成する関数
func get_combinations(cards: Array, length: int) -> Array:
    if length == 0:
        return [[]]
    if cards.size() == 0:
        return []
    var result = []
    for i in range(cards.size()):
        for combination in get_combinations(cards.slice(i + 1, cards.size()), length - 1):
            result.append([cards[i]] + combination)
    return result