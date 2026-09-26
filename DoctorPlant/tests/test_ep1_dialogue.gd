extends GutTest
## 1화 대본(ep1.dialogue)과 번역 테이블·연출 명령이 서로 맞는지 확인한다.
## Dialogue Manager 는 `$> stage.xxx()` 가 실제로 있는지, 번역이 빠졌는지를 컴파일 때 알려주지 않는다.

const LINES: Script = preload("res://scripts/story/ep1_lines.gd")
const EPISODE_PLAYER: Script = preload("res://scripts/story/episode_player.gd")
const STAGE_CALL_PATTERN: String = "\\$>\\s*stage\\.(\\w+)\\("

var _dialogue: DialogueResource = null


func before_all() -> void:
	_dialogue = load(LINES.DIALOGUE_PATH)


func test_dialogue_loads() -> void:
	assert_not_null(_dialogue, "대본을 불러오지 못했다: %s" % LINES.DIALOGUE_PATH)
	assert_true(_dialogue.cues.has("start"), "대본에 ~ start 가 없다.")


func test_every_line_has_english() -> void:
	var english: Dictionary = LINES.DIALOGUE["en"]
	var missing: PackedStringArray = []
	for id: String in _static_ids():
		if not english.has(id):
			missing.append(id)
	assert_eq(missing.size(), 0, "영어 번역이 없는 대사: %s" % ", ".join(missing))


func test_every_speaker_has_english() -> void:
	var english: Dictionary = LINES.DIALOGUE["en"]
	var missing: PackedStringArray = []
	for speaker: String in _dialogue.character_names:
		if not english.has(speaker):
			missing.append(speaker)
	assert_eq(missing.size(), 0, "영어 이름이 없는 화자: %s" % ", ".join(missing))


func test_no_unused_english() -> void:
	var used: PackedStringArray = _static_ids()
	used.append_array(_dialogue.character_names)
	var unused: PackedStringArray = []
	for key: String in LINES.DIALOGUE["en"].keys():
		if not used.has(key):
			unused.append(key)
	assert_eq(unused.size(), 0, "대본에 없는 번역 키: %s" % ", ".join(unused))


func test_source_text_is_registered() -> void:
	var previous: String = TranslationServer.get_locale()
	TranslationServer.set_locale("ko")
	assert_eq(
		TranslationServer.translate("EP1_P1_01", Localization.DIALOGUE_CONTEXT),
		"안녕하세요, 선생님."
	)
	TranslationServer.set_locale("en")
	assert_eq(
		TranslationServer.translate("EP1_P1_01", Localization.DIALOGUE_CONTEXT),
		"Good morning, doctor."
	)
	TranslationServer.set_locale(previous)


func test_stage_calls_exist() -> void:
	var methods: PackedStringArray = []
	for method: Dictionary in EPISODE_PLAYER.get_script_method_list():
		methods.append(String(method["name"]))
	var regex := RegEx.create_from_string(STAGE_CALL_PATTERN)
	var text: String = FileAccess.get_file_as_string(LINES.DIALOGUE_PATH)
	var calls: Array[RegExMatch] = regex.search_all(text)
	assert_gt(calls.size(), 0, "대본에서 연출 명령을 하나도 찾지 못했다.")
	var unknown: PackedStringArray = []
	for found: RegExMatch in calls:
		var method_name: String = found.get_string(1)
		if not methods.has(method_name) and not unknown.has(method_name):
			unknown.append(method_name)
	assert_eq(unknown.size(), 0, "EpisodePlayer 에 없는 연출 명령: %s" % ", ".join(unknown))


func test_scene_uses_dialogue() -> void:
	var episode: Node = (load("res://scenes/ch1/ep1.tscn") as PackedScene).instantiate()
	assert_eq(episode.get("dialogue"), _dialogue, "ep1.tscn 에 대본이 연결되어 있지 않다.")
	episode.free()


