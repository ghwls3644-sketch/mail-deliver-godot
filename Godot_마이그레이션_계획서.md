# Godot 4 마이그레이션 계획서

> 우편배달부 게임 (Python+Ursina → Godot 4.x GDScript)
> 작성일: 2026-04-06

---

## 1. 마이그레이션 목표

- Ursina/Panda3D의 PBR 렌더링 한계 해결 (Nature 킷 검은색 문제)
- Godot 내장 에디터로 시각적 맵 배치 전환 (editor.py 대체)
- 장기 확장성 확보 (애니메이션, 파티클, 사운드, exe 빌드)
- 기존 게임 로직 100% 보존

---

## 2. 현재 시스템 요약 (보존 대상)

### 2.1 핵심 게임 흐름

```
타이틀 화면 → 시작하기 → 배달 플레이 → 전부 배달 완료 → 완료 화면 → 재시작
```

### 2.2 우편물 시스템

| 타입 | 이름 | 색상 | 배달 방식 | 대상 |
|------|------|------|---------|------|
| letter | 편지 | yellow | 우체통에 투입 | Mailbox |
| parcel | 소포 | rgb(139,90,43) | 건물 앞에 놓기 | Building |
| express | 등기 | azure | NPC에게 직접 전달 | NPC |

튜토리얼 우편물 3개:
- 편지 → Dolly(B_DOLLY) 빨간 우체통
- 소포 → Eric(B_ERIC) 파란 우체통 집
- 등기 → Kenny(B_KENNY) 노란 우체통 집

### 2.3 NPC 시스템 (간소화)

> 관계 단계별 승격 시스템은 **보류**. 추후 Phase 3에서 재도입 검토.

현재 구현 범위:
- NPC에게 E키로 말 걸면 가벼운 인삿말 출력
- 등기 우편물이 있으면 직접 전달 처리
- 관계 단계/승격 로직 없음 (단일 단계)

대사 예시:
```
"안녕하세요!"
"오늘 날씨 좋죠?"
"배달 감사합니다!"
```

### 2.4 플레이어 수치

| 항목 | 값 |
|------|-----|
| 이동 속도 | 5 units/sec |
| 상호작용 거리 | 2.5 units |
| 상호작용 쿨다운 | 2.0 sec |
| 시작 위치 | (0, 0.5, 2) |
| 몸통 스케일 | (0.5, 1.0, 0.5), 주황색 |
| 머리 스케일 | 0.6, 노란색, y=0.8 오프셋 |

### 2.5 NPC 수치

| 항목 | 값 |
|------|-----|
| 몸통 스케일 | (0.45, 0.9, 0.45) |
| 머리 스케일 | 0.65, y=0.75 오프셋 |
| 이름표 | y=1.4, 빌보드 |

### 2.6 카메라

| 항목 | 값 |
|------|-----|
| 투영 | Orthographic |
| 오프셋 | (-8, 13.5, 18) |
| 회전 | Pitch=30, Yaw=135, Roll=0 |
| FOV/Size | 22 |

### 2.7 조명

| 종류 | 색상 | 방향 |
|------|------|------|
| AmbientLight | (0.45, 0.45, 0.45) | - |
| DirectionalLight | (1.0, 0.92, 0.8) | H=40, P=-45 |

### 2.8 월드 세팅

| 항목 | 값 |
|------|-----|
| 배경색 | rgb(180, 210, 255) |
| 바닥 평면 스케일 | 80 |
| 바닥 텍스처 | grass_block.jpeg, 반복=(40, 40) |
| 바닥 색조 | rgb(180, 220, 150) |

### 2.9 오브젝트 세부 수치

| 오브젝트 | 항목 | 값 |
|---------|------|-----|
| 건물 이름표 | y 오프셋 | 1.2 |
| 건물 이름표 | scale | 4, 빌보드 |
| 우체통 | 스케일 | (0.35, 0.55, 0.35) |
| 상호작용 메시지 | y 오프셋 | 0.15 (오브젝트 위) |
| 상호작용 메시지 | 표시 시간 | 건물 2.0초 / NPC 2.5초 |
| 상호작용 힌트 | 화면 위치 | (0, -0.40) 하단 |

