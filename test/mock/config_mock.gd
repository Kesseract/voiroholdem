extends Node
class_name MockFileAccess

var fake_storage = {}
var force_error = false  # 強制的にエラーを発生させるフラグ

func open(path: String, mode: int):
	if force_error:
		return null  # `null` を返してエラーを再現
	if mode == FileAccess.WRITE:
		fake_storage[path] = ""
	return self

func store_var(data):
	if force_error:
		return  # 何もしない（エラーを再現）
	fake_storage["user://config.cfg"] = data

func get_var():
	return fake_storage.get("user://config.cfg", {})

func file_exists(path: String) -> bool:
	if force_error:
		return false  # 強制エラー時は存在しない扱いにする
	return path in fake_storage

func close():
	pass  # モックでは何もしない
