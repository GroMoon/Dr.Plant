# 코드 컨벤션

## GDScript

- 파일명·폴더명: `snake_case` (예: `player_controller.gd`)
- 클래스명·노드명: `PascalCase`
- 변수·함수: `snake_case`, private은 `_` 접두사
- 상수: `UPPER_SNAKE_CASE`
- 시그널: 과거형 동사 (`health_changed`, `plant_watered`)
- 타입 힌트를 명시한다: `var hp: int = 100`, `func heal(amount: int) -> void:`

## 씬

- 씬 파일: `scenes/` 하위, `snake_case.tscn`
- 스크립트: `scripts/` 하위, 대응하는 씬과 같은 이름
- 에셋: `assets/` 하위 (`sprites/`, `audio/`, `fonts/`)