### 2.10 HUD 튜토리얼 힌트 문구 (STEPS)

| 우편물 타입 | 힌트 텍스트 | 색상 |
|-----------|-----------|------|
| letter (편지) | 빨간 우체통에 가서 편지를 넣으세요 | red |
| parcel (소포) | Eric 집 앞에서 소포를 놓으세요 | rgb(200, 140, 80) |
| express (등기) | Kenny에게 직접 등기를 전달하세요 | yellow |

---

## 3. Godot 프로젝트 구조 설계

```
mail_deliver_godot/
├── project.godot
├── assets/
│   ├── fonts/
│   │   └── malgun.ttf
│   ├── textures/
│   │   └── grass_block.jpeg
│   ├── models/           ← Kenney GLB 모델 (5개 팩)
│   │   ├── suburban/
│   │   ├── roads/
│   │   ├── commercial/
│   │   ├── nature/       ← Godot이 PBR 자동 처리
│   │   └── cars/
│   └── images/
│       └── title.png
├── scenes/
│   ├── main.tscn          ← 게임 메인 씬
│   ├── title/
│   │   └── title_screen.tscn
│   ├── game/
│   │   ├── game_world.tscn
│   │   ├── player.tscn
│   │   ├── building.tscn
│   │   ├── mailbox.tscn
│   │   └── npc.tscn
│   ├── maps/
│   │   └── tutorial.tscn  ← 맵 배치 (Godot 에디터에서 직접)
│   └── ui/
│       ├── hud.tscn
│       ├── settings_panel.tscn
│       ├── credits_panel.tscn
│       └── complete_screen.tscn
├── scripts/
│   ├── main.gd
│   ├── game/
│   │   ├── player.gd
│   │   ├── building.gd
│   │   ├── mailbox.gd
│   │   ├── npc.gd
│   │   └── mail.gd
│   ├── ui/
│   │   ├── hud.gd
│   │   ├── title_screen.gd
│   │   └── complete_screen.gd
│   └── autoload/
│       └── game_data.gd   ← 전역 상태 (우편물, 게임 진행)
└── maps/
    └── tutorial.json       ← 기존 에디터 맵 데이터 (호환용)
```

---

## 4. 씬 트리 설계

### 4.1 Main (main.tscn)

```
Main (Node)
├── TitleScreen (Control)          ← 시작 시 표시
└── GameWorld (Node3D)             ← 시작하기 클릭 시 활성화
    ├── Environment
    │   ├── WorldEnvironment
    │   ├── DirectionalLight3D     ← H=40, P=-45, (1.0, 0.92, 0.8)
    │   └── Ground (MeshInstance3D) ← 평면 + grass 텍스처
    ├── Camera3D                    ← Orthographic, 플레이어 추적
    ├── Player (CharacterBody3D)
    ├── Map (Node3D)
    │   ├── Roads (Node3D)
    │   ├── Buildings (Node3D)      ← Building 씬 인스턴스들
    │   ├── Mailboxes (Node3D)
    │   ├── NPCs (Node3D)
    │   ├── Trees (Node3D)
    │   └── Decorations (Node3D)
    └── HUD (CanvasLayer)
        ├── DeliveryList (VBoxContainer)
        ├── TutorialHint (PanelContainer)
        ├── InteractHint (Label)
        └── ControlGuide (Label)
```

### 4.2 Player (player.tscn)

```
Player (CharacterBody3D)
├── Body (MeshInstance3D)           ← BoxMesh (0.5, 1.0, 0.5), orange
├── Head (MeshInstance3D)           ← SphereMesh (0.6), yellow, y=0.8
├── CollisionShape3D                ← BoxShape3D
└── InteractArea (Area3D)           ← SphereShape3D radius=2.5
    └── CollisionShape3D
```

