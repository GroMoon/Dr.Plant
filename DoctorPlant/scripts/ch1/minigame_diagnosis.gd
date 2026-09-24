extends Control
## 진찰 미니게임 — **임시 구현(스텁)**.
##
## design/requirements/ch1/02-minigame.md 에 "미니게임 1" 제목만 있고
## 규칙이 비어 있어, 스토리가 끊기지 않도록 최소 절차만 만들어 두었다.
## 환자의 빛나는 부위 세 곳을 살피면 진찰이 끝난다.
## 기획이 확정되면 이 씬만 갈아끼우면 된다(episode_player 의 minigame 명령).

signal finished(result: Dictionary)

const SPOTS: Array[Dictionary] = [
	{"id": "head", "label": "MINIGAME_SPOT_HEAD", "note": "MINIGAME_NOTE_HEAD", "at": Vector2(180.0, 55.0)},
	{"id": "leaf", "label": "MINIGAME_SPOT_LEAF", "note": "MINIGAME_NOTE_LEAF", "at": Vector2(-200.0, 135.0)},
	{"id": "root", "label": "MINIGAME_SPOT_ROOT", "note": "MINIGAME_NOTE_ROOT", "at": Vector2(195.0, 215.0)},
]

## 첫 진료에서는 튜토리얼 안내를 함께 보여준다.
@export var tutorial: bool = false
## 진찰 대상 화자 키(현재는 표시용).
@export var patient_key: String = ""

@onready var _title: Label = $Rows/Title
@onready var _notice: Label = $Rows/Notice
@onready var _tutorial: Label = $Rows/Tutorial
@onready var _progress: Label = $Rows/Progress
@onready var _note: Label = $Note
@onready var _spots_root: Control = $Board/Spots

var _buttons: Dictionary = {}
var _examined: Array[String] = []
var _closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_title.text = tr("MINIGAME_TITLE")
	_notice.text = tr("MINIGAME_STUB_NOTICE")
	_tutorial.text = tr("MINIGAME_TUTORIAL")
	_tutorial.visible = tutorial
	_note.text = tr("MINIGAME_HINT")
	_build_spots()
	_update_progress()
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.35)
	if not _buttons.is_empty():
		(_buttons.values()[0] as Button).grab_focus()


func _build_spots() -> void:
	for spot: Dictionary in SPOTS:
		var button := Button.new()
		button.name = "Spot_%s" % spot["id"]
		button.text = tr(String(spot["label"]))
		button.custom_minimum_size = Vector2(120.0, 54.0)
		button.position = spot["at"] as Vector2 - Vector2(60.0, 27.0)
		button.pressed.connect(_on_spot_pressed.bind(spot))
		_spots_root.add_child(button)
		_buttons[String(spot["id"])] = button


func _on_spot_pressed(spot: Dictionary) -> void:
	if _closing:
		return
	AudioManager.play_select()
	var id: String = String(spot["id"])
	_note.text = tr(String(spot["note"]))
	if not _examined.has(id):
		_examined.append(id)
	var button: Button = _buttons[id]
	button.disabled = true
	_update_progress()
	if _examined.size() >= SPOTS.size():
		_finish()
	else:
		_focus_next()


func _focus_next() -> void:
	for button: Button in _buttons.values():
		if not button.disabled:
			button.grab_focus()
			return


func _update_progress() -> void:
	_progress.text = tr("MINIGAME_PROGRESS").format([_examined.size(), SPOTS.size()])


func _finish() -> void:
	_closing = true
	_note.text = tr("MINIGAME_DONE")
	var tween := create_tween()
	tween.tween_interval(1.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	await tween.finished
	finished.emit({"examined": _examined.duplicate(), "complete": true})
