extends Node2D

var game_process
var table_backend

# 必要な値
var bet_size = { "name": "table_1 bb:2 sb:1", "bb": 2, "sb": 1 }
var buy_in = 100
var dealer_name = "ずんだもん"
var selected_cpus = ["四国めたん", "ずんだもん", "春日部つむぎ", "雨晴はう"]

func _init():
	# game_process = GameProcessBackend.new()
	# add_child(game_process)
	table_backend = TableBackend.new(bet_size, buy_in, dealer_name, selected_cpus)

	print(table_backend)
	print(table_backend.player.participant_name)
	for cpu_player in table_backend.cpu_players:
		print(cpu_player.participant_name)
	print(table_backend.dealer.participant_name)

	# Table.tscn をロードして表示
	var table_scene = preload("res://scenes/gamecomponents/Table.tscn").instantiate()
	add_child(table_scene)

	# TableBackend のデータを Table に渡して連携
	table_scene.setup_with_backend(table_backend)

func _ready():
	pass
