extends Minigame
## 알약 분류. 컨베이어로 내려오는 알약을 맨 아래 것부터 세 바구니에 나눈다.
## 둥근 알약은 왼쪽, 캡슐은 오른쪽, 금 간 알약은 모양과 상관없이 폐기(아래).
## GOAL 개를 맞게 나누면 끝난다. 잘못 넣거나 놓치면 실수로 세고 개수에 넣지 않는다.

const GOAL: int = 14
const CRACK_CHANCE: float = 0.3
## 맞게 나눈 개수에 따라 점점 빨라진다(처음 → 끝).
const SPAWN_INTERVAL: Vector2 = Vector2(1.0, 0.7)
const FALL_SPEED: Vector2 = Vector2(150.0, 215.0)
const FLY_TIME: float = 0.25
const DROP_TIME: float = 0.5

const CHUTE_RECT: Rect2 = Rect2(470.0, 0.0, 180.0, 430.0)
const SPAWN_Y: float = -30.0
const BINS: Dictionary = {
	"left": Rect2(40.0, 452.0, 340.0, 168.0),
	"trash": Rect2(420.0, 472.0, 280.0, 148.0),
	"right": Rect2(740.0, 452.0, 340.0, 168.0),
}
const BIN_LABELS: Dictionary = {
	"left": "MG_PILL_BIN_ROUND",
	"trash": "MG_PILL_BIN_TRASH",
	"right": "MG_PILL_BIN_CAPSULE",
}
const KEY_BINS: Array[Array] = [["move_left", "left"], ["move_right", "right"], ["move_down", "trash"]]
const PILL_COLORS: Array[Color] = [
	Color(0.96, 0.95, 0.9),
	Color(0.98, 0.88, 0.5),
	Color(0.96, 0.66, 0.74),
	Color(0.62, 0.8, 0.96),
]
const CRACK_COLOR: Color = Color(0.22, 0.17, 0.16, 0.95)
const CHUTE_COLOR: Color = Color(0.11, 0.15, 0.13)

var _pills: Array[Dictionary] = []
var _sorted: int = 0
var _spawn_left: float = 0.0
var _time: float = 0.0
var _flash: Dictionary = {}


func _setup() -> void:
	for bin: String in BINS.keys():
		_flash[bin] = {"t": 0.0, "ok": true}
	_report()


static func category_for(shape: String, cracked: bool) -> String:
	if cracked:
		return "trash"
	return "left" if shape == "round" else "right"


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	for pair: Array in KEY_BINS:
		if event.is_action_pressed(String(pair[0])):
			_sort(String(pair[1]))
			get_viewport().set_input_as_handled()
			return


func _gui_input(event: InputEvent) -> void:
	if not active:
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	for bin: String in BINS.keys():
		if (BINS[bin] as Rect2).has_point(click.position):
			_sort(bin)
			accept_event()
			return


func _process(delta: float) -> void:
	_time += delta
	var progress: float = float(_sorted) / float(GOAL)
	if active:
		_spawn_left -= delta
		if _spawn_left <= 0.0:
			_spawn()
			_spawn_left += lerpf(SPAWN_INTERVAL.x, SPAWN_INTERVAL.y, progress)
	var speed: float = lerpf(FALL_SPEED.x, FALL_SPEED.y, progress)
	for pill: Dictionary in _pills:
		_move_pill(pill, delta, speed)
	_pills = _pills.filter(func(p: Dictionary) -> bool: return p["state"] != "gone")
	for bin: String in _flash.keys():
		_flash[bin]["t"] = maxf(float(_flash[bin]["t"]) - delta * 2.5, 0.0)
	queue_redraw()


