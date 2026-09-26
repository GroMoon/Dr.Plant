extends RefCounted
## 챕터 1 / 1화 문자열 테이블. localization.gd 가 읽어 TranslationServer 에 등록한다.
##
## STRINGS  : 화면 문구(타이틀 카드·필드 안내·조사 지점 이름표). 씬·코드에서 tr("EP1_...") 로 쓴다.
## DIALOGUE : 대본(DIALOGUE_PATH) 대사의 번역. 키는 대사 줄 끝의 [ID:...], 화자는 대본에 쓴 이름 그대로.
##            한국어는 대본 원문을 그대로 쓰므로 여기에는 다른 언어만 둔다.
##
## 원문: design/requirements/ch1/03-ep1-script.md
## 영어는 임시 번역이다(요구사항 메모 참조).

const DIALOGUE_PATH: String = "res://dialogue/ch1/ep1.dialogue"

const STRINGS: Dictionary = {
	"ko": {
		# ── 타이틀 카드 ────────────────────────────────────────────
		"EP1_CHAPTER_LABEL": "CHAPTER 1",
		"EP1_CHAPTER_TITLE": "식물들의 병원",
		"EP1_EPISODE_LABEL": "EP. 1",
		"EP1_END": "1화 끝",

		# ── 진료실 오브젝트 이름표 ─────────────────────────────────
		"EP1_OBJ_COMPUTER": "컴퓨터",
		"EP1_OBJ_FRAME_A": "액자 A",
		"EP1_OBJ_FRAME_B": "액자 B",
		"EP1_OBJ_SCHEDULER": "스케줄러",
		"EP1_OBJ_DOOR": "문",
		"EP1_OBJ_WINDOW": "창문",
		"EP1_OBJ_SUN_BUTTON": "해바라기 단추",

		# ── 필드 안내 ──────────────────────────────────────────────
		"EP1_HINT_CLINIC": "진료실을 둘러보자. 문으로 다가가면 다음 환자를 부른다.",
		"EP1_HINT_WINDOW": "창문으로 다가가 보자.",
		"EP1_HINT_EXIT": "문 밖으로 나가 보자.",
	},
	"en": {
		"EP1_CHAPTER_LABEL": "CHAPTER 1",
		"EP1_CHAPTER_TITLE": "The Plant Hospital",
		"EP1_EPISODE_LABEL": "EP. 1",
		"EP1_END": "End of Episode 1",

		"EP1_OBJ_COMPUTER": "Computer",
		"EP1_OBJ_FRAME_A": "Frame A",
		"EP1_OBJ_FRAME_B": "Frame B",
		"EP1_OBJ_SCHEDULER": "Scheduler",
		"EP1_OBJ_DOOR": "Door",
		"EP1_OBJ_WINDOW": "Window",
		"EP1_OBJ_SUN_BUTTON": "Sunbathing Button",

		"EP1_HINT_CLINIC": "Look around the clinic. Step up to the door to call the next patient.",
		"EP1_HINT_WINDOW": "Step up to the window.",
		"EP1_HINT_EXIT": "Head out through the door.",
	},
}

