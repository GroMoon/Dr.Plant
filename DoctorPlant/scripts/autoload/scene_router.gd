extends CanvasLayer
## 씬 전환 담당. 로딩 화면을 덮고 비동기로 씬을 읽은 뒤 교체한다.

const LOADING_SCENE: PackedScene = preload("res://scenes/loading_screen.tscn")
const FADE_TIME: float = 0.2
const MIN_SHOW_TIME: float = 0.4

signal scene_changed(path: String)

var _loading: Control
var _target_path: String = ""
var _elapsed: float = 0.0
var _swapped: bool = false


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_loading = LOADING_SCENE.instantiate()
	add_child(_loading)
	_loading.visible = false
	set_process(false)


func is_busy() -> bool:
	return _target_path != ""


func change_scene(path: String) -> void:
	if is_busy():
		return
	if not ResourceLoader.exists(path):
		push_error("씬을 찾을 수 없다: %s" % path)
		return
	_target_path = path
	_elapsed = 0.0
	_swapped = false
	get_tree().paused = false
	_loading.visible = true
	_loading.modulate.a = 0.0
	_loading.set_progress(0.0)
	var tween := create_tween()
	tween.tween_property(_loading, "modulate:a", 1.0, FADE_TIME)
	ResourceLoader.load_threaded_request(path)
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	# 교체가 끝났으면 로딩 상태를 다시 묻지 않는다.
	# load_threaded_get 으로 이미 꺼내간 요청이라 INVALID_RESOURCE 가 돌아온다.
	if _swapped:
		if _elapsed >= MIN_SHOW_TIME:
			_finish()
		return

	var progress: Array = []
	var status: int = ResourceLoader.load_threaded_get_status(_target_path, progress)
	if not progress.is_empty():
		_loading.set_progress(float(progress[0]))

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("씬 로딩 실패: %s" % _target_path)
			_finish()
			return

	var packed := ResourceLoader.load_threaded_get(_target_path) as PackedScene
	if packed == null:
		push_error("씬 인스턴스화 실패: %s" % _target_path)
		_finish()
		return
	_loading.set_progress(1.0)
	get_tree().change_scene_to_packed(packed)
	scene_changed.emit(_target_path)
	_swapped = true


func _finish() -> void:
	set_process(false)
	_target_path = ""
	var tween := create_tween()
	tween.tween_property(_loading, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(func() -> void: _loading.visible = false)
