extends Node2D
class_name PlantFigure
## 정식 캐릭터 에셋이 없는 동안 쓰는 식물 인물 도형.
## 흰 가운(몸통) + 꽃잎 머리로 그린다. 플레이어와 NPC가 같이 쓴다.
## (CLAUDE.md 기본 규칙 5 — 에셋이 없으면 단순 도형으로 만든다)

@export var petal_color: Color = Color(0.945, 0.694, 0.780)
@export var center_color: Color = Color(0.976, 0.847, 0.451)
@export var leaf_color: Color = Color(0.353, 0.588, 0.325)
@export var coat_color: Color = Color(0.949, 0.957, 0.945)
@export var figure_scale: float = 1.0
@export var petal_count: int = 8
## 걷지 않아도 살짝 흔들리게 한다(앉아 있는 NPC 등).
@export var idle_sway: bool = true

var facing: String = "down":
	set(value):
		facing = value
		queue_redraw()

var walking: bool = false

var _time: float = 0.0
var _bob: float = 0.0


func _ready() -> void:
	_time = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	var target: float = sin(_time * (9.0 if walking else 1.6)) * (3.0 if walking else 1.0)
	if not walking and not idle_sway:
		target = 0.0
	if absf(target - _bob) > 0.05:
		_bob = lerpf(_bob, target, clampf(delta * 12.0, 0.0, 1.0))
		queue_redraw()


func _draw() -> void:
	var s: float = figure_scale
	var head_center := Vector2(0.0, -34.0 * s + _bob)

	# 그림자
	draw_set_transform(Vector2(0.0, 6.0 * s), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 16.0 * s, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 다리
	draw_rect(Rect2(Vector2(-9.0, -6.0) * s, Vector2(6.0, 12.0) * s), Color(0.145, 0.153, 0.161))
	draw_rect(Rect2(Vector2(3.0, -6.0) * s, Vector2(6.0, 12.0) * s), Color(0.145, 0.153, 0.161))

	# 가운
	var coat := Rect2(Vector2(-13.0, -30.0) * s + Vector2(0.0, _bob), Vector2(26.0, 26.0) * s)
	draw_rect(coat, coat_color)
	draw_rect(coat, Color(0.0, 0.0, 0.0, 0.18), false, 1.5)

	# 줄기
	draw_line(Vector2(0.0, -28.0 * s + _bob), head_center, leaf_color, 3.0 * s)

	# 꽃잎
	for i: int in petal_count:
		var angle: float = TAU * float(i) / float(maxi(petal_count, 1))
		var offset := Vector2(cos(angle), sin(angle)) * 11.0 * s
		draw_circle(head_center + offset, 7.0 * s, petal_color)
	draw_circle(head_center, 8.0 * s, center_color)

	# 바라보는 방향 표시(에셋이 들어오면 스프라이트로 교체된다)
	var look := Vector2.ZERO
	match facing:
		"up":
			look = Vector2(0.0, -1.0)
		"left":
			look = Vector2(-1.0, 0.0)
		"right":
			look = Vector2(1.0, 0.0)
		_:
			look = Vector2(0.0, 1.0)
	draw_circle(head_center + look * 5.0 * s, 2.6 * s, Color(0.2, 0.18, 0.16, 0.85))
