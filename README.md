# 오이코스 (Oikos)

> 돈을 관리하게 만드는 것이 아니라, 자연스럽게 이해하게 만든다.

그리스어 οἶκος(집·가정, economy의 어원)에서 이름을 딴 가계부 앱.
Google Play와 iOS App Store 동시 출시를 목표로 하는 Flutter 앱입니다.

## 제품 원칙 (요약)

- 첫 화면은 거래내역이 아니라 **"내 금융 상태" 한 문장** — 날씨앱이 날씨를 보여주듯
- 기록은 **평균 3초**: 금액 입력 → 스마트 카테고리 추천 → 저장
- **Invisible AI**: 룰 기반 온디바이스 인사이트. "AI"라는 단어는 앱 어디에도 없음
- 게임화 없음(포인트·배지·스트릭 X), 알림 남발 없음, 빨간 숫자 없음 — 편안함이 기본값
- 완전 오프라인: 모든 데이터는 기기에만 저장, 서버·계정·수집 없음

## 현재 구현된 것

- **홈** (`/`) — 헤드라인 인사이트 한 문장(탭하면 "이렇게 읽었어요" 근거 시트), 보조 감각 라인, 주간 지출 소문, 최근 기록 3건, 풀폭 기록하기 버튼
- **기록 시트** — 금액 자동 포커스 → 카테고리 칩이 추천순으로 실시간 재정렬되고 1위가 자동 선택 → 저장. 지출/수입 세그먼트, 메모·날짜는 선택
- **스마트 카테고리 추천** — 시간대·금액대·평일/주말 이력 매칭(지수 감쇠) + 콜드스타트 prior. 예: 평일 12:30 + 12,000원 → 식사
- **룰 기반 인사이트 엔진** — 6개 룰(카테고리 증가/감소, 빈도, 조용한 주, 요일 패턴, 콜드스타트) + steady 폴백. 같은 날 같은 데이터면 항상 같은 문장(결정적)
- **내역** (`/history`) — 날짜 그룹 타임라인, 월 경계 구분선, 탭=수정, 롱프레스=삭제
- **설정** (`/settings`) — JSON 내보내기(클립보드), 전체 삭제, 오픈소스 라이선스, 버전

v1에서 의도적으로 뺀 것: 예산/한도, 목표, 모든 차트, 계좌 연동, 알림, 검색/필터, 로그인/동기화.

## 기술

- Flutter (android / ios / web), Material 3, 시드 컬러 `#5E7A66`
- Riverpod + go_router + shared_preferences (codegen 없음)
- 저장은 SharedPreferences JSON 단일 키 `oikos_entries_v1` — 포맷 변경 시 v2 키 + 마이그레이션
- 로컬 Flutter SDK 없이 개발 — 검증·빌드는 GitHub Actions에서 수행

### 구조

```
lib/
├─ main.dart                  # ProviderScope + prefs override
├─ app/                       # router('/', '/history', '/settings'), theme(light+dark)
├─ core/                      # clock(시간 주입), formats(원화·날짜), prefs
├─ data/                      # Entry 모델, EntryStore(영속)
├─ insight/                   # baseline, 룰 엔진, 문장(insight_messages), 카테고리 추천기
└─ features/                  # home / record / history / settings 화면
```

## 개발 워크플로

1. main에 푸시 → Actions가 `analyze` → `test` → APK(→ 서명 secrets 등록 시 AAB) 빌드
2. Actions 실행 페이지에서 `oikos-apk` 아티팩트를 받아 기기에서 사이드로드 확인

### 지켜야 할 규칙

- codegen(build_runner) 의존성 금지
- 사용자에게 노출되는 인사이트 문장은 `lib/insight/insight_messages.dart` 한 곳에만 — 명령형·판단어 금지 톤 계약을 `test/tone_test.dart`가 기계 검증
- 지출 금액에 빨간색 금지, 게임화 요소 금지
- 스토어 업로드 시 `pubspec.yaml`의 buildNumber(+N)를 올릴 것

## 남은 로드맵

- **M6 — 3초 폴리시**: 커스텀 금액 키패드, 다크모드/타이포 패스, 앱 아이콘, iOS 빌드 워크플로
- **M7 — 스토어 트랙**: Play Console 등록·폐쇄 테스트, 개인정보처리방침 페이지 공개, iOS는 Apple Developer 가입 후 결정

전체 구현 계획과 근거는 [docs/PLAN.md](docs/PLAN.md) 참고.
