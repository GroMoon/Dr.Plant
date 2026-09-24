extends RefCounted
## 챕터 1 / 1화 진행 대본. episode_player.gd 가 위에서부터 실행한다.
## 원문: design/requirements/ch1/03-ep1-script.md
##
## 명령 종류
##   title/end  : 장·에피소드 카드            {label, title, sub, time}
##   room       : 필드 씬 교체                {path, player, spawn, camera, zoom}
##   tint       : 방 전체 색조(시간대 표현)   {color, time}
##   npc        : 방 안 NPC 표시/이동         {id, show, at}
##   player     : 플레이어 표시/이동          {show, at}
##   enable     : 조사 지점 켜고 끄기         {id, on}
##   cam_set    : 카메라 즉시 이동            {at, zoom}
##   cam        : 카메라 이동 연출            {to, zoom, time}
##   cam_follow : 카메라가 플레이어를 따라감  {on, zoom}
##   fade       : 화면 암전                   {to, time}
##   wait       : 대기                        {time}
##   sfx        : 효과음                      {id}
##   amb        : 반복 환경음                 {id, on, db}
##   say/sys/notice : 대사 한 줄              {who, key}
##   hide_dialogue  : 대사창 닫기
##   choice     : 선택지                      {key, options:[{key, flag, value, then}]}
##   minigame   : 진찰 미니게임               {tutorial}
##   field      : 필드 조작 구간              {hint, exit:[조사지점 id], zoom}
##   view       : 전면 연출 씬                {scene, time}
##   view_close : 연출 씬 닫기                {time}
##   save       : 진행 저장                   {checkpoint}
##   flag       : 플래그 지정                 {flag, value}

const ROOM_LOBBY: String = "res://scenes/field/room_lobby.tscn"
const ROOM_CLINIC: String = "res://scenes/field/room_clinic.tscn"
const VIEW_SUNBATHING: String = "res://scenes/ch1/sunbathing_view.tscn"

const WARM_MORNING: Color = Color(1.0, 0.867, 0.616, 0.18)
const WARM_AFTERNOON: Color = Color(1.0, 0.816, 0.475, 0.30)
const EVENING: Color = Color(0.184, 0.157, 0.341, 0.38)

