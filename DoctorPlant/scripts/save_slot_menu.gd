extends Control
## 저장소 4칸 선택 창. 빈 칸은 "새로 시작"으로 보여준다.
## 진행 로그 저장은 아직 미구현이라, 지금은 슬롯을 만들고 챕터 씬으로 넘기는 것까지 한다.

signal slot_chosen(slot: int)
signal closed

@onready var _slots_box: VBoxContainer = $Center/Panel/Box/Slots
@onready var _back_button: Button = $Center/Panel/Box/Buttons/BackButton

var _slot_buttons: Array[Button] = []
var _return_focus: Control = null


func _ready() -> void:
	_build_slot_buttons()
	_back_button.pressed.connect(_on_back_pressed)
	hide()


func _build_slot_buttons() -> void:
	for slot: int in SaveSystem.SLOT_COUNT:
		var button := Button.new()
		button.name = "Slot%dButton" % (slot + 1)
		button.custom_minimum_size = Vector2(0, 58)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_slot_pressed.bind(slot))
		_slots_box.add_child(button)
		_slot_buttons.append(button)


func open(return_focus: Control = null) -> void:
	_return_focus = return_focus
	refresh()
	show()
	if not _slot_buttons.is_empty():
		_slot_buttons[0].grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	if is_instance_valid(_return_focus):
		_return_focus.grab_focus()
	closed.emit()


func refresh() -> void:
	SaveSystem.refresh()
	for slot: int in _slot_buttons.size():
		_slot_buttons[slot].text = _slot_text(slot)


func _slot_text(slot: int) -> String:
	var label: String = tr("SLOT_LABEL").format([slot + 1])
	var data: Dictionary = SaveSystem.get_slot_data(slot)
	if data.is_empty():
		return "%s    —    %s" % [label, tr("SLOT_EMPTY")]
	var chapter: String = tr("SLOT_CHAPTER").format([int(data.get("chapter", 1))])
	var playtime: String = tr("SLOT_PLAYTIME").format([SaveSystem.format_playtime(float(data.get("playtime", 0.0)))])
	return "%s    %s    %s    %s" % [label, chapter, playtime, String(data.get("saved_at", ""))]


func _on_slot_pressed(slot: int) -> void:
	AudioManager.play_select()
	slot_chosen.emit(slot)


func _on_back_pressed() -> void:
	AudioManager.play_select()
	close()