## inspect_<id> 구간 이름이 틀리면 조사해도 대사가 안 나올 뿐 오류가 없으므로 여기서 잡는다.
func test_inspect_cues_match_interactables() -> void:
	var ids: PackedStringArray = []
	for path: String in EPISODE_PLAYER.ROOMS.values():
		var room: Node = (load(path) as PackedScene).instantiate()
		for node: Node in room.find_children("*", "Area2D"):
			if node is Interactable:
				ids.append((node as Interactable).id)
		room.free()
	var orphans: PackedStringArray = []
	for cue: String in _dialogue.cues.keys():
		if cue.begins_with(EPISODE_PLAYER.INSPECT_CUE_PREFIX):
			if not ids.has(cue.trim_prefix(EPISODE_PLAYER.INSPECT_CUE_PREFIX)):
				orphans.append(cue)
	assert_eq(orphans.size(), 0, "어느 방에도 없는 조사 지점의 구간: %s" % ", ".join(orphans))


## chatter_<이름> 구간 이름이 틀리면 말풍선이 안 뜰 뿐 오류가 없으므로 여기서 잡는다.
func test_chatter_cues_match_figures() -> void:
	var cues: PackedStringArray = []
	for path: String in EPISODE_PLAYER.ROOMS.values():
		var room: FieldRoom = (load(path) as PackedScene).instantiate()
		for figure: Node2D in room.figures():
			cues.append(EPISODE_PLAYER.chatter_cue(figure))
		room.free()
	var found: int = 0
	var orphans: PackedStringArray = []
	for cue: String in _dialogue.cues.keys():
		if not cue.begins_with(EPISODE_PLAYER.CHATTER_CUE_PREFIX):
			continue
		found += 1
		if not cues.has(cue):
			orphans.append(cue)
	assert_gt(found, 0, "대본에 chatter_ 구간이 하나도 없다.")
	assert_eq(orphans.size(), 0, "어느 방에도 없는 인물의 혼잣말 구간: %s" % ", ".join(orphans))


func test_chatter_cues_speak() -> void:
	var stage := RecordingStage.new()
	assert_eq(
		await _walk("chatter_staff1", stage),
		PackedStringArray(["EP1_CHAT_STAFF1_01", "EP1_CHAT_STAFF1_02", "EP1_CHAT_STAFF1_03"])
	)
	assert_eq(await _walk("chatter_walker2", stage), PackedStringArray(["EP1_CHAT_WALKER2_01"]))
	stage.free()


## 대본을 처음부터 끝까지 흘려 본다(선택지는 매번 첫 번째).
## 연출 명령은 기록만 하는 RecordingStage 가 받는다. EpisodePlayer 를 상속해 같은 시그니처를
## 그대로 덮어쓰므로, 대본의 인자 개수·타입이 실제 함수와 어긋나면 여기서 걸린다.
func test_full_run_reaches_end() -> void:
	var stage := RecordingStage.new()
	var spoken: PackedStringArray = await _walk("start", stage)
	assert_eq(spoken.size(), 22, "대사 줄 수가 달라졌다: %s" % ", ".join(spoken))
	assert_eq(spoken[0], "EP1_P1_01")
	assert_eq(spoken[spoken.size() - 1], "EP1_SYS_TIRED")
	assert_eq(stage.calls_named("field"), [["EP1_HINT_CLINIC", "door"], ["EP1_HINT_WINDOW", "sun_button"], ["EP1_HINT_EXIT", "exit_door"]])
	assert_eq(stage.calls_named("minigame"), [[true, ""], [false, ""]])
	assert_eq(stage.calls_named("chatter"), [[true], [false]])
	assert_eq(stage.calls_named("save"), [["ep1_s2_clinic"], ["ep1_s2_sunbathing"], ["ep1_s3_evening"]])
	assert_true(bool(StoryState.get_flag("ep1_prescribed_p1", false)), "환자1 처방 플래그가 저장되지 않았다.")
	assert_true(bool(StoryState.get_flag("ep1_prescribed_p2", false)), "환자2 처방 플래그가 저장되지 않았다.")
	StoryState.reset()
	stage.free()


