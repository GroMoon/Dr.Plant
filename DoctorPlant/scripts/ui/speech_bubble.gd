extends PanelContainer
class_name SpeechBubble
## 필드 인물 머리 위에 뜨는 말풍선. 대사창과 달리 진행·조작을 막지 않는다.
## 월드가 아니라 화면(CanvasLayer)에 그려 글자가 카메라 줌에 뭉개지지 않게 하고,
## 따라갈 인물(target)의 머리 위 위치를 매 프레임 화면 좌표로 옮겨 붙는다.

## 한 줄이 이보다 길면 줄바꿈한다(화면 픽셀).
const MAX_TEXT_WIDTH: float = 340.0
const MIN_TEXT_WIDTH: float = 24.0
## 꼬리(아래 삼각형) 높이. 말풍선 몸통은 이만큼 위로 띄운다.
const TAIL_HEIGHT: float = 12.0
const POP_TIME: float = 0.22
const HIDE_TIME: float = 0.24
const POP_FROM_SCALE: float = 0.6

@onready var _text: TypingLabel = $Text
@onready var _tail: Polygon2D = $Tail

var _target: Node2D = null
var _head_offset: Vector2 = Vector2.ZERO
var _tween: Tween = null
var _open: bool = false
## 씬에 적어 둔 타이핑음 크기. 거리에 따른 감쇠는 여기서 뺀다.
var _base_volume_db: float = 0.0


func _ready() -> void:
	_base_volume_db = _text.voice_volume_db
	hide()
	set_process(false)


## 따라갈 인물과 머리 위 지점(인물 기준 월드 좌표 오프셋).
func attach(target: Node2D, head_offset: Vector2) -> void:
	_target = target
	_head_offset = head_offset


func say(line: String, voice_pitch: float = 1.0) -> void:
	_open = true
	_text.voice_pitch = voice_pitch
	_text.custom_minimum_size.x = _text_width(line)
	_text.show_line(line)
	show()
	set_process(true)
	_follow()
	scale = Vector2.ONE * POP_FROM_SCALE
	modulate.a = 0.0
	_animate(1.0, Vector2.ONE, POP_TIME, Tween.TRANS_BACK)


func is_open() -> bool:
	return _open


## 타이핑음 크기 배율(0~1). 듣는 사람과 멀어질수록 작게 줄 때 쓴다.
func set_voice_gain(gain: float) -> void:
	_text.voice_volume_db = _base_volume_db + linear_to_db(maxf(gain, 0.001))


## 지금 띄운 대사(번역된 글자).
func text() -> String:
	return _text.text


## 아직 글자가 찍히는 중인지.
func is_typing() -> bool:
	return _open and _text.is_typing()


func dismiss() -> void:
	if not _open:
		return
	_open = false
	_text.skip()
	_animate(0.0, Vector2.ONE * 0.9, HIDE_TIME, Tween.TRANS_SINE)
	_tween.tween_callback(_on_hidden)


func _process(_delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_visible_in_tree():
		dismiss()
		return
	_follow()


## 글자 수에 맞게 몸통을 줄이고, 인물 머리 위(꼬리 끝)에 맞춘다.
func _follow() -> void:
	if not is_instance_valid(_target):
		return
	reset_size()
	var anchor: Vector2 = get_viewport().get_canvas_transform() * (_target.global_position + _head_offset)
	var tip := Vector2(size.x * 0.5, size.y + TAIL_HEIGHT)
	pivot_offset = tip
	position = (anchor - tip).round()
	_tail.position = Vector2(size.x * 0.5, size.y - 1.0)


func _text_width(line: String) -> float:
	var font: Font = _text.get_theme_font(&"font")
	var font_size: int = _text.get_theme_font_size(&"font_size")
	var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	return ceilf(clampf(width + 2.0, MIN_TEXT_WIDTH, MAX_TEXT_WIDTH))


func _animate(alpha: float, to_scale: Vector2, time: float, transition: Tween.TransitionType) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(transition)
	_tween.set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", alpha, time)
	_tween.tween_property(self, "scale", to_scale, time)
	_tween.chain()


func _on_hidden() -> void:
	hide()
	set_process(false)
