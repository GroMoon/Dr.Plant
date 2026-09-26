extends Node
## 게임 내 모든 UI 문자열을 코드에서 등록하는 번역 테이블.
## Translation 리소스를 런타임에 만들어 TranslationServer 에 넣기 때문에
## .po/.csv 임포트 없이도 언어 전환이 동작한다.

## 챕터 문자열은 분량이 커서 별도 파일로 뺀다. 여기에 모아 한 번에 등록한다.
## 각 테이블은 STRINGS(화면 문구), DIALOGUE(대본 번역), DIALOGUE_PATH(대본 경로)를 가진다.
const EPISODE_TABLES: Array = [
	preload("res://scripts/story/ep1_lines.gd"),
	preload("res://scripts/minigame/minigame_lines.gd"),
]

## 대본(.dialogue)을 쓰는 언어이자 기본 언어.
const DEFAULT_LOCALE: String = "ko"

## Dialogue Manager 는 대사를 tr(키, "dialogue") 로 찾는다. 대본 번역은 이 문맥으로 등록한다.
const DIALOGUE_CONTEXT: StringName = &"dialogue"

const SUPPORTED_LOCALES: Array[Dictionary] = [
	{"code": "ko", "label": "한국어"},
	{"code": "en", "label": "English"},
]

const STRINGS: Dictionary = {
	"ko": {
		"GAME_TITLE": "식물의사",
		"MENU_START": "게임 시작",
		"MENU_SETTINGS": "설정",
		"MENU_QUIT": "나가기",
		"MENU_RESUME": "돌아가기",
		"MENU_BACK": "뒤로",
		"MENU_CLOSE": "닫기",
		"SLOT_TITLE": "저장소 선택",
		"SLOT_EMPTY": "새로 시작",
		"SLOT_LABEL": "저장소 {0}",
		"SLOT_CHAPTER": "챕터 {0}",
		"SLOT_PLAYTIME": "플레이 시간 {0}",
		"SETTINGS_TITLE": "설정",
		"SETTINGS_BGM": "배경음",
		"SETTINGS_SFX": "효과음",
		"SETTINGS_WINDOW_MODE": "화면 모드",
		"SETTINGS_RESOLUTION": "창 크기",
		"SETTINGS_LANGUAGE": "언어",
		"SETTINGS_TEXT_SPEED": "텍스트 속도",
		"SETTINGS_TEXT_SIZE": "텍스트 크기",
		"SETTINGS_PREVIEW": "미리보기",
		"SETTINGS_RESET": "기본값으로",
		"WINDOW_MODE_WINDOWED": "창 모드",
		"WINDOW_MODE_BORDERLESS": "전체화면(테두리 없음)",
		"WINDOW_MODE_EXCLUSIVE": "전체화면(전용)",
		"TEXT_SIZE_SMALL": "작게",
		"TEXT_SIZE_NORMAL": "보통",
		"TEXT_SIZE_LARGE": "크게",
		"TEXT_SPEED_INSTANT": "즉시",
		"PAUSE_TITLE": "일시정지",
		"QUIT_CONFIRM": "게임을 종료할까요?",
		"PAUSE_QUIT_CONFIRM": "타이틀 화면으로 돌아갈까요?\n저장되지 않은 진행은 사라집니다.",
		"CONFIRM_YES": "예",
		"CONFIRM_NO": "아니오",
		"LOADING": "불러오는 중",
		"PREVIEW_SAMPLE": "진료를 시작하지. 어디가 아파서 왔나요?",
		"FIELD_MOVE_HINT": "WASD · 방향키 · 스틱 으로 이동",
		"FIELD_INTERACT_HINT": "{0}  —  스페이스 · 클릭 · 패드 A",
		"STUB_TITLE": "챕터 1 — 식물들의 병원",
		"STUB_NOTICE": "본편은 아직 제작 전입니다. (design/requirements/ch1 미작성)",
		"STUB_HINT": "클릭 · 스페이스 · 엔터 · 패드 A 로 진행 / ESC 로 일시정지",
		"STUB_LINE_1": "여기에 챕터 1 의 대사가 들어갑니다.",
		"STUB_LINE_2": "텍스트 속도와 크기 설정이 이 대사에 그대로 적용됩니다.",
		"STUB_LINE_3": "ESC 를 눌러 일시정지 메뉴를 확인해 보세요.",
	},
	"en": {
		"GAME_TITLE": "Doctor Plant",
		"MENU_START": "Start Game",
		"MENU_SETTINGS": "Settings",
		"MENU_QUIT": "Quit",
		"MENU_RESUME": "Resume",
		"MENU_BACK": "Back",
		"MENU_CLOSE": "Close",
		"SLOT_TITLE": "Select Save Slot",
		"SLOT_EMPTY": "New Game",
		"SLOT_LABEL": "Slot {0}",
		"SLOT_CHAPTER": "Chapter {0}",
		"SLOT_PLAYTIME": "Playtime {0}",
		"SETTINGS_TITLE": "Settings",
		"SETTINGS_BGM": "Music",
		"SETTINGS_SFX": "Sound Effects",
		"SETTINGS_WINDOW_MODE": "Window Mode",
		"SETTINGS_RESOLUTION": "Window Size",
		"SETTINGS_LANGUAGE": "Language",
		"SETTINGS_TEXT_SPEED": "Text Speed",
		"SETTINGS_TEXT_SIZE": "Text Size",
		"SETTINGS_PREVIEW": "Preview",
		"SETTINGS_RESET": "Reset to Default",
		"WINDOW_MODE_WINDOWED": "Windowed",
		"WINDOW_MODE_BORDERLESS": "Fullscreen (Borderless)",
		"WINDOW_MODE_EXCLUSIVE": "Fullscreen (Exclusive)",
		"TEXT_SIZE_SMALL": "Small",
		"TEXT_SIZE_NORMAL": "Normal",
		"TEXT_SIZE_LARGE": "Large",
		"TEXT_SPEED_INSTANT": "Instant",
		"PAUSE_TITLE": "Paused",
		"QUIT_CONFIRM": "Quit the game?",
		"PAUSE_QUIT_CONFIRM": "Return to the title screen?\nUnsaved progress will be lost.",
		"CONFIRM_YES": "Yes",
		"CONFIRM_NO": "No",
		"LOADING": "Loading",
		"PREVIEW_SAMPLE": "Let's begin the examination. What brings you here?",
		"FIELD_MOVE_HINT": "Move with WASD · arrow keys · stick",
		"FIELD_INTERACT_HINT": "{0}  —  Space · Click · Pad A",
		"STUB_TITLE": "Chapter 1 — The Plant Hospital",
		"STUB_NOTICE": "The chapter itself is not authored yet (design/requirements/ch1 is empty).",
		"STUB_HINT": "Click · Space · Enter · Pad A to advance / ESC to pause",
		"STUB_LINE_1": "Chapter 1 dialogue goes here.",
		"STUB_LINE_2": "The text speed and size settings apply to this line directly.",
		"STUB_LINE_3": "Press ESC to check the pause menu.",
	},
}


