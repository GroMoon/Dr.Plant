extends Node2D
class_name EpisodePlayer
## 에피소드 진행기. 명령 목록(ep1_script.gd 같은 데이터)을 위에서부터 실행한다.
##
## 대사·연출·필드 이동·미니게임이 한 씬 안에서 이어지므로
## 장면마다 씬을 따로 만들지 않고 명령으로 전환한다.
##
## 명령 종류는 scripts/story/ep1_script.gd 머리말 참조.

const TITLE_SCENE: String = "res://scenes/title_screen.tscn"
const MINIGAME_SCENE: PackedScene = preload("res://scenes/ch1/minigame_diagnosis.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/field/field_player.tscn")

const FOLLOW_ZOOM: Vector2 = Vector2(1.6, 1.6)

signal advance_requested

## 이 에피소드가 실행할 명령 목록을 담은 스크립트(COMMANDS 상수를 가진다).
@export var script_data: Script = null
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
var _finished: bool = false


func _ready() -> void:
	_fade.color.a = 1.0
	_prompt.hide()
	_hint.hide()
	_card.hide()
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
	if script_data == null:
		push_error("실행할 에피소드 스크립트가 지정되지 않았다.")
		return
	var commands: Array = script_data.get_script_constant_map().get("COMMANDS", [])
	if commands.is_empty():
		push_error("에피소드 스크립트에 COMMANDS 가 없다: %s" % script_data.resource_path)
		return
	for i: int in commands.size():
		if _finished:
			break
		await _exec(commands[i], _peek(commands, i + 1))
	await _leave()


## 바로 다음 명령. 대사가 이어지는지 판단하는 데 쓴다.
func _peek(commands: Array, index: int) -> Dictionary:
	if index >= commands.size():
		return {}
	return commands[index]


## 대사를 이어서 출력하는 명령인지.
func _is_dialogue(command: Dictionary) -> bool:
	return String(command.get("t", "")) in ["say", "sys", "notice"]


func _exec(command: Dictionary, next_command: Dictionary = {}) -> void:
	match String(command.get("t", "")):
		"title":
			await _show_card(command)
		"room":
			await _load_room(command)
		"tint":
			await _tint(command)
		"npc":
			_set_npc(command)
		"player":
			_set_player(command)
		"enable":
			_set_interactable_enabled(command)
		"cam_set":
			_camera_follow = false
			_camera.global_position = command.get("at", _camera.global_position)
			_camera.zoom = command.get("zoom", _camera.zoom)
		"cam":
			await _move_camera(command)
		"cam_follow":
			_camera_follow = bool(command.get("on", true))
			if _camera_follow and is_instance_valid(_player):
				_camera.zoom = command.get("zoom", FOLLOW_ZOOM)
		"fade":
			await _do_fade(command)
		"wait":
			await _sleep(float(command.get("time", 1.0)))
		"sfx":
			AudioManager.play_sfx(StringName(command.get("id", "")))
		"amb":
			if bool(command.get("on", true)):
				AudioManager.start_ambience(
					StringName(command.get("id", "")), float(command.get("db", -6.0))
				)
			else:
				AudioManager.stop_ambience(StringName(command.get("id", "")))
		"say":
			await _say(
				String(command.get("who", "")), String(command.get("key", "")), _is_dialogue(next_command)
			)
		"sys":
			await _say("CH_SYSTEM", String(command.get("key", "")), _is_dialogue(next_command))
		"notice":
			await _say("CH_NOTICE", String(command.get("key", "")), _is_dialogue(next_command))
		"hide_dialogue":
			_dialogue.close()
		"choice":
			await _choose(command)
		"minigame":
			await _run_minigame(command)
		"field":
			await _run_field(command)
		"view":
			await _open_view(command)
		"view_close":
			await _close_view(float(command.get("time", 0.4)))
		"save":
			StoryState.checkpoint = String(command.get("checkpoint", ""))
			StoryState.save_to_slot(scene_path)
		"flag":
			StoryState.set_flag(String(command.get("flag", "")), command.get("value", true))
		"end":
			await _show_card(command)
			_finished = true
		_:
			push_warning("알 수 없는 명령: %s" % command)


