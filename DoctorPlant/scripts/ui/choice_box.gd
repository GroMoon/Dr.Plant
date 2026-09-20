extends Control
class_name ChoiceBox
## 선택지 창. 버튼으로 만들기 때문에 클릭·키보드·게임패드가 모두 그대로 동작한다.

signal chosen(index: int)

@onready var _prompt: Label = $Center/Panel/Rows/Prompt
@onready var _buttons_box: VBoxContainer = $Center/Panel/Rows/Buttons

var _option_keys: PackedStringArray = PackedStringArray()
var _buttons: Array[Button] = []


func _ready() -> void:
	GameSettings.settings_changed.connect(_on_settings_changed)
	hide()


## prompt_key 가 비면 질문 줄을 숨긴다.
func open(prompt_key: String, option_keys: PackedStringArray) -> void:
	_option_keys = option_keys
	_clear_buttons()
	_prompt.visible = not prompt_key.is_empty()
	_prompt.text = tr(prompt_key) if _prompt.visible else ""
	for i: int in _option_keys.size():
		var button := Button.new()
		button.name = "Option%dButton" % i
		button.custom_minimum_size = Vector2(420, 52)
		button.text = tr(_option_keys[i])
		button.pressed.connect(_on_option_pressed.bind(i))
		_buttons_box.add_child(button)
		_buttons.append(button)
	show()
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	_clear_buttons()
	hide()


func _clear_buttons() -> void:
	for button: Button in _buttons:
		_buttons_box.remove_child(button)
		button.queue_free()
	_buttons.clear()


func _on_option_pressed(index: int) -> void:
	AudioManager.play_select()
	hide()
	chosen.emit(index)


func _on_settings_changed() -> void:
	if not visible:
		return
	for i: int in _buttons.size():
		_buttons[i].text = tr(_option_keys[i])
