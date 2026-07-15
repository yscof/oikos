# 오이코스 (Oikos) — 가계부 앱 구현 계획

## Context

사용자의 3개 제품 문서(기존 가계부 인사이트, Product Document, Best Product)를 바탕으로 새 가계부 앱을 만든다. 핵심 철학: **"돈을 관리하게 만드는 것이 아니라, 자연스럽게 이해하게 만든다."** 첫 화면은 거래내역/달력이 아니라 날씨앱처럼 "내 금융 상태"를 한 문장으로 보여주는 인사이트 공간이고, 기록은 평균 3초(금액 입력 → 스마트 카테고리 추천 → 저장)가 목표다.

현재 didim 저장소는 다른 제품(챌린지 코칭)이므로 **새 독립 저장소**로 만들되, didim의 검증된 기술 패턴(Flutter + Riverpod + GoRouter + SharedPreferences, 테스트 패턴, CI 구조)과 android/ios/web 플랫폼 스캐폴드를 복사·개명해 재사용한다.

**확정된 결정:**
- 이름: **오이코스 (Oikos)** — 그리스어 οἶκος(집·가정), economy의 어원
- 위치: `c:\Users\user\Desktop\oikos` + 새 GitHub 저장소 `yscof/oikos` (public 권장 — Actions 무료)
- 인사이트: **룰 기반, 완전 오프라인** (서버·API 키 없음, "Invisible AI" 철학 부합)
- 기록: 수동 3초 기록만 (알림 파싱 없음)
- 타겟: Google Play + iOS App Store (스토어 제출은 후속 마일스톤)

**환경 제약 (didim과 동일 워크플로):**
- 로컬 Flutter SDK 없음 → `flutter create` 불가, 모든 파일 수작업 작성. 검증은 main 푸시 → GitHub Actions
- codegen(build_runner) 의존성 금지
- `gh` CLI 미설치 확인됨 → GitHub 저장소는 사용자가 github.com/new 에서 수동 생성

## 정체성 결정

