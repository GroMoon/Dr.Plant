extends Control
## 예/아니오 확인 창. 타이틀·일시정지의 "나가기"에서 공용으로 쓴다.

signal confirmed
signal canceled

@onready var _message: Label = $Center/Panel/Box/Message
@onready var _yes_button: Button = $Center/Panel/Box/Buttons/YesButton
@onready var _no_button: Button = $Center/Panel/Box/Buttons/NoButton

var _return_focus: Control = null


func _ready() -> void:
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)
	hide()


func open(message_key: String, return_focus: Control = null) -> void:
	_message.text = message_key
	_return_focus = return_focus
	show()
	_no_button.grab_focus()


func close() -> void:
	hide()
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()


func _on_yes_pressed() -> void:
	AudioManager.play_select()
	hide()
	confirmed.emit()


func _on_no_pressed() -> void:
	AudioManager.play_select()
	close()
	canceled.emit()
