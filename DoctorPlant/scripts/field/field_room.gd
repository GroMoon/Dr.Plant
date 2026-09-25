extends Node2D
class_name FieldRoom
## 필드(맵) 한 칸. 배경·충돌·조사 지점을 들고 있고,
## 플레이어가 어느 조사 지점 앞에 서 있는지 알려준다.

## 지금 조사할 수 있는 지점이 바뀌었을 때(없으면 null).
signal focus_changed(target: Interactable)
## 조사 지점이 실제로 선택되었을 때.
signal interaction_requested(target: Interactable)

## 인물(NPC)을 모아 두는 노드 이름. Npcs 는 대본이 켜고 끄는 인물, Crowd 는 배경 인물.
const FIGURE_HOLDERS: Array[String] = ["Npcs", "Crowd"]

## 카메라가 벗어나지 않을 범위.
@export var camera_bounds: Rect2 = Rect2(0.0, 0.0, 960.0, 640.0)
## 플레이어 등장 위치.
@export var spawn_point: Vector2 = Vector2(480.0, 420.0)

var _player: Node2D = null
var _nearby: Array[Interactable] = []
var _focus: Interactable = null


func _ready() -> void:
	for target: Interactable in interactables():
		target.body_entered.connect(_on_body_entered.bind(target))
		target.body_exited.connect(_on_body_exited.bind(target))
		target.interacted.connect(_on_interacted)
		target.set_highlight(false)


func interactables() -> Array[Interactable]:
	var found: Array[Interactable] = []
	var holder: Node = get_node_or_null("Interactables")
	for child: Node in (holder if holder != null else self).get_children():
		if child is Interactable:
			found.append(child)
	return found


## 방 안의 인물(Npcs·Crowd 아래 노드). 말풍선 혼잣말 대상이다.
func figures() -> Array[Node2D]:
	var found: Array[Node2D] = []
	for holder_name: String in FIGURE_HOLDERS:
		var holder: Node = get_node_or_null(holder_name)
		if holder == null:
			continue
		for child: Node in holder.get_children():
			if child is Node2D:
				found.append(child)
	return found


func find_interactable(id: String) -> Interactable:
	for target: Interactable in interactables():
		if target.id == id:
			return target
	return null


func set_player(player: Node2D) -> void:
	_player = player
	if _player != null:
		_player.global_position = spawn_point


func focus() -> Interactable:
	return _focus


## 대사 중에는 조사 지점의 마우스 클릭까지 막는다.
func set_input_enabled(active: bool) -> void:
	for target: Interactable in interactables():
		target.input_pickable = active


## 진행 입력이 들어왔을 때 호출. 앞에 선 지점이 있으면 true.
func try_interact() -> bool:
	if _focus == null:
		return false
	_focus.trigger()
	return true


func _process(_delta: float) -> void:
	_update_focus()


func _update_focus() -> void:
	var next: Interactable = null
	if _player != null:
		var best: float = INF
		for target: Interactable in _nearby:
			if not target.enabled:
				continue
			var distance: float = target.global_position.distance_to(_player.global_position)
			if distance < best:
				best = distance
				next = target
	if next == _focus:
		return
	if _focus != null:
		_focus.set_highlight(false)
	_focus = next
	if _focus != null:
		_focus.set_highlight(true)
		AudioManager.play_move()
	focus_changed.emit(_focus)


func _on_body_entered(body: Node, target: Interactable) -> void:
	if body != _player or _nearby.has(target):
		return
	_nearby.append(target)


func _on_body_exited(body: Node, target: Interactable) -> void:
	if body != _player:
		return
	_nearby.erase(target)


func _on_interacted(target: Interactable) -> void:
	interaction_requested.emit(target)