### 4.3 Building (building.tscn)

```
Building (StaticBody3D)
├── Model (MeshInstance3D 또는 Node3D) ← GLB 모델
├── CollisionShape3D                    ← BoxShape3D
├── Label3D                             ← 건물 이름 빌보드
└── InteractArea (Area3D)               ← 상호작용 범위
```

### 4.4 NPC (npc.tscn)

```
NPC (StaticBody3D)
├── Body (MeshInstance3D)           ← BoxMesh (0.45, 0.9, 0.45)
├── Head (MeshInstance3D)           ← SphereMesh (0.65), y=0.75
├── CollisionShape3D
├── NameTag (Label3D)               ← "Kenny", 빌보드
└── InteractArea (Area3D)
```

---

## 5. 스크립트 설계

### 5.1 game_data.gd (Autoload 전역)

```
역할: 우편물 목록, 게임 상태 관리
보존: Mail 구조체, MAIL_TYPES, get_tutorial_mails()

변수:
  - mails: Array[Mail]
  - game_started: bool

함수:
  - get_tutorial_mails() → Array[Mail]
  - is_all_delivered() → bool
```

### 5.2 player.gd

```
역할: 이동, 충돌, 상호작용
보존: 이동 속도(5), 쿨다운(2.0), 거리 판정(2.5)

핵심 로직:
  - _physics_process(): WASD 이동 (카메라 yaw 135도 기준 방향 계산)
  - move_and_slide(): 벽 슬라이딩 자동 처리 (Ursina보다 간단)
  - _input(): E키 → InteractArea 내 가장 가까운 interactable 호출
```

### 5.3 building.gd / mailbox.gd / npc.gd

```
역할: 상호작용 인터페이스 구현
보존: interact(player) 로직 그대로

공통 인터페이스:
  - interactable: bool
  - interact_label: String
  - interact(player) → void
```

### 5.4 hud.gd

```
역할: 배달 목록, 튜토리얼 안내
보존: STEPS 딕셔너리, update() 로직, show_complete()
```

### 5.5 title_screen.gd

```
역할: 타이틀, 설정, 크레딧
보존: 버튼 3개, 설정 패널, 크레딧 패널, 패널 열림 시 버튼 비활성화
```

---

## 6. 단계별 작업 계획

### Phase 1: 프로젝트 초기화 + 기본 월드 ✅ 완료

```
완료 항목:
  1. Godot 4.x 프로젝트 생성 (mail-deliver-godot)
  2. 기본 에셋 복사 (grass_block.jpeg, title.png, malgun.ttf)
  3. 메인 씬 구성 (scenes/main.tscn):
     - WorldEnvironment (배경색 #B4D2FF, Custom Color)
     - DirectionalLight3D (색상 #FFF5CC, Rotation X=-45 Y=40)
     - Ground MeshInstance3D (PlaneMesh 80x80, 단색 #B4DC96)
  4. Camera3D 설정 (Orthographic, size=22, Rotation X=-30 Y=135)
  5. Player 씬 생성 (scenes/player.tscn, CharacterBody3D)

비고:
  - grass_block.jpeg 텍스처는 마인크래프트 스타일이라 단색으로 대체
  - main.tscn을 메인 씬으로 설정 완료
  - GitHub 커밋 완료 (b3e0d9d)

검증 완료:
  - ✅ 게임 실행 시 초록 바닥 + 하늘색 배경 보임
  - ✅ 카메라 쿼터뷰 각도 확인
```

### Phase 2: 플레이어 이동 + 충돌 (1일차)

```
작업 목록:
  1. Player CharacterBody3D 구성 (큐브+구)
  2. 이동 로직 (WASD, 속도 5, 카메라 기준 방향)
  3. move_and_slide() 충돌 처리
  4. 테스트용 벽 배치

검증:
  - WASD로 이동, 벽에 부딪히면 슬라이딩
  - 카메라가 플레이어 추적
```