const DIALOGUE: Dictionary = {
	"en": {
		# ── 화자 ───────────────────────────────────────────────────
		"SYSTEM": "SYSTEM",
		"알림": "Announcement",
		"환자1": "Patient 1",
		"환자2": "Patient 2",
		"직원1": "Staff 1",
		"직원2": "Staff 2",

		# ── 장면 2 : 진료실 / 환자1 ────────────────────────────────
		"EP1_P1_01": "Good morning, doctor.",
		"EP1_P1_02": "I've had a bit of a headache since the day before yesterday, and I think that's why I have no appetite either.",
		"EP1_P1_03": "Ah, which side hurts more?",
		"EP1_P1_04": "...Hmm, it's on the side of my head, toward the left, I think.",
		"EP1_P1_05": "It sort of... buzzes, and sometimes it feels like someone is knocking on it...",
		"EP1_P1_PRESCRIBE_Q": "Prescribe medication?",
		"EP1_P1_PRESCRIBE_YES": "Prescribe",
		"EP1_P1_PRESCRIBE_NO": "Do not prescribe",
		"EP1_P1_06": "Thank you again today, doctor!",

		# ── 장면 2 : 진료실 / 환자2 ────────────────────────────────
		"EP1_P2_01": "That queasiness I mentioned last time is much better now~ I still need the medicine, so I'd like a prescription.",
		"EP1_SYS_NEED_EXAM": "An examination is always required before prescribing.",
		"EP1_P2_PRESCRIBE_Q": "Prescribe medication?",
		"EP1_P2_PRESCRIBE_YES": "Prescribe",
		"EP1_P2_PRESCRIBE_NO": "Do not prescribe",
		"EP1_P2_02": "Yes~ thank you.",

		# ── 장면 2 : 해바라기 ──────────────────────────────────────
		"EP1_NOTICE_SUNBATH": "Ten minutes until Sunbathing.",
		"EP1_SYS_AFTERNOON": "2 PM. The sunlight reaching into the clinic grows stronger. You want to open the window and bask in it.",
		"EP1_SYS_OUTSIDE_1": "Outside the window, all sorts of plants lean out or step into the street to catch the sun.",
		"EP1_SYS_OUTSIDE_2": "Every one of them stands still, facing the sun. Against the warm light, the city holds its breath.",
		"EP1_SYS_SUNBATH_1": "Every plant must bask in the sunlight at the same hour each day.",
		"EP1_SYS_SUNBATH_2": "This ritual is called 'Sunbathing'.",
		"EP1_SYS_SUNBATH_3": "A warm energy fills you.",

		# ── 장면 3 : 병원 내부(저녁) ───────────────────────────────
		"EP1_STAFF1_01": "How busy must tomorrow be, for today to have been this quiet?",
		"EP1_STAFF1_02": "Ugh, brace yourself and see you tomorrow, director~",
		"EP1_STAFF2_01": "Good work today~",
		"EP1_SYS_TIRED": "Fatigue washes over you.",

		# ── 조사 대사 (진료실) ─────────────────────────────────────
		"EP1_SYS_COMPUTER": "The clinic computer. A few items are up on the screen.",
		"EP1_OPT_PATIENT_LIST": "TODAY patient list",
		"EP1_SYS_PATIENT_LIST": "TODAY patient list. Today's appointments are lined up. (details TBD)",
		"EP1_OPT_MESSENGER": "Internal messenger",
		"EP1_SYS_MESSENGER": "Internal messenger. No unread threads. (details TBD)",
		"EP1_OPT_INTERNET": "Internet",
		"EP1_SYS_INTERNET": "The internet. Nothing in particular comes to mind to look up. (details TBD)",
		"EP1_OPT_CLOSE": "Close",
		"EP1_SYS_FRAME_A": "Frame A. A medical license hangs here.",
		"EP1_SYS_FRAME_B": "Frame B. An anatomical chart of plants hangs here.",
		"EP1_SYS_SCHEDULER": "You check today's schedule. Every day at 2 PM it reads 'Sunbathing'.",

		# ── 말풍선 혼잣말 (저녁 로비) ──────────────────────────────
		"EP1_CHAT_STAFF1_01": "Seen tomorrow's bookings? Ugh, it's already packed.",
		"EP1_CHAT_STAFF1_02": "The sun was lovely at Sunbathing today, wasn't it~",
		"EP1_CHAT_STAFF1_03": "Go home and get some rest too, director!",
		"EP1_CHAT_STAFF2_01": "I watered all the pots.",
		"EP1_CHAT_STAFF2_02": "Haaah... my leaves feel heavy today.",
		"EP1_CHAT_SEATED1_01": "The doctor's medicine really works...",
		"EP1_CHAT_SEATED1_02": "I'll come again tomorrow. And the day after.",
		"EP1_CHAT_SEATED2_01": "......",
		"EP1_CHAT_SEATED3_01": "The tips of my leaves keep curling lately.",
		"EP1_CHAT_SEATED3_02": "They say a strange illness is going around the next city...",
		"EP1_CHAT_SEATED4_01": "I wish Sunbathing lasted a little longer.",
		"EP1_CHAT_SEATED4_02": "The sun's already down...",
		"EP1_CHAT_SEATED5_01": "Mmm... mmm...",
		"EP1_CHAT_SEATED6_01": "I feel uneasy... for no reason...",
		"EP1_CHAT_SEATED6_02": "No, it'll be fine. The doctor is here.",
		"EP1_CHAT_WALKER1_01": "My shoelace came undone again.",
		"EP1_CHAT_WALKER1_02": "The sofas here are so soft.",
		"EP1_CHAT_WALKER2_01": "......",
		"EP1_CHAT_WALKER3_01": "It's time for water...",
		"EP1_CHAT_WALKER3_02": "That's the director, they say. That one.",
		"EP1_SYS_CALL_NEXT": "You call in the next patient.",
	},
}
