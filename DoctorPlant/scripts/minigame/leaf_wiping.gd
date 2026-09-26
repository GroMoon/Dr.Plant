extends Minigame
## 잎 닦기. 잎에 묻은 얼룩을 문질러 지운다.
## 문지른 거리만큼 얼룩이 옅어지고, 너무 빠르게 문지르면 잎이 상해 잠시 닦이지 않는다.
## 희미한 얼룩이 섞여 있어 잎 전체를 살펴야 한다.

const LEAF_CENTER: Vector2 = Vector2(540.0, 330.0)
const LEAF_LENGTH: float = 880.0
const LEAF_HALF_WIDTH: float = 210.0
const LEAF_STEPS: int = 48
## 얼룩 구성: 보통 얼룩(그중 일부는 끈적함) + 희미한 얼룩.
const STAIN_COUNT: int = 7
const STICKY_COUNT: int = 2
const FAINT_COUNT: int = 2
const STAIN_GAP: float = 120.0
## 얼룩 하나를 지우는 데 필요한 문지른 거리(px).
const RUB_NORMAL: float = 900.0
const RUB_STICKY: float = 1700.0
const RUB_FAINT: float = 650.0
## 문지르는 속도(px/초)가 이보다 빠르면 잎이 상한다.
const SPEED_LIMIT: float = 3400.0
const BRUISE_TIME: float = 0.7
## 키보드·패드로 움직이는 걸레의 속도.
const CURSOR_SPEED: float = 620.0
const BRUSH_RADIUS: float = 34.0
const GAUGE_RECT: Rect2 = Rect2(1052.0, 110.0, 24.0, 420.0)
const SAFE_RATIO: float = 0.75

const LEAF_COLOR: Color = Color(0.388, 0.62, 0.345)
const LEAF_EDGE: Color = Color(0.255, 0.44, 0.235)
const LEAF_HURT: Color = Color(0.62, 0.36, 0.3)
const VEIN_COLOR: Color = Color(0.64, 0.82, 0.54, 0.55)
const DIRT_COLOR: Color = Color(0.43, 0.34, 0.2)
const STICKY_COLOR: Color = Color(0.25, 0.2, 0.13)

var _stains: Array[Dictionary] = []
var _sparkles: Array[Dictionary] = []
var _leaf: PackedVector2Array = PackedVector2Array()
var _brush: Vector2 = LEAF_CENTER
var _last_brush: Vector2 = LEAF_CENTER
var _speed: float = 0.0
var _bruise: float = 0.0
var _rubbing: bool = false
var _faint_hint_shown: bool = false


func _setup() -> void:
	mouse_default_cursor_shape = Control.CURSOR_CROSS
	_leaf = _build_leaf()
	_place_stains()
	_report()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# 누르는 순간 걸레를 그 자리로 옮긴다. 순간이동을 빠른 문지르기로 세지 않는다.
		_brush = (event as InputEventMouseButton).position
		_last_brush = _brush
		_speed = 0.0
	elif event is InputEventMouseMotion:
		_brush = (event as InputEventMouseMotion).position


func _process(delta: float) -> void:
	_update_sparkles(delta)
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		_brush += direction * CURSOR_SPEED * delta
	_brush = _brush.clamp(Vector2.ZERO, BOARD_SIZE)
	var moved: float = _brush.distance_to(_last_brush)
	_last_brush = _brush
	_rubbing = active and Input.is_action_pressed("advance")
	var instant: float = moved / delta if (_rubbing and delta > 0.0) else 0.0
	_speed = lerpf(_speed, instant, clampf(delta * 12.0, 0.0, 1.0))
	_bruise = maxf(_bruise - delta, 0.0)
	if _rubbing:
		_rub(moved)
	queue_redraw()


func _rub(moved: float) -> void:
	if _bruise > 0.0:
		return
	if _speed > SPEED_LIMIT:
		_bruise = BRUISE_TIME
		_mistake("MG_LEAF_TOO_HARD")
		return
	for stain: Dictionary in _stains:
		if float(stain["dirt"]) <= 0.0:
			continue
		if _brush.distance_to(stain["pos"]) > float(stain["radius"]) + BRUSH_RADIUS * 0.5:
			continue
		stain["dirt"] = maxf(float(stain["dirt"]) - moved / float(stain["need"]), 0.0)
		if float(stain["dirt"]) <= 0.0:
			_on_cleaned(stain)