### Phase 3: 맵 배치 (2일차)

```
작업 목록:
  1. Kenney 모델을 Godot 씬에 직접 배치 (에디터 드래그&드롭)
  2. 도로 네트워크 (road-straight, crossroad, roundabout 등)
  3. 구역 A: 우체국, 상업 건물 4개, 주거 건물 6개
  4. 구역 B: Kenny 집, 주택 10개
  5. 소공원, 나무, 장식물
  6. Nature 킷 모델 배치 → PBR 색상 자동 적용 확인

검증:
  - 모든 모델에 색상 정상 표시 (특히 Nature 킷!)
  - 건물 위치/회전 기존과 일치
```

### Phase 4: 상호작용 시스템 (2일차)

```
작업 목록:
  1. Interactable 인터페이스 정의
  2. Building 씬 + 스크립트 (배달 판정, 점멸 효과)
  3. Mailbox 씬 + 스크립트 (편지 투입)
  4. NPC 씬 + 스크립트 (가벼운 인삿말 + 등기 전달)
  5. Player InteractArea (2.5 범위) + E키 입력
  6. 상호작용 힌트 텍스트 "[E] Dolly의 집"
  7. 메시지 표시 (2.0~2.5초 자동 소멸)

검증:
  - E키로 건물/우체통/NPC와 상호작용
  - 편지→우체통, 소포→건물, 등기→NPC 정상 작동
  - 쿨다운 2초 작동
```

### Phase 5: 우편물 + HUD (3일차)

```
작업 목록:
  1. Mail 리소스 클래스 (mail_type, recipient, target_id, delivered)
  2. game_data.gd Autoload (우편물 목록, 상태)
  3. HUD 씬:
     - 배달 목록 (좌상단, 반투명 검정 배경)
     - 튜토리얼 안내 (중상단, 단계별 힌트)
     - 조작 안내 (하단)
  4. 완료 화면 (배달 완료!, 다시 하기 버튼)

검증:
  - 배달 시 목록 갱신 (체크 표시, 회색 전환)
  - 전부 배달 시 완료 화면 표시
  - 다시 하기 → 처음부터 재시작
```

### Phase 6: 타이틀 화면 (3일차)

```
작업 목록:
  1. 타이틀 씬 (title.png 배경, 버튼 3개)
  2. 설정 패널 (BGM/효과음 볼륨 — UI만, 기능은 나중에)
  3. 크레딧 패널
  4. 패널 열림 시 메인 버튼 비활성화
  5. 시작하기 → GameWorld 씬 전환

검증:
  - 타이틀 → 시작하기 → 게임 → 완료 → 재시작 전체 흐름
```

### Phase 7: 에디터 맵 데이터 호환 (선택)

```
작업 목록:
  1. 기존 tutorial.json 로드 스크립트 (maps/ 폴더)
  2. JSON → Godot 씬 변환 도구 (1회성)

비고:
  - Godot 에디터에서 직접 배치하므로 editor.py는 마이그레이션 불필요
  - 기존 JSON 데이터는 참고용으로 보존
```

---

## 7. Ursina → Godot 매핑 표

### 7.1 노드 타입

| Ursina | Godot |
|--------|-------|
| Entity(model='cube') | MeshInstance3D + BoxMesh |
| Entity(model='sphere') | MeshInstance3D + SphereMesh |
| Entity(model='plane') | MeshInstance3D + PlaneMesh |
| Entity(model='quad') | MeshInstance3D + QuadMesh |
| Entity(model='path.glb') | PackedScene.instantiate() |
| Entity(collider='box') | StaticBody3D + CollisionShape3D |
| Text(billboard=True) | Label3D |
| Text(parent=camera.ui) | Label (Control 노드) |
| Button() | Button (Control 노드) |
| camera.ui | CanvasLayer |

### 7.2 입력

