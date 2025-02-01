extends TextureButton

signal seat_clicked(seat_node)  # 席の親ノードを通知

var seat_node = null  # 席の親ノードを保持

func _ready():
	connect("pressed", Callable(self, "_on_pressed"))

func setup(parent_node):
	seat_node = parent_node

func _on_pressed():
	if seat_node:
		seat_clicked.emit(seat_node)  # 席の親ノードを通知