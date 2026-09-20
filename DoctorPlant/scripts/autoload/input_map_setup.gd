extends Node
## project.godot 의 InputMap 이 비어 있거나 손상된 경우를 대비한 안전망.
## 이미 정의된 액션은 건드리지 않고, 없는 액션만 코드로 채운다.
## 요구사항: 클릭/스페이스로 진행, 방향키, 조이스틱(게임패드) 지원.

const DEADZONE: float = 0.2


func _ready() -> void:
	_ensure_action("advance", [
		_key(KEY_SPACE),
		_key(KEY_ENTER),
		_key(KEY_KP_ENTER),
		_mouse(MOUSE_BUTTON_LEFT),
		_pad(JOY_BUTTON_A),
	])
	_ensure_action("pause", [
		_key(KEY_ESCAPE),
		_pad(JOY_BUTTON_START),
	])
	# 기본 ui_* 액션에 게임패드 입력이 빠져 있으면 보강한다.
	_ensure_event("ui_cancel", _pad(JOY_BUTTON_B))
	_ensure_event("ui_accept", _pad(JOY_BUTTON_A))


func _ensure_action(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty():
		return
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


func _ensure_event(action: StringName, event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	for existing: InputEvent in InputMap.action_get_events(action):
		if existing.is_match(event):
			return
	InputMap.action_add_event(action, event)


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event
