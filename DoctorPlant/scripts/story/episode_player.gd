extends Node2D
class_name EpisodePlayer
## 에피소드 진행기. 대본(.dialogue)을 start 부터 끝까지 실행한다.
##
## 대사·선택지는 Dialogue Manager 가 대본에서 한 줄씩 꺼내 주고,
## 화면 연출(방 전환·카메라·페이드·필드 조작·미니게임)은 대본의
## `$> stage.명령(...)` 줄이 이 노드의 공개 함수를 부른다(아래 "연출 명령" 절).
##
## 대사·연출·필드 이동·미니게임이 한 씬 안에서 이어지므로
## 장면마다 씬을 따로 만들지 않고 명령으로 전환한다.

const TITLE_SCENE: String = "res://scenes/title_screen.tscn"
const MINIGAME_SCENE: PackedScene = preload("res://scenes/ch1/minigame_diagnosis.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/field/field_player.tscn")

## 대본에서 방을 이름으로 부른다: stage.room("clinic")
const ROOMS: Dictionary = {
	"lobby": "res://scenes/field/room_lobby.tscn",
	"clinic": "res://scenes/field/room_clinic.tscn",
}
## 대본에서 전면 연출 씬을 이름으로 부른다: stage.view_open("sunbathing", 1.2)
const VIEWS: Dictionary = {
	"sunbathing": "res://scenes/ch1/sunbathing_view.tscn",
}
## 시간대 색조. 대본에서 stage.tint("morning", 초) 처럼 부른다.
const TINTS: Dictionary = {
	"morning": Color(1.0, 0.867, 0.616, 0.18),
	"afternoon": Color(1.0, 0.816, 0.475, 0.30),
	"evening": Color(0.184, 0.157, 0.341, 0.38),
}
## 필드에서 조사 지점을 조사하면 대본의 이 접두사 + 지점 id 구간을 실행한다.
const INSPECT_CUE_PREFIX: String = "inspect_"

const FOLLOW_ZOOM: float = 1.6

signal advance_requested

## 실행할 대본.
@export var dialogue: DialogueResource = null
## 대본에서 처음 실행할 구간.
@export var start_cue: String = "start"
## 저장 슬롯에 기록할 이 씬의 경로.
@export var scene_path: String = ""
## 저장 슬롯에 기록할 챕터 번호.
@export var chapter: int = 1
## 에피소드가 끝나면 갈 씬. 비우면 타이틀로 돌아간다.
@export var next_scene: String = ""

@onready var _world: Node2D = $World
@onready var _camera: Camera2D = $World/Camera
@onready var _dialogue: DialogueBox = $Ui/DialogueBox
@onready var _choices: ChoiceBox = $Ui/ChoiceBox
@onready var _prompt: Label = $Ui/InteractPrompt
@onready var _hint: Label = $Ui/FieldHint
@onready var _card: Control = $Ui/Card
@onready var _card_label: Label = $Ui/Card/Rows/CardLabel
@onready var _card_title: Label = $Ui/Card/Rows/CardTitle
@onready var _card_sub: Label = $Ui/Card/Rows/CardSub
@onready var _view_layer: CanvasLayer = $ViewLayer
@onready var _minigame_layer: CanvasLayer = $MinigameLayer
@onready var _fade: ColorRect = $FadeLayer/Fade
@onready var _pause_menu: CanvasLayer = $PauseMenu

var _room: FieldRoom = null
var _player: FieldPlayer = null
var _view: Node = null
var _minigame: Node = null
var _camera_follow: bool = false
var _field_active: bool = false
var _awaiting_advance: bool = false
## 대본에 넘겨주는 상태. 대본에서 `stage.` 으로 이 노드를 부른다.
var _states: Array = []


func _ready() -> void:
	_fade.color.a = 1.0
	_prompt.hide()
	_hint.hide()
	_card.hide()
	_states = [{"stage": self}]
	DialogueManager.mutated.connect(_on_dialogue_mutated)
	StoryState.load_from_slot(SaveSystem.current_slot)
	StoryState.chapter = chapter
	AudioManager.stop_bgm()
	_run()


func _process(delta: float) -> void:
	StoryState.playtime += delta


