# Doctor Plant — 작업 지침

Claude Code가 이 저장소에서 작업할 때 따르는 최상위 지침이다.
세부 지침은 아래 import로 자동 로드된다.

@guidelines/workflow.md
@guidelines/code-conventions.md

## 프로젝트 개요

- **게임 이름**: Doctor Plant
- **엔진**: Godot 4.7.1 (Forward+)
- **Godot 프로젝트 경로**: `DoctorPlant/` (저장소 루트가 아님 — MCP 도구의 `projectPath`는 항상 이 폴더)

## 폴더 구조

```
Dr.Plant/                    ← 저장소 루트 (작업 디렉터리)
├── CLAUDE.md                ← 이 파일. 지침의 진입점
├── guidelines/              ← Claude에게 주는 세부 지침
├── design/                  ← 기획
│   ├── story/               ← 스토리·세계관·시나리오
│   └── requirements/        ← 기능 요구사항·명세
└── DoctorPlant/             ← Godot 프로젝트 본체
```

## 이름 규칙

- **폴더명·파일명은 영어, 공백 없이.** 문서 제목과 내용은 한글로 쓴다.
  한글 경로는 Windows 콘솔·빌드 스크립트·CI에서 인코딩이 깨질 수 있다.
- 문서 파일은 번호 접두사로 읽는 순서를 고정한다 (`00-`, `10-`, `20-`).

## 기본 규칙

1. 기획 문서(`design/`)는 **구현의 근거**다. 구현 요청을 받으면 관련 요구사항/스토리 문서를 먼저 읽는다.
2. 기획 문서와 코드가 어긋나면 임의로 코드를 맞추지 말고 **어긋난 지점을 먼저 보고**한다.
3. 기획 문서는 요청받았을 때만 수정한다. 구현하면서 조용히 고쳐 쓰지 않는다.
4. `design/`, `guidelines/` 는 Godot 프로젝트 **바깥**에 둔다. 안에 넣으면 `res://`로 임포트되어 빌드에 포함된다.