# ── 개별 명령 ─────────────────────────────────────────────────────────

func _sleep(seconds: float) -> void:
	if seconds <= 0.0:
		return
	await get_tree().create_timer(seconds).timeout


## keep_open 이 false 면 다 읽고 넘어가는 순간 대사창을 닫는다.
## 대사가 끝났는데 창만 남아 있는 것을 막는다.
func _say(speaker_key: String, body_key: String, keep_open: bool = false) -> void:
	if body_key.is_empty():
		return
	_dialogue.show_line(speaker_key, body_key)
	await _wait_advance()
	if not keep_open:
		_dialogue.close()


func _wait_advance() -> void:
	_awaiting_advance = true
	await advance_requested
	_awaiting_advance = false


func _choose(command: Dictionary) -> void:
	var options: Array = command.get("options", [])
	var keys := PackedStringArray()
	for option: Dictionary in options:
		keys.append(String(option.get("key", "")))
	_choices.open(String(command.get("key", "")), keys)
	var index: int = await _choices.chosen
	_choices.close()
	var picked: Dictionary = options[clampi(index, 0, options.size() - 1)]
	if picked.has("flag"):
		StoryState.set_flag(String(picked["flag"]), picked.get("value", true))
	var follow_ups: Array = picked.get("then", [])
	for i: int in follow_ups.size():
		await _exec(follow_ups[i], _peek(follow_ups, i + 1))


func _do_fade(command: Dictionary) -> void:
	var target: float = float(command.get("to", 1.0))
	var time: float = float(command.get("time", 1.0))
	if time <= 0.0:
		_fade.color.a = target
		return
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", target, time)
	await tween.finished


func _move_camera(command: Dictionary) -> void:
	_camera_follow = false
	var time: float = float(command.get("time", 1.0))
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	if command.has("to"):
		tween.tween_property(_camera, "global_position", command["to"], time)
	if command.has("zoom"):
		tween.tween_property(_camera, "zoom", command["zoom"], time)
	await tween.finished


func _show_card(command: Dictionary) -> void:
	_card_label.text = tr(String(command.get("label", "")))
	_card_label.visible = not _card_label.text.is_empty()
	_card_title.text = tr(String(command.get("title", "")))
	_card_title.visible = not _card_title.text.is_empty()
	_card_sub.text = tr(String(command.get("sub", "")))
	_card_sub.visible = not _card_sub.text.is_empty()
	_card.modulate.a = 0.0
	_card.show()
	var tween := create_tween()
	tween.tween_property(_card, "modulate:a", 1.0, 0.6)
	await tween.finished
	await _sleep(float(command.get("time", 2.0)))
	var out := create_tween()
	out.tween_property(_card, "modulate:a", 0.0, 0.6)
	await out.finished
	_card.hide()


func _load_room(command: Dictionary) -> void:
	var path: String = String(command.get("path", ""))
	if not ResourceLoader.exists(path):
		push_error("필드 씬을 찾을 수 없다: %s" % path)
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
	if bool(command.get("player", false)):
		_spawn_player(command.get("spawn", _room.spawn_point))
	if command.has("camera"):
		_camera.global_position = command["camera"]
	if command.has("zoom"):
		_camera.zoom = command["zoom"]
	await _sleep(0.0)


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


func _set_player(command: Dictionary) -> void:
	if _player == null:
		if bool(command.get("show", true)) and _room != null:
			_spawn_player(command.get("at", _room.spawn_point))
		return
	_player.visible = bool(command.get("show", true))
	if command.has("at"):
		_player.global_position = command["at"]


func _set_npc(command: Dictionary) -> void:
	if _room == null:
		return
	var holder: Node = _room.get_node_or_null("Npcs")
	if holder == null:
		return
	var npc: Node = holder.get_node_or_null(NodePath(String(command.get("id", ""))))
	if npc == null:
		push_warning("NPC 를 찾을 수 없다: %s" % command.get("id", ""))
		return
	if npc is CanvasItem:
		(npc as CanvasItem).visible = bool(command.get("show", true))
	if command.has("at") and npc is Node2D:
		(npc as Node2D).position = command["at"]