func _on_cleaned(stain: Dictionary) -> void:
	AudioManager.play_move()
	_sparkles.append({"pos": stain["pos"], "t": 0.0})
	_report()
	var left: Array[Dictionary] = _stains.filter(func(s: Dictionary) -> bool: return float(s["dirt"]) > 0.0)
	if left.is_empty():
		_complete()
		return
	var only_faint: bool = left.all(func(s: Dictionary) -> bool: return s["kind"] == "faint")
	if only_faint and not _faint_hint_shown:
		_faint_hint_shown = true
		_say("MG_LEAF_FAINT_LEFT")


func _report() -> void:
	var cleaned: int = _stains.filter(func(s: Dictionary) -> bool: return float(s["dirt"]) <= 0.0).size()
	_report_progress(tr("MG_LEAF_PROGRESS").format([cleaned, _stains.size()]))


func _update_sparkles(delta: float) -> void:
	for sparkle: Dictionary in _sparkles:
		sparkle["t"] = float(sparkle["t"]) + delta
	_sparkles = _sparkles.filter(func(s: Dictionary) -> bool: return float(s["t"]) < 0.6)


# ── 잎과 얼룩 만들기 ──────────────────────────────────────────────────

## t(0=잎자루 쪽, 1=잎끝)에서 잎 폭의 절반.
func _half_width(t: float) -> float:
	return LEAF_HALF_WIDTH * pow(sin(PI * clampf(t, 0.0, 1.0)), 0.8)


func _leaf_x(t: float) -> float:
	return LEAF_CENTER.x - LEAF_LENGTH * 0.5 + LEAF_LENGTH * t


func _build_leaf() -> PackedVector2Array:
	var points := PackedVector2Array()
	for i: int in LEAF_STEPS + 1:
		var t: float = float(i) / float(LEAF_STEPS)
		points.append(Vector2(_leaf_x(t), LEAF_CENTER.y - _half_width(t)))
	for i: int in range(LEAF_STEPS - 1, 0, -1):
		var t: float = float(i) / float(LEAF_STEPS)
		points.append(Vector2(_leaf_x(t), LEAF_CENTER.y + _half_width(t)))
	return points


func _place_stains() -> void:
	var kinds: Array[String] = []
	for i: int in STAIN_COUNT:
		kinds.append("sticky" if i < STICKY_COUNT else "normal")
	for i: int in FAINT_COUNT:
		kinds.append("faint")
	for kind: String in kinds:
		var radius: float = randf_range(30.0, 38.0) if kind == "faint" else randf_range(36.0, 50.0)
		var need: float = RUB_NORMAL
		if kind == "sticky":
			need = RUB_STICKY
		elif kind == "faint":
			need = RUB_FAINT
		_stains.append({
			"pos": _random_spot(),
			"radius": radius,
			"dirt": 1.0,
			"need": need,
			"kind": kind,
			"blobs": _make_blobs(radius),
		})


func _random_spot() -> Vector2:
	var spot: Vector2 = LEAF_CENTER
	for attempt: int in 80:
		var t: float = randf_range(0.14, 0.86)
		var reach: float = _half_width(t) * 0.68
		spot = Vector2(_leaf_x(t), LEAF_CENTER.y + randf_range(-reach, reach))
		var clear: bool = true
		for stain: Dictionary in _stains:
			if spot.distance_to(stain["pos"]) < STAIN_GAP:
				clear = false
				break
		if clear:
			return spot
	return spot


func _make_blobs(radius: float) -> Array[Dictionary]:
	var blobs: Array[Dictionary] = []
	for i: int in randi_range(4, 6):
		blobs.append({
			"offset": Vector2.from_angle(randf() * TAU) * randf_range(0.0, radius * 0.5),
			"radius": randf_range(radius * 0.35, radius * 0.6),
		})
	return blobs


# ── 그리기 ────────────────────────────────────────────────────────────

