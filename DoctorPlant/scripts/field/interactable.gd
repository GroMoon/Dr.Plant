extends Area2D
class_name Interactable
## 필드에서 조사할 수 있는 지점. 다가가서 진행 입력(스페이스·클릭·패드 A)을 누르거나
## 마우스로 직접 눌러도 동작한다.

signal interacted(source: Interactable)

## 에피소드 스크립트가 구분에 쓰는 이름.
@export var id: String = ""
## 화면에 뜨는 이름표 키.
@export var label_key: String = ""
## 조사했을 때 SYSTEM 으로 읽어줄 문장 키. 비면 아무 문장도 읽지 않는다.
@export var description_key: String = ""
## 하위 선택지(예: 컴퓨터의 환자 리스트/메신저/인터넷). 비면 선택지를 띄우지 않는다.
@export var option_keys: PackedStringArray = PackedStringArray()
## option_keys 와 같은 순서의 설명 문장 키.
@export var option_description_keys: PackedStringArray = PackedStringArray()
## 켜면 하위 선택지 끝에 "닫는다"가 붙는다.
@export var options_closable: bool = true
## 꺼진 지점은 화면에서도 사라지고 조사할 수 없다.
@export var enabled: bool = true:
	set(value):
		enabled = value
		visible = value

var _highlight: bool = false


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)


func label() -> String:
	return tr(label_key) if not label_key.is_empty() else id


func set_highlight(value: bool) -> void:
	if _highlight == value:
		return
	_highlight = value
	var marker: Node = get_node_or_null("Marker")
	if marker is CanvasItem:
		var tween := create_tween()
		tween.tween_property(marker, "modulate:a", 1.0 if value else 0.35, 0.15)


func trigger() -> void:
	if not enabled:
		return
	interacted.emit(self)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		trigger()
