extends Control
class_name DialogueBox
## 비주얼 노벨 대사창. 화자 이름 + 본문 + 진행 화살표.
## Dialogue Manager 가 돌려준 대사 한 줄(DialogueLine)을 보여준다.
## 본문은 TypingLabel 이라 설정의 텍스트 속도·크기가 그대로 적용된다.

signal line_finished

## 화자별 이름표 색. SYSTEM·알림은 대사와 구분되게 보여준다. 키는 대본에 쓴 화자 이름.
const SPEAKER_COLORS: Dictionary = {
	"SYSTEM": Color(0.612, 0.827, 0.573),
	"알림": Color(0.898, 0.804, 0.475),
}
const SPEAKER_COLOR_DEFAULT: Color = Color(0.945, 0.957, 0.898)

@onready var _speaker: Label = $Box/Margin/Rows/Speaker
@onready var _body: TypingLabel = $Box/Margin/Rows/Body
@onready var _arrow: Label = $Arrow

var _line: DialogueLine = null


func _ready() -> void:
	_body.line_finished.connect(_on_line_finished)
	GameSettings.settings_changed.connect(_on_settings_changed)
	_arrow.visible = false
	hide()


## 화자가 비어 있으면 이름표를 숨긴다(나레이션).
func show_line(line: DialogueLine) -> void:
	_line = line
	show()
	_arrow.visible = false
	_render()


func is_typing() -> bool:
	return _body.is_typing()


## 출력 중이면 즉시 완성하고 true.
func skip() -> bool:
	return _body.skip()


func close() -> void:
	_line = null
	_arrow.visible = false
	hide()


func _render() -> void:
	var speaker: String = _line.character
	_speaker.visible = not speaker.is_empty()
	if _speaker.visible:
		_speaker.text = tr(speaker, Localization.DIALOGUE_CONTEXT)
		_speaker.add_theme_color_override(
			"font_color", SPEAKER_COLORS.get(speaker, SPEAKER_COLOR_DEFAULT)
		)
	_body.show_line(_line.text)


func _on_line_finished() -> void:
	_arrow.visible = visible
	line_finished.emit()


func _on_settings_changed() -> void:
	# 언어를 바꾸면 화면에 떠 있는 대사도 새 언어로 다시 찍는다.
	# 대사 안의 {{변수}} 치환은 다시 하지 않는다(지금 대본에는 쓰지 않음).
	if visible and _line != null:
		_line.text = tr(_line.static_id, Localization.DIALOGUE_CONTEXT)
		_render()
