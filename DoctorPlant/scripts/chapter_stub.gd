extends Control
## 챕터 1 임시 씬.
## 챕터 본편(design/requirements/ch1)이 비어 있어 내용 대신
## 입력·텍스트 속도/크기·일시정지가 실제로 동작하는지 확인할 수 있는 자리만 잡아둔다.

const LINE_KEYS: Array[String] = ["STUB_LINE_1", "STUB_LINE_2", "STUB_LINE_3"]

@onready var _dialogue: TypingLabel = $DialogueBox/Dialogue
@onready var _progress_hint: Label = $ProgressHint
@onready var _pause_menu: CanvasLayer = $PauseMenu

var _index: int = 0
var _playtime: float = 0.0


func _ready() -> void:
	GameSettings.settings_changed.connect(_on_settings_changed)
	_show_line(0)


func _process(delta: float) -> void:
	_playtime += delta


func _unhandled_input(event: InputEvent) -> void:
	if _pause_menu.is_open() or SceneRouter.is_busy():
		return
	if not event.is_action_pressed("advance"):
		return
	get_viewport().set_input_as_handled()
	if _dialogue.skip():
		return
	_advance()


func _advance() -> void:
	AudioManager.play_move()
	if _index + 1 >= LINE_KEYS.size():
		_return_to_title()
		return
	_show_line(_index + 1)


func _show_line(index: int) -> void:
	_index = index
	_dialogue.show_line(tr(LINE_KEYS[_index]))
	_progress_hint.text = "%d / %d" % [_index + 1, LINE_KEYS.size()]


func _on_settings_changed() -> void:
	# 언어를 바꾸면 현재 대사도 새 언어로 다시 출력한다.
	_dialogue.show_line(tr(LINE_KEYS[_index]))


func _return_to_title() -> void:
	_save_progress()
	AudioManager.play_bgm_title()
	SceneRouter.change_scene("res://scenes/title_screen.tscn")


func _save_progress() -> void:
	var slot: int = SaveSystem.current_slot
	if slot < 0:
		return
	var data: Dictionary = SaveSystem.get_slot_data(slot).duplicate()
	data["chapter"] = 1
	data["scene"] = "res://scenes/chapter_stub.tscn"
	data["playtime"] = float(data.get("playtime", 0.0)) + _playtime
	SaveSystem.write_slot(slot, data)