func test_inspect_cues_speak() -> void:
	var stage := RecordingStage.new()
	assert_eq(await _walk("inspect_door", stage), PackedStringArray(["EP1_SYS_CALL_NEXT"]))
	assert_eq(await _walk("inspect_frame_a", stage), PackedStringArray(["EP1_SYS_FRAME_A"]))
	# 컴퓨터: 첫 줄이 선택지 질문, 첫 번째 선택지(환자 리스트)의 설명이 이어진다.
	assert_eq(
		await _walk("inspect_computer", stage),
		PackedStringArray(["EP1_SYS_COMPUTER", "EP1_SYS_PATIENT_LIST"])
	)
	stage.free()


## cue 부터 끝까지 진행하며 나온 대사의 ID 를 순서대로 돌려준다. 대기(wait)는 기다리지 않는다.
func _walk(cue: String, stage: RecordingStage) -> PackedStringArray:
	var states: Array = [{"stage": stage}]
	var spoken: PackedStringArray = []
	var behaviour := DMConstants.MutationBehaviour.DoNotWait
	var line: DialogueLine = await DialogueManager.get_next_dialogue_line(_dialogue, cue, states, behaviour)
	while line != null:
		spoken.append(line.static_id)
		var next_id: String = line.next_id
		if not line.responses.is_empty():
			next_id = (line.responses[0] as DialogueResponse).next_id
		line = await DialogueManager.get_next_dialogue_line(_dialogue, next_id, states, behaviour)
	return spoken


func _static_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for line: Dictionary in _dialogue.lines.values():
		if line.has("static_id"):
			ids.append(String(line["static_id"]))
	return ids


## 연출 명령을 실행하지 않고 [이름, 인자...] 만 기록하는 EpisodePlayer.
class RecordingStage extends EpisodePlayer:
	var calls: Array = []

	func calls_named(method_name: String) -> Array:
		var found: Array = []
		for entry: Array in calls:
			if entry[0] == method_name:
				found.append(entry.slice(1))
		return found

	func card(label_key: String, title_key: String, sub_key: String, time: float = 2.0) -> void:
		calls.append(["card", label_key, title_key, sub_key, time])

	func room(room_id: String) -> void:
		assert(ROOMS.has(room_id), "알 수 없는 방: %s" % room_id)
		calls.append(["room", room_id])

	func player_at(at: Vector2) -> void:
		calls.append(["player_at", at])

	func player_hide() -> void:
		calls.append(["player_hide"])

	func tint(preset: String, time: float) -> void:
		assert(TINTS.has(preset), "알 수 없는 색조: %s" % preset)
		calls.append(["tint", preset, time])

	func npc(id: String, shown: bool) -> void:
		calls.append(["npc", id, shown])

	func enable(id: String, on: bool) -> void:
		calls.append(["enable", id, on])

	func cam_set(at: Vector2, zoom: float) -> void:
		calls.append(["cam_set", at, zoom])

	func cam_move(to: Vector2, time: float, zoom: float = 0.0) -> void:
		calls.append(["cam_move", to, time, zoom])

	func cam_follow(on: bool, zoom: float = FOLLOW_ZOOM) -> void:
		calls.append(["cam_follow", on, zoom])

	func fade_in(time: float) -> void:
		calls.append(["fade_in", time])

	func fade_out(time: float) -> void:
		calls.append(["fade_out", time])

	func sfx(id: String) -> void:
		calls.append(["sfx", id])

	func amb_start(id: String, db: float = -6.0) -> void:
		calls.append(["amb_start", id, db])

	func amb_stop(id: String) -> void:
		calls.append(["amb_stop", id])

	func minigame(tutorial: bool, game_id: String = "") -> void:
		if not game_id.is_empty():
			assert(not MinigameHost.find_game(game_id).is_empty(), "알 수 없는 미니게임: %s" % game_id)
		calls.append(["minigame", tutorial, game_id])

	func field(hint_key: String, exit_id: String) -> void:
		calls.append(["field", hint_key, exit_id])

	func chatter(on: bool) -> void:
		calls.append(["chatter", on])

	func view_open(view_id: String, time: float = 0.8) -> void:
		assert(VIEWS.has(view_id), "알 수 없는 연출: %s" % view_id)
		calls.append(["view_open", view_id, time])

	func view_close(time: float = 0.4) -> void:
		calls.append(["view_close", time])

	func save(checkpoint: String) -> void:
		calls.append(["save", checkpoint])
