extends Minigame
## 불안 피하기. 언더테일 전투처럼 상자 안에서 씨앗을 움직여 쏟아지는 불안을 피한다.
## 세 구간(가시 비 → 걱정 벌레 → 불안 포자)을 차례로 버티면 끝난다.
## 한 구간에서 MAX_ANXIETY 번 맞으면 그 구간을 처음부터 다시 버틴다.

const ARENA_RECT: Rect2 = Rect2(300.0, 130.0, 520.0, 380.0)
const SEED_RADIUS: float = 10.0
## 맞았는지 볼 때는 겉모습보다 작게 잡는다(스쳤는데 맞았다는 억울함을 줄인다).
const HIT_RADIUS: float = 6.0
const SEED_SPEED: float = 330.0
const PHASES: Array[String] = ["thorns", "bugs", "spores"]
const PHASE_TIME: float = 6.0
const MAX_ANXIETY: int = 3
const INVULNERABLE_TIME: float = 1.0
## 상자 밖으로 이만큼 나간 탄은 지운다.
const MARGIN: float = 40.0
## 조준 포자는 씨앗과 이만큼 떨어진 테두리에서만 나온다.
const SPORE_MIN_DISTANCE: float = 170.0

const ARENA_COLOR: Color = Color(0.02, 0.03, 0.03)
const SEED_COLOR: Color = Color(0.6, 0.83, 0.5)
const THORN_COLOR: Color = Color(0.92, 0.42, 0.5)
const BUG_COLOR: Color = Color(0.58, 0.45, 0.76)
const SPORE_COLOR: Color = Color(0.8, 0.76, 0.88)

var _arena: Control = null
var _seed: Vector2 = Vector2.ZERO
var _bullets: Array[Dictionary] = []
var _spawn_timers: Dictionary = {}
var _phase: int = 0
var _phase_time: float = 0.0
var _anxiety: int = 0
var _invulnerable: float = 0.0
var _shake: float = 0.0
var _time: float = 0.0
var _percent: int = -1


func _setup() -> void:
	_arena = Control.new()
	_arena.name = "Arena"
	_arena.position = ARENA_RECT.position
	_arena.size = ARENA_RECT.size
	_arena.clip_contents = true
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.draw.connect(_draw_arena)
	add_child(_arena)
	_seed = ARENA_RECT.size * 0.5
	_report(0)


func _process(delta: float) -> void:
	_time += delta
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_shake = maxf(_shake - delta * 3.0, 0.0)
	if active:
		_move_seed(delta)
		_phase_time += delta
		_spawn(delta)
		if _phase_time >= PHASE_TIME:
			_next_phase()
	_move_bullets(delta)
	if active:
		_check_hits()
	var total: float = PHASE_TIME * PHASES.size()
	_report(int(clampf((_phase * PHASE_TIME + _phase_time) / total, 0.0, 1.0) * 100.0))
	_arena.position = ARENA_RECT.position + Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 8.0 * _shake
	queue_redraw()
	_arena.queue_redraw()


func _next_phase() -> void:
	if _phase >= PHASES.size() - 1:
		_phase_time = PHASE_TIME
		_complete()
		return
	_phase += 1
	_phase_time = 0.0
	_spawn_timers.clear()


func _move_seed(delta: float) -> void:
	var motion: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down") * SEED_SPEED
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to_mouse: Vector2 = _arena.get_local_mouse_position() - _seed
		if to_mouse.length() > 1.0:
			motion = to_mouse.normalized() * minf(SEED_SPEED, to_mouse.length() / delta)
	_seed += motion * delta
	var edge := Vector2(SEED_RADIUS, SEED_RADIUS)
	_seed = _seed.clamp(edge, ARENA_RECT.size - edge)


# ── 탄 ────────────────────────────────────────────────────────────────

func _spawn(delta: float) -> void:
	match PHASES[_phase]:
		"thorns":
			_every("thorn", 0.2, delta, _spawn_thorn)
		"bugs":
			_every("bug", 0.5, delta, _spawn_bug)
			_every("thorn", 0.7, delta, _spawn_thorn)
		"spores":
			_every("spore", 0.45, delta, _spawn_spore)
			_every("thorn", 0.9, delta, _spawn_thorn)


