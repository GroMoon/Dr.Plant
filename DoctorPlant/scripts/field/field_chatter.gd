extends Node
class_name FieldChatter
## 필드에서 인물에게 다가가면 머리 위 말풍선으로 혼잣말을 중얼거리게 한다.
## 대사창과 달리 조작을 막지 않는다. 버튼 없이 가까이 서 있기만 하면 한 줄씩 이어서 말하고,
## 멀어지면 말풍선을 거둔다. 말풍선이 겹치지 않도록 가장 가까운 한 명만 말한다.
##
## 인물별 대사는 대본의 chatter_<NPC 이름> 구간이다(episode_player.gd 의 chatter 명령이 읽어 넘긴다).

const BUBBLE_SCENE: PackedScene = preload("res://scenes/ui/speech_bubble.tscn")

## 이 거리(월드 픽셀) 안으로 들어오면 말을 건다.
const TALK_RADIUS: float = 130.0
## 말하는 중에는 이 거리까지 벗어나야 멈춘다(경계에서 깜빡이지 않게).
const LEAVE_RADIUS: float = 180.0
## 필드가 막 시작됐을 때 바로 옆 인물이 곧장 떠들지 않도록 잠깐 기다린다.
const START_DELAY: float = 1.2
## 다 찍힌 한 줄을 보여주는 시간 = 기본 + 글자당 추가, 최소·최대 사이.
const HOLD_BASE: float = 1.2
const HOLD_PER_CHAR: float = 0.07
const HOLD_MIN: float = 1.6
const HOLD_MAX: float = 4.0
## 다음 줄로 넘어가기 전 쉬는 시간 / 한 바퀴 다 말한 뒤 쉬는 시간.
const LINE_GAP: float = 0.6
const ROUND_REST: float = 6.0
## 멀어진 뒤 말풍선이 남아 있는 시간 / 다시 말을 걸 수 있을 때까지의 시간.
const LINGER: float = 0.5
const LEAVE_REST: float = 1.0
## 인물마다 목소리 높이를 이 범위에서 고른다(이름으로 정해 매번 같다).
const PITCH_MIN: float = 0.82
const PITCH_MAX: float = 1.18
## 타이핑음은 이 거리까지는 제 크기로 들리고, 멀어질수록 줄어 SILENT 거리에서 사라진다.
const VOICE_FULL_RADIUS: float = 70.0
const VOICE_SILENT_RADIUS: float = 300.0
## 말풍선은 월드 위, 암전(FadeLayer)·전면 연출(ViewLayer) 아래에 그린다.
const BUBBLE_LAYER: int = 4

const STATE_IDLE: int = 0
const STATE_TYPING: int = 1
const STATE_HOLDING: int = 2
const STATE_RESTING: int = 3


class Speaker:
	var figure: Node2D
	var lines: PackedStringArray
	var bubble: SpeechBubble
	var pitch: float = 1.0
	var home_facing: String = ""
	var state: int = STATE_IDLE
	var timer: float = 0.0
	var index: int = 0


var _player: Node2D = null
var _layer: CanvasLayer = null
var _speakers: Array[Speaker] = []
var _focus: Speaker = null
var _listening: bool = false


## lines: 인물 노드 → 그 인물이 할 대사 키(대본 번역 키) 목록.
func setup(player: Node2D, lines: Dictionary) -> void:
	_player = player
	_layer = CanvasLayer.new()
	_layer.name = "BubbleLayer"
	_layer.layer = BUBBLE_LAYER
	add_child(_layer)
	for figure: Node2D in lines.keys():
		var ids: PackedStringArray = lines[figure]
		if ids.is_empty():
			continue
		var speaker := Speaker.new()
		speaker.figure = figure
		speaker.lines = ids
		speaker.pitch = _voice_pitch(String(figure.name))
		speaker.home_facing = (figure as PlantFigure).facing if figure is PlantFigure else ""
		speaker.bubble = BUBBLE_SCENE.instantiate()
		_layer.add_child(speaker.bubble)
		speaker.bubble.attach(figure, Vector2(0.0, _head_top(figure)))
		_speakers.append(speaker)


## 대사·선택지가 떠 있을 때는 끈다. 켜질 때마다 잠깐 뜸을 들인다.
func set_listening(on: bool) -> void:
	if _listening == on:
		return
	_listening = on
	_focus = null
	for speaker: Speaker in _speakers:
		speaker.bubble.dismiss()
		speaker.state = STATE_RESTING
		speaker.timer = START_DELAY if on else 0.0


