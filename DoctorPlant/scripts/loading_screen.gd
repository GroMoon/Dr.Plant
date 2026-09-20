extends Control
## SceneRouter 가 씬을 읽는 동안 덮어두는 화면.

@onready var _progress: ProgressBar = $Center/Box/Progress
@onready var _message: Label = $Center/Box/Message


func _ready() -> void:
	_message.text = "LOADING"


func set_progress(value: float) -> void:
	_progress.value = clampf(value, 0.0, 1.0)
