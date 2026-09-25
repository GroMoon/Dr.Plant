class_name TypingLabel
extends Label
## 설정의 "텍스트 속도 / 텍스트 크기"가 실제로 적용되는 대사 라벨.
## 한 글자씩 출력하고, 진행 입력을 받으면 즉시 전체를 보여준다.

signal line_finished

## 글자가 찍힐 때 "토도도" 타이핑음을 낼지.
@export var typing_sound: bool = true
## 타이핑음 높이(1.0 = 기본). 말풍선에서 인물마다 목소리를 다르게 줄 때 쓴다.
@export var voice_pitch: float = 1.0
@export var voice_volume_db: float = -4.0
## 설정의 텍스트 크기를 따를지. 말풍선처럼 크기가 정해진 곳은 끈다.
@export var follow_text_size: bool = true

var _typing: bool = false
var _shown_chars: float = 0.0


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if follow_text_size:
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
	var before: int = visible_characters
	_shown_chars += delta * GameSettings.text_speed
	visible_characters = int(_shown_chars)
	if visible_characters > before:
		_play_typing_sound(before, visible_characters)
	if visible_characters >= get_total_character_count():
		_finish()


## 이번 프레임에 새로 나온 글자 중 공백이 아닌 게 있으면 한 번 소리 낸다.
func _play_typing_sound(from: int, to: int) -> void:
	if not typing_sound:
		return
	var shown: String = text.substr(from, to - from)
	if shown.strip_edges().is_empty():
		return
	AudioManager.play_typing(voice_pitch, voice_volume_db)


func _finish() -> void:
	_typing = false
	set_process(false)
	visible_characters = -1
	line_finished.emit()
