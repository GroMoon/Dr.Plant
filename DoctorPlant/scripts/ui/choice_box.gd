extends Control
class_name ChoiceBox
## 선택지 창. 버튼으로 만들기 때문에 클릭·키보드·게임패드가 모두 그대로 동작한다.
## Dialogue Manager 의 선택지 줄을 받아, 그 줄의 본문을 질문으로, 응답들을 버튼으로 띄운다.
## 조건([if ... /])을 통과하지 못한 응답은 보여주지 않는다.

signal chosen(response: DialogueResponse)

@onready var _prompt: Label = $Center/Panel/Rows/Prompt
@onready var _buttons_box: VBoxContainer = $Center/Panel/Rows/Buttons

var _line: DialogueLine = null
var _responses: Array[DialogueResponse] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	GameSettings.settings_changed.connect(_on_settings_changed)
	hide()


## 줄의 본문이 비면 질문 줄을 숨긴다.
func open(line: DialogueLine) -> void:
	_line = line
	_clear_buttons()
	for response: DialogueResponse in line.responses:
		if response.is_allowed:
			_responses.append(response)
	for i: int in _responses.size():
		var button := Button.new()
		button.name = "Option%dButton" % i
		button.custom_minimum_size = Vector2(420, 52)
		button.pressed.connect(_on_option_pressed.bind(i))
		_buttons_box.add_child(button)
		_buttons.append(button)
	_render()
	show()
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	_clear_buttons()
	_line = null
	hide()


func _render() -> void:
	_prompt.visible = not _line.text.is_empty()
	_prompt.text = _line.text
	for i: int in _buttons.size():
		_buttons[i].text = _responses[i].text


func _clear_buttons() -> void:
	for button: Button in _buttons:
		_buttons_box.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_responses.clear()


func _on_option_pressed(index: int) -> void:
	AudioManager.play_select()
	hide()
	chosen.emit(_responses[index])


func _on_settings_changed() -> void:
	# 언어를 바꾸면 질문과 버튼도 새 언어로 다시 쓴다.
	if not visible or _line == null:
		return
	_line.text = tr(_line.static_id, Localization.DIALOGUE_CONTEXT)
	for response: DialogueResponse in _responses:
		response.text = tr(response.static_id, Localization.DIALOGUE_CONTEXT)
	_render()