func _draw() -> void:
	var hurt: float = _bruise / BRUISE_TIME
	var stem_start := Vector2(_leaf_x(0.0) - 70.0, LEAF_CENTER.y + 26.0)
	draw_line(stem_start, Vector2(_leaf_x(0.0), LEAF_CENTER.y), LEAF_EDGE, 12.0, true)
	draw_colored_polygon(_leaf, LEAF_COLOR.lerp(LEAF_HURT, hurt * 0.7))
	var outline := _leaf.duplicate()
	outline.append(_leaf[0])
	draw_polyline(outline, LEAF_EDGE, 4.0, true)
	_draw_veins()

	for stain: Dictionary in _stains:
		_draw_stain(stain)
	for sparkle: Dictionary in _sparkles:
		_draw_sparkle(sparkle)
	_draw_brush()
	_draw_gauge()


func _draw_veins() -> void:
	draw_line(Vector2(_leaf_x(0.0), LEAF_CENTER.y), Vector2(_leaf_x(0.97), LEAF_CENTER.y), VEIN_COLOR, 5.0, true)
	var t: float = 0.12
	while t < 0.86:
		var root := Vector2(_leaf_x(t), LEAF_CENTER.y)
		var reach: float = _half_width(t + 0.08) * 0.78
		draw_line(root, Vector2(_leaf_x(t + 0.08), LEAF_CENTER.y - reach), VEIN_COLOR, 3.0, true)
		draw_line(root, Vector2(_leaf_x(t + 0.08), LEAF_CENTER.y + reach), VEIN_COLOR, 3.0, true)
		t += 0.09


func _draw_stain(stain: Dictionary) -> void:
	var dirt: float = float(stain["dirt"])
	if dirt <= 0.0:
		return
	var kind: String = String(stain["kind"])
	var base_alpha: float = 0.85
	var color: Color = DIRT_COLOR
	if kind == "sticky":
		base_alpha = 0.95
		color = STICKY_COLOR
	elif kind == "faint":
		base_alpha = 0.26
	var alpha: float = base_alpha * (0.25 + 0.75 * dirt)
	var shrink: float = 0.6 + 0.4 * dirt
	var center: Vector2 = stain["pos"]
	for blob: Dictionary in stain["blobs"]:
		draw_circle(center + (blob["offset"] as Vector2) * shrink, float(blob["radius"]) * shrink, Color(color, alpha))
	if kind == "sticky":
		draw_circle(center + Vector2(-8.0, -9.0) * shrink, 7.0 * shrink, Color(1.0, 1.0, 1.0, 0.22 * dirt))


func _draw_sparkle(sparkle: Dictionary) -> void:
	var t: float = float(sparkle["t"]) / 0.6
	var center: Vector2 = sparkle["pos"]
	var reach: float = lerpf(12.0, 46.0, t)
	var color := Color(1.0, 1.0, 0.86, 1.0 - t)
	for i: int in 4:
		var direction: Vector2 = Vector2.from_angle(TAU * float(i) / 4.0 + PI * 0.25)
		draw_line(center + direction * reach * 0.4, center + direction * reach, color, 3.0, true)


func _draw_brush() -> void:
	var color: Color = COLOR_BAD if _bruise > 0.0 else Color(1.0, 1.0, 1.0, 0.75)
	if _rubbing:
		draw_circle(_brush, BRUSH_RADIUS, Color(color, 0.18))
	draw_arc(_brush, BRUSH_RADIUS, 0.0, TAU, 40, color, 3.0, true)


## 문지르는 힘(속도) 게이지. 초록 칸 안에서 문지르면 된다.
func _draw_gauge() -> void:
	var rect: Rect2 = GAUGE_RECT
	var safe_height: float = rect.size.y * SAFE_RATIO
	draw_rect(Rect2(rect.position.x, rect.end.y - safe_height, rect.size.x, safe_height), Color(COLOR_GOOD, 0.18))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y - safe_height)), Color(COLOR_BAD, 0.22))
	var ratio: float = clampf(_speed / SPEED_LIMIT, 0.0, 1.0)
	var fill_color: Color = COLOR_GOOD if ratio < SAFE_RATIO else (COLOR_WARN if ratio < 1.0 else COLOR_BAD)
	var fill_height: float = rect.size.y * ratio
	draw_rect(Rect2(rect.position.x, rect.end.y - fill_height, rect.size.x, fill_height), fill_color)
	draw_rect(rect, Color(COLOR_TEXT, 0.5), false, 2.0)
	_draw_text_centered(tr("MG_LEAF_FORCE"), Vector2(rect.get_center().x, rect.position.y - 24.0), 22, COLOR_TEXT)
