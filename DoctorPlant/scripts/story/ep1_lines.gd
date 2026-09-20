extends RefCounted
## 챕터 1 / 1화 대사·나레이션 문자열 테이블.
## localization.gd 가 이 테이블을 읽어 TranslationServer 에 등록하므로
## 씬에서는 다른 UI 문자열과 똑같이 tr("EP1_...") 로 쓴다.
##
## 원문: design/requirements/ch1/03. story progress(1ep).md
## 영어는 임시 번역이다(요구사항 메모 참조).

const STRINGS: Dictionary = {
	"ko": {
		# ── 화자 이름 ──────────────────────────────────────────────
		"CH_SYSTEM": "SYSTEM",
		"CH_NOTICE": "알림",
		"CH_PATIENT_1": "환자1",
		"CH_PATIENT_2": "환자2",
		"CH_STAFF_1": "직원1",
		"CH_STAFF_2": "직원2",

		# ── 타이틀 카드 ────────────────────────────────────────────
		"EP1_CHAPTER_LABEL": "CHAPTER 1",
		"EP1_CHAPTER_TITLE": "식물들의 병원",
		"EP1_EPISODE_LABEL": "EP. 1",
		"EP1_END": "1화 끝",

		# ── 장면 2 : 진료실 / 환자1 ────────────────────────────────
		"EP1_P1_01": "안녕하세요, 선생님.",
		"EP1_P1_02": "엊그제부터 두통이 좀 있었는데, 그래서 그런지 입맛도 없는 것 같아요.",
		"EP1_P1_03": "아, 어느쪽이 더 아픈지요?",
		"EP1_P1_04": "…음, 머리 옆쪽이면서 왼쪽으로 아픈 것 같아요.",
		"EP1_P1_05": "그러니까… 웅웅 울리기도 하고, 누군가 두들기는 것 같기도 하고…",
		"EP1_P1_06": "오늘도 감사해요, 선생님!",

		# ── 처방 선택 ──────────────────────────────────────────────
		"EP1_SYS_PRESCRIBE": "약을 처방해줄까?",
		"EP1_OPT_PRESCRIBE": "처방한다",
		"EP1_OPT_NO_PRESCRIBE": "처방하지 않는다",

		# ── 진료실 오브젝트 ────────────────────────────────────────
		"EP1_OBJ_COMPUTER": "컴퓨터",
		"EP1_OBJ_FRAME_A": "액자 A",
		"EP1_OBJ_FRAME_B": "액자 B",
		"EP1_OBJ_SCHEDULER": "스케줄러",
		"EP1_OBJ_DOOR": "문",
		"EP1_OBJ_WINDOW": "창문",
		"EP1_OBJ_SUN_BUTTON": "해바라기 단추",

		"EP1_OPT_PATIENT_LIST": "TODAY 환자 리스트",
		"EP1_OPT_MESSENGER": "원내 메신저",
		"EP1_OPT_INTERNET": "인터넷",
		"EP1_OPT_CLOSE": "닫는다",

		"EP1_SYS_COMPUTER": "진료실 컴퓨터. 화면에 몇 가지 항목이 떠 있다.",
		"EP1_SYS_PATIENT_LIST": "TODAY 환자 리스트. 오늘 예약된 이름들이 줄지어 있다. (세부 내용 미정)",
		"EP1_SYS_MESSENGER": "원내 메신저. 읽지 않은 대화는 없다. (세부 내용 미정)",
		"EP1_SYS_INTERNET": "인터넷. 딱히 찾아볼 것이 떠오르지 않는다. (세부 내용 미정)",
		"EP1_SYS_FRAME_A": "액자 A. 의사 면허증이 걸려 있다.",
		"EP1_SYS_FRAME_B": "액자 B. 식물 해부도가 걸려 있다.",
		"EP1_SYS_SCHEDULER": "오늘 스케줄을 확인했다. 오후 2시마다 '해바라기'라고 적혀 있다.",
		"EP1_SYS_CALL_NEXT": "다음 환자를 호출했다.",

		# ── 장면 2 : 진료실 / 환자2 ────────────────────────────────
		"EP1_P2_01": "지난번에 울렁거린다고 말씀드렸던 거, 많이 좋아졌어요~ 아직은 약이 필요해서, 처방받고 싶어요.",
		"EP1_SYS_NEED_EXAM": "약을 처방하기 전에는 진료과정이 꼭 필요합니다.",
		"EP1_P2_02": "네~ 고맙습니다.",

		# ── 장면 2 : 해바라기 ──────────────────────────────────────
		"EP1_NOTICE_SUNBATH": "해바라기 10분 전입니다.",
		"EP1_SYS_AFTERNOON": "14시. 진료실 내부로 들어오는 햇빛이 강해진다. 창문을 열고 햇빛을 만끽하고 싶어진다.",
		"EP1_SYS_OUTSIDE_1": "창밖에는 다양한 식물들이 햇볕을 쬐려고 창밖으로 얼굴을 내밀거나, 건물 밖으로 나와 있다.",
		"EP1_SYS_OUTSIDE_2": "하나같이 태양을 보며 가만히 서 있다. 따스한 햇빛과 대비되게, 도시는 숨죽이듯 멈춰 있다.",
		"EP1_SYS_SUNBATH_1": "모든 식물들은 매일 같은 시간에 햇빛을 쬐어야 합니다.",
		"EP1_SYS_SUNBATH_2": "이 과정을 '해바라기'라고 합니다.",
		"EP1_SYS_SUNBATH_3": "따스한 기운이 충만해진다.",

		# ── 장면 3 : 병원 내부(저녁) ───────────────────────────────
		"EP1_STAFF1_01": "내일 얼마나 바쁘려고 오늘 이렇게 한가했대요?",
		"EP1_STAFF1_02": "어우, 마음의 준비하고 내일 봬요~ 원장님.",
		"EP1_STAFF2_01": "수고하셨어요~",
		"EP1_SYS_TIRED": "피로가 몰려온다.",

		# ── 필드 안내 ──────────────────────────────────────────────
		"EP1_HINT_CLINIC": "진료실을 둘러보자. 문으로 다가가면 다음 환자를 부른다.",
		"EP1_HINT_WINDOW": "창문으로 다가가 보자.",
		"EP1_HINT_EXIT": "문 밖으로 나가 보자.",
	},
	"en": {
		"CH_SYSTEM": "SYSTEM",
		"CH_NOTICE": "Announcement",
		"CH_PATIENT_1": "Patient 1",
		"CH_PATIENT_2": "Patient 2",
		"CH_STAFF_1": "Staff 1",
		"CH_STAFF_2": "Staff 2",

		"EP1_CHAPTER_LABEL": "CHAPTER 1",
		"EP1_CHAPTER_TITLE": "The Plant Hospital",
		"EP1_EPISODE_LABEL": "EP. 1",
		"EP1_END": "End of Episode 1",

		"EP1_P1_01": "Good morning, doctor.",
		"EP1_P1_02": "I've had a bit of a headache since the day before yesterday, and I think that's why I have no appetite either.",
		"EP1_P1_03": "Ah, which side hurts more?",
		"EP1_P1_04": "...Hmm, it's on the side of my head, toward the left, I think.",
		"EP1_P1_05": "It sort of... buzzes, and sometimes it feels like someone is knocking on it...",
		"EP1_P1_06": "Thank you again today, doctor!",

		"EP1_SYS_PRESCRIBE": "Prescribe medication?",
		"EP1_OPT_PRESCRIBE": "Prescribe",
		"EP1_OPT_NO_PRESCRIBE": "Do not prescribe",

		"EP1_OBJ_COMPUTER": "Computer",
		"EP1_OBJ_FRAME_A": "Frame A",
		"EP1_OBJ_FRAME_B": "Frame B",
		"EP1_OBJ_SCHEDULER": "Scheduler",
		"EP1_OBJ_DOOR": "Door",
		"EP1_OBJ_WINDOW": "Window",
		"EP1_OBJ_SUN_BUTTON": "Sunbathing Button",

		"EP1_OPT_PATIENT_LIST": "TODAY patient list",
		"EP1_OPT_MESSENGER": "Internal messenger",
		"EP1_OPT_INTERNET": "Internet",
		"EP1_OPT_CLOSE": "Close",

		"EP1_SYS_COMPUTER": "The clinic computer. A few items are up on the screen.",
		"EP1_SYS_PATIENT_LIST": "TODAY patient list. Today's appointments are lined up. (details TBD)",
		"EP1_SYS_MESSENGER": "Internal messenger. No unread threads. (details TBD)",
		"EP1_SYS_INTERNET": "The internet. Nothing in particular comes to mind to look up. (details TBD)",
		"EP1_SYS_FRAME_A": "Frame A. A medical license hangs here.",
		"EP1_SYS_FRAME_B": "Frame B. An anatomical chart of plants hangs here.",
		"EP1_SYS_SCHEDULER": "You check today's schedule. Every day at 2 PM it reads 'Sunbathing'.",
		"EP1_SYS_CALL_NEXT": "You call in the next patient.",

		"EP1_P2_01": "That queasiness I mentioned last time is much better now~ I still need the medicine, so I'd like a prescription.",
		"EP1_SYS_NEED_EXAM": "An examination is always required before prescribing.",
		"EP1_P2_02": "Yes~ thank you.",

		"EP1_NOTICE_SUNBATH": "Ten minutes until Sunbathing.",
		"EP1_SYS_AFTERNOON": "2 PM. The sunlight reaching into the clinic grows stronger. You want to open the window and bask in it.",
		"EP1_SYS_OUTSIDE_1": "Outside the window, all sorts of plants lean out or step into the street to catch the sun.",
		"EP1_SYS_OUTSIDE_2": "Every one of them stands still, facing the sun. Against the warm light, the city holds its breath.",
		"EP1_SYS_SUNBATH_1": "Every plant must bask in the sunlight at the same hour each day.",
		"EP1_SYS_SUNBATH_2": "This ritual is called 'Sunbathing'.",
		"EP1_SYS_SUNBATH_3": "A warm energy fills you.",

		"EP1_STAFF1_01": "How busy must tomorrow be, for today to have been this quiet?",
		"EP1_STAFF1_02": "Ugh, brace yourself and see you tomorrow, director~",
		"EP1_STAFF2_01": "Good work today~",
		"EP1_SYS_TIRED": "Fatigue washes over you.",

		"EP1_HINT_CLINIC": "Look around the clinic. Step up to the door to call the next patient.",
		"EP1_HINT_WINDOW": "Step up to the window.",
		"EP1_HINT_EXIT": "Head out through the door.",
	},
}
