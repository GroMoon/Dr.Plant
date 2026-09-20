extends Node
## 저장소 슬롯 4칸 관리. user://saves/slot_N.json 에 기록한다.
## 실제 진행 로그 저장은 아직 미구현이라, 지금은 슬롯 생성/조회/삭제만 다룬다.

const SLOT_COUNT: int = 4
const SAVE_DIR: String = "user://saves"
const SAVE_VERSION: int = 1

var current_slot: int = -1

var _cache: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	refresh()


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


func refresh() -> void:
	_cache.clear()
	for slot: int in SLOT_COUNT:
		_cache[slot] = _read_slot(slot)


func has_slot(slot: int) -> bool:
	return not get_slot_data(slot).is_empty()


func get_slot_data(slot: int) -> Dictionary:
	if not _cache.has(slot):
		_cache[slot] = _read_slot(slot)
	return _cache[slot]


## 새 게임 시작. 빈 슬롯에 초기 데이터를 기록하고 반환한다.
func create_slot(slot: int) -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"chapter": 1,
		"scene": "res://scenes/ch1/ep1.tscn",
		"playtime": 0.0,
		"checkpoint": "",
		"flags": {},
		"saved_at": Time.get_datetime_string_from_system(false, true),
	}
	write_slot(slot, data)
	return data


func write_slot(slot: int, data: Dictionary) -> void:
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("저장 실패: %s" % slot_path(slot))
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	_cache[slot] = data


func delete_slot(slot: int) -> void:
	if FileAccess.file_exists(slot_path(slot)):
		DirAccess.remove_absolute(slot_path(slot))
	_cache[slot] = {}


## "02:35" 형태의 플레이 시간 문자열.
func format_playtime(seconds: float) -> String:
	var total: int = int(seconds)
	var hours: int = floori(total / 3600.0)
	var minutes: int = floori(float(total % 3600) / 60.0)
	return "%02d:%02d" % [hours, minutes]


func _read_slot(slot: int) -> Dictionary:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("저장 파일이 깨졌다: %s" % path)
		return {}
	return parsed