func _set_interactable_enabled(command: Dictionary) -> void:
	if _room == null:
		return
	var id: String = String(command.get("id", ""))
	var target: Interactable = _room.find_interactable(id)
	if target == null:
		push_warning("조사 지점을 찾을 수 없다: %s" % id)
		return
	target.enabled = bool(command.get("on", true))


func _tint(command: Dictionary) -> void:
	if _room == null:
		return
	var tint: Node = _room.get_node_or_null("Tint")
	if not (tint is CanvasItem):
		return
	var time: float = float(command.get("time", 1.0))
	var color: Color = command.get("color", Color(0, 0, 0, 0))
	if time <= 0.0:
		(tint as CanvasItem).modulate = Color.WHITE
		(tint as ColorRect).color = color
		return
	(tint as ColorRect).color = Color(color.r, color.g, color.b, (tint as ColorRect).color.a)
	var tween := create_tween()
	tween.tween_property(tint, "color:a", color.a, time)
	await tween.finished


func _open_view(command: Dictionary) -> void:
	var path: String = String(command.get("scene", ""))
	if not ResourceLoader.exists(path):
		push_error("연출 씬을 찾을 수 없다: %s" % path)
		return
	await _close_view(0.0)
	_view = (load(path) as PackedScene).instantiate()
	_view_layer.add_child(_view)
	if _view is CanvasItem:
		(_view as CanvasItem).modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(_view, "modulate:a", 1.0, float(command.get("time", 0.8)))
		await tween.finished


func _close_view(time: float) -> void:
	if _view == null or not is_instance_valid(_view):
		_view = null
		return
	if time > 0.0 and _view is CanvasItem:
		var tween := create_tween()
		tween.tween_property(_view, "modulate:a", 0.0, time)
		await tween.finished
	_view.queue_free()
	_view = null


func _run_minigame(command: Dictionary) -> void:
	_dialogue.close()
	_prompt.hide()
	_minigame = MINIGAME_SCENE.instantiate()
	_minigame.set("tutorial", bool(command.get("tutorial", false)))
	_minigame.set("patient_key", String(command.get("patient", "")))
	_minigame_layer.add_child(_minigame)
	await _minigame.finished
	_minigame.queue_free()
	_minigame = null


func _run_field(command: Dictionary) -> void:
	if _room == null:
		push_error("필드 명령인데 방이 없다.")
		return
	if _player == null:
		_spawn_player(command.get("spawn", _room.spawn_point))
	_dialogue.close()
	_player.visible = true
	_camera_follow = true
	_camera.zoom = command.get("zoom", FOLLOW_ZOOM)
	var hint_key: String = String(command.get("hint", ""))
	if not hint_key.is_empty():
		_hint.text = "%s\n%s" % [tr(hint_key), tr("FIELD_MOVE_HINT")]
		_hint.show()

	var exits: Array = command.get("exit", [])
	while true:
		_enable_field(true)
		var target: Interactable = await _room.interaction_requested
		_enable_field(false)
		await _inspect(target)
		if exits.has(target.id):
			break

	_hint.hide()
	_prompt.hide()
	_dialogue.close()
	if _player != null:
		_player.controllable = false


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


## 조사 지점 하나를 처리한다. 하위 선택지가 있으면 먼저 띄운다.
func _inspect(target: Interactable) -> void:
	if target.option_keys.size() > 0:
		var keys := PackedStringArray(target.option_keys)
		var descriptions := PackedStringArray(target.option_description_keys)
		if target.options_closable:
			keys.append("EP1_OPT_CLOSE")
		if not target.description_key.is_empty():
			await _say("CH_SYSTEM", target.description_key)
		_choices.open(target.label_key, keys)
		var index: int = await _choices.chosen
		_choices.close()
		if index < descriptions.size():
			await _say("CH_SYSTEM", descriptions[index])
		return
	if not target.description_key.is_empty():
		await _say("CH_SYSTEM", target.description_key)


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
