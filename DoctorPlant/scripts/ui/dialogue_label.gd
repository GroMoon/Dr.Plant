class_name DialogueLabel
extends Label
## 설정의 "텍스트 속도 / 텍스트 크기"가 실제로 적용되는 대사 라벨.
## 한 글자씩 출력하고, 진행 입력을 받으면 즉시 전체를 보여준다.

signal line_finished

var _typing: bool = false
var _shown_chars: float = 0.0


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GameSettings.text_size_changed.connect(_apply_font_size)
	_apply_font_size(GameSettings.text_size())
	set_process(false)


func _apply_font_size(font_size: int) -> void:
	add_theme_font_size_override("font_size", font_size)


func show_line(line: String) -> void:
	text = line
	_shown_chars = 0.0
	visible_characters = 0
	if GameSettings.is_text_instant() or line.is_empty():
		_finish()
		return
	_typing = true
	set_process(true)


func is_typing() -> bool:
	return _typing


## 출력 중이면 즉시 완성하고 true, 이미 다 나왔으면 false 를 돌려준다.
func skip() -> bool:
	if not _typing:
		return false
	_finish()
	return true


func _process(delta: float) -> void:
	_shown_chars += delta * GameSettings.text_speed
	visible_characters = int(_shown_chars)
	if visible_characters >= get_total_character_count():
		_finish()


func _finish() -> void:
	_typing = false
	set_process(false)
	visible_characters = -1
	line_finished.emit()
