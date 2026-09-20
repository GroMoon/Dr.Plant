extends Control
## 타이틀 화면. 게임 시작(저장소 선택) / 설정 / 나가기.

@onready var _start_button: Button = $Menu/StartButton
@onready var _settings_button: Button = $Menu/SettingsButton
@onready var _quit_button: Button = $Menu/QuitButton
@onready var _background_dark: TextureRect = $BackgroundDark
@onready var _slot_menu: Control = $SaveSlotMenu
@onready var _settings_menu: Control = $SettingsMenu
@onready var _confirm_popup: Control = $ConfirmPopup


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	_slot_menu.slot_chosen.connect(_on_slot_chosen)
	_slot_menu.closed.connect(_on_panel_closed)
	_settings_menu.closed.connect(_on_panel_closed)
	_confirm_popup.confirmed.connect(_on_quit_confirmed)
	_confirm_popup.canceled.connect(_on_panel_closed)

	AudioManager.play_bgm_title()
	_start_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _confirm_popup.visible:
		_confirm_popup.close()
	elif _settings_menu.visible:
		_settings_menu.close()
	elif _slot_menu.visible:
		_slot_menu.close()
	else:
		return
	get_viewport().set_input_as_handled()


func _open_panel(panel: Control) -> void:
	panel.open(_focused_button())
	_fade_background(1.0)


func _focused_button() -> Control:
	var focused: Control = get_viewport().gui_get_focus_owner()
	return focused if focused != null else _start_button


func _on_panel_closed() -> void:
	if not (_slot_menu.visible or _settings_menu.visible or _confirm_popup.visible):
		_fade_background(0.0)


func _fade_background(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_background_dark, "modulate:a", alpha, 0.25)


# ── 버튼 ──────────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	AudioManager.play_select()
	_open_panel(_slot_menu)


func _on_settings_pressed() -> void:
	AudioManager.play_select()
	_open_panel(_settings_menu)


func _on_quit_pressed() -> void:
	AudioManager.play_select()
	_confirm_popup.open("QUIT_CONFIRM", _quit_button)
	_fade_background(1.0)


func _on_quit_confirmed() -> void:
	get_tree().quit()


func _on_slot_chosen(slot: int) -> void:
	var data: Dictionary = SaveSystem.get_slot_data(slot)
	if data.is_empty():
		data = SaveSystem.create_slot(slot)
	SaveSystem.current_slot = slot
	StoryState.load_from_slot(slot)
	var scene_path: String = String(data.get("scene", "res://scenes/ch1/ep1.tscn"))
	AudioManager.stop_bgm()
	SceneRouter.change_scene(scene_path)
