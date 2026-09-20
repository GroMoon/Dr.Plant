extends Node2D
## **TEST 씬** — `assets/characters/sprite/doctor_tmp.png` 확인용 프로토타입.
##
## 임시 시트라 정식 에셋은 아니지만, 지금은 본편 플레이어도 같은 시트를 쓰고
## 1화가 끝나면 이 씬으로 이어진다(ep1.tscn 의 next_scene).
## 시트가 8열 5행이라는 것만 확실하고 어느 행이 어느 용도인지는 정해지지 않아,
## 여기서 직접 걸어보며 행 번호를 맞춘 뒤 그 값을 FieldPlayer 기본값에 옮기면 된다.
##
## 지금 기본값(걷기 아래=1 위=2 왼쪽=3 오른쪽=4 / 제자리 아래=0)은
## 시트를 뜯어본 결과다. 0행은 8프레임짜리 미세한 제자리 동작,
## 1·2행은 4프레임 걷기를 두 번 반복하는 구성이었다.
##
## 조작
##   WASD · 방향키 · 스틱 = 이동
##   1~5        = 지금 보는 방향의 **걷기** 행 배정
##   Shift+1~5  = 지금 보는 방향의 **제자리** 행 배정 (걷기 행과 같게 두면 첫 프레임만 씀)
##   R = 초기화 / ESC = 일시정지·설정

const DEFAULT_WALK: Array[int] = [1, 2, 3, 4]
const DEFAULT_IDLE: Array[int] = [0, 2, 3, 4]
const DIRECTION_LABELS: Array[String] = ["아래", "위", "왼쪽", "오른쪽"]
const DIRECTION_ORDER: Array[String] = ["down", "up", "left", "right"]

@onready var _player: FieldPlayer = $Player
@onready var _camera: Camera2D = $Camera
@onready var _mapping_label: Label = $Ui/Panel/Rows/Mapping
@onready var _sheet: TextureRect = $Ui/Panel/Rows/Sheet
@onready var _walk_highlight: ColorRect = $Ui/Panel/Rows/Sheet/WalkHighlight
@onready var _idle_highlight: ColorRect = $Ui/Panel/Rows/Sheet/IdleHighlight

var _walk: PackedInt32Array = PackedInt32Array(DEFAULT_WALK)
var _idle: PackedInt32Array = PackedInt32Array(DEFAULT_IDLE)


func _ready() -> void:
	_player.controllable = true
	_camera.global_position = _player.global_position
	_apply_rows()


## 카메라를 물리 프레임에서 따라가게 하고 정수 픽셀에 맞춘다.
## 렌더 프레임(_process)에서 따라가면 물리 갱신과 어긋나 떨린다.
func _physics_process(delta: float) -> void:
	var target: Vector2 = _camera.global_position.lerp(
		_player.global_position, clampf(delta * 8.0, 0.0, 1.0)
	)
	_camera.global_position = target.round()
	_update_highlights()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	var key: int = key_event.keycode
	if key == KEY_R:
		_walk = PackedInt32Array(DEFAULT_WALK)
		_idle = PackedInt32Array(DEFAULT_IDLE)
		_apply_rows()
		return
	if key < KEY_1 or key > KEY_5:
		return
	var index: int = DIRECTION_ORDER.find(_player.facing())
	if index < 0:
		return
	if key_event.shift_pressed:
		_idle[index] = key - KEY_1
	else:
		_walk[index] = key - KEY_1
	_apply_rows()


func _apply_rows() -> void:
	_player.set_direction_rows(_walk, _idle)
	var parts: PackedStringArray = PackedStringArray()
	for i: int in DIRECTION_LABELS.size():
		parts.append("%s %d/%d" % [DIRECTION_LABELS[i], _walk[i], _idle[i]])
	_mapping_label.text = "걷기/제자리 행:   %s" % "     ".join(parts)


## 지금 보는 방향에 배정된 두 행을 시트 미리보기 위에 표시한다.
func _update_highlights() -> void:
	var index: int = DIRECTION_ORDER.find(_player.facing())
	if index < 0:
		return
	var row_height: float = _sheet.size.y / float(maxi(_player.sheet_rows, 1))
	var band := Vector2(_sheet.size.x, row_height)
	_walk_highlight.size = band
	_walk_highlight.position = Vector2(0.0, row_height * float(_walk[index]))
	_idle_highlight.size = band
	_idle_highlight.position = Vector2(0.0, row_height * float(_idle[index]))
	# 두 행이 같으면 위아래로 겹쳐 보이므로 제자리 표시를 숨긴다.
	_idle_highlight.visible = _idle[index] != _walk[index]