| Ursina | Godot |
|--------|-------|
| held_keys['w'] | Input.is_action_pressed("move_forward") |
| input(key) == 'e' | Input.is_action_just_pressed("interact") |
| mouse.world_point | Raycast / InputEventMouse |

### 7.3 유틸리티

| Ursina | Godot |
|--------|-------|
| distance(a, b) | a.global_position.distance_to(b.global_position) |
| destroy(entity) | entity.queue_free() |
| destroy(entity, delay=2) | get_tree().create_timer(2).timeout.connect(entity.queue_free) |
| invoke(func, delay=0.6) | get_tree().create_timer(0.6).timeout.connect(func) |
| time.dt | delta (in _process / _physics_process) |
| color.orange | Color.ORANGE |
| color.rgba(r,g,b,a) | Color(r/255.0, g/255.0, b/255.0, a/255.0) |

### 7.4 씬 전환

| Ursina | Godot |
|--------|-------|
| TitleScreen → start_game() | get_tree().change_scene_to_file() 또는 노드 visibility 전환 |
| os.execv (재시작) | get_tree().reload_current_scene() |

---

## 8. 에셋 임포트 주의사항

### 8.1 Kenney GLB 모델

| 에셋 팩 | 특이사항 | Godot 처리 |
|--------|---------|-----------|
| Suburban | colormap.png 내장 | 자동 인식 |
| Roads | colormap.png 내장 | 자동 인식 |
| Commercial | colormap.png 내장 | 자동 인식 |
| Cars | colormap.png 내장 | 자동 인식 |
| **Nature** | **baseColorFactor만 (텍스처 없음)** | **Godot PBR이 자동 처리** |

### 8.2 스케일 프리셋 (배치 시 적용)

| 카테고리 | 스케일 |
|---------|--------|
| 도로 | (2, 2, 2) |
| 건물 | (2, 2, 2) |
| 나무 (보통) | (1.5, 1.5, 1.5) |
| 나무 (큰) | (2, 2, 2) |
| 꽃/식물 | (1, 1, 1) |
| 차량 | (1.5, 1.5, 1.5) |
| 소품 | (1.5, 1.5, 1.5) |

### 8.3 한글 폰트

- malgun.ttf → assets/fonts/에 복사
- Godot Theme 또는 각 Control 노드에 커스텀 폰트로 설정
- DynamicFont 사이즈 조절 필요

---

## 9. 리스크 및 대응

| 리스크 | 확률 | 대응 |
|--------|------|------|
| GDScript 학습 곡선 | 낮음 | Python과 유사, 공식 문서 참고 |
| Nature 킷 PBR 렌더링 | 매우 낮음 | Godot 3D PBR 기본 지원 |
| 한글 텍스트 렌더링 | 낮음 | TTF 폰트 직접 지정 |
| 맵 배치 시간 | 중간 | Godot 에디터 드래그&드롭으로 효율적 |
| 기존 JSON 맵 데이터 손실 | 낮음 | 원본 프로젝트 보존, JSON 참고용 유지 |

---

## 10. 일정 요약

| 일차 | 작업 | 산출물 |
|------|------|--------|
| **1일차** | Phase 1~2: 프로젝트 + 플레이어 | 걸어다닐 수 있는 월드 |
| **2일차** | Phase 3~4: 맵 배치 + 상호작용 | 건물/우체통/NPC 배치 + E키 작동 |
| **3일차** | Phase 5~6: HUD + 타이틀 | 전체 게임 흐름 완성 |
| **4일차** | 테스트 + 버그 수정 + 폴리싱 | 배포 가능 상태 |

**총 예상: 3~4일**

---

## 11. 시작 전 체크리스트

- [ ] Godot 4.x 설치 (https://godotengine.org)
- [ ] 새 프로젝트 폴더 생성
- [ ] Kenney 에셋 5개 팩 복사 (기존 assets/ 폴더에서)
- [ ] malgun.ttf + grass_block.jpeg + title.png 복사
- [ ] 기존 프로젝트 원본 보존 (건드리지 않음)
