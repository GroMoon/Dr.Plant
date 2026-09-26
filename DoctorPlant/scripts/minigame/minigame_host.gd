extends Control
class_name MinigameHost
## 진찰 미니게임 진행기. 미니게임 한 판을 골라(기본은 무작위) 띄우고, 끝나면 finished 로 결과를 알린다.
##
## 흐름: 등장 → 제목·안내 → "준비…" → 플레이 → "완료!" → 퇴장.
## 에피소드 대본에서는 `$> stage.minigame(튜토리얼)` 로 부른다(episode_player.gd).
## 요구사항: design/requirements/ch1/02-minigame.md

signal finished(result: Dictionary)

## 무작위로 나오는 미니게임 목록. key 는 문자열 접두사(<key>_TITLE / _HINT / _CONTROLS).
const GAMES: Array[Dictionary] = [
	{"id": "stethoscope", "key": "MG_STETHO", "scene": "res://scenes/minigame/stethoscope_tuning.tscn"},
	{"id": "leaf", "key": "MG_LEAF", "scene": "res://scenes/minigame/leaf_wiping.tscn"},
	{"id": "dodge", "key": "MG_DODGE", "scene": "res://scenes/minigame/anxiety_dodge.tscn"},
	{"id": "measure", "key": "MG_MEASURE", "scene": "res://scenes/minigame/define_measuring.tscn"},
	{"id": "pill", "key": "MG_PILL", "scene": "res://scenes/minigame/pill_sorting.tscn"},
]
const FADE_TIME: float = 0.35
const READY_TIME: float = 1.2
const CLEAR_HOLD: float = 1.3
const STATUS_HOLD: float = 1.4

## 첫 진료에서는 미니게임 방식을 설명하는 줄을 함께 보여준다.
@export var tutorial: bool = false
## 할 미니게임 id. 비우면 무작위로 고른다(직전 판과 같은 것은 피한다).
@export var game_id: String = ""

## 직전에 한 미니게임. 같은 미니게임이 연달아 나오지 않게 한다.
static var last_game_id: String = ""

@onready var _title: Label = $Header/Title
@onready var _hint: Label = $Header/Hint
@onready var _controls: Label = $Header/Controls
@onready var _tutorial: Label = $Header/Tutorial
@onready var _progress: Label = $Progress
@onready var _slot: Control = $Slot
@onready var _status: Label = $Status
@onready var _stamp: Label = $Stamp

var _entry: Dictionary = {}
var _game: Minigame = null
var _elapsed: float = 0.0
var _playing: bool = false
var _status_tween: Tween = null


static func pick_game_id(exclude: String = "") -> String:
	var pool: Array[String] = []
	for entry: Dictionary in GAMES:
		if entry["id"] != exclude:
			pool.append(String(entry["id"]))
	if pool.is_empty():
		return String(GAMES[0]["id"])
	return pool.pick_random()


static func find_game(id: String) -> Dictionary:
	for entry: Dictionary in GAMES:
		if entry["id"] == id:
			return entry
	return {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var id: String = game_id if not game_id.is_empty() else pick_game_id(last_game_id)
	_entry = find_game(id)
	if _entry.is_empty():
		push_error("알 수 없는 미니게임: %s" % id)
		_entry = find_game(pick_game_id(last_game_id))
	last_game_id = String(_entry["id"])

	var key: String = String(_entry["key"])
	_title.text = "%s · %s" % [tr("MG_HEADER"), tr(key + "_TITLE")]
	_hint.text = tr(key + "_HINT")
	_controls.text = tr(key + "_CONTROLS")
	_tutorial.text = tr("MG_TUTORIAL")
	_tutorial.visible = tutorial
	_progress.text = ""
	_stamp.text = tr("MG_CLEAR")
	_stamp.hide()
	_status.text = ""

	_game = (load(String(_entry["scene"])) as PackedScene).instantiate() as Minigame
	_game.progress_changed.connect(_on_progress_changed)
	_game.status_shown.connect(_on_status_shown)
	_game.completed.connect(_on_completed)
	_slot.add_child(_game)

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, FADE_TIME)
	_show_status(tr("MG_READY"), Minigame.COLOR_TEXT, READY_TIME)
	await get_tree().create_timer(READY_TIME, false).timeout
	_playing = true
	_game.begin()


func _process(delta: float) -> void:
	if _playing:
		_elapsed += delta


func current_game() -> Minigame:
	return _game


func current_game_id() -> String:
	return String(_entry.get("id", ""))


func _on_progress_changed(text: String) -> void:
	_progress.text = text


func _on_status_shown(text: String, good: bool) -> void:
	_show_status(text, Minigame.COLOR_GOOD if good else Minigame.COLOR_BAD, STATUS_HOLD)


func _show_status(text: String, color: Color, hold: float) -> void:
	if _status_tween != null and _status_tween.is_valid():
		_status_tween.kill()
	_status.text = text
	_status.add_theme_color_override("font_color", color)
	_status.modulate.a = 1.0
	_status_tween = create_tween()
	_status_tween.tween_interval(hold)
	_status_tween.tween_property(_status, "modulate:a", 0.0, 0.3)


func _on_completed() -> void:
	_playing = false
	AudioManager.play_sfx(&"chime")
	_stamp.show()
	_stamp.pivot_offset = _stamp.size * 0.5
	_stamp.scale = Vector2(1.6, 1.6)
	_stamp.modulate.a = 0.0
	var pop := create_tween().set_parallel(true)
	pop.tween_property(_stamp, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(_stamp, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(CLEAR_HOLD, false).timeout
	var out := create_tween()
	out.tween_property(self, "modulate:a", 0.0, FADE_TIME)
	await out.finished
	finished.emit({
		"game": current_game_id(),
		"complete": true,
		"mistakes": _game.mistakes,
		"time": _elapsed,
	})