## 카메라 추적은 물리 프레임에서 한다. 렌더 프레임에서 따라가면
## 플레이어 갱신과 어긋나 화면이 떨린다.
func _physics_process(delta: float) -> void:
	if not (_camera_follow and is_instance_valid(_player)):
		return
	var target: Vector2 = _camera.global_position.lerp(
		_player.global_position, clampf(delta * 8.0, 0.0, 1.0)
	)
	_camera.global_position = target.round()


func _unhandled_input(event: InputEvent) -> void:
	if _pause_menu.is_open() or SceneRouter.is_busy() or _minigame != null:
		return
	if not event.is_action_pressed("advance"):
		return
	if _field_active:
		if _room != null and _room.try_interact():
			get_viewport().set_input_as_handled()
		return
	get_viewport().set_input_as_handled()
	if _dialogue.skip():
		return
	if _awaiting_advance:
		advance_requested.emit()


# ── 실행 ──────────────────────────────────────────────────────────────

func _run() -> void:
	if dialogue == null:
		push_error("실행할 대본이 지정되지 않았다.")
		return
	await _play(start_cue)
	await _leave()


## 대본의 cue 구간을 끝(=> END)까지 진행한다.
## 연출 명령은 Dialogue Manager 가 줄을 꺼내는 도중에 실행되고 끝날 때까지 기다린다.
func _play(cue: String) -> void:
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(dialogue, cue, _states)
	while line != null:
		var next_id: String = line.next_id
		if line.responses.is_empty():
			await _say(line)
		else:
			var response: DialogueResponse = await _choose(line)
			next_id = response.next_id
		line = await DialogueManager.get_next_dialogue_line(dialogue, next_id, _states)
	_dialogue.close()


func _say(line: DialogueLine) -> void:
	_dialogue.show_line(line)
	_awaiting_advance = true
	await advance_requested
	_awaiting_advance = false


func _choose(line: DialogueLine) -> DialogueResponse:
	_dialogue.close()
	_choices.open(line)
	var response: DialogueResponse = await _choices.chosen
	_choices.close()
	return response


## 대사 다음에 연출 명령이 오면 대사창을 닫는다.
## 대사가 끝났는데 창만 남아 있는 것을 막는다.
func _on_dialogue_mutated(mutation: Dictionary) -> void:
	if not bool(mutation.get("is_inline", false)):
		_dialogue.close()


# ── 연출 명령 ─────────────────────────────────────────────────────────
# 대본에서 `$> stage.명령(인자)` 로 부른다. 명령이 끝날 때까지 대본 진행이 멈춘다.
#
#   card(label, title, sub, 초)         장·에피소드 카드. 인자는 문자열 키, 안 쓰는 칸은 ""
#   room(방)                            필드 씬 교체. 방 이름은 ROOMS
#   player_at(위치) / player_hide()     플레이어 세우기(없으면 만든다) / 숨기기
#   tint(시간대, 초)                    방 전체 색조. 시간대는 TINTS
#   npc(id, 보임)                       방 안 NPC 표시/숨김
#   enable(조사지점 id, 켬)             조사 지점 켜고 끄기
#   cam_set(위치, 줌)                   카메라 즉시 이동
#   cam_move(위치, 초, 줌=유지)         카메라 이동 연출
#   cam_follow(켬, 줌)                  카메라가 플레이어를 따라감
#   fade_in(초) / fade_out(초)          암전 풀기 / 암전
#   sfx(id)                             효과음
#   amb_start(id, dB) / amb_stop(id)    반복 환경음
#   minigame(튜토리얼)                  진찰 미니게임
#   field(안내 키, 나가는 지점 id)      필드 조작 구간. 조사하면 inspect_<id> 구간 실행
#   view_open(연출, 초) / view_close(초)  전면 연출 씬. 연출 이름은 VIEWS
#   save(체크포인트)                    진행 저장
#
# 대기는 Dialogue Manager 내장 `$> wait(초)`, 플래그는 `$> StoryState.set_flag(이름, 값)`.

