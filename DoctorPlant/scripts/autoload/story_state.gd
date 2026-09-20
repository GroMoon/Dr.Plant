extends Node
## 스토리 진행 상태. 선택지 결과(플래그)와 체크포인트를 들고 있다가
## 저장 슬롯(SaveSystem)에 함께 기록한다.
##
## 슬롯이 선택되지 않은 상태(씬을 직접 실행하는 등)에서도 동작해야 하므로
## 저장은 current_slot 이 있을 때만 이뤄진다.

signal flag_changed(flag: String, value: Variant)

var chapter: int = 1
var checkpoint: String = ""
var playtime: float = 0.0

var _flags: Dictionary = {}


func set_flag(flag: String, value: Variant) -> void:
	_flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: String, default_value: Variant = false) -> Variant:
	return _flags.get(flag, default_value)


func has_flag(flag: String) -> bool:
	return _flags.has(flag)


func flags() -> Dictionary:
	return _flags.duplicate(true)


func reset() -> void:
	_flags.clear()
	chapter = 1
	checkpoint = ""
	playtime = 0.0


## 슬롯을 골랐을 때 호출. 저장된 플래그를 되살린다.
func load_from_slot(slot: int) -> void:
	reset()
	if slot < 0:
		return
	var data: Dictionary = SaveSystem.get_slot_data(slot)
	if data.is_empty():
		return
	chapter = int(data.get("chapter", 1))
	checkpoint = String(data.get("checkpoint", ""))
	playtime = float(data.get("playtime", 0.0))
	var saved_flags: Variant = data.get("flags", {})
	if typeof(saved_flags) == TYPE_DICTIONARY:
		_flags = (saved_flags as Dictionary).duplicate(true)


## 현재 상태를 슬롯에 기록한다. 슬롯이 없으면 아무것도 하지 않는다.
func save_to_slot(scene_path: String) -> void:
	var slot: int = SaveSystem.current_slot
	if slot < 0:
		return
	var data: Dictionary = SaveSystem.get_slot_data(slot).duplicate(true)
	data["chapter"] = chapter
	data["scene"] = scene_path
	data["checkpoint"] = checkpoint
	data["playtime"] = playtime
	data["flags"] = flags()
	SaveSystem.write_slot(slot, data)
