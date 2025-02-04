extends Node

var default_config_data = {
	# サウンド設定
	"bgm_volume": 1.0,
	"se_volume": 1.0,
	"voice_volume": 1.0,

	# グラフィック設定
	"resolution": "1280x720",
	"fullscreen": false
}

# ゲーム起動時に実行される処理
func _ready():
	# 設定ファイルが存在するか確認
	if FileAccess.file_exists("user://config.cfg"):
		# 存在する場合は設定を読み込む
		load_config()
	else:
		# 存在しない場合はデフォルト設定でファイルを作成
		save_config(default_config_data)
		load_config()

# 設定の保存
func save_config(config_data: Dictionary):
	var config_path = "user://config.cfg"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	if file:
		file.store_var(config_data)
		file.close()

# 設定の読み込み
func load_config() -> Dictionary:
	var config_path = "user://config.cfg"
	var config_data = {}

	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			config_data = file.get_var()  # 読み込むデータ形式が正しいかも確認
			file.close()
			DisplayServer.window_set_size(Vector2(int(config_data["resolution"].split("x")[0]), int(config_data["resolution"].split("x")[1])))
			if config_data["fullscreen"]:
				DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
	else:
		# デフォルト値を設定
		save_config(default_config_data)  # ファイルがない場合にデフォルト値を保存する
	return config_data