func _every(key: String, interval: float, delta: float, spawner: Callable) -> void:
	var left: float = float(_spawn_timers.get(key, 0.0)) - delta
	if left <= 0.0:
		spawner.call()
		left += interval
	_spawn_timers[key] = left


## 가시 비: 위에서 떨어진다.
func _spawn_thorn() -> void:
	_bullets.append({
		"kind": "thorn",
		"pos": Vector2(randf_range(12.0, ARENA_RECT.size.x - 12.0), -12.0),
		"vel": Vector2(0.0, randf_range(240.0, 330.0)),
		"r": 8.0,
		"age": 0.0,
	})


## 걱정 벌레: 양옆에서 꿈틀대며 가로지른다.
func _spawn_bug() -> void:
	var from_left: bool = randf() < 0.5
	var y: float = randf_range(30.0, ARENA_RECT.size.y - 30.0)
	_bullets.append({
		"kind": "bug",
		"pos": Vector2(-16.0 if from_left else ARENA_RECT.size.x + 16.0, y),
		"vel": Vector2(210.0 if from_left else -210.0, 0.0),
		"base_y": y,
		"wiggle": randf() * TAU,
		"r": 12.0,
		"age": 0.0,
	})


## 불안 포자: 테두리에서 나와 씨앗이 있던 자리로 날아간다.
func _spawn_spore() -> void:
	var from: Vector2 = _border_point()
	for attempt: int in 8:
		if from.distance_to(_seed) >= SPORE_MIN_DISTANCE:
			break
		from = _border_point()
	_bullets.append({
		"kind": "spore",
		"pos": from,
		"vel": (_seed - from).normalized() * 230.0,
		"r": 10.0,
		"age": 0.0,
	})


func _border_point() -> Vector2:
	var w: float = ARENA_RECT.size.x
	var h: float = ARENA_RECT.size.y
	match randi() % 4:
		0:
			return Vector2(randf() * w, 0.0)
		1:
			return Vector2(randf() * w, h)
		2:
			return Vector2(0.0, randf() * h)
	return Vector2(w, randf() * h)


func _move_bullets(delta: float) -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, ARENA_RECT.size).grow(MARGIN)
	for bullet: Dictionary in _bullets:
		bullet["age"] = float(bullet["age"]) + delta
		var pos: Vector2 = bullet["pos"] + (bullet["vel"] as Vector2) * delta
		if bullet["kind"] == "bug":
			pos.y = float(bullet["base_y"]) + sin(float(bullet["age"]) * 5.0 + float(bullet["wiggle"])) * 22.0
		bullet["pos"] = pos
	_bullets = _bullets.filter(func(b: Dictionary) -> bool: return bounds.has_point(b["pos"]))


func _check_hits() -> void:
	if _invulnerable > 0.0:
		return
	for bullet: Dictionary in _bullets:
		if _seed.distance_to(bullet["pos"]) < float(bullet["r"]) + HIT_RADIUS:
			_on_hit()
			return


func _on_hit() -> void:
	_anxiety += 1
	_invulnerable = INVULNERABLE_TIME
	_shake = 1.0
	if _anxiety < MAX_ANXIETY:
		_mistake("MG_DODGE_HIT")
		return
	# 불안이 가득 찼다. 이 구간을 처음부터 다시 버틴다.
	_mistake("MG_DODGE_RESET")
	_anxiety = 0
	_phase_time = 0.0
	_bullets.clear()
	_spawn_timers.clear()
	_invulnerable = INVULNERABLE_TIME * 1.2


func _report(percent: int) -> void:
	if percent == _percent:
		return
	_percent = percent
	_report_progress(tr("MG_DODGE_PROGRESS").format([percent]))


# ── 그리기 ────────────────────────────────────────────────────────────

