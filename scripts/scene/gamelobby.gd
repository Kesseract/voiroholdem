extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
    $TournamentButton.connect("pressed", Callable(self, "_on_tournament_button_pressed"))
    $CounterButton.connect("pressed", Callable(self, "_on_counter_button_pressed"))
    $RingGameTable.connect("pressed", Callable(self, "_on_ringgame_table_pressed"))
    $VSTable.connect("pressed", Callable(self, "_on_vs_table_pressed"))

    $PlayerName.text = "プレイヤー名：" + str(Global.player_name)
    $Chips.text = "チップ数：" + str(Global.chips)

func _on_tournament_button_pressed():
    print("Tournament button pressed")
    var name_modal = preload("res://scenes/modals/gamelobby/TournamentModal.tscn").instantiate()
    add_child(name_modal)
    name_modal.set_exclusive(true)
    name_modal.popup_centered()

func _on_counter_button_pressed():
    print("Counter button pressed")
    # var name_modal = preload("res://scenes/modals/gamelobby/TutorialModal.tscn").instantiate()
    # add_child(name_modal)
    # name_modal.set_exclusive(true)
    # name_modal.popup_centered()

func _on_ringgame_table_pressed():
    print("RingGame table pressed")
    var name_modal = preload("res://scenes/modals/gamelobby/RingGameModal.tscn").instantiate()
    add_child(name_modal)
    name_modal.set_exclusive(true)
    name_modal.popup_centered()

func _on_vs_table_pressed():
    print("VS table pressed")
    var name_modal = preload("res://scenes/modals/gamelobby/VSModal.tscn").instantiate()
    add_child(name_modal)
    name_modal.set_exclusive(true)
    name_modal.popup_centered()

func _on_config_button_pressed():
    print("Config Button pressed")
    var name_modal = preload("res://scenes/modals/config/ConfigModal.tscn").instantiate()
    add_child(name_modal)
    name_modal.set_exclusive(true)
    name_modal.popup_centered()

func _on_save_button_pressed():
    print("Save Button pressed")
    var name_modal = preload("res://scenes/modals/save/SaveModal.tscn").instantiate()
    add_child(name_modal)
    name_modal.set_exclusive(true)
    name_modal.popup_centered()