func _spawn() -> void:
	var color: Color = PILL_COLORS.pick_random()
	var second: Color = PILL_COLORS.pick_random()
	while second == color:
		second = PILL_COLORS.pick_random()
	_pills.append({
		"shape": "round" if randf() < 0.5 else "capsule",
		"cracked": randf() < CRACK_CHANCE,
		"color": color,
		"color2": second,
		"pos": Vector2(CHUTE_RECT.get_center().x + randf_range(-28.0, 28.0), SPAWN_Y),
		"state": "fall",
		"t": 0.0,
	})


func _move_pill(pill: Dictionary, delta: float, speed: float) -> void:
	match String(pill["state"]):
		"fall":
			pill["pos"] = (pill["pos"] as Vector2) + Vector2(0.0, speed * delta)
			if active and (pill["pos"] as Vector2).y > CHUTE_RECT.end.y:
				pill["state"] = "drop"
				pill["t"] = 0.0
				_mistake("MG_PILL_MISSED")
		"fly":
			pill["t"] = float(pill["t"]) + delta / FLY_TIME
			var eased: float = ease(clampf(float(pill["t"]), 0.0, 1.0), 0.5)
			pill["pos"] = (pill["from"] as Vector2).lerp(pill["to"], eased)
			if float(pill["t"]) >= 1.0:
				pill["state"] = "gone"
		"drop":
			pill["t"] = float(pill["t"]) + delta
			pill["pos"] = (pill["pos"] as Vector2) + Vector2(0.0, 320.0 * delta)
			if float(pill["t"]) >= DROP_TIME:
				pill["state"] = "gone"


## 아직 떨어지는 중인 알약 가운데 가장 아래 것.
func _front() -> Dictionary:
	var front: Dictionary = {}
	for pill: Dictionary in _pills:
		if pill["state"] != "fall":
			continue
		if front.is_empty() or (pill["pos"] as Vector2).y > (front["pos"] as Vector2).y:
			front = pill
	return front


func _sort(bin: String) -> void:
	var pill: Dictionary = _front()
	if pill.is_empty():
		return
	var ok: bool = category_for(String(pill["shape"]), bool(pill["cracked"])) == bin
	pill["state"] = "fly"
	pill["t"] = 0.0
	pill["from"] = pill["pos"]
	pill["to"] = (BINS[bin] as Rect2).get_center() + Vector2(randf_range(-40.0, 40.0), 26.0)
	_flash[bin] = {"t": 1.0, "ok": ok}
	if not ok:
		_mistake("MG_PILL_WRONG")
		return
	_sorted += 1
	AudioManager.play_move()
	_report()
	if _sorted >= GOAL:
		_complete()


func _report() -> void:
	_report_progress(tr("MG_PILL_PROGRESS").format([_sorted, GOAL]))


# ── 그리기 ────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_chute()
	for bin: String in BINS.keys():
		_draw_bin(bin)
	var front: Dictionary = _front()
	for pill: Dictionary in _pills:
		var alpha: float = 1.0
		if pill["state"] == "drop":
			alpha = 1.0 - float(pill["t"]) / DROP_TIME
		elif pill["state"] == "fly":
			alpha = 1.0 - clampf(float(pill["t"]) - 0.6, 0.0, 0.4) / 0.4
		_draw_pill(pill["pos"], String(pill["shape"]), bool(pill["cracked"]), pill["color"], pill["color2"], 1.0, alpha)
	if not front.is_empty() and active:
		var pulse: float = 0.6 + 0.4 * sin(_time * 8.0)
		draw_arc(front["pos"], 48.0, 0.0, TAU, 40, Color(COLOR_WARN, pulse), 3.0, true)


