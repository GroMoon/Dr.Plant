extends Control
class_name Minigame
## 진찰 미니게임 한 판의 공통 틀. 개별 미니게임은 이 클래스를 상속한다.
##
## MinigameHost 가 제목·안내를 띄우고 "준비"가 끝나면 begin() 을 부른다.
## 미니게임은 조건을 채우면 _complete() 를 부르고, 진행 상황과 알림은 시그널로 알린다.
## 게임 오버는 없다. 실수는 mistakes 로 세어 결과에 담는다.
## 요구사항: design/requirements/ch1/02-minigame.md

signal completed
signal progress_changed(text: String)
signal status_shown(text: String, good: bool)

## 모든 미니게임이 같은 크기의 판 위에서 돌아간다(1920×1080 화면 기준).
const BOARD_SIZE: Vector2 = Vector2(1120.0, 640.0)

const COLOR_TEXT: Color = Color(0.859, 0.902, 0.831)
const COLOR_DIM: Color = Color(0.859, 0.902, 0.831, 0.55)
const COLOR_GOOD: Color = Color(0.612, 0.827, 0.573)
const COLOR_WARN: Color = Color(0.937, 0.729, 0.325)
const COLOR_BAD: Color = Color(0.894, 0.42, 0.42)

## begin() 과 _complete() 사이에만 true. 이때만 입력·판정을 받는다.
var active: bool = false
var mistakes: int = 0


func _ready() -> void:
	custom_minimum_size = BOARD_SIZE
	size = BOARD_SIZE
	_setup()


func begin() -> void:
	if active:
		return
	active = true
	_on_begin()


## 판을 처음 그릴 준비. 노드가 트리에 들어간 뒤 한 번 불린다.
func _setup() -> void:
	pass


## "준비"가 끝나 플레이가 시작될 때 불린다.
func _on_begin() -> void:
	pass


func _complete() -> void:
	if not active:
		return
	active = false
	completed.emit()


func _report_progress(text: String) -> void:
	progress_changed.emit(text)


func _say(key: String, good: bool = true) -> void:
	status_shown.emit(tr(key), good)


func _mistake(key: String) -> void:
	mistakes += 1
	AudioManager.play_sfx(&"buzz")
	_say(key, false)


func _font() -> Font:
	return get_theme_font(&"font", &"Label")


func _draw_text_centered(text: String, center: Vector2, font_size: int, color: Color, target: CanvasItem = self) -> void:
	var font: Font = _font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline: float = center.y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	target.draw_string(font, Vector2(center.x - width * 0.5, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
