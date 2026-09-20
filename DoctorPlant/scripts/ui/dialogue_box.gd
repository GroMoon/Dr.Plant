extends Control
class_name DialogueBox
## 비주얼 노벨 대사창. 화자 이름 + 본문 + 진행 화살표.
## 본문은 DialogueLabel 이라 설정의 텍스트 속도·크기가 그대로 적용된다.

signal line_finished

## 화자 종류별 이름표 색. SYSTEM·알림은 대사와 구분되게 보여준다.
const SPEAKER_COLORS: Dictionary = {
	"CH_SYSTEM": Color(0.612, 0.827, 0.573),
	"CH_NOTICE": Color(0.898, 0.804, 0.475),
}
const SPEAKER_COLOR_DEFAULT: Color = Color(0.945, 0.957, 0.898)

@onready var _speaker: Label = $Box/Margin/Rows/Speaker
@onready var _body: DialogueLabel = $Box/Margin/Rows/Body
@onready var _arrow: Label = $Arrow

var _speaker_key: String = ""
var _body_key: String = ""


func _ready() -> void:
	_body.line_finished.connect(_on_line_finished)
	GameSettings.settings_changed.connect(_on_settings_changed)
	_arrow.visible = false
	hide()


## speaker_key 가 비면 이름표를 숨긴다(나레이션).
func show_line(speaker_key: String, body_key: String) -> void:
	_speaker_key = speaker_key
	_body_key = body_key
	show()
	_arrow.visible = false
	_render()


func is_typing() -> bool:
	return _body.is_typing()


## 출력 중이면 즉시 완성하고 true.
func skip() -> bool:
	return _body.skip()


func close() -> void:
	_speaker_key = ""
	_body_key = ""
	_arrow.visible = false
	hide()


func _render() -> void:
	_speaker.visible = not _speaker_key.is_empty()
	if _speaker.visible:
		_speaker.text = tr(_speaker_key)
		_speaker.add_theme_color_override(
			"font_color", SPEAKER_COLORS.get(_speaker_key, SPEAKER_COLOR_DEFAULT)
		)
	_body.show_line(tr(_body_key))


func _on_line_finished() -> void:
	_arrow.visible = visible
	line_finished.emit()


func _on_settings_changed() -> void:
	# 언어를 바꾸면 화면에 떠 있는 대사도 새 언어로 다시 찍는다.
	if visible and not _body_key.is_empty():
		_render()
