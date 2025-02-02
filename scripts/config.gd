extends Node

var config_data = {}

# デフォルト設定
const DEFAULT_CONFIG = {
	"bgm_volume": 1.0,
	"se_volume": 1.0,
	"voice_volume": 1.0,
	"resolution": "1280x720",
	"fullscreen": false
}

const CONFIG_PATH = "user://config.cfg"

# `FileAccess` をラップして、モック可能に
var file_access_class = FileAccess  # ここにモックを注入可能

func _ready():
	load_config()

# 📌 設定を保存
func save_config():
	var file = file_access_class.open(CONFIG_PATH, FileAccess.WRITE)
	if file:
		file.store_var(config_data)
		file.close()

# 📌 設定を読み込む
func load_config():
	if file_access_class.file_exists(CONFIG_PATH):
		var file = file_access_class.open(CONFIG_PATH, FileAccess.READ)
		if file:
			config_data = file.get_var()
			file.close()
	else:
		# ファイルがない場合はデフォルト値を適用
		config_data = DEFAULT_CONFIG.duplicate(true)
		save_config()

	apply_settings()

# 📌 画面設定を適用
func apply_settings():
	var res = config_data["resolution"].split("x")
	DisplayServer.window_set_size(Vector2(int(res[0]), int(res[1])))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if config_data["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
