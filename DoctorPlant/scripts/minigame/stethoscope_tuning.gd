extends Minigame
## 청진 주파수 맞추기. 슬라이더 두 개(음높이·크기)로 청진기 파형을 환자의 파형에 겹친다.
## 환자의 파형은 천천히 흔들리므로 맞춘 뒤에도 계속 따라가야 한다.
## 겹친 채로 LOCK_TIME 초를 채우면 끝난다. 벗어나면 게이지가 줄어든다.

const FREQ_MIN: float = 1.0
const FREQ_MAX: float = 6.0
const AMP_MIN: float = 0.15
const AMP_MAX: float = 1.0
## 이 차이 안쪽이면 겹친 것으로 본다.
const FREQ_TOLERANCE: float = 0.14
const AMP_TOLERANCE: float = 0.07
## 환자 파형이 흔들리는 폭.
const DRIFT_FREQ: float = 0.22
const DRIFT_AMP: float = 0.05
const LOCK_TIME: float = 1.8
const DRAIN_TIME: float = 1.2
const SCROLL_SPEED: float = 2.4
const SAMPLES: int = 160

const SCREEN_RECT: Rect2 = Rect2(60.0, 36.0, 1000.0, 360.0)
const GAUGE_RECT: Rect2 = Rect2(60.0, 414.0, 1000.0, 16.0)
const SLIDER_LEFT: float = 250.0
const SLIDER_ROWS: Array[float] = [492.0, 572.0]
const KNOB_SIZE: int = 34
const TARGET_COLOR: Color = Color(0.957, 0.561, 0.678)
const SCREEN_COLOR: Color = Color(0.039, 0.071, 0.059)

var _base_freq: float = 3.0
var _base_amp: float = 0.5
var _target_freq: float = 3.0
var _target_amp: float = 0.5
var _lock: float = 0.0
var _time: float = 0.0
var _percent: int = -1
var _pitch: HSlider = null
var _volume: HSlider = null


func _setup() -> void:
	_base_freq = randf_range(2.0, 5.0)
	_base_amp = randf_range(0.35, 0.8)
	_update_target()
	_pitch = _make_slider("MG_STETHO_PITCH", SLIDER_ROWS[0])
	_volume = _make_slider("MG_STETHO_VOLUME", SLIDER_ROWS[1])
	# 시작 값은 목표에서 충분히 떨어뜨린다.
	_pitch.value = _far_from(inverse_lerp(FREQ_MIN, FREQ_MAX, _base_freq))
	_volume.value = _far_from(inverse_lerp(AMP_MIN, AMP_MAX, _base_amp))
	_report(0)


func _on_begin() -> void:
	_pitch.editable = true
	_volume.editable = true
	_pitch.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	_update_target()
	if active:
		if is_matched():
			_lock += delta / LOCK_TIME
		else:
			_lock -= delta / DRAIN_TIME
		_lock = clampf(_lock, 0.0, 1.0)
		_report(int(_lock * 100.0))
		if _lock >= 1.0:
			_pitch.editable = false
			_volume.editable = false
			_complete()
	queue_redraw()


func is_matched() -> bool:
	return (
		absf(my_freq() - _target_freq) <= FREQ_TOLERANCE
		and absf(my_amp() - _target_amp) <= AMP_TOLERANCE
	)


func my_freq() -> float:
	return lerpf(FREQ_MIN, FREQ_MAX, _pitch.value)


func my_amp() -> float:
	return lerpf(AMP_MIN, AMP_MAX, _volume.value)


func _update_target() -> void:
	_target_freq = _base_freq + DRIFT_FREQ * sin(_time * 0.8)
	_target_amp = _base_amp + DRIFT_AMP * sin(_time * 1.1 + 1.3)


## 0 이면 멀고 1 이면 거의 겹쳤다. 청진기 파형 색에 쓴다.
func _closeness() -> float:
	var freq_gap: float = absf(my_freq() - _target_freq) / (FREQ_TOLERANCE * 4.0)
	var amp_gap: float = absf(my_amp() - _target_amp) / (AMP_TOLERANCE * 4.0)
	return 1.0 - clampf(maxf(freq_gap, amp_gap), 0.0, 1.0)


func _far_from(ratio: float) -> float:
	return ratio - 0.4 if ratio > 0.5 else ratio + 0.4


func _report(percent: int) -> void:
	if percent == _percent:
		return
	_percent = percent
	_report_progress(tr("MG_STETHO_PROGRESS").format([percent]))


# ── 그리기 ────────────────────────────────────────────────────────────