const COMMANDS: Array = [
	# ══════════════════════════════════════════════════════════════════
	# 장면 1 : 병원 내부(오전) / 애니메이션
	# ══════════════════════════════════════════════════════════════════
	{"t": "title", "label": "EP1_CHAPTER_LABEL", "title": "EP1_CHAPTER_TITLE", "sub": "EP1_EPISODE_LABEL", "time": 2.4},
	{"t": "room", "path": ROOM_LOBBY, "player": false},
	{"t": "tint", "color": WARM_MORNING, "time": 0.0},
	{"t": "cam_set", "at": Vector2(600.0, 450.0), "zoom": Vector2(1.6, 1.6)},
	{"t": "amb", "id": "murmur", "on": true, "db": -16.0},
	{"t": "fade", "to": 0.0, "time": 2.0},

	# 왼쪽에서 오른쪽으로 천천히 슬라이드하며 전체 배경을 보여준다.
	{"t": "cam", "to": Vector2(1800.0, 450.0), "time": 9.0},

	# 걸어다니는 식물들의 신발 클로즈업 + 발소리.
	{"t": "amb", "id": "steps", "on": true, "db": -8.0},
	{"t": "cam", "to": Vector2(1480.0, 620.0), "zoom": Vector2(3.4, 3.4), "time": 2.6},
	{"t": "wait", "time": 2.2},
	{"t": "amb", "id": "steps", "on": false},

	# 똑똑. 노크 뒤에 문이 열리는 소리와 함께 페이드 아웃.
	{"t": "sfx", "id": "knock"},
	{"t": "wait", "time": 1.4},
	{"t": "sfx", "id": "door_open"},
	{"t": "fade", "to": 1.0, "time": 1.8},
	{"t": "amb", "id": "murmur", "on": false},
	{"t": "wait", "time": 0.8},

	# ══════════════════════════════════════════════════════════════════
	# 장면 2 : 진료실
	# ══════════════════════════════════════════════════════════════════
	{"t": "room", "path": ROOM_CLINIC, "player": true, "spawn": Vector2(700.0, 620.0)},
	{"t": "tint", "color": WARM_MORNING, "time": 0.0},
	{"t": "cam_set", "at": Vector2(700.0, 450.0), "zoom": Vector2(1.6, 1.6)},
	{"t": "enable", "id": "sun_button", "on": false},
	{"t": "npc", "id": "Patient", "show": true},
	{"t": "fade", "to": 0.0, "time": 1.2},

	# ── 환자1 ─────────────────────────────────────────────────────────
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_01"},
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_02"},
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_03"},
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_04"},
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_05"},

	# (미니게임 화면으로 전환, 튜토리얼 진행)
	{"t": "minigame", "tutorial": true, "patient": "CH_PATIENT_1"},

	{"t": "choice", "key": "EP1_SYS_PRESCRIBE", "options": [
		{"key": "EP1_OPT_PRESCRIBE", "flag": "ep1_prescribed_p1", "value": true},
		{"key": "EP1_OPT_NO_PRESCRIBE", "flag": "ep1_prescribed_p1", "value": false},
	]},
	{"t": "say", "who": "CH_PATIENT_1", "key": "EP1_P1_06"},

	# 걸어 나가는 발소리 뒤에, 문이 열리고 닫히는 소리.
	{"t": "hide_dialogue"},
	{"t": "npc", "id": "Patient", "show": false},
	{"t": "amb", "id": "steps", "on": true, "db": -10.0},
	{"t": "wait", "time": 1.6},
	{"t": "amb", "id": "steps", "on": false},
	{"t": "sfx", "id": "door_open"},
	{"t": "wait", "time": 0.9},
	{"t": "sfx", "id": "door_close"},
	{"t": "wait", "time": 0.6},
	{"t": "save", "checkpoint": "ep1_s2_clinic"},

	# ── 진료실 둘러보기 (컴퓨터 / 액자A / 액자B / 스케줄러 / 문) ──────
	{"t": "field", "hint": "EP1_HINT_CLINIC", "exit": ["door"]},

	# ── 환자2 ─────────────────────────────────────────────────────────
	{"t": "npc", "id": "Patient", "show": true},
	{"t": "cam_set", "at": Vector2(700.0, 450.0), "zoom": Vector2(1.6, 1.6)},
	{"t": "say", "who": "CH_PATIENT_2", "key": "EP1_P2_01"},
	{"t": "sys", "key": "EP1_SYS_NEED_EXAM"},
	{"t": "minigame", "tutorial": false, "patient": "CH_PATIENT_2"},
	{"t": "choice", "key": "EP1_SYS_PRESCRIBE", "options": [
		{"key": "EP1_OPT_PRESCRIBE", "flag": "ep1_prescribed_p2", "value": true},
		{"key": "EP1_OPT_NO_PRESCRIBE", "flag": "ep1_prescribed_p2", "value": false},
	]},
	{"t": "say", "who": "CH_PATIENT_2", "key": "EP1_P2_02"},

	{"t": "hide_dialogue"},
	{"t": "npc", "id": "Patient", "show": false},
	{"t": "amb", "id": "steps", "on": true, "db": -10.0},
	{"t": "wait", "time": 1.6},
	{"t": "amb", "id": "steps", "on": false},
	{"t": "sfx", "id": "door_open"},
	{"t": "wait", "time": 0.9},
	{"t": "sfx", "id": "door_close"},

	# ── 검은 화면 유지 → 알림음 ───────────────────────────────────────
	{"t": "fade", "to": 1.0, "time": 1.2},
	{"t": "wait", "time": 2.0},
	{"t": "sfx", "id": "chime"},
	{"t": "wait", "time": 1.0},
	{"t": "notice", "key": "EP1_NOTICE_SUNBATH"},
	{"t": "hide_dialogue"},
	{"t": "fade", "to": 0.0, "time": 1.4},

	# ── 14시. 해바라기 ────────────────────────────────────────────────
	{"t": "tint", "color": WARM_AFTERNOON, "time": 2.0},
	{"t": "sys", "key": "EP1_SYS_AFTERNOON"},
	{"t": "enable", "id": "door", "on": false},
	{"t": "enable", "id": "sun_button", "on": true},
	{"t": "save", "checkpoint": "ep1_s2_sunbathing"},
	{"t": "field", "hint": "EP1_HINT_WINDOW", "exit": ["sun_button"]},

	{"t": "sfx", "id": "window_open"},
	{"t": "view", "scene": VIEW_SUNBATHING, "time": 1.2},
	{"t": "sys", "key": "EP1_SYS_OUTSIDE_1"},
	{"t": "sys", "key": "EP1_SYS_OUTSIDE_2"},
	{"t": "sys", "key": "EP1_SYS_SUNBATH_1"},
	{"t": "sys", "key": "EP1_SYS_SUNBATH_2"},
	{"t": "sys", "key": "EP1_SYS_SUNBATH_3"},
	{"t": "hide_dialogue"},
	{"t": "fade", "to": 1.0, "time": 1.8},
	{"t": "view_close", "time": 0.0},
	{"t": "wait", "time": 0.8},

	# ══════════════════════════════════════════════════════════════════
	# 장면 3 : 병원 내부(저녁)
	# ══════════════════════════════════════════════════════════════════
	{"t": "room", "path": ROOM_LOBBY, "player": true, "spawn": Vector2(1180.0, 640.0)},
	{"t": "tint", "color": EVENING, "time": 0.0},
	{"t": "cam_set", "at": Vector2(1180.0, 450.0), "zoom": Vector2(1.6, 1.6)},
	{"t": "npc", "id": "Staff1", "show": true},
	{"t": "npc", "id": "Staff2", "show": true},
	{"t": "fade", "to": 0.0, "time": 1.4},
	{"t": "save", "checkpoint": "ep1_s3_evening"},

	{"t": "say", "who": "CH_STAFF_1", "key": "EP1_STAFF1_01"},
	{"t": "say", "who": "CH_STAFF_1", "key": "EP1_STAFF1_02"},
	{"t": "say", "who": "CH_STAFF_2", "key": "EP1_STAFF2_01"},

	# 대화창에서 플레이화면으로 전환. 문 밖으로 나가려고 하면 페이드 아웃.
	{"t": "field", "hint": "EP1_HINT_EXIT", "exit": ["exit_door"]},
	{"t": "sfx", "id": "door_open"},
	{"t": "sys", "key": "EP1_SYS_TIRED"},
	{"t": "hide_dialogue"},
	{"t": "fade", "to": 1.0, "time": 2.2},
	{"t": "end", "title": "EP1_END", "time": 2.4},
]
