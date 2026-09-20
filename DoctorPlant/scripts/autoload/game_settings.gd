extends Node
## 사용자 설정(음량·화면·언어·텍스트)을 보관하고 user://settings.cfg 에 저장한다.
## 타이틀 설정 창과 일시정지 설정 창이 같은 인스턴스를 공유한다.

signal settings_changed
signal text_speed_changed(chars_per_second: float)
signal text_size_changed(font_size: int)

const SETTINGS_PATH: String = "user://settings.cfg"

enum WindowMode { WINDOWED, BORDERLESS, EXCLUSIVE }

## 창 크기 후보. 렌더 해상도는 project.godot 의 1920x1080 으로 고정이고
## 화면 비율도 16:9 로 고정이라(stretch: canvas_items / keep),
## 이 값은 "창을 얼마나 크게 띄울지"만 결정한다.
## 모니터보다 큰 값은 목록에서 빠진다(창이 화면 밖으로 나가는 것을 막는다).
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

const TEXT_SIZES: Array[int] = [18, 22, 28]
const TEXT_SIZE_KEYS: Array[String] = ["TEXT_SIZE_SMALL", "TEXT_SIZE_NORMAL", "TEXT_SIZE_LARGE"]

## 텍스트 속도: 초당 글자 수. 최대값이면 즉시 출력으로 취급한다.
const TEXT_SPEED_MIN: float = 5.0
const TEXT_SPEED_MAX: float = 120.0

const DEFAULTS: Dictionary = {
	"bgm_volume": 0.8,
	"sfx_volume": 0.8,
	"window_mode": WindowMode.WINDOWED,
	"resolution_index": 2,
	"locale": "ko",
	"text_speed": 40.0,
	"text_size_index": 1,
}

var bgm_volume: float = DEFAULTS["bgm_volume"]
var sfx_volume: float = DEFAULTS["sfx_volume"]
var window_mode: int = DEFAULTS["window_mode"]
var resolution_index: int = DEFAULTS["resolution_index"]
var locale: String = DEFAULTS["locale"]
var text_speed: float = DEFAULTS["text_speed"]
var text_size_index: int = DEFAULTS["text_size_index"]

func _ready() -> void:
	load_settings()
	_clamp_resolution_to_screen()
	apply_all()


func text_size() -> int:
	return TEXT_SIZES[clampi(text_size_index, 0, TEXT_SIZES.size() - 1)]


func resolution() -> Vector2i:
	return RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]


## 지금 쓰는 모니터 크기.
func screen_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(1920, 1080)
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


## 창을 띄울 수 있는 영역(작업 표시줄 제외).
func usable_screen_rect() -> Rect2i:
	if DisplayServer.get_name() == "headless":
		return Rect2i(0, 0, 1920, 1080)
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())


## 지금 모니터에 들어가는 창 크기인지. 가장 작은 값은 항상 남겨 둔다.
func is_resolution_available(index: int) -> bool:
	if index == 0:
		return true
	var size: Vector2i = RESOLUTIONS[clampi(index, 0, RESOLUTIONS.size() - 1)]
	var screen: Vector2i = screen_size()
	return size.x <= screen.x and size.y <= screen.y


## 목록에 띄울 창 크기들.
func available_resolution_indices() -> PackedInt32Array:
	var indices := PackedInt32Array()
	for i: int in RESOLUTIONS.size():
		if is_resolution_available(i):
			indices.append(i)
	return indices


## 저장된 값이 지금 모니터에 안 맞으면 들어가는 것 중 가장 큰 값으로 낮춘다.
func _clamp_resolution_to_screen() -> void:
	if is_resolution_available(resolution_index):
		return
	var indices: PackedInt32Array = available_resolution_indices()
	resolution_index = indices[indices.size() - 1] if indices.size() > 0 else 0


func is_text_instant() -> bool:
	return text_speed >= TEXT_SPEED_MAX