| 항목 | 값 | 비고 |
|---|---|---|
| Dart 패키지명 | `oikos` | |
| Application ID / Bundle ID | `com.oikos.app` | 첫 Play Console 업로드 전까지 변경 가능(3파일). 도메인 미보유 시 `com.yscof.oikos` 대안 — 사용자에게 업로드 전 확정 요청 |
| 앱 표시명 | `오이코스` | AndroidManifest label, iOS CFBundleDisplayName |
| 브랜드 색 | seed `0xFF5E7A66` (차분한 세이지 그린) | didim 그린(#2F6B4F)과 구분, "편안함" 원칙. light+dark 테마 모두 fromSeed. **지출 금액에 빨간색 절대 금지** |

## 1. 스캐폴드 — didim에서 복사/개명

프로젝트는 저장소 루트에 배치 (frontend/ 하위 아님).

**그대로 복사** (`didim\frontend\` 기준): `.gitignore`, `.metadata`, `analysis_options.yaml`, `android/` 전체(아래 개명 파일 제외 — AGP 9.0.1/Kotlin 2.3.20/Gradle 9.1.0 wrapper 포함), `ios/` 전체(아래 개명 파일 제외), `web/` 아이콘류.

**복사 후 개명** (검증 완료된 위치):
| 파일 | 변경 |
|---|---|
| `android/app/build.gradle.kts` | L8 `namespace`, L19 `applicationId` → `com.oikos.app` |
| `android/app/src/main/AndroidManifest.xml` | `android:label="오이코스"` |
| `android/app/src/main/kotlin/com/oikos/app/MainActivity.kt` | 경로 이동(`com/didim/didim/` →) + `package com.oikos.app` |
| `ios/Runner.xcodeproj/project.pbxproj` | `com.didim.didim` 6곳 (L385, 401, 418, 433, 564, 586) → `com.oikos.app`(.RunnerTests 포함) |
| `ios/Runner/Info.plist` | CFBundleDisplayName `오이코스`, CFBundleName `oikos` |
| `web/index.html`, `web/manifest.json` | 타이틀/이름 `오이코스`, theme_color `#5E7A66` |
| `pubspec.yaml` | 신규 작성: `name: oikos`, sdk `^3.12.2`, deps: flutter_riverpod ^3.3.2, go_router ^17.3.0, shared_preferences ^2.5.5, cupertino_icons ^1.0.8; dev: flutter_lints ^6.0.0. image_picker 제외 |

didim의 `lib/`, `test/`, `pubspec.lock`은 복사하지 않음 — 패턴만 재구현. lock은 CI 아티팩트로 받아 커밋.

## 2. 파일 트리 (lib/)

```
lib/
├─ main.dart                  # OikosApp: ProviderScope + sharedPreferencesProvider override (didim main.dart 패턴)
├─ app/router.dart            # per-instance createRouter(): '/', '/history', '/settings'
├─ app/theme.dart             # fromSeed(0xFF5E7A66) light+dark, Cupertino 전환 전 플랫폼 적용
├─ core/clock.dart            # clockProvider: DateTime Function() — 테스트 시간 주입
├─ core/formats.dart          # won() KRW 포맷터(didim models.dart 재구현), 날짜 라벨(오늘/어제/M월 d일)
├─ data/entry.dart            # EntryKind(지출/수입), Category enum, Entry 모델 + 관용적 fromJson
├─ data/entry_store.dart      # EntryNotifier(Notifier<List<Entry>>) + prefs 저장 + 파생 프로바이더
├─ insight/
│  ├─ insight.dart            # Insight 모델 + evidence(근거 수치)
│  ├─ baseline.dart           # 주간 baseline 통계 (pure Dart)
│  ├─ insight_engine.dart     # 룰 평가 + 결정적 선택
│  ├─ insight_messages.dart   # 모든 사용자 노출 문장 단일 파일 + 톤 계약
│  └─ category_suggester.dart # 스마트 카테고리 추천
└─ features/
   ├─ home/                   # home_screen, insight_card, recent_entries
   ├─ record/record_sheet.dart
   ├─ history/history_screen.dart
   └─ settings/settings_screen.dart
```

## 3. 데이터 레이어

- **저장: SharedPreferences JSON** (키 `oikos_entries_v1`, didim `LedgerNotifier` 패턴). 근거: codegen 금지 제약, 검증된 테스트 패턴, 인사이트 엔진이 어차피 전체 목록을 메모리에 필요로 함. 헤비유저 연 ~3.6천 건 ≈ 550KB/년으로 충분. 모든 읽기가 프로바이더 경유이므로 1만 건 초과 시 sqflite 전환은 1파일 교체(문서화만 해둠).
- **Entry**: `id, kind, amountWon, category, memo("금융 경험" 한 줄), occurredAt(시각 포함 — 추천기 입력), createdAt`. `fromJson`은 미지 카테고리 → `etc`로 관용 처리(구버전 호환).
- **Category** (20-30대 소비축, 아이콘 포함): 식사, 카페·간식, **배달**, 편의점·마트, **온라인쇼핑**, **술·모임**, 교통, 구독, 문화·여가, 패션·뷰티, 주거·통신, 의료·건강, 기타 + 수입(월급, 기타 수입). 배달/온라인쇼핑/술·모임은 문서의 인사이트 예문이 의존하므로 1급 카테고리.

## 4. 룰 기반 인사이트 엔진 (pure Dart, 결정적)

입력 `(List<Entry>, DateTime now)`. Baseline = 이번 주(월요일 시작) 이전 4주 평균.

**룰** (각각 pure function → 후보 + 우선순위 + 근거):
1. **CategoryDeltaUp**: 이번 주 카테고리 지출 ≥ 1.4× baseline (하한 필터 포함) → 『이번 주 {카테고리} 소비가 평소보다 조금 많았어요』
2. **CategoryDeltaDown**: ≤ 0.6× → 『…평소보다 줄었어요』 (담백한 긍정, 칭찬 게임화 금지)
3. **Frequency**: 건수 ≥ 3 그리고 ≥ 2× baseline 건수 → 『이번 주는 {카테고리}이(가) 잦았어요』
4. **QuietWeek**: 주 3일차 이후 총액 ≤ 0.7× → 『이번 주는 평소보다 차분한 소비 흐름이에요』
5. **WeekdayPattern** (저순위): 특정 요일 집중 → 『주로 {요일}에 소비가 모이는 편이에요』
6. **ColdStart** (기록 <8건 또는 <7일): 『기록이 쌓이면 소비의 흐름을 읽어드릴게요』 등 순환

**선택**: 우선순위 정렬 → 1위 = 홈 헤드라인, 이후 다른 룰 타입 ≤2개 = "이번 주 감각" 보조 라인. 같은 날 같은 데이터 = 같은 문장 (신뢰).

**톤 계약**: 모든 문장은 `insight_messages.dart` 한 곳에만 존재. 명령형(~하세요/마세요)·판단어(과소비/낭비) 금지 — **유닛 테스트로 기계 검증**. 헤드라인 탭 → 『이렇게 읽었어요: 최근 4주 평균 3.2만원 → 이번 주 5.1만원』 근거 시트 (설명가능성). 앱 어디에도 "AI"라는 단어 없음.

## 5. 스마트 카테고리 추천 (category_suggester.dart)

`rank(now, amountWon, history)` → 점수순 카테고리. 점수 = `2.0×과거이력매칭 + 1.0×콜드스타트 prior`.
- 이력 매칭: 시간대 버킷(아침/점심/오후/저녁/밤/새벽) + 금액 밴드(≤5천/~1.5만/~5만/~15만/초과) + 평일·주말 일치도, 지수 감쇠(반감기 30일)
- 콜드스타트 prior 하드코딩 표: 점심+5천~1.5만→식사, 밤+1.5만~5만→배달·술, 주말오후→온라인쇼핑 등
- 문서의 정본 케이스가 곧 테스트: `평일 12:30 + 12,000원 → 식사` 1위

## 6. 화면 스펙 (한 화면 한 목적, 바텀내비 없음)

- **홈 `/`**: 상단 날짜 라벨 + 조용한 아이콘 2개(내역/설정) → **헤드라인 인사이트 큰 문장**(탭=근거 시트) → 보조 라인 ≤2 → 『이번 주 지출 12만 4천원』 무채색 소문(차트 아님) → 최근 기록 3건 → 하단 풀폭 **기록하기** 버튼. 포인트/배지/스트릭 일절 없음.
- **기록 시트 (모달)**: 금액 필드 자동포커스(숫자 키보드) → 카테고리 칩이 추천순 실시간 재정렬 + **1위 자동 선택** → 저장. 해피패스 = 입력 2번 ≈ 3초. 메모 placeholder 『어떤 순간이었나요? (선택)』. 지출/수입 세그먼트(지출 기본), 날짜 『오늘』 버튼. 저장 후 팡파레 없음.
- **내역 `/history`**: 날짜 그룹 타임라인(오늘/어제/M월 d일), 월 경계는 『7월 · 지출 42만원』 무채색 구분선. 탭=수정(M5), 롱프레스=삭제. 의미는 홈에, 여기는 사실만.
- **설정 `/settings`**: 데이터 내보내기(JSON→클립보드), 모든 데이터 삭제(확인), 오픈소스 라이선스, 버전, 『모든 데이터는 이 기기에만 저장됩니다』.

**v1 제외 (명시적)**: 예산/한도, 목표, **모든 차트**(문장이 차트를 대체 — 제품의 승부수), 계좌 연동, 알림/푸시, 반복거래, 검색/필터, 다중통화, 로그인/동기화, 위젯.

## 7. CI — `.github/workflows/ci.yml`

didim `deploy-web.yml` 구조 재사용, 단일 `verify` 잡(ubuntu-latest), push main + PR + workflow_dispatch:
checkout → **setup-java (temurin 17, AGP 9 필수 — didim 웹 워크플로엔 없던 단계)** → subosito/flutter-action@v2(stable, cache) → pub get → analyze → test → `flutter build apk --release`(복사한 gradle이 debug 서명 폴백이라 무서명 성공) → **APK 아티팩트 업로드**(안드로이드 폰 사이드로드 테스트용) + 최초 1회 `pubspec.lock` 아티팩트(받아서 커밋).

iOS CI는 M6에서 `workflow_dispatch` 전용 잡(macos-latest, `flutter build ios --no-codesign`)으로 추가 — 푸시마다 돌리기엔 신호 대비 지연이 큼.

## 8. 테스트 전략

- `insight_engine_test.dart`: 고정 시계 + 합성 이력, 룰 경계값 on/off, 콜드스타트 게이트, 결정성, **톤 테스트**(금지어 부재 기계 검증), 근거 수치 정확성
- `category_suggester_test.dart`: 정본 케이스(12:30+12,000→식사), 이력 우세, 감쇠, 수입 제외
- `entry_store_test.dart`: didim `ledger_test.dart` 패턴 — setMockInitialValues + ProviderContainer 2개로 영속 왕복, 손상 JSON→[], 미지 카테고리→etc
- `record_flow_test.dart`/`home_test.dart` (위젯): 시트 열기→12000 입력→선선택 칩 확인→저장→홈/내역 반영, 삭제, 빈 상태

## 9. 마일스톤 (각 = 1 push = 1 CI 검증)

- **M0 — CI 그린 셸**: 플랫폼 복사·개명 + pubspec + theme + 최소 main/홈 + 스모크 테스트 + ci.yml + README. 푸시 → 전부 그린 + APK 아티팩트. 후속 커밋으로 pubspec.lock.
- **M1 — 데이터 레이어**: entry, entry_store, clock, formats + 유닛 테스트
- **M2 — 기록 + 내역**: record_sheet(TextField 버전), 홈 최근 기록, history, 라우터 + 위젯 테스트
- **M3 — 추천기**: 칩 정렬·선선택 연결 + 테스트
- **M4 — 인사이트 엔진**: baseline/engine/messages, 홈 헤드라인 + 감각 라인 + 근거 시트 + 테스트 ← 이 마일스톤이 "오이코스"를 만든다
- **M5 — 설정 + 수정**: 설정 화면, 항목 수정, 빈 상태 다듬기
- **M6 — 3초 폴리시**: 커스텀 금액 키패드, 다크모드/타이포 패스, 앱 아이콘, iOS 빌드 워크플로
- **M7+ — 스토어 트랙**: 개인정보처리방침(GitHub Pages 정적 페이지 — 오프라인 앱이라 "데이터 수집 없음"으로 양 스토어 서식 최단 경로), Play 키스토어(CI keytool + secrets) + appbundle, Apple Developer/서명은 그때 결정. applicationId 최종 확정은 첫 업로드 전.

## 10. Git/GitHub 부트스트랩

1. `c:\Users\user\Desktop\oikos` 생성 → M0 파일 작성 → `git init -b main` → 첫 커밋
2. **사용자 작업**: github.com/new 에서 빈 저장소 `yscof/oikos` 생성 (README 없이, public 권장) — gh CLI 미설치
3. `git remote add origin https://github.com/yscof/oikos.git` → `git push -u origin main` → Actions 자동 트리거

## 검증 방법

로컬 Flutter가 없으므로 **모든 검증은 CI**: 각 마일스톤 푸시 후 GitHub Actions 실행 결과 확인(analyze/test/APK 빌드 그린). 사용자는 Actions 실행 페이지에서 APK 아티팩트를 받아 안드로이드 기기에서 실사용 확인 가능. 유닛/위젯 테스트가 인사이트 룰·추천기·기록 플로를 커버하므로 CI 그린 = 핵심 로직 검증 완료.
