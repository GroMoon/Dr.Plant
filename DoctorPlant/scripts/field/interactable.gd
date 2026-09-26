extends Area2D
class_name Interactable
## 필드에서 조사할 수 있는 지점. 다가가서 진행 입력(스페이스·클릭·패드 A)을 누르거나
## 마우스로 직접 눌러도 동작한다.
##
## 조사했을 때의 대사·선택지는 에피소드 대본의 "~ inspect_<id>" 구간에 쓴다.

signal interacted(source: Interactable)

## 대본이 구분에 쓰는 이름. 조사 대사는 대본의 inspect_<id> 구간.
@export var id: String = ""
## 화면에 뜨는 이름표 키.
@export var label_key: String = ""
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