## 한 글자를 찍는 데 걸리는 시간(초). 즉시 출력이면 0.
func seconds_per_char() -> float:
	if is_text_instant():
		return 0.0
	return 1.0 / maxf(text_speed, 1.0)


# ── 적용 ──────────────────────────────────────────────────────────────

func apply_all() -> void:
	apply_audio()
	apply_display()
	apply_locale()
	apply_text()
	settings_changed.emit()


func apply_audio() -> void:
	_set_bus_volume("BGM", bgm_volume)
	_set_bus_volume("SFX", sfx_volume)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		push_warning("오디오 버스를 찾을 수 없다: %s" % bus_name)
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match window_mode:
		WindowMode.BORDERLESS:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		WindowMode.EXCLUSIVE:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			_clamp_resolution_to_screen()
			var size: Vector2i = resolution()
			DisplayServer.window_set_size(size)
			var usable: Rect2i = usable_screen_rect()
			var offset := Vector2i((Vector2(usable.size) - Vector2(size)) * 0.5)
			# 창이 화면보다 크면 offset 이 음수가 되어 제목 표시줄이 화면 밖으로 나간다.
			DisplayServer.window_set_position(usable.position + offset.max(Vector2i.ZERO))


func apply_locale() -> void:
	TranslationServer.set_locale(locale)


## 텍스트 크기는 UI 전체가 아니라 대사 텍스트(DialogueLabel)에만 적용한다.
## 메뉴 레이아웃이 글자 크기에 따라 흔들리는 것을 막기 위함이다.
func apply_text() -> void:
	text_size_changed.emit(text_size())
	text_speed_changed.emit(text_speed)


# ── 값 변경 API (설정 창에서 호출) ────────────────────────────────────

func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_audio()
	settings_changed.emit()


func set_window_mode(mode: int) -> void:
	window_mode = clampi(mode, 0, int(WindowMode.EXCLUSIVE))
	apply_display()
	settings_changed.emit()


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	_clamp_resolution_to_screen()
	apply_display()
	settings_changed.emit()


func set_locale(code: String) -> void:
	locale = code
	apply_locale()
	settings_changed.emit()


func set_text_speed(value: float) -> void:
	text_speed = clampf(value, TEXT_SPEED_MIN, TEXT_SPEED_MAX)
	text_speed_changed.emit(text_speed)
	settings_changed.emit()


func set_text_size_index(index: int) -> void:
	text_size_index = clampi(index, 0, TEXT_SIZES.size() - 1)
	apply_text()
	settings_changed.emit()


func reset_to_defaults() -> void:
	bgm_volume = DEFAULTS["bgm_volume"]
	sfx_volume = DEFAULTS["sfx_volume"]
	window_mode = DEFAULTS["window_mode"]
	resolution_index = DEFAULTS["resolution_index"]
	locale = DEFAULTS["locale"]
	text_speed = DEFAULTS["text_speed"]
	text_size_index = DEFAULTS["text_size_index"]
	apply_all()
	save_settings()


# ── 저장 / 불러오기 ───────────────────────────────────────────────────

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "resolution_index", resolution_index)
	config.set_value("text", "locale", locale)
	config.set_value("text", "text_speed", text_speed)
	config.set_value("text", "text_size_index", text_size_index)
	var err: int = config.save(SETTINGS_PATH)
	if err != OK:
		push_warning("설정 저장 실패: %d" % err)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	bgm_volume = float(config.get_value("audio", "bgm_volume", DEFAULTS["bgm_volume"]))
	sfx_volume = float(config.get_value("audio", "sfx_volume", DEFAULTS["sfx_volume"]))
	window_mode = int(config.get_value("display", "window_mode", DEFAULTS["window_mode"]))
	resolution_index = int(config.get_value("display", "resolution_index", DEFAULTS["resolution_index"]))
	locale = String(config.get_value("text", "locale", DEFAULTS["locale"]))
	text_speed = float(config.get_value("text", "text_speed", DEFAULTS["text_speed"]))
	text_size_index = int(config.get_value("text", "text_size_index", DEFAULTS["text_size_index"]))