func card(label_key: String, title_key: String, sub_key: String, time: float = 2.0) -> void:
	_card_label.text = tr(label_key)
	_card_label.visible = not _card_label.text.is_empty()
	_card_title.text = tr(title_key)
	_card_title.visible = not _card_title.text.is_empty()
	_card_sub.text = tr(sub_key)
	_card_sub.visible = not _card_sub.text.is_empty()
	_card.modulate.a = 0.0
	_card.show()
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", 1.0, 0.6)
	await tween.finished
	await _sleep(time)
	var out := create_tween()
	out.tween_property(_card, "modulate:a", 0.0, 0.6)
	await out.finished
	_card.hide()


func room(room_id: String) -> void:
	var path: String = String(ROOMS.get(room_id, ""))
	if not ResourceLoader.exists(path):
		push_error("필드 씬을 찾을 수 없다: %s" % room_id)
		return
	_clear_room()
	var packed: PackedScene = load(path)
	_room = packed.instantiate()
	_world.add_child(_room)
	_world.move_child(_room, 0)
	_room.interaction_requested.connect(_on_interaction_requested)
	_room.focus_changed.connect(_on_focus_changed)
	_room.set_input_enabled(false)
	_camera.limit_left = int(_room.camera_bounds.position.x)
	_camera.limit_top = int(_room.camera_bounds.position.y)
	_camera.limit_right = int(_room.camera_bounds.end.x)
	_camera.limit_bottom = int(_room.camera_bounds.end.y)
	await _sleep(0.0)


func player_at(at: Vector2) -> void:
	if _player == null:
		_spawn_player(at)
		return
	_player.visible = true
	_player.global_position = at


func player_hide() -> void:
	if _player != null:
		_player.visible = false


func tint(preset: String, time: float) -> void:
	if _room == null:
		return
	if not TINTS.has(preset):
		push_error("알 수 없는 색조: %s" % preset)
		return
	var node: Node = _room.get_node_or_null("Tint")
	if not (node is ColorRect):
		return
	var rect := node as ColorRect
	var color: Color = TINTS[preset]
	if time <= 0.0:
		rect.modulate = Color.WHITE
		rect.color = color
		return
	rect.color = Color(color.r, color.g, color.b, rect.color.a)
	var tween := create_tween()
	tween.tween_property(rect, "color:a", color.a, time)
	await tween.finished


func npc(id: String, shown: bool) -> void:
	if _room == null:
		return
	var holder: Node = _room.get_node_or_null("Npcs")
	if holder == null:
		return
	var target: Node = holder.get_node_or_null(NodePath(id))
	if target == null:
		push_warning("NPC 를 찾을 수 없다: %s" % id)
		return
	if target is CanvasItem:
		(target as CanvasItem).visible = shown


func enable(id: String, on: bool) -> void:
	if _room == null:
		return
	var target: Interactable = _room.find_interactable(id)
	if target == null:
		push_warning("조사 지점을 찾을 수 없다: %s" % id)
		return
	target.enabled = on


func cam_set(at: Vector2, zoom: float) -> void:
	_camera_follow = false
	_camera.global_position = at
	_camera.zoom = Vector2(zoom, zoom)


## zoom 이 0 이하면 줌은 그대로 두고 위치만 옮긴다.
func cam_move(to: Vector2, time: float, zoom: float = 0.0) -> void:
	_camera_follow = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_camera, "global_position", to, time)
	if zoom > 0.0:
		tween.tween_property(_camera, "zoom", Vector2(zoom, zoom), time)
	await tween.finished


func cam_follow(on: bool, zoom: float = FOLLOW_ZOOM) -> void:
	_camera_follow = on
	if _camera_follow and is_instance_valid(_player):
		_camera.zoom = Vector2(zoom, zoom)


func fade_in(time: float) -> void:
	await _fade_to(0.0, time)


func fade_out(time: float) -> void:
	await _fade_to(1.0, time)


func sfx(id: String) -> void:
	AudioManager.play_sfx(StringName(id))


func amb_start(id: String, db: float = -6.0) -> void:
	AudioManager.start_ambience(StringName(id), db)


func amb_stop(id: String) -> void:
	AudioManager.stop_ambience(StringName(id))


