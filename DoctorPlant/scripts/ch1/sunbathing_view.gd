extends Control
## '해바라기' 창밖 연출. 배경 에셋이 없어 도형으로 그린다.
## (CLAUDE.md 기본 규칙 5)
##
## 따스한 햇빛 / 태양을 향해 멈춰 선 식물들 / 숨죽인 도시.

const SKY_TOP: Color = Color(0.639, 0.812, 0.914)
const SKY_BOTTOM: Color = Color(0.988, 0.914, 0.749)
const SUN_COLOR: Color = Color(1.0, 0.957, 0.792)
var _time: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var view: Vector2 = size
	# 하늘
	draw_rect(Rect2(Vector2.ZERO, view), SKY_TOP)
	var band_count: int = 24
	for i: int in band_count:
		var ratio: float = float(i) / float(band_count - 1)
		var band := Rect2(
			Vector2(0.0, view.y * ratio * 0.72),
			Vector2(view.x, view.y * 0.72 / float(band_count) + 2.0)
		)
		draw_rect(band, SKY_TOP.lerp(SKY_BOTTOM, ratio))

	# 태양
	var sun_center := Vector2(view.x * 0.72, view.y * 0.22)
	var pulse: float = 1.0 + 0.02 * sin(_time * 1.5)
	draw_circle(sun_center, view.y * 0.16 * pulse, Color(1.0, 0.925, 0.706, 0.35))
	draw_circle(sun_center, view.y * 0.1 * pulse, SUN_COLOR)

	# 도시 실루엣 — 숨죽이듯 멈춰 있다
	var ground_y: float = view.y * 0.72
	var x: float = -40.0
	var index: int = 0
	while x < view.x + 80.0:
		var width: float = 90.0 + float((index * 53) % 90)
		var height: float = 120.0 + float((index * 97) % 240)
		var shade: float = 0.26 + 0.05 * float(index % 3)
		draw_rect(
			Rect2(Vector2(x, ground_y - height), Vector2(width, height)),
			Color(shade + 0.2, shade + 0.24, shade + 0.28, 0.9)
		)
		# 창문
		var window_y: float = ground_y - height + 18.0
		while window_y < ground_y - 24.0:
			var window_x: float = x + 14.0
			while window_x < x + width - 20.0:
				draw_rect(
					Rect2(Vector2(window_x, window_y), Vector2(10.0, 14.0)),
					Color(1.0, 0.933, 0.776, 0.55)
				)
				window_x += 24.0
			window_y += 30.0
		x += width + 14.0
		index += 1

	# 바닥
	draw_rect(Rect2(Vector2(0.0, ground_y), Vector2(view.x, view.y - ground_y)), Color(0.788, 0.769, 0.714))

	# 태양을 보며 가만히 서 있는 식물들
	var figure_count: int = 9
	for i: int in figure_count:
		var fx: float = view.x * (0.06 + 0.1 * float(i))
		var fy: float = ground_y + view.y * (0.04 + 0.09 * float(i % 3))
		var scale_factor: float = 0.8 + 0.25 * float(i % 3)
		_draw_plant(Vector2(fx, fy), scale_factor, sun_center)


func _draw_plant(at: Vector2, figure_scale: float, sun_center: Vector2) -> void:
	var stem_height: float = 70.0 * figure_scale
	var head := at - Vector2(0.0, stem_height)
	draw_set_transform(at + Vector2(0.0, 4.0 * figure_scale), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 16.0 * figure_scale, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_line(at, head, Color(0.353, 0.588, 0.325), 5.0 * figure_scale)
	for i: int in 8:
		var angle: float = TAU * float(i) / 8.0
		draw_circle(
			head + Vector2(cos(angle), sin(angle)) * 13.0 * figure_scale,
			8.0 * figure_scale,
			Color(0.976, 0.808, 0.435)
		)
	draw_circle(head, 9.0 * figure_scale, Color(0.639, 0.427, 0.259))
	# 모두 태양 쪽을 보고 있다
	var look: Vector2 = (sun_center - head).normalized()
	draw_circle(head + look * 5.0 * figure_scale, 3.0 * figure_scale, Color(0.25, 0.18, 0.12, 0.8))