func _draw_chute() -> void:
	draw_rect(CHUTE_RECT, CHUTE_COLOR)
	var gap: float = 40.0
	var offset: float = fmod(_time * 60.0, gap)
	var y: float = CHUTE_RECT.position.y + offset
	while y < CHUTE_RECT.end.y:
		draw_line(Vector2(CHUTE_RECT.position.x, y), Vector2(CHUTE_RECT.end.x, y), Color(1.0, 1.0, 1.0, 0.05), 2.0)
		y += gap
	draw_line(CHUTE_RECT.position, Vector2(CHUTE_RECT.position.x, CHUTE_RECT.end.y), Color(COLOR_TEXT, 0.4), 4.0)
	draw_line(Vector2(CHUTE_RECT.end.x, CHUTE_RECT.position.y), CHUTE_RECT.end, Color(COLOR_TEXT, 0.4), 4.0)
	draw_line(Vector2(CHUTE_RECT.position.x, CHUTE_RECT.end.y), CHUTE_RECT.end, Color(COLOR_WARN, 0.6), 3.0)


func _draw_bin(bin: String) -> void:
	var rect: Rect2 = BINS[bin]
	var flash: Dictionary = _flash[bin]
	var tint: Color = COLOR_GOOD if bool(flash["ok"]) else COLOR_BAD
	draw_rect(rect, Color(1.0, 1.0, 1.0, 0.06).lerp(Color(tint, 0.35), float(flash["t"])))
	draw_rect(rect, Color(COLOR_TEXT, 0.45), false, 3.0)
	_draw_text_centered(tr(String(BIN_LABELS[bin])), Vector2(rect.get_center().x, rect.position.y + 30.0), 24, COLOR_TEXT)
	# 바구니에 들어갈 알약 견본
	var sample: Vector2 = rect.get_center() + Vector2(0.0, 26.0)
	var white: Color = PILL_COLORS[0]
	match bin:
		"left":
			_draw_pill(sample, "round", false, white, white, 0.8, 0.8)
		"right":
			_draw_pill(sample, "capsule", false, PILL_COLORS[2], PILL_COLORS[3], 0.8, 0.8)
		"trash":
			_draw_pill(sample + Vector2(-44.0, 0.0), "round", true, white, white, 0.7, 0.8)
			_draw_pill(sample + Vector2(40.0, 0.0), "capsule", true, PILL_COLORS[1], PILL_COLORS[2], 0.7, 0.8)


func _draw_pill(at: Vector2, shape: String, cracked: bool, color: Color, color2: Color, scale_factor: float, alpha: float) -> void:
	var grey := Color(0.62, 0.6, 0.56)
	var main: Color = Color(color.lerp(grey, 0.3) if cracked else color, alpha)
	var edge := Color(0.0, 0.0, 0.0, 0.35 * alpha)
	if shape == "round":
		var r: float = 22.0 * scale_factor
		draw_circle(at, r, main)
		draw_arc(at, r, 0.0, TAU, 32, edge, 2.0, true)
		draw_line(at + Vector2(-r * 0.6, 0.0), at + Vector2(r * 0.6, 0.0), Color(0.0, 0.0, 0.0, 0.18 * alpha), 2.0)
	else:
		var half: float = 22.0 * scale_factor
		var r: float = 16.0 * scale_factor
		var second: Color = Color(color2.lerp(grey, 0.3) if cracked else color2, alpha)
		draw_circle(at + Vector2(-half, 0.0), r, main)
		draw_rect(Rect2(at + Vector2(-half, -r), Vector2(half, r * 2.0)), main)
		draw_circle(at + Vector2(half, 0.0), r, second)
		draw_rect(Rect2(at + Vector2(0.0, -r), Vector2(half, r * 2.0)), second)
		draw_line(at + Vector2(0.0, -r), at + Vector2(0.0, r), edge, 2.0)
	if cracked:
		var s: float = scale_factor
		draw_polyline(PackedVector2Array([
			at + Vector2(-14.0, -12.0) * s,
			at + Vector2(-4.0, -3.0) * s,
			at + Vector2(-9.0, 4.0) * s,
			at + Vector2(3.0, 9.0) * s,
			at + Vector2(12.0, 14.0) * s,
		]), Color(CRACK_COLOR, CRACK_COLOR.a * alpha), 3.0 * s, true)
