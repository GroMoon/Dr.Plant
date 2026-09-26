extends Minigame
## 디파인 계량. 재료 세 가지를 차례로 비커에 부어 초록 눈금 안에 맞춘다.
## 누르고 있으면 부어지고, 오래 누를수록 빨라진다. 손을 떼도 잠깐 더 흘러내리므로
## 눈금 가까이에서는 짧게 끊어 붓는 집중이 필요하다. 눈금을 넘기면 비우고 다시 붓는다.

const INGREDIENTS: Array[Dictionary] = [
	{"key": "MG_MEASURE_SUN", "color": Color(0.98, 0.8, 0.3), "band": 0.09},
	{"key": "MG_MEASURE_DEW", "color": Color(0.55, 0.8, 0.95), "band": 0.075},
	{"key": "MG_MEASURE_ROOT", "color": Color(0.76, 0.42, 0.32), "band": 0.06},
]
## 붓는 속도(비커 높이 비율/초). 누르는 동안 BASE 에서 MAX 까지 빨라진다.
const BASE_FLOW: float = 0.1
const FLOW_ACCEL: float = 0.55
const MAX_FLOW: float = 0.7
## 손을 뗀 뒤에도 흘러내리는 시간.
const DRIP_TIME: float = 0.18
## 눈금 안에서 이만큼 가만히 있으면 계량 완료.
const SETTLE_TIME: float = 0.5
const SPILL_TIME: float = 0.8
const BAND_MIN: float = 0.4
const BAND_MAX: float = 0.78

const BEAKER_X: Array[float] = [250.0, 560.0, 870.0]
const BEAKER_SIZE: Vector2 = Vector2(170.0, 300.0)
const BEAKER_BOTTOM: float = 580.0
const BOTTLE_TOP: float = 86.0
const NOZZLE_Y: float = 222.0
const GLASS_COLOR: Color = Color(0.859, 0.902, 0.831, 0.7)

var _index: int = 0
var _levels: Array[float] = []
var _bands: Array[float] = []
var _holding: bool = false
var _flow: float = BASE_FLOW
var _drip: float = 0.0
var _drip_flow: float = 0.0
var _settle: float = 0.0
var _spill: float = 0.0


func _setup() -> void:
	for i: int in INGREDIENTS.size():
		_levels.append(0.0)
		_bands.append(randf_range(BAND_MIN, BAND_MAX))
	_report()


func _input(event: InputEvent) -> void:
	if not active or _index >= INGREDIENTS.size():
		return
	if event.is_action_pressed("advance"):
		if _spill <= 0.0:
			_holding = true
			_flow = BASE_FLOW
	elif event.is_action_released("advance") and _holding:
		_release()


func _process(delta: float) -> void:
	# 일시정지 중에 손을 뗐다면 뗀 이벤트를 못 받았을 수 있다.
	if _holding and not Input.is_action_pressed("advance"):
		_release()
	if _spill > 0.0:
		_spill = maxf(_spill - delta, 0.0)
		_levels[_index] = maxf(_levels[_index] - delta / SPILL_TIME * 1.2, 0.0)
	elif active:
		_pour(delta)
	queue_redraw()


func _release() -> void:
	_holding = false
	_drip_flow = _flow
	_drip = DRIP_TIME


func _pour(delta: float) -> void:
	var level: float = _levels[_index]
	if _holding:
		_flow = minf(_flow + FLOW_ACCEL * delta, MAX_FLOW)
		level += _flow * delta
	elif _drip > 0.0:
		level += _drip_flow * delta * (_drip / DRIP_TIME)
		_drip = maxf(_drip - delta, 0.0)
	_levels[_index] = level

	if level > band_top(_index):
		_overflow()
	elif not _holding and _drip <= 0.0 and level >= band_bottom(_index):
		_settle += delta
		if _settle >= SETTLE_TIME:
			_finish_beaker()
	else:
		_settle = 0.0


func band_top(index: int) -> float:
	return _bands[index] + float(INGREDIENTS[index]["band"]) * 0.5


func band_bottom(index: int) -> float:
	return _bands[index] - float(INGREDIENTS[index]["band"]) * 0.5


func _overflow() -> void:
	_mistake("MG_MEASURE_OVERFLOW")
	_holding = false
	_drip = 0.0
	_flow = BASE_FLOW
	_settle = 0.0
	_spill = SPILL_TIME


func _finish_beaker() -> void:
	AudioManager.play_select()
	_say("MG_MEASURE_GOOD")
	_index += 1
	_holding = false
	_drip = 0.0
	_flow = BASE_FLOW
	_settle = 0.0
	_report()
	if _index >= INGREDIENTS.size():
		_complete()


func _report() -> void:
	_report_progress(tr("MG_MEASURE_PROGRESS").format([_index, INGREDIENTS.size()]))


