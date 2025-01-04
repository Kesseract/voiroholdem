extends Window

@onready var config_value = Config.load_config()

@onready var option_button = $VBoxContainer/WindowSize/OptionButton

@onready var fullscreen_button = $VBoxContainer/FullScreen/Value/FullScreen
@onready var window_button = $VBoxContainer/FullScreen/Value/Window

func _ready():

	print("Ready function called")
	# Configファイルの読み込み

	# 画面に反映
	$VBoxContainer/BGM/HBoxContainer/Value.text = str(config_value["bgm_volume"] * 100) + "%"
	$VBoxContainer/BGM/HSlider.value = config_value["bgm_volume"]
	$VBoxContainer/SE/HBoxContainer/Value.text = str(config_value["se_volume"] * 100) + "%"
	$VBoxContainer/SE/HSlider.value = config_value["se_volume"]
	$VBoxContainer/VOICE/HBoxContainer/Value.text = str(config_value["voice_volume"] * 100) + "%"
	$VBoxContainer/VOICE/HSlider.value = config_value["voice_volume"]
	# Global の WINDOW_SIZES を OptionButton に追加
	for window_size in Global.WINDOW_SIZES:
		option_button.add_item(window_size)
	option_button.select(select_by_text(option_button, str(config_value["resolution"])))
	if config_value["fullscreen"]:
		fullscreen_button.disabled = true
		window_button.disabled = false
	else:
		fullscreen_button.disabled = false
		window_button.disabled = true

	# 実設定にも反映
	# var volume_db = linear_to_db(config_value["bgm_volume"])  # 線形値をデシベルに変換
	# $Audio_StreamPlayer.volume_db = volume_db
	# var volume_db = linear_to_db(config_value["se_volume"])  # 線形値をデシベルに変換
	# $SE_StreamPlayer.volume_db = se_volume_db
	# var volume_db = linear_to_db(config_value["voice_volume"])  # 線形値をデシベルに変換
	# $VOICE_StreamPlayer.volume_db = volume_db
	DisplayServer.window_set_size(Vector2(int(config_value["resolution"].split("x")[0]), int(config_value["resolution"].split("x")[1])))
	if config_value["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)

	$VBoxContainer/BGM/HSlider.connect("value_changed", Callable(self, "_on_bgm_slider_value_changed"))
	$VBoxContainer/SE/HSlider.connect("value_changed", Callable(self, "_on_se_slider_value_changed"))
	$VBoxContainer/VOICE/HSlider.connect("value_changed", Callable(self, "_on_voice_slider_value_changed"))
	option_button.connect("item_selected", Callable(self, "_on_window_size_option_selected"))
	fullscreen_button.connect("pressed", Callable(self, "_on_fullscreen_button_pressed"))
	window_button.connect("pressed", Callable(self, "_on_window_button_pressed"))

	# Close ボタンのシグナル接続
	$VBoxContainer/Close.connect("pressed", Callable(self, "_on_close_button_pressed"))

	# Windowの×ボタンが押されたときにモーダルを閉じる
	self.connect("close_requested", Callable(self, "_on_close_requested"))

func _on_close_button_pressed():
	# ここでコンフィグ反映
	Config.save_config(config_value)
	hide()

func _on_close_requested():
	# ここでコンフィグ反映
	Config.save_config(config_value)
	queue_free()

# 音量スライダーの値変更時に呼び出される関数
func _on_bgm_slider_value_changed(value):
	# BGM音量の設定を反映
	$VBoxContainer/BGM/HBoxContainer/Value.text = str(value * 100) + "%"
	config_value["bgm_volume"] = value
	# var volume_db = linear_to_db(config_value["bgm_volume"])  # 線形値をデシベルに変換
	# $Audio_StreamPlayer.volume_db = volume_db
	Config.save_config(config_value)

func _on_se_slider_value_changed(value):
	# SE音量の設定を反映
	$VBoxContainer/SE/HBoxContainer/Value.text = str(value * 100) + "%"
	config_value["se_volume"] = value
	# var volume_db = linear_to_db(config_value["se_volume"])  # 線形値をデシベルに変換
	# $SE_StreamPlayer.volume_db = se_volume_db
	Config.save_config(config_value)

func _on_voice_slider_value_changed(value):
	# ボイス音量の設定を反映
	$VBoxContainer/VOICE/HBoxContainer/Value.text = str(value * 100) + "%"
	config_value["voice_volume"] = value
	# var volume_db = linear_to_db(config_value["voice_volume"])  # 線形値をデシベルに変換
	# $VOICE_StreamPlayer.volume_db = volume_db
	Config.save_config(config_value)

func _on_window_size_option_selected(index):
	# 選択されたテキストを取得
	var selected_text = option_button.get_item_text(index)
	DisplayServer.window_set_size(Vector2(int(selected_text.split("x")[0]), int(selected_text.split("x")[1])))
	config_value["resolution"] = selected_text
	Config.save_config(config_value)

func _on_fullscreen_button_pressed():
	fullscreen_button.disabled = true
	window_button.disabled = false
	config_value["fullscreen"] = true
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	Config.save_config(config_value)

func _on_window_button_pressed():
	fullscreen_button.disabled = false
	window_button.disabled = true
	config_value["fullscreen"] = false
	DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	Config.save_config(config_value)

func select_by_text(option: OptionButton, text: String):
	for i in range(option.get_item_count()):
		if option.get_item_text(i) == text: return i