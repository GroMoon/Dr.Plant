extends Control
## 타이틀과 일시정지에서 공용으로 쓰는 설정 창.
## 값이 바뀌면 GameSettings 에 즉시 반영하고, 창을 닫을 때 파일로 저장한다.

signal closed

@onready var _bgm_slider: HSlider = $Center/Panel/Box/Grid/BgmSlider
@onready var _bgm_value: Label = $Center/Panel/Box/Grid/BgmValue
@onready var _sfx_slider: HSlider = $Center/Panel/Box/Grid/SfxSlider
@onready var _sfx_value: Label = $Center/Panel/Box/Grid/SfxValue
@onready var _window_mode_option: OptionButton = $Center/Panel/Box/Grid/WindowModeOption
@onready var _resolution_option: OptionButton = $Center/Panel/Box/Grid/ResolutionOption
@onready var _language_option: OptionButton = $Center/Panel/Box/Grid/LanguageOption
@onready var _text_speed_slider: HSlider = $Center/Panel/Box/Grid/TextSpeedSlider
@onready var _text_speed_value: Label = $Center/Panel/Box/Grid/TextSpeedValue
@onready var _text_size_option: OptionButton = $Center/Panel/Box/Grid/TextSizeOption
@onready var _preview: DialogueLabel = $Center/Panel/Box/PreviewBox/Preview
@onready var _reset_button: Button = $Center/Panel/Box/Buttons/ResetButton
@onready var _close_button: Button = $Center/Panel/Box/Buttons/CloseButton

var _syncing: bool = false
var _return_focus: Control = null


func _ready() -> void:
	_build_options()
	_connect_signals()
	hide()


func _build_options() -> void:
	_window_mode_option.clear()
	_window_mode_option.add_item("WINDOW_MODE_WINDOWED", GameSettings.WindowMode.WINDOWED)
	_window_mode_option.add_item("WINDOW_MODE_BORDERLESS", GameSettings.WindowMode.BORDERLESS)
	_window_mode_option.add_item("WINDOW_MODE_EXCLUSIVE", GameSettings.WindowMode.EXCLUSIVE)

	_resolution_option.clear()
	for i: int in GameSettings.available_resolution_indices():
		var res: Vector2i = GameSettings.RESOLUTIONS[i]
		_resolution_option.add_item("%d x %d" % [res.x, res.y], i)

	_language_option.clear()
	for i: int in Localization.SUPPORTED_LOCALES.size():
		_language_option.add_item(String(Localization.SUPPORTED_LOCALES[i]["label"]), i)

	_text_size_option.clear()
	for i: int in GameSettings.TEXT_SIZE_KEYS.size():
		_text_size_option.add_item(GameSettings.TEXT_SIZE_KEYS[i], i)


func _connect_signals() -> void:
	_bgm_slider.value_changed.connect(_on_bgm_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_window_mode_option.item_selected.connect(_on_window_mode_selected)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_language_option.item_selected.connect(_on_language_selected)
	_text_speed_slider.value_changed.connect(_on_text_speed_changed)
	_text_size_option.item_selected.connect(_on_text_size_selected)
	_reset_button.pressed.connect(_on_reset_pressed)
	_close_button.pressed.connect(_on_close_pressed)


func open(return_focus: Control = null) -> void:
	_return_focus = return_focus
	_sync_from_settings()
	show()
	_play_preview()
	_bgm_slider.grab_focus()


func close() -> void:
	if not visible:
		return
	GameSettings.save_settings()
	hide()
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()
	closed.emit()


func _sync_from_settings() -> void:
	_syncing = true
	_bgm_slider.value = GameSettings.bgm_volume
	_sfx_slider.value = GameSettings.sfx_volume
	_window_mode_option.select(_window_mode_option.get_item_index(GameSettings.window_mode))
	_resolution_option.select(_resolution_option.get_item_index(GameSettings.resolution_index))
	_language_option.select(Localization.locale_index(GameSettings.locale))
	_text_speed_slider.value = GameSettings.text_speed
	_text_size_option.select(_text_size_option.get_item_index(GameSettings.text_size_index))
	_syncing = false
	_refresh_labels()


func _refresh_labels() -> void:
	_bgm_value.text = "%d%%" % roundi(GameSettings.bgm_volume * 100.0)
	_sfx_value.text = "%d%%" % roundi(GameSettings.sfx_volume * 100.0)
	if GameSettings.is_text_instant():
		_text_speed_value.text = tr("TEXT_SPEED_INSTANT")
	else:
		_text_speed_value.text = "%d" % roundi(GameSettings.text_speed)
	# 전체화면에서는 해상도 선택이 의미가 없다.
	_resolution_option.disabled = GameSettings.window_mode != GameSettings.WindowMode.WINDOWED


func _play_preview() -> void:
	_preview.show_line(tr("PREVIEW_SAMPLE"))


# ── 입력 처리 ─────────────────────────────────────────────────────────

func _on_bgm_changed(value: float) -> void:
	if _syncing:
		return
	GameSettings.set_bgm_volume(value)
	_refresh_labels()


func _on_sfx_changed(value: float) -> void:
	if _syncing:
		return
	GameSettings.set_sfx_volume(value)
	_refresh_labels()
	AudioManager.play_move()


func _on_window_mode_selected(index: int) -> void:
	if _syncing:
		return
	AudioManager.play_select()
	GameSettings.set_window_mode(_window_mode_option.get_item_id(index))
	_refresh_labels()


func _on_resolution_selected(index: int) -> void:
	if _syncing:
		return
	AudioManager.play_select()
	GameSettings.set_resolution_index(_resolution_option.get_item_id(index))


func _on_language_selected(index: int) -> void:
	if _syncing:
		return
	AudioManager.play_select()
	GameSettings.set_locale(String(Localization.SUPPORTED_LOCALES[index]["code"]))
	_refresh_labels()
	_play_preview()


func _on_text_speed_changed(value: float) -> void:
	if _syncing:
		return
	GameSettings.set_text_speed(value)
	_refresh_labels()
	_play_preview()


func _on_text_size_selected(index: int) -> void:
	if _syncing:
		return
	AudioManager.play_select()
	GameSettings.set_text_size_index(_text_size_option.get_item_id(index))
	_play_preview()


func _on_reset_pressed() -> void:
	AudioManager.play_select()
	GameSettings.reset_to_defaults()
	_sync_from_settings()
	_play_preview()


func _on_close_pressed() -> void:
	AudioManager.play_select()
	close()
