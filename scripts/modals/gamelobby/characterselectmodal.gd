extends Window

signal characters_selected(selected_characters)

var selected_characters = []  # 親から渡された選択済みキャラクター
var max_participants = 9
var selected_count = 0


func _ready():
    # クローズボタンにシグナルを接続
    $Close.connect("pressed", Callable(self, "_on_close_button_pressed"))
    self.connect("close_requested", Callable(self, "_on_close_requested"))

# モーダルを表示するメソッド
func open_modal():
    populate_character_checkboxes()  # モーダルを開くたびにチェックボックスをリセット・更新
    popup_centered()  # モーダルを中央に表示

# キャラクター選択モーダルが開いたときに選択済みキャラクターを設定する
func set_selected_characters(selected_list):
    selected_characters = selected_list

# チェックボックスを作成してGridContainerに追加
func populate_character_checkboxes():
    var characters_container = $VBoxContainer/ScrollContainer/VBoxContainer

    # 既存の子ノード（前回のチェックボックス）を全て削除
    for child in characters_container.get_children():
        characters_container.remove_child(child)
        child.queue_free()  # メモリからも解放

    # 新たにチェックボックスを追加
    for category in Global.CHARACTERS:
        # カテゴリラベルの追加
        var category_label = Label.new()
        category_label.text = category
        characters_container.add_child(category_label)

        # 区切り線の追加
        var separator = HSeparator.new()
        characters_container.add_child(separator)

        # キャラクター用の GridContainer を作成
        var grid_container = GridContainer.new()
        grid_container.columns = 8  # キャラクターを一行に4つ並べる

        # 各キャラクターのチェックボックスを追加
        for character in Global.CHARACTERS[category]:
            var check_box = CheckBox.new()
            check_box.text = character
            grid_container.add_child(check_box)

            # もしキャラクターが既に選択されている場合はチェックをつける
            if character in selected_characters:
                check_box.set_pressed(true)  # チェックをONにする

            # シグナル接続でキャラクターの選択状態を管理
            check_box.connect("toggled", Callable(self, "_on_character_toggled").bind(character))

        # キャラクター用の GridContainer を追加
        characters_container.add_child(grid_container)


# チェックボックスのトグルに応じてキャラクターを管理
func _on_character_toggled(button_pressed: bool, character: String):
    if button_pressed:
        if character not in selected_characters:
            selected_characters.append(character)
            selected_count += 1
    else:
        if character in selected_characters:
            selected_characters.erase(character)
            selected_count -= 1

    # 9人選択されたら全てのチェックが入っていないチェックボックスを無効化
    var characters_container = $VBoxContainer/ScrollContainer/VBoxContainer
    if selected_count >= max_participants:
        _disable_unselected_checkboxes_recursive(characters_container, true)
    else:
        _disable_unselected_checkboxes_recursive(characters_container, false)

# 再帰的にノードを探索してチェックボックスを無効化する
func _disable_unselected_checkboxes_recursive(node: Node, disable: bool):
    for child in node.get_children():
        # 子ノードにさらに子がある場合は再帰的に探す
        if child.get_child_count() > 0:
            _disable_unselected_checkboxes_recursive(child, disable)
        # CheckBoxを見つけたら無効化処理
        if child is CheckBox:
            if not child.is_pressed():
                child.disabled = disable

# クローズボタンが押されたときに選択結果を通知して閉じる
func _on_close_button_pressed():
    print(selected_characters)
    emit_signal("characters_selected", selected_characters)  # 選択結果をシグナルで通知
    queue_free()

func _on_close_requested():
    emit_signal("characters_selected", selected_characters)  # ウィンドウを閉じた場合も通知
    queue_free()
