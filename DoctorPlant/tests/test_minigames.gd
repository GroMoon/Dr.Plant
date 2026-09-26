extends GutTest
## 진찰 미니게임: 목록·문자열·무작위 선택과 미니게임별 판정이 요구사항대로인지 확인한다.
## 요구사항: design/requirements/ch1/02-minigame.md

const LINES: Script = preload("res://scripts/minigame/minigame_lines.gd")
const HOST_SCENE: PackedScene = preload("res://scenes/minigame/minigame_host.tscn")
const STETHO_SCENE: PackedScene = preload("res://scenes/minigame/stethoscope_tuning.tscn")
const LEAF_SCENE: PackedScene = preload("res://scenes/minigame/leaf_wiping.tscn")
const DODGE_SCENE: PackedScene = preload("res://scenes/minigame/anxiety_dodge.tscn")
const MEASURE_SCENE: PackedScene = preload("res://scenes/minigame/define_measuring.tscn")
const PILL_SCRIPT: Script = preload("res://scripts/minigame/pill_sorting.gd")
const SCRIPT_DIR: String = "res://scripts/minigame/"
const KEY_PATTERN: String = "\"(MG_[A-Z0-9_]+)\""


func test_every_game_is_a_minigame() -> void:
	assert_eq(MinigameHost.GAMES.size(), 5)
	for entry: Dictionary in MinigameHost.GAMES:
		var packed := load(String(entry["scene"])) as PackedScene
		assert_not_null(packed, "씬을 불러오지 못했다: %s" % entry["scene"])
		if packed == null:
			continue
		var game: Node = packed.instantiate()
		assert_true(game is Minigame, "%s 가 Minigame 이 아니다." % entry["id"])
		game.free()


func test_locales_have_same_keys() -> void:
	var korean: Array = LINES.STRINGS["ko"].keys()
	var english: Array = LINES.STRINGS["en"].keys()
	korean.sort()
	english.sort()
	assert_eq(korean, english)


func test_every_game_has_host_strings() -> void:
	var korean: Dictionary = LINES.STRINGS["ko"]
	for entry: Dictionary in MinigameHost.GAMES:
		for suffix: String in ["_TITLE", "_HINT", "_CONTROLS"]:
			var key: String = String(entry["key"]) + suffix
			assert_true(korean.has(key), "문자열이 없다: %s" % key)


## 코드에 적힌 "MG_..." 키가 모두 문자열 표에 있는지 본다(접두사로만 쓰는 키는 뺀다).
func test_keys_used_in_code_exist() -> void:
	var prefixes: Array[String] = []
	for entry: Dictionary in MinigameHost.GAMES:
		prefixes.append(String(entry["key"]))
	var korean: Dictionary = LINES.STRINGS["ko"]
	var regex := RegEx.create_from_string(KEY_PATTERN)
	var missing: PackedStringArray = []
	for file: String in DirAccess.get_files_at(SCRIPT_DIR):
		if not file.ends_with(".gd") or file == "minigame_lines.gd":
			continue
		var source: String = FileAccess.get_file_as_string(SCRIPT_DIR + file)
		for found: RegExMatch in regex.search_all(source):
			var key: String = found.get_string(1)
			if not korean.has(key) and not prefixes.has(key):
				missing.append("%s (%s)" % [key, file])
	assert_eq(missing.size(), 0, "문자열 표에 없는 키: %s" % ", ".join(missing))


func test_random_pick_avoids_last_and_covers_all() -> void:
	var seen: Dictionary = {}
	var last: String = ""
	for i: int in 200:
		var id: String = MinigameHost.pick_game_id(last)
		assert_ne(id, last)
		seen[id] = true
		last = id
	assert_eq(seen.size(), MinigameHost.GAMES.size(), "무작위로 나오지 않는 미니게임이 있다.")


