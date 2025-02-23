extends GutTest


var hand_evaluator
var test_params


func before_each():
    # 各テストの前に実行される関数
    pass


func after_each():
    # 各テストの後に実行される関数
    pass


func before_all():
    # 一番最初に実行される関数
    hand_evaluator = HandEvaluatorBackend.new()

    # 固定テスト
    test_params = {
        "evaluate_hand": [
            [
                ["A", "Spades"], ["10", "Spades"], ["J", "Spades"], ["Q", "Spades"], ["K", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.ROYAL_FLUSH,
                    "rank": [14, 13, 12, 11, 10]
                }
            ],
            [
                ["A", "Spades"], ["2", "Spades"], ["3", "Spades"], ["4", "Spades"], ["5", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [14, 5, 4, 3, 2]
                }
            ],
            [
                ["10", "Spades"], ["9", "Spades"], ["8", "Spades"], ["6", "Spades"], ["7", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [10, 9, 8, 7, 6]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["10", "Clubs"], ["10", "Hearts"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["A", "Diamonds"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [10, 14]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["9", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["9", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [10, 14]
                }
            ],
            [
                ["5", "Spades"], ["4", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"], ["3", "Spades"], ["2", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FLUSH,
                    "rank": [13, 12, 8, 5, 4]
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [5]
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [14]
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [10]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.THREE_OF_A_KIND,
                    "rank": [2, 14, 9]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.TWO_PAIR,
                    "rank": [7, 2, 14]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ONE_PAIR,
                    "rank": [2, 14, 10, 9]
                }
            ],
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["4", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [14, 11, 10, 8, 7]
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"], ["7", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [13, 12, 9, 8, 7]
                }
            ],
        ],
        "best_hand_from_seven": [
            [
                ["A", "Spades"], ["10", "Spades"], ["J", "Spades"], ["Q", "Spades"], ["K", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.ROYAL_FLUSH,
                    "rank": [14, 13, 12, 11, 10]
                }
            ],
            [
                ["A", "Spades"], ["2", "Spades"], ["3", "Spades"], ["4", "Spades"], ["5", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [14, 5, 4, 3, 2]
                }
            ],
            [
                ["10", "Spades"], ["9", "Spades"], ["8", "Spades"], ["6", "Spades"], ["7", "Spades"], ["A", "Hearts"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [10, 9, 8, 7, 6]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["10", "Clubs"], ["10", "Hearts"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["A", "Diamonds"], ["A", "Clubs"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [10, 14]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["9", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"], ["9", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [10, 14]
                }
            ],
            [
                ["5", "Spades"], ["4", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"], ["3", "Spades"], ["2", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FLUSH,
                    "rank": [13, 12, 8, 5, 4]
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [5]
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [14]
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [10]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.THREE_OF_A_KIND,
                    "rank": [2, 14, 9]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["7", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.TWO_PAIR,
                    "rank": [7, 2, 14]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ONE_PAIR,
                    "rank": [2, 14, 10, 9]
                }
            ],
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"], ["8", "Hearts"], ["4", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [14, 11, 10, 8, 7]
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"], ["7", "Hearts"], ["9", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [13, 12, 9, 8, 7]
                }
            ],
        ],
        "evaluate_five": [
            [
                ["A", "Spades"], ["10", "Spades"], ["J", "Spades"], ["Q", "Spades"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ROYAL_FLUSH,
                    "rank": [14, 13, 12, 11, 10]
                }
            ],
            [
                ["A", "Spades"], ["2", "Spades"], ["3", "Spades"], ["4", "Spades"], ["5", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [14, 5, 4, 3, 2]
                }
            ],
            [
                ["10", "Spades"], ["9", "Spades"], ["8", "Spades"], ["6", "Spades"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [10, 9, 8, 7, 6]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [10, 14]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [10, 14]
                }
            ],
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FLUSH,
                    "rank": [13, 12, 8, 5, 3]
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [5]
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [14]
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [10]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.THREE_OF_A_KIND,
                    "rank": [2, 14, 7]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.TWO_PAIR,
                    "rank": [7, 2, 14]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ONE_PAIR,
                    "rank": [2, 14, 10, 7]
                }
            ],
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [14, 11, 10, 7, 2]
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [13, 12, 8, 5, 3]
                }
            ],
        ],
        "is_royal_flush": [
            [
                ["A", "Spades"], ["10", "Spades"], ["J", "Spades"], ["Q", "Spades"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ROYAL_FLUSH,
                    "rank": [14, 13, 12, 11, 10]
                }
            ],
            [
                ["A", "Spades"], ["2", "Spades"], ["3", "Spades"], ["4", "Spades"], ["5", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [14, 5, 4, 3, 2]
                }
            ],
            [
                ["10", "Spades"], ["9", "Spades"], ["8", "Spades"], ["6", "Spades"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [10, 9, 8, 7, 6]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_straight_flush": [
            [
                ["A", "Spades"], ["2", "Spades"], ["3", "Spades"], ["4", "Spades"], ["5", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [14, 5, 4, 3, 2]
                }
            ],
            [
                ["10", "Spades"], ["9", "Spades"], ["8", "Spades"], ["6", "Spades"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT_FLUSH,
                    "rank": [10, 9, 8, 7, 6]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_four_of_a_kind": [
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["10", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FOUR_OF_A_KIND,
                    "rank": [10, 14]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_full_house": [
            [
                ["A", "Spades"], ["A", "Diamonds"], ["A", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [14, 10]
                }
            ],
            [
                ["A", "Spades"], ["A", "Diamonds"], ["10", "Clubs"], ["10", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FULL_HOUSE,
                    "rank": [10, 14]
                }
            ],
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_flush": [
            [
                ["5", "Spades"], ["3", "Spades"], ["Q", "Spades"], ["8", "Spades"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.FLUSH,
                    "rank": [13, 12, 8, 5, 3]
                }
            ],
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_straight": [
            [
                ["A", "Spades"], ["2", "Diamonds"], ["3", "Clubs"], ["4", "Hearts"], ["5", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [5]
                }
            ],
            [
                ["A", "Spades"], ["K", "Diamonds"], ["Q", "Clubs"], ["J", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [14]
                }
            ],
            [
                ["10", "Spades"], ["9", "Diamonds"], ["8", "Clubs"], ["6", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.STRAIGHT,
                    "rank": [10]
                }
            ],
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_three_of_a_kind": [
            [
                ["2", "Spades"], ["2", "Diamonds"], ["2", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.THREE_OF_A_KIND,
                    "rank": [2, 14, 7]
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["Q", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_two_pair": [
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["7", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.TWO_PAIR,
                    "rank": [7, 2, 14]
                }
            ],
            [
                ["5", "Spades"], ["5", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_one_pair": [
            [
                ["2", "Spades"], ["2", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.ONE_PAIR,
                    "rank": [2, 14, 10, 7]
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": null,
                    "rank": null
                }
            ],
        ],
        "is_high_card": [
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [14, 11, 10, 7, 2]
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "category": hand_evaluator.HandCategory.HIGH_CARD,
                    "rank": [13, 12, 8, 5, 3]
                }
            ],
        ],
        "get_rank_counts": [
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                {
                    "2": 1,
                    "J": 1,
                    "7": 1,
                    "A": 1,
                    "10": 1,
                }
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                {
                    "5": 1,
                    "3": 1,
                    "Q": 1,
                    "8": 1,
                    "K": 1,
                }
            ],
            [
                ["2", "Spades"], ["5", ""], ["3", "Diamonds"], ["5", "Hearts"], ["2", "Clubs"],
                {
                    "2": 2,
                    "5": 2,
                    "3": 1,
                }
            ],
        ],
        "sorted_ranks": [
            [
                ["2", "Spades"], ["J", "Diamonds"], ["7", "Clubs"], ["A", "Hearts"], ["10", "Spades"],
                [14, 11, 10, 7, 2]  # (A, J, 10, 7, 2)
            ],
            [
                ["5", "Spades"], ["3", "Clubs"], ["Q", "Diamonds"], ["8", "Hearts"], ["K", "Spades"],
                [13, 12, 8, 5, 3]  # (K, Q, 8, 5, 3)
            ],
            [
                ["2", "Spades"], ["5", ""], ["3", "Diamonds"], ["5", "Hearts"], ["2", "Clubs"],
                [5, 5, 3, 2, 2]  # (5, 5, 3, 2, 2)
            ],
        ]
    }

    # **動的に追加する**
    for i in range(3):

        # sorted_ranks
        var append_list = []
        for j in range(5):
            var card = generate_random_card()
            append_list.append(card)
        append_list.append(get_expected_sorted_ranks(append_list))
        test_params["sorted_ranks"].append(append_list)


# **ランクの変換**
func get_expected_sorted_ranks(cards: Array) -> Array:
    var sorted_ranks = []
    for card in cards:
        sorted_ranks.append(Global.RANKS[card[0]])  # ランクを数値に変換
    sorted_ranks.sort()
    sorted_ranks.reverse()
    return sorted_ranks


var rank_list = HandEvaluatorBackend.RANKS.keys()


# **ランダムなカードリストを生成する関数**
func generate_random_card() -> Array:
    var selected_ranks = rank_list.duplicate()
    selected_ranks.shuffle()
    var rank = selected_ranks[0]
    return [rank, "Spades"]


func after_all():
    # 一番最後に実行される関数
    pass


func test_evaluate_hand(params=use_parameters(test_params["evaluate_hand"])):
    # `CardBackend` をテスト関数内で生成
    var player_hand: Array[CardBackend] = []
    var community_cards: Array[CardBackend] = []

    for card_data in params.slice(0, 2):  # 先頭7つの要素をカードとして生成
        player_hand.append(CardBackend.new(card_data[0], card_data[1], false))

    for card_data in params.slice(2, 7):
        community_cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[7]  # 8番目の要素（期待する結果）

    var result = hand_evaluator.evaluate_hand(player_hand, community_cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_best_hand_from_seven(params=use_parameters(test_params["best_hand_from_seven"])):
    # `CardBackend` をテスト関数内で生成
    var cards: Array[CardBackend] = []
    for card_data in params.slice(0, 7):  # 先頭7つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[7]  # 8番目の要素（期待する結果）

    var result = hand_evaluator.best_hand_from_seven(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_get_combinations():
    # 🎯 1. `length = 0` の場合、 `[[]]` が返る
    var cards: Array[CardBackend] = [
        CardBackend.new("A", "Spades", false),
        CardBackend.new("K", "Spades", false),
        CardBackend.new("Q", "Spades", false),
    ]
    var result = hand_evaluator.get_combinations(cards, 0)
    assert_eq(result, [[]], "Expected [[]] for length 0")

    # 🎯 2. `cards` が空の配列で `length > 0` の場合、 `[]` が返る
    var empty_list: Array[CardBackend] = []
    result = hand_evaluator.get_combinations(empty_list, 2)
    assert_eq(result, [], "Expected [] for empty input and length > 0")

    # 🎯 3. `length = 1` の場合、各カード単体のリストが生成される
    result = hand_evaluator.get_combinations(cards, 1)
    var expected = [
        [cards[0]],
        [cards[1]],
        [cards[2]],
    ]
    assert_eq(result, expected, "Each card should be in its own list for length 1")

    # 🎯 4. `length = 2` の場合、ペアの組み合わせが正しく生成される
    result = hand_evaluator.get_combinations(cards, 2)
    expected = [
        [cards[0], cards[1]],
        [cards[0], cards[2]],
        [cards[1], cards[2]],
    ]
    assert_eq(result, expected, "Expected correct pairs for length 2")

    # 🎯 5. `length = 3` の場合、3枚の組み合わせが正しく生成される
    result = hand_evaluator.get_combinations(cards, 3)
    expected = [
        [cards[0], cards[1], cards[2]],
    ]
    assert_eq(result, expected, "Expected full set for length 3")

    # 🎯 6. `length > cards.size()` の場合、空の配列が返る
    result = hand_evaluator.get_combinations(cards, 4)
    assert_eq(result, [], "Expected [] when length > number of cards")

    # 🎯 7. `length == cards.size()` の場合、元の配列全体が1つの組み合わせとして返る
    result = hand_evaluator.get_combinations(cards, 3)
    expected = [
        [cards[0], cards[1], cards[2]],
    ]
    assert_eq(result, expected, "Expected entire set when length == number of cards")

    # 🎯 8. 順序が保持されているか
    var cards_ordered: Array[CardBackend] = [
        CardBackend.new("2", "Spades", false),
        CardBackend.new("3", "Spades", false),
        CardBackend.new("4", "Spades", false),
    ]
    result = hand_evaluator.get_combinations(cards_ordered, 2)
    expected = [
        [cards_ordered[0], cards_ordered[1]],
        [cards_ordered[0], cards_ordered[2]],
        [cards_ordered[1], cards_ordered[2]],
    ]
    assert_eq(result, expected, "Expected order-preserved combinations")


func test_evaluate_five(params=use_parameters(test_params["evaluate_five"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.evaluate_five(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_royal_flush(params=use_parameters(test_params["is_royal_flush"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_royal_flush(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_straight_flush(params=use_parameters(test_params["is_straight_flush"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_straight_flush(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_four_of_a_kind(params=use_parameters(test_params["is_four_of_a_kind"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_four_of_a_kind(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_full_house(params=use_parameters(test_params["is_full_house"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_full_house(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_flush(params=use_parameters(test_params["is_flush"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_flush(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_straight(params=use_parameters(test_params["is_straight"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_straight(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_three_of_a_kind(params=use_parameters(test_params["is_three_of_a_kind"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_three_of_a_kind(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_two_pair(params=use_parameters(test_params["is_two_pair"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_two_pair(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")



func test_is_one_pair(params=use_parameters(test_params["is_one_pair"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素をカードとして生成
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_result = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_one_pair(cards)

    # 判定が成功している場合
    if result["category"] != null and result["rank"] != null:
        assert_eq(result["category"], expected_result["category"], "One Pair: Category mismatch")
        assert_eq(result["rank"], expected_result["rank"], "One Pair: Rank mismatch")
    else:
        # 判定が失敗する（ワンペアではない）場合
        assert_null(result["category"], "One Pair: Category should be null")
        assert_null(result["rank"], "One Pair: Rank should be null")


func test_is_high_card(params=use_parameters(test_params["is_high_card"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素を使う
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_results = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.is_high_card(cards)

    # ハイカードの判定ができているか確認
    assert_eq(result["category"], expected_results["category"], "result category")
    assert_eq(result["rank"], expected_results["rank"], "result ranks")


func test_get_rank_counts(params=use_parameters(test_params["get_rank_counts"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素を使う
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_results = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.get_rank_counts(cards)

    # ソート結果の要素数を確認
    assert_eq(result.size(), expected_results.size(), "get_rank_counts should return exactly " + str(expected_results.size()) + " elements")

    # ランクが正しくカウントできているか確認
    assert_eq(result, expected_results, "get_rank_counts should return")


func test_sorted_ranks(params=use_parameters(test_params["sorted_ranks"])):
    # `CardBackend` をテスト関数内で生成
    var cards = []
    for card_data in params.slice(0, 5):  # 先頭5つの要素を使う
        cards.append(CardBackend.new(card_data[0], card_data[1], false))

    var expected_results = params[5]  # 6番目の要素（期待する結果）

    var result = hand_evaluator.sorted_ranks(cards)

    # ソート結果の要素数を確認
    assert_eq(result.size(), expected_results.size(), "sorted_ranks should return exactly " + str(expected_results.size()) + " elements")

    # 降順になっているか確認
    for i in range(result.size()):
        assert_eq(result[i], expected_results[i], "Mismatch at index " + str(i))

    # 降順になっているか確認
    for i in range(result.size() - 1):
        assert_true(result[i] >= result[i+1], "Rank at index %d (%d) should be >= rank at index %d (%d)" % [i, result[i], i+1, result[i+1]])