func minigame(tutorial: bool) -> void:
	_dialogue.close()
	_prompt.hide()
	_minigame = MINIGAME_SCENE.instantiate()
	_minigame.set("tutorial", tutorial)
	_minigame_layer.add_child(_minigame)
	await _minigame.finished
	_minigame.queue_free()
	_minigame = null


## 플레이어가 조작하는 구간. exit_id 지점을 조사하면 끝난다.
func field(hint_key: String, exit_id: String) -> void:
	if _room == null:
		push_error("필드 명령인데 방이 없다.")
		return
	if _player == null:
		_spawn_player(_room.spawn_point)
	_dialogue.close()
	_player.visible = true
	_camera_follow = true
	_camera.zoom = Vector2(FOLLOW_ZOOM, FOLLOW_ZOOM)
	if not hint_key.is_empty():
		_hint.text = "%s\n%s" % [tr(hint_key), tr("FIELD_MOVE_HINT")]
		_hint.show()

	while true:
		_enable_field(true)
		var target: Interactable = await _room.interaction_requested
		_enable_field(false)
		await _inspect(target)
		if target.id == exit_id:
			break

	_hint.hide()
	_prompt.hide()
	_dialogue.close()
	if _player != null:
		_player.controllable = false


func view_open(view_id: String, time: float = 0.8) -> void:
	var path: String = String(VIEWS.get(view_id, ""))
	if not ResourceLoader.exists(path):
		push_error("연출 씬을 찾을 수 없다: %s" % view_id)
		return
	await view_close(0.0)
	_view = (load(path) as PackedScene).instantiate()
	_view_layer.add_child(_view)
	if _view is CanvasItem:
		(_view as CanvasItem).modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_view, "modulate:a", 1.0, time)
		await tween.finished


func view_close(time: float = 0.4) -> void:
	if _view == null or not is_instance_valid(_view):
		_view = null
		return
	if time > 0.0 and _view is CanvasItem:
		var tween := create_tween()
		tween.tween_property(_view, "modulate:a", 0.0, time)
		await tween.finished
	_view.queue_free()
	_view = null


func save(checkpoint: String) -> void:
	StoryState.checkpoint = checkpoint
	StoryState.save_to_slot(scene_path)


# ── 내부 ──────────────────────────────────────────────────────────────

func _sleep(seconds: float) -> void:
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds).timeout


func _fade_to(alpha: float, time: float) -> void:
	if time <= 0.0:
		_fade.color.a = alpha
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, time)
	await tween.finished


func _clear_room() -> void:
	if _player != null and is_instance_valid(_player):
		_player.queue_free()
		_player = null
	if _room != null and is_instance_valid(_room):
		_room.queue_free()
	_room = null


func _spawn_player(at: Vector2) -> void:
	if _room == null:
		return
	_player = PLAYER_SCENE.instantiate()
	_room.add_child(_player)
	_player.global_position = at
	_player.controllable = false
	_room.set_player(_player)
	_player.global_position = at


func _enable_field(active: bool) -> void:
	_field_active = active
	if _player != null and is_instance_valid(_player):
		_player.controllable = active
	if _room != null and is_instance_valid(_room):
		_room.set_input_enabled(active)
	if not active:
		_prompt.hide()
	elif _room != null and _room.focus() != null:
		_on_focus_changed(_room.focus())


## 조사 지점의 대사(대본의 inspect_<id> 구간)를 실행한다. 구간이 없으면 대사 없이 넘어간다.
func _inspect(target: Interactable) -> void:
	var cue: String = INSPECT_CUE_PREFIX + target.id
	if dialogue.cues.has(cue):
		await _play(cue)


func _on_interaction_requested(_target: Interactable) -> void:
	pass


func _on_focus_changed(target: Interactable) -> void:
	if target == null or not _field_active:
		_prompt.hide()
		return
	_prompt.text = tr("FIELD_INTERACT_HINT").format([target.label()])
	_prompt.show()


func _leave() -> void:
	AudioManager.stop_all_ambience()
	StoryState.checkpoint = "ep1_end"
	StoryState.save_to_slot(scene_path)
	var destination: String = next_scene if not next_scene.is_empty() else TITLE_SCENE
	if destination == TITLE_SCENE:
		AudioManager.play_bgm_title()
	SceneRouter.change_scene(destination)