func test_host_finishes_with_result() -> void:
	var host := HOST_SCENE.instantiate() as MinigameHost
	host.game_id = "pill"
	add_child_autofree(host)
	watch_signals(host)
	await wait_seconds(MinigameHost.READY_TIME + 0.2)
	var game: Minigame = host.current_game()
	assert_true(game.active, "준비 시간이 지나도 미니게임이 시작되지 않았다.")
	game._complete()
	await wait_for_signal(host.finished, 5.0)
	assert_signal_emitted(host, "finished")
	var result: Dictionary = get_signal_parameters(host, "finished")[0]
	assert_eq(result["game"], "pill")
	assert_true(bool(result["complete"]))
	assert_eq(MinigameHost.last_game_id, "pill")


func test_every_game_runs_a_while() -> void:
	for entry: Dictionary in MinigameHost.GAMES:
		var game := (load(String(entry["scene"])) as PackedScene).instantiate() as Minigame
		add_child_autofree(game)
		game.begin()
		await wait_process_frames(20)
		assert_true(game.active, "%s 가 아무것도 안 했는데 끝났다." % entry["id"])


# ── 미니게임별 판정 ───────────────────────────────────────────────────

func test_stethoscope_matches_only_when_overlapping() -> void:
	var game = STETHO_SCENE.instantiate()
	add_child_autofree(game)
	game._pitch.value = inverse_lerp(game.FREQ_MIN, game.FREQ_MAX, game._target_freq)
	game._volume.value = inverse_lerp(game.AMP_MIN, game.AMP_MAX, game._target_amp)
	assert_true(game.is_matched())
	game._pitch.value += 0.1
	assert_false(game.is_matched())


func test_leaf_rubbing_too_fast_bruises() -> void:
	var game = LEAF_SCENE.instantiate()
	add_child_autofree(game)
	game.begin()
	game._speed = game.SPEED_LIMIT * 2.0
	game._rub(10.0)
	assert_eq(game.mistakes, 1)
	assert_gt(game._bruise, 0.0)


func test_leaf_rubbing_cleans_a_stain() -> void:
	var game = LEAF_SCENE.instantiate()
	add_child_autofree(game)
	game.begin()
	var stain: Dictionary = game._stains[0]
	game._brush = stain["pos"]
	game._rub(float(stain["need"]) + 1.0)
	assert_eq(float(stain["dirt"]), 0.0)
	assert_eq(game.mistakes, 0)


func test_dodge_third_hit_restarts_phase() -> void:
	var game = DODGE_SCENE.instantiate()
	add_child_autofree(game)
	game.begin()
	game._phase_time = 3.0
	game._on_hit()
	game._on_hit()
	assert_eq(game._phase_time, 3.0, "두 번까지는 구간이 그대로여야 한다.")
	game._on_hit()
	assert_eq(game.mistakes, 3)
	assert_eq(game._phase_time, 0.0)
	assert_eq(game._anxiety, 0)


func test_measure_overflow_empties_beaker() -> void:
	var game = MEASURE_SCENE.instantiate()
	add_child_autofree(game)
	game.begin()
	game._levels[0] = game.band_top(0) - 0.001
	game._holding = true
	game._pour(0.1)
	assert_eq(game.mistakes, 1)
	assert_gt(game._spill, 0.0)
	assert_eq(game._index, 0)


func test_measure_settles_inside_band() -> void:
	var game = MEASURE_SCENE.instantiate()
	add_child_autofree(game)
	game.begin()
	game._levels[0] = game._bands[0]
	game._pour(0.3)
	game._pour(0.3)
	assert_eq(game._index, 1)
	assert_eq(game.mistakes, 0)


func test_pill_categories() -> void:
	assert_eq(PILL_SCRIPT.category_for("round", false), "left")
	assert_eq(PILL_SCRIPT.category_for("capsule", false), "right")
	assert_eq(PILL_SCRIPT.category_for("round", true), "trash")
	assert_eq(PILL_SCRIPT.category_for("capsule", true), "trash")