func _draw() -> void:
	var box := Rect2(_arena.position, ARENA_RECT.size)
	draw_rect(box, ARENA_COLOR)
	draw_rect(box.grow(2.0), Color.WHITE, false, 4.0)

	# 버틴 시간
	var bar := Rect2(ARENA_RECT.position.x, ARENA_RECT.position.y - 40.0, ARENA_RECT.size.x, 14.0)
	draw_rect(bar, Color(1.0, 1.0, 1.0, 0.1))
	var total: float = PHASE_TIME * PHASES.size()
	var ratio: float = clampf((_phase * PHASE_TIME + _phase_time) / total, 0.0, 1.0)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), COLOR_GOOD)
	for i: int in range(1, PHASES.size()):
		var x: float = bar.position.x + bar.size.x * float(i) / float(PHASES.size())
		draw_line(Vector2(x, bar.position.y - 4.0), Vector2(x, bar.end.y + 4.0), COLOR_DIM, 2.0)

	# 불안 게이지
	var row_y: float = ARENA_RECT.end.y + 44.0
	var label_x: float = ARENA_RECT.get_center().x - 90.0
	_draw_text_centered(tr("MG_DODGE_ANXIETY"), Vector2(label_x, row_y), 24, COLOR_TEXT)
	for i: int in MAX_ANXIETY:
		var center := Vector2(label_x + 80.0 + 44.0 * float(i), row_y)
		if i < _anxiety:
			draw_circle(center, 14.0, COLOR_BAD)
		else:
			draw_arc(center, 13.0, 0.0, TAU, 32, COLOR_DIM, 3.0, true)


func _draw_arena() -> void:
	for bullet: Dictionary in _bullets:
		match String(bullet["kind"]):
			"thorn":
				_draw_thorn(bullet)
			"bug":
				_draw_bug(bullet)
			"spore":
				_draw_spore(bullet)
	_draw_seed()


func _draw_thorn(bullet: Dictionary) -> void:
	var pos: Vector2 = bullet["pos"]
	var r: float = float(bullet["r"])
	_arena.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0.0, r + 6.0),
		pos + Vector2(-r * 0.8, -r),
		pos + Vector2(r * 0.8, -r),
	]), THORN_COLOR)


func _draw_bug(bullet: Dictionary) -> void:
	var pos: Vector2 = bullet["pos"]
	var r: float = float(bullet["r"])
	var heading: float = signf((bullet["vel"] as Vector2).x)
	var step: float = sin(float(bullet["age"]) * 18.0) * 4.0
	for i: int in 3:
		var x: float = pos.x + (float(i) - 1.0) * r * 0.6
		_arena.draw_line(Vector2(x, pos.y), Vector2(x - step, pos.y - r - 5.0), BUG_COLOR, 2.0)
		_arena.draw_line(Vector2(x, pos.y), Vector2(x + step, pos.y + r + 5.0), BUG_COLOR, 2.0)
	_arena.draw_circle(pos, r, BUG_COLOR)
	_arena.draw_circle(pos + Vector2(heading * r * 0.95, 0.0), r * 0.55, BUG_COLOR.darkened(0.3))


func _draw_spore(bullet: Dictionary) -> void:
	var pos: Vector2 = bullet["pos"]
	var r: float = float(bullet["r"])
	var spin: float = float(bullet["age"]) * 4.0
	for i: int in 6:
		var direction: Vector2 = Vector2.from_angle(spin + TAU * float(i) / 6.0)
		_arena.draw_line(pos + direction * r * 0.6, pos + direction * (r + 6.0), SPORE_COLOR, 2.0)
	_arena.draw_circle(pos, r * 0.75, SPORE_COLOR)


func _draw_seed() -> void:
	if _invulnerable > 0.0 and fmod(_time * 12.0, 2.0) < 1.0:
		return
	_arena.draw_line(_seed + Vector2(0.0, -SEED_RADIUS), _seed + Vector2(0.0, -SEED_RADIUS - 8.0), SEED_COLOR, 2.5)
	_arena.draw_circle(_seed + Vector2(4.0, -SEED_RADIUS - 8.0), 4.0, SEED_COLOR)
	_arena.draw_set_transform(_seed, 0.0, Vector2(0.82, 1.0))
	_arena.draw_circle(Vector2.ZERO, SEED_RADIUS, Color(0.83, 0.66, 0.4))
	_arena.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