func _draw() -> void:
	draw_rect(SCREEN_RECT, SCREEN_COLOR)
	var grid: Color = Color(COLOR_GOOD, 0.08)
	for i: int in range(1, 10):
		var x: float = SCREEN_RECT.position.x + SCREEN_RECT.size.x * float(i) / 10.0
		draw_line(Vector2(x, SCREEN_RECT.position.y), Vector2(x, SCREEN_RECT.end.y), grid, 1.0)
	for j: int in range(1, 6):
		var y: float = SCREEN_RECT.position.y + SCREEN_RECT.size.y * float(j) / 6.0
		draw_line(Vector2(SCREEN_RECT.position.x, y), Vector2(SCREEN_RECT.end.x, y), grid, 1.0)

	var matched: bool = is_matched()
	_draw_wave(_target_freq, _target_amp, Color(TARGET_COLOR, 0.5), 14.0)
	var mine: Color = COLOR_DIM.lerp(COLOR_GOOD, _closeness())
	if matched:
		mine = Color(0.78, 1.0, 0.74)
	_draw_wave(my_freq(), my_amp(), mine, 3.5)
	draw_rect(SCREEN_RECT, Color(COLOR_GOOD, 0.35 if not matched else 0.8), false, 2.0)

	_draw_legend(Vector2(SCREEN_RECT.position.x + 24.0, SCREEN_RECT.position.y + 28.0), Color(TARGET_COLOR, 0.8), "MG_STETHO_PATIENT")
	_draw_legend(Vector2(SCREEN_RECT.position.x + 184.0, SCREEN_RECT.position.y + 28.0), COLOR_GOOD, "MG_STETHO_MINE")

	draw_rect(GAUGE_RECT, Color(1.0, 1.0, 1.0, 0.08))
	var fill := Rect2(GAUGE_RECT.position, Vector2(GAUGE_RECT.size.x * _lock, GAUGE_RECT.size.y))
	draw_rect(fill, COLOR_GOOD if matched else COLOR_WARN)


func _draw_wave(freq: float, amp: float, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	var half: float = SCREEN_RECT.size.y * 0.5 - 18.0
	var center_y: float = SCREEN_RECT.get_center().y
	for i: int in SAMPLES + 1:
		var ratio: float = float(i) / float(SAMPLES)
		var x: float = SCREEN_RECT.position.x + SCREEN_RECT.size.x * ratio
		var y: float = center_y - sin(TAU * freq * ratio - _time * SCROLL_SPEED) * amp * half
		points.append(Vector2(x, y))
	draw_polyline(points, color, width, true)


func _draw_legend(at: Vector2, color: Color, key: String) -> void:
	draw_line(at, at + Vector2(28.0, 0.0), color, 5.0)
	draw_string(_font(), at + Vector2(38.0, 8.0), tr(key), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COLOR_TEXT)


# ── 슬라이더 ──────────────────────────────────────────────────────────

func _make_slider(label_key: String, center_y: float) -> HSlider:
	var label := Label.new()
	label.text = tr(label_key)
	label.position = Vector2(SCREEN_RECT.position.x, center_y - 22.0)
	label.size = Vector2(SLIDER_LEFT - SCREEN_RECT.position.x - 20.0, 44.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	# 키보드·패드는 한 번에 step 만큼 움직인다. 허용 오차(약 3칸)보다 잘게 둔다.
	slider.step = 0.01
	slider.editable = false
	slider.position = Vector2(SLIDER_LEFT, center_y - 22.0)
	slider.size = Vector2(SCREEN_RECT.end.x - SLIDER_LEFT, 44.0)
	_style_slider(slider)
	add_child(slider)
	return slider


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1.0, 1.0, 1.0, 0.1)
	track.set_corner_radius_all(8)
	track.content_margin_top = 8.0
	track.content_margin_bottom = 8.0
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = Color(COLOR_GOOD, 0.7)
	var hot := track.duplicate() as StyleBoxFlat
	hot.bg_color = COLOR_GOOD
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", hot)
	slider.add_theme_icon_override("grabber", _circle_texture(KNOB_SIZE, COLOR_TEXT))
	slider.add_theme_icon_override("grabber_highlight", _circle_texture(KNOB_SIZE, Color.WHITE))
	slider.add_theme_icon_override("grabber_disabled", _circle_texture(KNOB_SIZE, COLOR_DIM))


static func _circle_texture(diameter: int, color: Color) -> ImageTexture:
	var image := Image.create_empty(diameter, diameter, false, Image.FORMAT_RGBA8)
	var radius: float = diameter * 0.5
	for y: int in diameter:
		for x: int in diameter:
			var distance: float = Vector2(x + 0.5, y + 0.5).distance_to(Vector2(radius, radius))
			# 가장자리 한 픽셀만 부드럽게 깎는다.
			var coverage: float = clampf(radius - distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(color, color.a * coverage))
	return ImageTexture.create_from_image(image)