## 말풍선을 거두고 스스로 사라진다.
func stop() -> void:
	set_listening(false)
	set_process(false)
	get_tree().create_timer(SpeechBubble.HIDE_TIME + 0.1).timeout.connect(queue_free)


func _process(delta: float) -> void:
	if not _listening or not is_instance_valid(_player):
		return
	_update_focus()
	for speaker: Speaker in _speakers:
		_step(speaker, delta)
		if speaker.bubble.is_typing():
			speaker.bubble.set_voice_gain(_voice_gain(speaker))


func _update_focus() -> void:
	if _focus != null and _can_talk(_focus) and _distance(_focus) <= LEAVE_RADIUS:
		return
	_focus = null
	var best: float = TALK_RADIUS
	for speaker: Speaker in _speakers:
		if not _can_talk(speaker):
			continue
		var distance: float = _distance(speaker)
		if distance < best:
			best = distance
			_focus = speaker


func _step(speaker: Speaker, delta: float) -> void:
	var near: bool = speaker == _focus
	match speaker.state:
		STATE_IDLE:
			if near:
				_speak(speaker)
			else:
				_face(speaker, speaker.home_facing)
		STATE_TYPING:
			if not speaker.bubble.is_typing():
				speaker.state = STATE_HOLDING
				speaker.timer = _hold_time(speaker.bubble)
		STATE_HOLDING:
			if not near:
				speaker.timer = minf(speaker.timer, LINGER)
			speaker.timer -= delta
			if speaker.timer <= 0.0:
				_finish_line(speaker, near)
		STATE_RESTING:
			if not near:
				speaker.timer = minf(speaker.timer, LEAVE_REST)
			speaker.timer -= delta
			if speaker.timer <= 0.0:
				speaker.state = STATE_IDLE


func _speak(speaker: Speaker) -> void:
	speaker.state = STATE_TYPING
	_face(speaker, _direction_to(speaker.figure.global_position, _player.global_position))
	var key: String = speaker.lines[speaker.index]
	speaker.bubble.say(tr(key, Localization.DIALOGUE_CONTEXT), speaker.pitch)


## 한 줄을 다 보여줬다. 다음 줄은 이어서, 한 바퀴를 다 돌았으면 좀 쉬었다가 처음부터.
func _finish_line(speaker: Speaker, near: bool) -> void:
	speaker.bubble.dismiss()
	speaker.index = (speaker.index + 1) % speaker.lines.size()
	speaker.state = STATE_RESTING
	if not near:
		speaker.timer = LEAVE_REST
	elif speaker.index == 0:
		speaker.timer = ROUND_REST
	else:
		speaker.timer = LINE_GAP


func _hold_time(bubble: SpeechBubble) -> float:
	var length: int = bubble.text().length()
	return clampf(HOLD_BASE + HOLD_PER_CHAR * length, HOLD_MIN, HOLD_MAX)


func _can_talk(speaker: Speaker) -> bool:
	return is_instance_valid(speaker.figure) and speaker.figure.is_visible_in_tree()


func _distance(speaker: Speaker) -> float:
	return speaker.figure.global_position.distance_to(_player.global_position)


## 말을 걸 때 플레이어 쪽을 돌아본다. 도형 인물(PlantFigure)만 방향이 있다.
func _face(speaker: Speaker, direction: String) -> void:
	if direction.is_empty() or not (speaker.figure is PlantFigure):
		return
	var figure := speaker.figure as PlantFigure
	if figure.facing != direction:
		figure.facing = direction


func _direction_to(from: Vector2, to: Vector2) -> String:
	var diff: Vector2 = to - from
	if absf(diff.x) > absf(diff.y):
		return "right" if diff.x > 0.0 else "left"
	return "down" if diff.y > 0.0 else "up"


## 꽃잎 머리 꼭대기보다 조금 위. 도형 인물이 아니면 대략의 키로 잡는다.
func _head_top(figure: Node2D) -> float:
	if figure is PlantFigure:
		return -58.0 * (figure as PlantFigure).figure_scale
	return -96.0


func _voice_pitch(figure_name: String) -> float:
	var ratio: float = float(absi(figure_name.hash()) % 1000) / 999.0
	return lerpf(PITCH_MIN, PITCH_MAX, ratio)
