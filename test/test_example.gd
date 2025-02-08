extends GutTest

func before_each():
    # 各テストの前に実行される関数
    print("before_each")
    gut.p("ran setup", 2)

func after_each():
    # 各テストの後に実行される関数
    print("after_each")
    gut.p("ran teardown", 2)

func before_all():
    # 一番最初に実行される関数
    print("before_all")
    gut.p("ran run setup", 2)

func after_all():
    # 一番最後に実行される関数
    print("after_all")
    gut.p("ran run teardown", 2)

func test_assert_eq_number_equal():
    print("test_assert_eq_number_equal")
    assert_eq('asdf', 'asdf', "Should pass")

func test_assert_true_with_true():
    print("test_assert_true_with_true")
    assert_true(true, "Should pass, true is true")