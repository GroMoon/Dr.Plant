extends CanvasLayer
## ESC(또는 패드 START)로 열리는 일시정지 메뉴.
## 게임 씬 어디에든 인스턴스로 붙여 쓴다.

signal opened
signal closed

@onready var _root: Control = $Root
@onready var _resume_button: Button = $Root/Center/Panel/Box/ResumeButton
@onready var _settings_button: Button = $Root/Center/Panel/Box/SettingsButton
@onready var _quit_button: Button = $Root/Center/Panel/Box/QuitButton
@onready var _settings_menu: Control = $SettingsMenu
@onready var _confirm_popup: Control = $ConfirmPopup


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resume_button.pressed.connect(close)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_menu.closed.connect(_on_child_panel_closed)
	_confirm_popup.confirmed.connect(_on_quit_confirmed)
	_confirm_popup.canceled.connect(_on_child_panel_closed)
	_root.hide()


func is_open() -> bool:
	return _root.visible


func _unhandled_input(event: InputEvent) -> void:
	if SceneRouter.is_busy():
		return

	if event.is_action_pressed("pause"):
		if _close_top_panel():
			pass
		elif is_open():
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return

	if is_open() and event.is_action_pressed("ui_cancel"):
		if not _close_top_panel():
			close()
		get_viewport().set_input_as_handled()


## 설정·확인 창이 열려 있으면 닫고 true 를 돌려준다.
func _close_top_panel() -> bool:
	if _confirm_popup.visible:
		_confirm_popup.close()
		return true
	if _settings_menu.visible:
		_settings_menu.close()
		return true
	return false


func open() -> void:
	if is_open():
		return
	get_tree().paused = true
	_root.show()
	_resume_button.grab_focus()
	AudioManager.play_select()
	opened.emit()


func close() -> void:
	if not is_open():
		return
	while _close_top_panel():
		pass
	_root.hide()
	get_tree().paused = false
	AudioManager.play_select()
	closed.emit()


func _on_settings_pressed() -> void:
	AudioManager.play_select()
	_settings_menu.open(_settings_button)


func _on_quit_pressed() -> void:
	AudioManager.play_select()
	_confirm_popup.open("QUIT_CONFIRM", _quit_button)


func _on_quit_confirmed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_child_panel_closed() -> void:
	if is_open():
		_resume_button.grab_focus()
