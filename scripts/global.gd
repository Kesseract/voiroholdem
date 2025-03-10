extends Node

# グローバル変数の宣言
var slot = 0
var player_name = ""
var chips = 0

var bet_size = ""
var buy_in = 0
var dealer = ""
var selected_characters = []

# トーナメントの種類
const TOURNAMENTS = [
	{"name": "Beginner Tournament", "prize": 1000, "max_players": 10, "buyin": 100},
	{"name": "Pro Tournament", "prize": 5000, "max_players": 20, "buyin": 250},
	{"name": "Master Tournament", "prize": 10000, "max_players": 20, "buyin": 500},
]

# テーブルのベットサイズ
const BET_SIZES = [
	{"name": "table_1 bb:2 sb:1", "bb": 2, "sb": 1},
	{"name": "table_2 bb:10 sb:5", "bb": 10, "sb": 5},
	{"name": "table_3 bb:20 sb:10", "bb": 20, "sb": 10},
	{"name": "table_4 bb:100 sb:50", "bb": 100, "sb": 50},
]

# 登場キャラクター
const CHARACTERS = {
	"VOICEVOX":[
		"ずんだもん",
		"四国めたん",
		"春日部つむぎ",
		"雨晴はう",
		"波音リツ",
		"玄野武宏",
		"白上虎太郎",
		"青山龍星",
		"冥鳴ひまり",
		"九州そら",
		"もち子さん",
		"剣崎雌雄",
		"WhiteCUL",
		"後鬼",
		"No.7",
		"ちび式じい",
		"櫻歌ミコ",
		"小夜/SAYO",
		"ナースロボ_タイプT",
		"†聖騎士 紅桜†",
		"雀松朱司",
		"麒ヶ島宗麟",
		"春歌ナナ",
		"猫使アル",
		"猫使ビィ",
		"中国うさぎ",
		"栗田まろん",
		"あいえるたん",
		"満別花丸",
		"琴詠ニア",
	]
}

# キャラクターのテクスチャファイルパス
const PATH = "res://assets/textures/Characters/"

const CHARACTER_TEXTURE_PATHS = {
	"player": {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"ずんだもん": {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"四国めたん": {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"春日部つむぎ": {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"雨晴はう": {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"波音リツ" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"玄野武宏" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"白上虎太郎" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"青山龍星" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"冥鳴ひまり" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"九州そら" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"もち子さん" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"剣崎雌雄" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"WhiteCUL" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"後鬼" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"No.7" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"ちび式じい" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"櫻歌ミコ" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"小夜/SAYO" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"ナースロボ_タイプT" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"†聖騎士 紅桜†" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"雀松朱司" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"麒ヶ島宗麟" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"春歌ナナ" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"猫使アル" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"猫使ビィ" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"中国うさぎ" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"栗田まろん" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"あいえるたん" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"満別花丸" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
	"琴詠ニア" : {
		"left": PATH + "test/left.png",
		"right": PATH + "test/right.png"
	},
}

# 座席ごとの方向情報
const SEAT_DIRECTIONS = {
	"Seat1": "right",
	"Seat2": "right",
	"Seat3": "right",
	"Seat4": "right",
	"Seat5": "right",
	"Seat6": "left",
	"Seat7": "left",
	"Seat8": "left",
	"Seat9": "left",
	"Seat10": "left"
}


# 設定値
const WINDOW_SIZES = [
	"640x360",
	"800x600",
	"1024x576",
	"1280x720"
]

func _ready():
	# ここでJSONファイルを読み込むようにすると、ユーザーが任意で値を切り替えられるようになる
	pass  # 必要に応じて初期化処理を追加

# delay: 指定した秒数だけ待機する
func delay(seconds: float):
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	get_tree().root.add_child(timer)  # Timerをツリーに追加
	timer.start()
	timer.queue_free()  # Timerを解放

# pause: 一時停止して入力で再開する
func pause():
	get_tree().paused = true  # 一時停止