# ── 그리기 ────────────────────────────────────────────────────────────

func _draw() -> void:
	for i: int in INGREDIENTS.size():
		_draw_station(i)


func _draw_station(index: int) -> void:
	var center_x: float = BEAKER_X[index]
	var ingredient: Dictionary = INGREDIENTS[index]
	var color: Color = ingredient["color"]
	var current: bool = index == _index
	var done: bool = index < _index
	var dim: float = 1.0 if (current or done) else 0.45

	# 재료 이름과 병
	_draw_text_centered(tr(String(ingredient["key"])), Vector2(center_x, BOTTLE_TOP - 34.0), 24, Color(COLOR_TEXT, dim))
	var bottle := Rect2(center_x - 42.0, BOTTLE_TOP, 84.0, 96.0)
	draw_rect(bottle, Color(color, 0.85 * dim))
	draw_rect(bottle, Color(GLASS_COLOR, dim), false, 3.0)
	draw_rect(Rect2(center_x - 10.0, bottle.end.y, 20.0, NOZZLE_Y - bottle.end.y), Color(GLASS_COLOR, 0.6 * dim))
	if current and active:
		var bob: float = sin(Time.get_ticks_msec() / 180.0) * 4.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(center_x - 14.0, BOTTLE_TOP - 70.0 + bob),
			Vector2(center_x + 14.0, BOTTLE_TOP - 70.0 + bob),
			Vector2(center_x, BOTTLE_TOP - 56.0 + bob),
		]), COLOR_WARN)

	var beaker := Rect2(center_x - BEAKER_SIZE.x * 0.5, BEAKER_BOTTOM - BEAKER_SIZE.y, BEAKER_SIZE.x, BEAKER_SIZE.y)
	var level: float = clampf(_levels[index], 0.0, 1.0)
	var surface_y: float = beaker.end.y - beaker.size.y * level

	# 붓는 물줄기
	if current and _spill <= 0.0 and (_holding or _drip > 0.0):
		var flow: float = _flow if _holding else _drip_flow * (_drip / DRIP_TIME)
		var width: float = 5.0 + 14.0 * clampf(flow / MAX_FLOW, 0.0, 1.0)
		draw_rect(Rect2(center_x - width * 0.5, NOZZLE_Y, width, surface_y - NOZZLE_Y), Color(color, 0.85))

	# 목표 눈금
	var band_rect := Rect2(
		beaker.position.x, beaker.end.y - beaker.size.y * band_top(index),
		beaker.size.x, beaker.size.y * float(ingredient["band"])
	)
	draw_rect(band_rect, Color(COLOR_GOOD, 0.22 * dim))

	# 내용물
	var liquid := Color(color, 0.85)
	if current and _spill > 0.0:
		liquid = liquid.lerp(COLOR_BAD, 0.5)
	draw_rect(Rect2(beaker.position.x, surface_y, beaker.size.x, beaker.end.y - surface_y), liquid)

	draw_line(band_rect.position, Vector2(band_rect.end.x, band_rect.position.y), Color(COLOR_GOOD, dim), 3.0)
	draw_line(Vector2(band_rect.position.x, band_rect.end.y), band_rect.end, Color(COLOR_GOOD, dim), 3.0)

	# 눈금자
	for step: int in range(1, 10):
		var y: float = beaker.end.y - beaker.size.y * float(step) / 10.0
		var length: float = 22.0 if step % 5 == 0 else 12.0
		draw_line(Vector2(beaker.position.x, y), Vector2(beaker.position.x + length, y), Color(GLASS_COLOR, 0.5 * dim), 2.0)

	# 유리(위는 열려 있다)
	var glass := Color(GLASS_COLOR, dim)
	draw_line(beaker.position, Vector2(beaker.position.x, beaker.end.y), glass, 4.0)
	draw_line(Vector2(beaker.end.x, beaker.position.y), beaker.end, glass, 4.0)
	draw_line(Vector2(beaker.position.x, beaker.end.y), beaker.end, glass, 4.0)

	# 넘쳐 흘러내리는 방울
	if current and _spill > 0.0:
		var t: float = 1.0 - _spill / SPILL_TIME
		for side: float in [-1.0, 1.0]:
			for drop: int in 3:
				var x: float = center_x + side * (BEAKER_SIZE.x * 0.5 + 10.0 + 8.0 * drop)
				var y: float = beaker.position.y + t * (120.0 + 40.0 * drop)
				draw_circle(Vector2(x, y), 6.0, Color(color, 1.0 - t))

	if done:
		var mark := Vector2(center_x, BEAKER_BOTTOM + 30.0)
		draw_polyline(PackedVector2Array([
			mark + Vector2(-16.0, 0.0), mark + Vector2(-4.0, 12.0), mark + Vector2(18.0, -12.0),
		]), COLOR_GOOD, 5.0, true)
