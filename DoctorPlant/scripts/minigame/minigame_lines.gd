extends RefCounted
## 진찰 미니게임 문자열 테이블. localization.gd 가 읽어 TranslationServer 에 등록한다.
##
## 미니게임마다 <키>_TITLE / _HINT / _CONTROLS 세 줄은 반드시 있어야 한다(MinigameHost 가 쓴다).
## 요구사항: design/requirements/ch1/02-minigame.md
## 영어는 임시 번역이다.

const STRINGS: Dictionary = {
	"ko": {
		# ── 공통 ───────────────────────────────────────────────────
		"MG_HEADER": "진찰",
		"MG_TUTORIAL": "진찰할 때마다 처치 과제 하나가 무작위로 주어집니다. 안내를 읽고 차분히 해 보세요. 실수해도 다시 할 수 있어요.",
		"MG_READY": "준비…",
		"MG_CLEAR": "완료!",

		# ── 청진 주파수 맞추기 ─────────────────────────────────────
		"MG_STETHO_TITLE": "청진 주파수 맞추기",
		"MG_STETHO_HINT": "슬라이더를 움직여 내 파형(초록)을 환자의 파형(분홍)에 겹친 채로 유지하세요. 환자의 파형은 조금씩 흔들려요.",
		"MG_STETHO_CONTROLS": "마우스로 슬라이더 끌기 · ↑↓ 슬라이더 고르기 · ←→ 조절",
		"MG_STETHO_PITCH": "음높이",
		"MG_STETHO_VOLUME": "크기",
		"MG_STETHO_PATIENT": "환자",
		"MG_STETHO_MINE": "청진기",
		"MG_STETHO_PROGRESS": "맞춤 {0}%",

		# ── 잎 닦기 ────────────────────────────────────────────────
		"MG_LEAF_TITLE": "잎 닦기",
		"MG_LEAF_HINT": "잎에 묻은 얼룩을 문질러 닦으세요. 너무 세게(빠르게) 문지르면 잎이 상해요.",
		"MG_LEAF_CONTROLS": "마우스 왼쪽 버튼을 누른 채 문지르기 · 방향키로 움직이며 Space 누르고 있기",
		"MG_LEAF_PROGRESS": "얼룩 {0} / {1}",
		"MG_LEAF_FORCE": "힘",
		"MG_LEAF_TOO_HARD": "살살! 잎이 상해요.",
		"MG_LEAF_FAINT_LEFT": "아직 희미한 얼룩이 남아 있어요. 잘 살펴보세요.",

		# ── 불안 피하기 ────────────────────────────────────────────
		"MG_DODGE_TITLE": "불안 피하기",
		"MG_DODGE_HINT": "환자의 불안이 쏟아집니다. 씨앗을 움직여 끝까지 피하세요. 세 번 맞으면 그 구간을 다시 버텨야 해요.",
		"MG_DODGE_CONTROLS": "WASD · 방향키 · 왼쪽 스틱 (마우스 왼쪽 버튼을 누르면 커서를 따라가요)",
		"MG_DODGE_PROGRESS": "버티기 {0}%",
		"MG_DODGE_ANXIETY": "불안",
		"MG_DODGE_HIT": "앗!",
		"MG_DODGE_RESET": "마음을 가다듬고 다시!",

		# ── 디파인 계량 ────────────────────────────────────────────
		"MG_MEASURE_TITLE": "디파인 계량",
		"MG_MEASURE_HINT": "누르고 있으면 재료가 부어져요. 초록 눈금 안에서 멈추세요. 오래 누를수록 빨라지고, 손을 떼도 조금 더 흘러요.",
		"MG_MEASURE_CONTROLS": "마우스 왼쪽 · Space · Enter · 패드 A 누르고 있기",
		"MG_MEASURE_PROGRESS": "계량 {0} / {1}",
		"MG_MEASURE_SUN": "햇빛 시럽",
		"MG_MEASURE_DEW": "아침 이슬",
		"MG_MEASURE_ROOT": "뿌리 추출액",
		"MG_MEASURE_OVERFLOW": "너무 많이 부었어요! 비우고 다시 부어 주세요.",
		"MG_MEASURE_GOOD": "딱 맞아요!",

		# ── 알약 분류 ──────────────────────────────────────────────
		"MG_PILL_TITLE": "알약 분류",
		"MG_PILL_HINT": "내려오는 알약을 맨 아래 것부터 바구니에 나누세요. 금 간 알약은 모양과 상관없이 폐기!",
		"MG_PILL_CONTROLS": "← 둥근 알약 · → 캡슐 · ↓ 폐기 (바구니를 클릭해도 돼요)",
		"MG_PILL_PROGRESS": "분류 {0} / {1}",
		"MG_PILL_BIN_ROUND": "← 둥근 알약",
		"MG_PILL_BIN_CAPSULE": "캡슐 →",
		"MG_PILL_BIN_TRASH": "↓ 금 간 약 (폐기)",
		"MG_PILL_WRONG": "잘못 넣었어요!",
		"MG_PILL_MISSED": "놓쳤어요!",
	},
	"en": {
		"MG_HEADER": "Examination",
		"MG_TUTORIAL": "Each examination gives you one random treatment task. Read the instructions and take it calmly. You can always try again.",
		"MG_READY": "Ready…",
		"MG_CLEAR": "Done!",

		"MG_STETHO_TITLE": "Tune the Stethoscope",
		"MG_STETHO_HINT": "Move the sliders so your wave (green) overlaps the patient's wave (pink), and keep it there. The patient's wave drifts a little.",
		"MG_STETHO_CONTROLS": "Drag the sliders · ↑↓ pick a slider · ←→ adjust",
		"MG_STETHO_PITCH": "Pitch",
		"MG_STETHO_VOLUME": "Volume",
		"MG_STETHO_PATIENT": "Patient",
		"MG_STETHO_MINE": "Stethoscope",
		"MG_STETHO_PROGRESS": "Match {0}%",

		"MG_LEAF_TITLE": "Wipe the Leaf",
		"MG_LEAF_HINT": "Rub the stains off the leaf. Rubbing too hard (too fast) hurts the leaf.",
		"MG_LEAF_CONTROLS": "Hold the left mouse button and rub · or move with the arrow keys while holding Space",
		"MG_LEAF_PROGRESS": "Stains {0} / {1}",
		"MG_LEAF_FORCE": "Force",
		"MG_LEAF_TOO_HARD": "Gently! You're hurting the leaf.",
		"MG_LEAF_FAINT_LEFT": "Some faint stains are still left. Look closely.",

		"MG_DODGE_TITLE": "Dodge the Anxiety",
		"MG_DODGE_HINT": "The patient's anxiety pours out. Move the seed and dodge until the end. Three hits and you must endure that part again.",
		"MG_DODGE_CONTROLS": "WASD · Arrow keys · Left stick (hold the left mouse button to follow the cursor)",
		"MG_DODGE_PROGRESS": "Endure {0}%",
		"MG_DODGE_ANXIETY": "Anxiety",
		"MG_DODGE_HIT": "Ouch!",
		"MG_DODGE_RESET": "Take a breath and try again!",

		"MG_MEASURE_TITLE": "Measure the Define",
		"MG_MEASURE_HINT": "Hold to pour. Stop inside the green mark. The longer you hold, the faster it flows, and a little more drips after you let go.",
		"MG_MEASURE_CONTROLS": "Hold left mouse · Space · Enter · Pad A",
		"MG_MEASURE_PROGRESS": "Measured {0} / {1}",
		"MG_MEASURE_SUN": "Sunlight Syrup",
		"MG_MEASURE_DEW": "Morning Dew",
		"MG_MEASURE_ROOT": "Root Extract",
		"MG_MEASURE_OVERFLOW": "Too much! Empty it and pour again.",
		"MG_MEASURE_GOOD": "Just right!",

		"MG_PILL_TITLE": "Sort the Pills",
		"MG_PILL_HINT": "Sort the falling pills into the bins, lowest first. Cracked pills go to the trash, whatever their shape!",
		"MG_PILL_CONTROLS": "← Round · → Capsule · ↓ Trash (or click a bin)",
		"MG_PILL_PROGRESS": "Sorted {0} / {1}",
		"MG_PILL_BIN_ROUND": "← Round",
		"MG_PILL_BIN_CAPSULE": "Capsule →",
		"MG_PILL_BIN_TRASH": "↓ Cracked (trash)",
		"MG_PILL_WRONG": "Wrong bin!",
		"MG_PILL_MISSED": "Missed one!",
	},
}
