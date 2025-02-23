extends GutTest

var participant

# モックの `GameProcessBackend`
class DummyGameProcessBackend extends GameProcessBackend:
    func _init(
        _bet_size: Dictionary = {},
        _buy_in: int = 0,
        _dealer_name: String = "",
        _selected_cpus: Array[String] = [],
        _table_place: Dictionary = {},
        _animation_place: Dictionary = {},
        _player_flg: bool = false,
        _seeing: bool = false,
    ):
        pass


func before_each():
    # テスト前に `ParticipantBackend` を初期化
    var game_process_mock = DummyGameProcessBackend.new()
    participant = ParticipantBackend.new(game_process_mock, "TestPlayer", 1000, false, "player", false)


func test_init_properties():
    assert_eq(participant.participant_name, "TestPlayer", "Participant name should be set correctly")
    assert_eq(participant.chips, 1000, "Chips should be set correctly")
    assert_eq(participant.is_cpu, false, "is_cpu should be set correctly")
    assert_eq(participant.role, "player", "Role should be set correctly")
    assert_eq(participant.seeing, false, "Seeing should be set correctly")


func test_init_front_created_when_seeing():
    var game_process_mock = DummyGameProcessBackend.new()
    var participant_with_front = ParticipantBackend.new(game_process_mock, "TestPlayer", 1000, false, "player", true)
    assert_not_null(participant_with_front.front, "Front should be created when seeing is true")


func test_ready_creates_correct_scripts():

    assert_not_null(participant.player_script, "Player script should be created for role 'player'")
    assert_null(participant.dealer_script, "Dealer script should not be created for role 'player'")

    var game_process_mock = DummyGameProcessBackend.new()
    var dealer_participant = ParticipantBackend.new(game_process_mock, "Dealer", 0, true, "dealer", false)

    assert_not_null(dealer_participant.dealer_script, "Dealer script should be created for role 'dealer'")
    assert_null(dealer_participant.player_script, "Player script should not be created for role 'dealer'")


func test_to_str_output():
    var expected_output = "=== ParticipantBackend 状態 ===\n"
    expected_output += "参加者名: TestPlayer\n"
    expected_output += "チップ数: 1000\n"
    expected_output += "CPUか: false\n"
    expected_output += "ロール: player\n"
    expected_output += "=======================\n"

    assert_eq(participant.to_str(), expected_output, "to_str() output should match expected format")
