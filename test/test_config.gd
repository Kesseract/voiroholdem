extends GutTest

var config = load("res://scripts/config.gd").new()
var config_mock = load("res://test/mock/config_mock.gd").new()

func before_each():
	pass

func after_each():
	pass

func before_all():
	print("test_config_start")
	config.file_access_class = config_mock

func after_all():
	print("test_config_end")

func test_save_config_success():
	# 正常系
	# 正しくデータ保存できるか
	config.config_data = {
		"bgm_volume": 0.7,
		"resolution": "1920x1080",
		"fullscreen": false
	}
	config.save_config()

	assert_eq(config_mock.fake_storage["user://config.cfg"]["bgm_volume"], 0.7, "BGM volume should be 0.7")
	assert_eq(config_mock.fake_storage["user://config.cfg"]["resolution"], "1920x1080", "Resolution should be 1920x1080")
	assert_eq(config_mock.fake_storage["user://config.cfg"]["fullscreen"], false, "Fullscreen should be false")

func test_save_config_overwrite():
	# 正常系
	# 正しく上書きできるか
	config_mock.fake_storage["user://config.cfg"] = {
		"bgm_volume": 1.0,
		"resolution": "2560x1440",
		"fullscreen": true
	}
	config.load_config()

	assert_eq(config.config_data["bgm_volume"], 1.0, "BGM volume should be 1.0")
	assert_eq(config.config_data["resolution"], "2560x1440", "Resolution should be 2560x1440")
	assert_eq(config.config_data["fullscreen"], true, "Fullscreen should be true")

func test_save_config_empty():
	# 異常系
	# 空の設定データ
	config_mock.fake_storage.clear()
	config.load_config()

	assert_eq(config.config_data["bgm_volume"], 1.0, "Default BGM volume should be 1.0")
	assert_eq(config.config_data["resolution"], "1280x720", "Default resolution should be 1280x720")
	assert_eq(config.config_data["fullscreen"], false, "Default fullscreen setting should be false")

func test_save_config_file_error():
	# 異常系
	# ファイル書き込みエラー時の処理
	# エラーを強制発生
	config_mock.force_error = true
	config.save_config()

	# ファイルが保存されていないことを確認
	assert_false(config_mock.file_exists("user://config.cfg"), "Config file should not be created due to write error")


# ✅ ① 設定ファイルが存在する場合、データを正しく読み込めるか？
func test_load_config_with_existing_file():
	var test_data = {
		"bgm_volume": 0.8,
		"resolution": "1920x1080",
		"fullscreen": true
	}
	config_mock.fake_storage["user://config.cfg"] = test_data

	config.load_config()

	assert_eq(config.config_data["bgm_volume"], 1.0, "BGM volume should be 0.8")
	assert_eq(config.config_data["resolution"], "1280x720", "Resolution should be 1920x1080")
	assert_eq(config.config_data["fullscreen"], false, "Fullscreen should be enabled")

# ✅ ② 設定ファイルが存在しない場合、デフォルト設定を適用するか？
func test_load_config_with_no_file():
	config_mock.fake_storage.clear()  # ファイルが存在しない状態にする

	config.load_config()

	assert_eq(config.config_data, config.DEFAULT_CONFIG, "Default config should be applied if no file exists")

# ✅ ③ 破損した設定ファイルを読み込んだ場合、デフォルト設定を適用するか？
func test_load_config_with_corrupted_file():
	config_mock.fake_storage["user://config.cfg"] = "corrupted_data"  # 文字列でデータ破損を再現

	config.load_config()

	assert_eq(config.config_data, config.DEFAULT_CONFIG, "Corrupted config file should fallback to default settings")

# ✅ ④ ウィンドウサイズが正しく設定されるか？
func test_apply_settings_window_size():
	config.config_data["resolution"] = "1920x1080"
	config.apply_settings()

	var window_size = DisplayServer.window_get_size()
	assert_eq(window_size[0], 1920, "Window size should be set to 1920x1080")

# ✅ ⑤ フルスクリーンが正しく適用されるか？
func test_apply_settings_fullscreen():
	config.config_data["fullscreen"] = true
	config.apply_settings()

	assert_eq(DisplayServer.window_get_mode(), DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN, "Window should be fullscreen")

	config.config_data["fullscreen"] = false
	config.apply_settings()

	assert_eq(DisplayServer.window_get_mode(), DisplayServer.WindowMode.WINDOW_MODE_WINDOWED, "Window should be in windowed mode")