func _ready() -> void:
	_register_translations()


func _register_translations() -> void:
	for locale_code: String in STRINGS.keys():
		var translation := Translation.new()
		translation.locale = locale_code
		_fill(translation, STRINGS[locale_code])
		for table: Script in EPISODE_TABLES:
			var constants: Dictionary = table.get_script_constant_map()
			var episode_strings: Dictionary = constants.get("STRINGS", {})
			if episode_strings.has(locale_code):
				_fill(translation, episode_strings[locale_code])
			if locale_code == DEFAULT_LOCALE:
				_fill_dialogue_source(translation, String(constants.get("DIALOGUE_PATH", "")))
			else:
				var dialogue_strings: Dictionary = constants.get("DIALOGUE", {})
				_fill(translation, dialogue_strings.get(locale_code, {}), DIALOGUE_CONTEXT)
		TranslationServer.add_translation(translation)


func _fill(translation: Translation, table: Dictionary, context: StringName = &"") -> void:
	for key: String in table.keys():
		translation.add_message(key, table[key], context)


## 대본 원문을 기본 언어 번역으로 등록한다.
## [ID:키] 가 붙은 대사는 키로 찾기 때문에, 원문 언어에도 키 → 원문 항목이 있어야 한다.
func _fill_dialogue_source(translation: Translation, path: String) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_error("대본을 찾을 수 없다: %s" % path)
		return
	var dialogue: DialogueResource = load(path)
	for line: Dictionary in dialogue.lines.values():
		if line.has("static_id"):
			translation.add_message(line["static_id"], line.get("text", ""), DIALOGUE_CONTEXT)


func locale_label(code: String) -> String:
	for entry: Dictionary in SUPPORTED_LOCALES:
		if entry["code"] == code:
			return String(entry["label"])
	return code


func locale_index(code: String) -> int:
	for i: int in SUPPORTED_LOCALES.size():
		if SUPPORTED_LOCALES[i]["code"] == code:
			return i
	return 0
